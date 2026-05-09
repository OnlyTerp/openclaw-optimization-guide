# MinerU Online Document Parsing Complete Guide (URL Method)

> Parse online PDFs directly using MinerU API (no local upload needed), supports formulas, tables, OCR

---

## 📋 Prerequisites

### 1. Environment Requirements
- `curl` command (usually pre-installed)
- `unzip` tool (for extracting results)
- MinerU API Token
- `jq` (optional but recommended for enhanced JSON parsing and security)

### 2. Configure Environment Variables

Scripts automatically read MinerU Token from environment variables (choose one):

```bash
# Option 1: Set MINERU_TOKEN
export MINERU_TOKEN="your_api_token_here"

# Option 2: Set MINERU_API_KEY (alias, also works)
export MINERU_API_KEY="your_api_token_here"

# Optional: Set API base URL (default is pre-configured)
export MINERU_BASE_URL="https://mineru.net/api/v4"
```

> 💡 **Get Token**: Visit https://mineru.net/apiManage/docs

---

## 🚀 Complete Process (2 Steps)

Online document parsing is **more concise** than local upload, only requires **2 steps**!

### Step 1: Submit Parsing Task (Provide URL)

**Command:**
```bash
curl -X POST "${MINERU_BASE_URL}/extract/task" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MINERU_TOKEN}" \
    -d '{
        "url": "https://example.com/path/to/your.pdf",
        "enable_formula": true,
        "language": "ch",
        "enable_table": true,
        "layout_model": "doclayout_yolo"
    }'
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | string | ✅ **Yes** | Complete URL of online PDF (supports http/https) |
| `enable_formula` | bool | No | Enable formula recognition, default true |
| `enable_table` | bool | No | Enable table recognition, default true |
| `language` | string | No | Language: `ch` (Chinese) / `en` (English) / `auto` |
| `layout_model` | string | No | Layout model: `doclayout_yolo` (fast) / `layoutlmv3` (accurate) |

**Success Response:**
```json
{
  "code": 0,
  "msg": "ok",
  "trace_id": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "data": {
    "task_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}
```

**Extract Key Fields:**
- `task_id`: Task ID for subsequent result queries

---

### Step 2: Poll Extraction Results

**Command:**
```bash
curl -X GET "${MINERU_BASE_URL}/extract/task/YOUR_TASK_ID" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MINERU_TOKEN}"
```

**Parameters:**

| Parameter | Description |
|-----------|-------------|
| `YOUR_TASK_ID` | `task_id` returned from Step 1 |

**Polling Strategy:**
- Wait 5 seconds before first query
- Query every 5 seconds
- Maximum 60 retries (~5 minutes)

**Response Status Descriptions:**

| state | Meaning | Action |
|-------|---------|--------|
| `done` | ✅ Extraction complete | Get `full_zip_url` to download results |
| `running` | 🔄 Processing | Continue polling |
| `pending` | ⏳ Queued | Continue polling |
| `failed` | ❌ Extraction failed | Check `err_msg` for error info |

**Success Response (done status):**
```json
{
  "code": 0,
  "msg": "ok",
  "trace_id": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "data": {
    "task_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "state": "done",
    "err_msg": "",
    "full_zip_url": "https://cdn-mineru.openxlab.org.cn/pdf/.../xxxx.zip"
  }
}
```

**Extract Key Fields:**
- `full_zip_url`: Result ZIP package download URL

---

### Step 3: Download and Extract Results

**Command:**
```bash
# Download ZIP package
curl -L -o "result.zip" \
  "YOUR_FULL_ZIP_URL_FROM_STEP2"

# Extract to folder
unzip -q "result.zip" -d "extracted_folder"
```

**Extracted File Structure:**
```
extracted_folder/
├── full.md                    # 📄 Complete Markdown (main result)
├── xxxxxxxx_content_list.json # Structured content list
├── xxxxxxxx_origin.pdf        # Original PDF copy
├── layout.json                # Layout analysis data
└── images/                    # 🖼️ Extracted images folder
    ├── image_001.png
    ├── image_002.png
    └── ...
```

**Key Output Files:**

| File | Description |
|------|-------------|
| `full.md` | 📄 Parsed complete Markdown document (most commonly used) |
| `images/` | All images extracted from document |
| `content_list.json` | Structured content with position info for each text segment |
| `layout.json` | Detailed layout analysis data |

---

## 📝 Complete One-Piece Script (Secure Version)

### Online Document Parsing Script (online_parse.sh)

```bash
#!/bin/bash
# MinerU Online Document Parsing Script (Secure Version)
# Usage: ./online_parse.sh <pdf_url> [output_directory]
#
# This script implements security measures to prevent:
# - JSON injection attacks via input sanitization
# - Directory traversal attacks via path validation
# - Malicious URL attacks via URL validation

set -e

# ============================================================================
# SECURITY FUNCTIONS
# ============================================================================

# Function: escape_json
# Purpose: Escape special characters in strings to prevent JSON injection
# Security: Prevents breaking JSON structure via malicious input
# Arguments:
#   $1 - Input string to escape
# Returns: Escaped string safe for JSON embedding
escape_json() {
    local str="$1"
    # Escape backslashes first to avoid double-escaping
    str="${str//\\/\\\\}"
    # Escape double quotes to prevent JSON injection
    str="${str//\"/\\\"}"
    # Escape newlines
    str="${str//$'\n'/\\n}"
    # Escape carriage returns
    str="${str//$'\r'/\\r}"
    echo "$str"
}

# Function: validate_url
# Purpose: Validate PDF URL format and prevent malicious URLs
# Security: Ensures URL points to a PDF file and uses http/https protocol
# Arguments:
#   $1 - Input URL
# Returns: Validated URL
# Exits: If URL is invalid
validate_url() {
    local url="$1"
    
    # SECURITY CHECK: Validate URL format
    # Must start with http:// or https:// and end with .pdf
    # This prevents:
    # - File protocol attacks (file:///etc/passwd)
    # - JavaScript protocol attacks (javascript:alert(1))
    # - Other malicious protocols
    if [[ ! "$url" =~ ^https?://[a-zA-Z0-9.-]+/.*\.pdf$ ]]; then
        echo "❌ Error: Invalid URL format. Must be http(s)://.../...pdf" >&2
        exit 1
    fi
    
    echo "$url"
}

# Function: validate_dirname
# Purpose: Validate directory names to prevent directory traversal attacks
# Security: Prevents ".." sequences and absolute paths that could escape
#           the intended directory and write to system locations
# Arguments:
#   $1 - Input directory name
# Returns: Validated directory name
# Exits: If directory name is invalid
validate_dirname() {
    local dir="$1"
    
    # SECURITY CHECK 1: Prevent directory traversal via ".."
    # Attack example: "../../../etc/passwd" could overwrite system files
    if [[ "$dir" == *".."* ]]; then
        echo "❌ Error: Invalid directory name. Cannot contain '..'" >&2
        exit 1
    fi
    
    # SECURITY CHECK 2: Prevent absolute paths
    # Attack example: "/etc/cron.d/malicious" could write to system directories
    if [[ "$dir" == /* ]]; then
        echo "❌ Error: Invalid directory name. Cannot start with '/'" >&2
        exit 1
    fi
    
    # SECURITY CHECK 3: Limit directory name length
    # Prevents buffer overflow attacks and keeps paths manageable
    if [ ${#dir} -gt 255 ]; then
        echo "❌ Error: Directory name too long (max 255 chars)" >&2
        exit 1
    fi
    
    echo "$dir"
}

# ============================================================================
# CONFIGURATION & SETUP
# ============================================================================

# Support MINERU_TOKEN or MINERU_API_KEY environment variables
MINERU_TOKEN="${MINERU_TOKEN:-${MINERU_API_KEY:-}}"
MINERU_BASE_URL="${MINERU_BASE_URL:-https://mineru.net/api/v4}"

# Validate that API token is configured
if [ -z "$MINERU_TOKEN" ]; then
    echo "❌ Error: Please set MINERU_TOKEN or MINERU_API_KEY environment variable"
    exit 1
fi

# ============================================================================
# INPUT VALIDATION
# ============================================================================

# Get PDF URL from arguments
PDF_URL="${1:-}"
if [ -z "$PDF_URL" ]; then
    echo "❌ Error: Please provide PDF URL address"
    echo "Usage: $0 <pdf_url> [output_directory]"
    echo ""
    echo "Example:"
    echo "  $0 \"https://arxiv.org/pdf/2410.17247.pdf\""
    exit 1
fi

# SECURITY: Validate URL format to prevent malicious URLs
PDF_URL=$(validate_url "$PDF_URL")

# Create JSON-safe version of URL
SAFE_URL=$(escape_json "$PDF_URL")

# Get output directory with default value
OUTPUT_DIR="${2:-online_result}"

# SECURITY: Validate output directory to prevent directory traversal
OUTPUT_DIR=$(validate_dirname "$OUTPUT_DIR")

# Configuration for polling
MAX_RETRIES=60          # Maximum number of status check attempts
RETRY_INTERVAL=5        # Seconds between checks

# ============================================================================
# STEP 1: Submit Parsing Task
# ============================================================================

echo "=== Step 1: Submit Parsing Task ==="
echo "PDF URL: ${PDF_URL:0:60}..."

# Build JSON payload securely
# SECURITY: Use jq if available for proper JSON construction
if command -v jq &> /dev/null; then
    # jq method: Safely constructs JSON with proper escaping
    JSON_PAYLOAD=$(jq -n \
        --arg url "$SAFE_URL" \
        --arg lang "ch" \
        '{
            url: $url,
            enable_formula: true,
            language: $lang,
            enable_table: true,
            layout_model: "doclayout_yolo"
        }')
else
    # Fallback method: Use pre-escaped URL
    JSON_PAYLOAD="{
        \"url\": \"$SAFE_URL\",
        \"enable_formula\": true,
        \"language\": \"ch\",
        \"enable_table\": true,
        \"layout_model\": \"doclayout_yolo\"
    }"
fi

# Send request to MinerU API
STEP1_RESPONSE=$(curl -s -X POST "${MINERU_BASE_URL}/extract/task" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MINERU_TOKEN}" \
    -d "$JSON_PAYLOAD")

# ============================================================================
# RESPONSE PARSING (Secure)
# ============================================================================

# SECURITY: Use jq for safe JSON parsing if available
if command -v jq &> /dev/null; then
    CODE=$(echo "$STEP1_RESPONSE" | jq -r '.code // 1')
    TASK_ID=$(echo "$STEP1_RESPONSE" | jq -r '.data.task_id // empty')
else
    CODE=$(echo "$STEP1_RESPONSE" | grep -o '"code":[0-9]*' | head -1 | cut -d':' -f2)
    TASK_ID=$(echo "$STEP1_RESPONSE" | grep -o '"task_id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [ "$CODE" != "0" ] || [ -z "$TASK_ID" ]; then
    echo "❌ Failed to submit task"
    exit 1
fi

echo "✅ Task submitted successfully"
echo "Task ID: $TASK_ID"
echo ""

# ============================================================================
# STEP 2: Poll Extraction Results
# ============================================================================

echo "=== Step 2: Poll Extraction Results ==="
echo "Waiting 5 seconds for system to start processing..."
sleep 5

# Poll until completion or max retries
for ((attempt=1; attempt<=MAX_RETRIES; attempt++)); do
    echo "[Attempt $attempt/$MAX_RETRIES] Querying..."
    
    # Query extraction status
    RESPONSE=$(curl -s -X GET "${MINERU_BASE_URL}/extract/task/${TASK_ID}" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${MINERU_TOKEN}")
    
    # Parse status from response
    if command -v jq &> /dev/null; then
        STATE=$(echo "$RESPONSE" | jq -r '.data.state // empty')
    else
        STATE=$(echo "$RESPONSE" | grep -o '"state":"[^"]*"' | head -1 | cut -d'"' -f4)
    fi
    
    echo "Status: $STATE"
    
    # Check extraction status
    if [ "$STATE" = "done" ]; then
        # Extract ZIP URL
        if command -v jq &> /dev/null; then
            ZIP_URL=$(echo "$RESPONSE" | jq -r '.data.full_zip_url // empty')
        else
            ZIP_URL=$(echo "$RESPONSE" | grep -o '"full_zip_url":"[^"]*"' | head -1 | cut -d'"' -f4)
        fi
        echo "✅ Extraction complete!"
        break
    elif [ "$STATE" = "failed" ]; then
        # Extract error message
        if command -v jq &> /dev/null; then
            ERR_MSG=$(echo "$RESPONSE" | jq -r '.data.err_msg // "Unknown error"')
        else
            ERR_MSG=$(echo "$RESPONSE" | grep -o '"err_msg":"[^"]*"' | head -1 | cut -d'"' -f4)
        fi
        echo "❌ Extraction failed: $ERR_MSG"
        exit 1
    fi
    
    # Wait before next check
    sleep $RETRY_INTERVAL
done

# Validate that we got a ZIP URL
if [ -z "$ZIP_URL" ]; then
    echo "❌ Polling timeout"
    exit 1
fi

# SECURITY: Validate ZIP URL to ensure it comes from official CDN
if [[ ! "$ZIP_URL" =~ ^https://cdn-mineru\.openxlab\.org\.cn/ ]]; then
    echo "❌ Error: Invalid ZIP URL"
    exit 1
fi

# ============================================================================
# DOWNLOAD AND EXTRACT RESULTS
# ============================================================================

echo ""
echo "=== Download and Extract Results ==="

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Download result ZIP
curl -L -o "${OUTPUT_DIR}/result.zip" "$ZIP_URL"

# SECURITY: Validate ZIP file before extraction
if ! unzip -t "${OUTPUT_DIR}/result.zip" &>/dev/null; then
    echo "❌ Error: Invalid ZIP file"
    rm -f "${OUTPUT_DIR}/result.zip"
    exit 1
fi

# Extract ZIP contents
echo "Extracting..."
unzip -q "${OUTPUT_DIR}/result.zip" -d "$OUTPUT_DIR/extracted"

# ============================================================================
# COMPLETION
# ============================================================================

echo ""
echo "✅ Complete! Results saved to: $OUTPUT_DIR/extracted/"
echo ""
echo "Key files:"
echo "  📄 $OUTPUT_DIR/extracted/full.md - Markdown document"
echo "  🖼️  $OUTPUT_DIR/extracted/images/ - Extracted images"
```

---

## 🔒 Security Features Explained

### 1. URL Validation
- **Format Check**: Ensures URL starts with http:// or https:// and ends with .pdf
- **Protocol Whitelist**: Prevents file://, javascript://, and other dangerous protocols
- **Pattern Matching**: Uses strict regex to validate URL structure

### 2. Input Sanitization
- **Directory Validation**: Prevents directory traversal via `..` sequences
- **Path Confinement**: Blocks absolute paths that could escape working directory
- **JSON Escaping**: Properly escapes special characters to prevent JSON injection

### 3. File Operations
- **ZIP Validation**: Tests ZIP integrity before extraction
- **URL Whitelist**: Only accepts downloads from official MinerU CDN
- **Safe Parsing**: Uses jq for secure JSON parsing when available

---

## 🔧 Usage Examples

### Example 1: Parse arXiv Paper

```bash
export MINERU_TOKEN="your_token_here"

./online_parse.sh "https://arxiv.org/pdf/2410.17247.pdf"
```

### Example 2: Parse Online PDF

```bash
export MINERU_TOKEN="your_token_here"

./online_parse.sh \
  "https://www.example.com/documents/report.pdf" \
  "my_report"
```

### Example 3: Manual Execution of Each Step

```bash
export MINERU_TOKEN="your_token_here"

# Step 1: Submit task
curl -X POST "https://mineru.net/api/v4/extract/task" \
  -H "Authorization: Bearer $MINERU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://arxiv.org/pdf/2410.17247.pdf",
    "enable_formula": true,
    "language": "en"
  }'
# Returns: {"task_id": "xxx"}

# Step 2: Poll results (loop until state=done)
curl "https://mineru.net/api/v4/extract/task/xxx" \
  -H "Authorization: Bearer $MINERU_TOKEN"

# Step 3: Download and extract
curl -L -o result.zip "https://cdn-mineru.openxlab.org.cn/pdf/.../xxx.zip"
unzip -q result.zip -d extracted/
```

---

## 📊 Online vs Local Parsing Comparison

| Feature | **Online URL Parsing** | **Local Upload Parsing** |
|---------|------------------------|--------------------------|
| **Steps** | 2 steps | 4 steps |
| **Upload Required** | ❌ No | ✅ Yes |
| **Average Time** | 10-20 seconds | 30-60 seconds |
| **Network Requirements** | Download results only | Upload + download |
| **Use Case** | Files already online (arXiv, websites, etc.) | Local files |
| **File Size Limit** | Limited by source server | 200MB |

---

## ⚠️ Notes

1. **URL Accessibility**: Ensure the provided URL is publicly accessible, MinerU servers need to download the file
2. **URL Encoding**: If URL contains Chinese or special characters, ensure proper encoding
3. **Token Security**: Do not hard-code MINERU_TOKEN in scripts
4. **File Limits**: Source file size recommended not exceeding 200MB

---

## 📚 References

| Document | Description |
|----------|-------------|
| `Local_File_Parsing_Guide.md` | Detailed curl commands and parameters for local PDF parsing |

External Resources:
- MinerU Official: https://mineru.net/
- API Documentation: https://mineru.net/apiManage/docs
- GitHub: https://github.com/opendatalab/MinerU

---

*Document Version: 1.0.0*  
*Release Date: 2026-02-18*
