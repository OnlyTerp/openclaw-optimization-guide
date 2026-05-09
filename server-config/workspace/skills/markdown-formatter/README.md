# Markdown-Formatter

**Format markdown. Keep your docs beautiful.** 🔮

## Quick Start

```bash
# Install
clawhub install markdown-formatter

# Format a document
cd ~/.openclaw/skills/markdown-formatter
node index.js formatMarkdown '{"markdown":"# My Title","style":"github"}'
```

## Features

- ✅ Multiple style guides (CommonMark, GitHub Flavored Markdown, custom rules)
- ✅ Linting & Cleanup
- ✅ Beautification
- ✅ Validation
- ✅ Smart heading normalization
- ✅ Link reference optimization

## Tool Functions

### `formatMarkdown`
Format markdown content according to style guide.

**Parameters:**
- `markdown` (string, required): Markdown content to format
- `style` (string, required): Style guide name ('commonmark', 'github', 'commonmark', 'custom')
- `options` (object, optional): Style guide options
  - `maxWidth` (number): Line wrap width (default: 80)
  - `headingStyle` (string): 'atx' | 'setext' | 'underlined' | 'consistent' (default: 'atx')
  - `listStyle` (string): 'consistent' | 'dash' | 'asterisk' | 'plus' (default: 'consistent')
  - `codeStyle` (string): 'fenced' | 'indented' (default: 'fenced')
  - `emphasisStyle` (string): 'underscore' | 'asterisk' (default: 'asterisk')
  - `strongStyle` (string): 'asterisk' | 'underline' (default: 'asterisk')
  - `linkStyle` (string): 'inline' | 'reference' | 'full' (default: 'inline')
  - `preserveHtml` (boolean): Keep HTML as-is (default: false)
  - `fixLists` (boolean): Fix inconsistent list markers (default: true)
  - `normalizeSpacing` (boolean): Fix spacing around formatting (default: true)

**Returns:**
- `formattedMarkdown` (string): Formatted markdown
- `warnings` (array): Array of warning messages
- `stats` (object): Formatting statistics

### `formatBatch`
Format multiple markdown files at once.

**Parameters:**
- `markdownFiles` (array, required): Array of file paths
- `style` (string, required): Style guide name
- `options` (object, optional): Same as formatMarkdown options

**Returns:**
- `results` (array): Array of formatting results
- `totalFiles` (number): Number of files processed
- `totalWarnings` (number): Total warnings across all files
- `processingTime` (number): Time taken in ms

### `lintMarkdown`
Check markdown for issues without formatting.

**Parameters:**
- `markdown` (string, required): Markdown content to lint
- `style` (string, required): Style guide name
- `options` (object, optional): Additional linting options
  - `checkLinks` (boolean): Validate links (default: true)
  - `checkHeadingLevels` (boolean): Check heading hierarchy (default: true)
  - `checkListConsistency` (boolean): Check list marker consistency (default: true)

**Returns:**
- `errors` (array): Array of error objects
- `warnings` (array): Array of warning objects
- `stats` (object): Linting statistics

## Configuration

Edit `config.json` to customize:

```json
{
  "defaultStyle": "github",
  "maxWidth": 80,
  "headingStyle": "atx",
  "listStyle": "consistent",
  "codeStyle": "fenced",
  "emphasisStyle": "asterisk",
  "strongStyle": "asterisk",
  "linkStyle": "inline",
  "fixLists": true,
  "normalizeSpacing": true
}
```

## Examples

### Format with GitHub Style
```javascript
const result = formatMarkdown({
  markdown: '# My Document\\n\\nThis is content.',
  style: 'github'
});

console.log(result.formattedMarkdown);
```

### Format and Beautify
```javascript
const result = formatMarkdown({
  markdown: '# My Title\\n\\n## Section 1\\n\\nParagraph...',
  style: 'github',
  options: {
    fixLists: true,
    normalizeSpacing: true,
    wrapWidth: 80
  }
});
```

### Lint and Fix
```javascript
const result = lintMarkdown({
  markdown: '# Title\\n- Item 1\\n- Item 2',
  style: 'github'
});

console.log(`Errors: ${result.errors.length}`);
console.log(`Warnings: ${result.warnings.length}`);
```

---

**Format markdown. Keep your docs beautiful.** 🔮
