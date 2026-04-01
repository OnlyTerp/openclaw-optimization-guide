import fs from 'fs';
import path from 'path';

// --- CONFIGURE THESE ---
// Extraction model: Cerebras is free and fast (~3s). Or use any OpenAI-compatible API.
// Get a free Cerebras key at: https://cloud.cerebras.ai/
// If you don't have Cerebras, use your existing provider (Anthropic, OpenRouter, etc.)
const EXTRACTION_URL = process.env.AUTOCAPTURE_API_URL || 'https://api.cerebras.ai/v1/chat/completions';
const EXTRACTION_API_KEY = process.env.AUTOCAPTURE_API_KEY || process.env.CEREBRAS_API_KEY || '';
const EXTRACTION_MODEL = process.env.AUTOCAPTURE_MODEL || 'qwen-3-235b-a22b-instruct-2507';
// Set this to your workspace vault inbox path
const INBOX_PATH = process.env.AUTOCAPTURE_INBOX || path.join(
  process.env.HOME || process.env.USERPROFILE || '~',
  '.openclaw', 'workspace', 'vault', '00_inbox'
);
const MAX_MESSAGES = 30;
const MIN_USER_MESSAGES = 4;
const REQUEST_TIMEOUT_MS = 20_000;
const SYSTEM_PROMPT =
  'You are a knowledge extraction assistant. Extract durable facts, decisions, insights, and lessons from this conversation worth remembering long-term. Skip small talk and trivial exchanges. Each note must have a claim-based filename (e.g. \'threading-lock-prevents-cuda-concurrent-errors.md\'). The filename IS the knowledge - make it a specific, actionable claim. Output ONLY valid JSON: {"notes": [{"filename": "claim-name.md", "content": "# Title\\n_Extracted: DATE_\\n\\nContent..."}]}. If nothing worth saving output: {"notes": []}';

type HookEvent = {
  action?: string;
  context?: {
    previousSessionEntry?: SessionEntry;
    sessionEntry?: SessionEntry;
  };
};

type SessionEntry = {
  sessionKey?: string;
  transcriptPath?: string;
};

type TranscriptLine = {
  message?: {
    role?: string;
    content?: string | Array<{ type?: string; text?: string }>;
  };
};

type ExtractedMessage = {
  role: 'user' | 'assistant';
  text: string;
};

type CerebrasResponse = {
  choices?: Array<{
    message?: {
      content?: string;
    };
  }>;
};

type ExtractedNotesResponse = {
  notes?: Array<{
    filename?: string;
    content?: string;
  }>;
};

function getSessionForAction(event: HookEvent): SessionEntry | undefined {
  if (event.action === 'command:new' || event.action === 'command:reset') {
    return event.context?.previousSessionEntry;
  }

  if (event.action === 'session:compact:before') {
    return event.context?.sessionEntry;
  }

  return undefined;
}

function getMessageText(
  content: string | Array<{ type?: string; text?: string }> | undefined,
): string {
  if (typeof content === 'string') {
    return content;
  }

  if (!Array.isArray(content)) {
    return '';
  }

  return content
    .filter((part) => part?.type === 'text' && typeof part.text === 'string')
    .map((part) => part.text)
    .join('\n');
}

function stripUntrustedMetadata(text: string): string {
  const lines = text.split(/\r?\n/);
  const cleaned: string[] = [];
  let skippingJsonBlob = false;
  let braceDepth = 0;
  let awaitingJsonStart = false;

  for (const line of lines) {
    const trimmed = line.trim();

    if (!skippingJsonBlob && /Sender \(untrusted metadata\)/.test(line)) {
      skippingJsonBlob = true;
      braceDepth = 0;
      awaitingJsonStart = true;
      continue;
    }

    if (skippingJsonBlob) {
      if (!trimmed) {
        continue;
      }

      if (awaitingJsonStart && !trimmed.startsWith('{') && !trimmed.startsWith('[')) {
        skippingJsonBlob = false;
        awaitingJsonStart = false;
      }

      if (!skippingJsonBlob) {
        cleaned.push(line);
        continue;
      }

      awaitingJsonStart = false;
      const opens = (line.match(/[{\[]/g) ?? []).length;
      const closes = (line.match(/[}\]]/g) ?? []).length;
      braceDepth += opens - closes;

      if (braceDepth <= 0 && (opens > 0 || closes > 0)) {
        skippingJsonBlob = false;
      }

      continue;
    }

    cleaned.push(line);
  }

  return cleaned.join('\n').trim();
}

function parseTranscript(transcriptPath: string): ExtractedMessage[] {
  const raw = fs.readFileSync(transcriptPath, 'utf8');
  const lines = raw.split(/\r?\n/);
  const messages: ExtractedMessage[] = [];

  for (const line of lines) {
    if (!line.trim()) {
      continue;
    }

    const parsed = JSON.parse(line) as TranscriptLine;
    const role = parsed.message?.role;

    if (role !== 'user' && role !== 'assistant') {
      continue;
    }

    const text = stripUntrustedMetadata(getMessageText(parsed.message?.content));

    if (!text) {
      continue;
    }

    messages.push({ role, text });
  }

  return messages;
}

function formatConversation(messages: ExtractedMessage[]): string {
  return messages
    .slice(-MAX_MESSAGES)
    .map((message) =>
      `${message.role === 'user' ? 'User' : 'Assistant'}: ${message.text}`,
    )
    .join('\n');
}

function sanitizeFilename(filename: string): string {
  const base = filename
    .toLowerCase()
    .replace(/\.md$/i, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

  return `${base || 'note'}.md`;
}

async function extractNotes(conversation: string): Promise<ExtractedNotesResponse> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  try {
    if (!EXTRACTION_API_KEY) {
      throw new Error('No API key configured. Set AUTOCAPTURE_API_KEY or CEREBRAS_API_KEY env var.');
    }

    const response = await fetch(EXTRACTION_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${EXTRACTION_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: EXTRACTION_MODEL,
        temperature: 0,
        max_tokens: 2000,
        messages: [
          {
            role: 'system',
            content: SYSTEM_PROMPT,
          },
          {
            role: 'user',
            content: conversation,
          },
        ],
      }),
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(`Cerebras API request failed: ${response.status}`);
    }

    const payload = (await response.json()) as CerebrasResponse;
    const content = payload.choices?.[0]?.message?.content;

    if (typeof content !== 'string') {
      throw new Error('Cerebras API returned no message content');
    }

    return JSON.parse(content) as ExtractedNotesResponse;
  } finally {
    clearTimeout(timeout);
  }
}

function writeNotes(notes: ExtractedNotesResponse['notes']): number {
  fs.mkdirSync(INBOX_PATH, { recursive: true });

  let savedCount = 0;

  for (const note of notes ?? []) {
    if (typeof note?.filename !== 'string' || typeof note.content !== 'string') {
      continue;
    }

    const filename = sanitizeFilename(note.filename);
    const outputPath = path.join(INBOX_PATH, filename);

    if (fs.existsSync(outputPath)) {
      continue;
    }

    fs.writeFileSync(outputPath, note.content, 'utf8');
    savedCount += 1;
    console.log(`[auto-capture] Saved: ${filename}`);
  }

  return savedCount;
}

export default async function handler(event: HookEvent): Promise<void> {
  void (async () => {
    try {
      const action = event.action ?? '';
      const session = getSessionForAction(event);
      const sessionKey = session?.sessionKey ?? 'unknown';

      console.log(`[auto-capture] Triggered: ${action} on ${sessionKey}`);

      if (!session?.transcriptPath) {
        return;
      }

      const messages = parseTranscript(session.transcriptPath);
      const userMessageCount = messages.filter(
        (message) => message.role === 'user',
      ).length;

      if (userMessageCount < MIN_USER_MESSAGES) {
        return;
      }

      const conversation = formatConversation(messages);
      const extracted = await extractNotes(conversation);
      const noteCount = extracted.notes?.length ?? 0;

      console.log(`[auto-capture] Extracted ${noteCount} notes`);

      if (noteCount === 0) {
        console.log('[auto-capture] Nothing worth saving');
        return;
      }

      writeNotes(extracted.notes);
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unknown error';
      console.log(`[auto-capture] Error: ${message}`);
    }
  })();
}
