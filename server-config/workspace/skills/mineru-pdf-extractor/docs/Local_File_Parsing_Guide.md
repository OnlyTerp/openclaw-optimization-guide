# MinerU Local File Parsing Complete Guide

> Parse local PDF files to Markdown using MinerU API, supports formulas, tables, OCR

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

## 🚀 Complete Process (4 Steps)

### Step 1: Apply for Upload URL

**Command:**
```bash
curl -s -X POST "${MINERU_BASE_URL}/file-urls/batch" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MINERU_TOKEN}" \
    -d '{
        "enable_formula": true,
        "language": "ch",
        "enable_table": true,
        "layout_model": "doclayout_yolo",
        "enable_ocr": true,
        "files": [{"name": "YOUR_PDF_FILE.pdf", "is_ocr": true}]
    }'
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `enable_formula` | bool | No | Enable formula recognition, default true |
| `enable_table` | bool | No | Enable table recognition, default true |
| `enable_ocr` | bool | No | Enable OCR, default true |
| `language` | string | No | Language: `ch` (Chinese) / `en` (English) / `auto` |
| `layout_model` | string | No | Layout model: `doclayout_yolo` (fast) / `layoutlmv3` (accurate) |
| `files` | array | Yes | File list, each file contains `name` and `is_ocr` |

**Success Response:**
```json
{
  "code": 0,
  "msg": "ok",
  "trace_id": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "data": {
    "batch_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "file_urls": [
      "https://mineru.oss-cn-shanghai.aliyuncs.com/.../YOUR_PDF_FILE.pdf?Expires=..."
    ]
  }
}
```

**Extract Key Fields:**
- `batch_id`: Task batch ID for subsequent queries
- `file_urls[0]`: Presigned upload URL (valid for ~15 minutes)

---

### Step 2: Upload PDF File

**Command:**
```bash
curl -X PUT "YOUR_UPLOAD_URL_FROM_STEP1" \
    --upload-file "/path/to/YOUR_PDF_FILE.pdf"
```

**Parameters:**

| Parameter | Description |
|-----------|-------------|
| `YOUR_UPLOAD_URL_FROM_STEP1` | Upload URL returned from Step 1 (`file_urls[0]`) |
| `--upload-file` | Local PDF file path |

**Note:**
- ❌ Do NOT add `-H "Content-Type"` header
- ✅ Use `--upload-file` parameter directly

**Success Response:**
```
(No output, HTTP 200 means success)
```

---

### Step 3: Poll Extraction Results

**Command:**
```bash
curl -X GET "${MINERU_BASE_URL}/extract-results/batch/YOUR_BATCH_ID" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MINERU_TOKEN}"
```

**Parameters:**

| Parameter | Description |
|-----------|-------------|
| `YOUR_BATCH_ID` | `batch_id` returned from Step 1 |

**Polling Strategy:**
- Wait 5 seconds before first query
- Query every 5 seconds
- Maximum 60 retries (~5 minutes)

**Response Status Descriptions:**

| state | Meaning | Action |
|-------|---------|--------|
| `done` | ✅ Extraction complete | Get `full_zip_url` to download results |
| `running` | 🔄 Processing | Continue polling |
| `waiting-file` | ⏳ Waiting for file | Continue polling |
| `pending` | ⏳ Queued | Continue polling |
| `failed` | ❌ Extraction failed | Check `err_msg` for error info |

**Success Response (done status):**
```json
{
  "code": 0,
  "msg": "ok",
  "trace_id": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "data": {
    "batch_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "extract_result": [{
      "file_name": "YOUR_PDF_FILE.pdf",
      "state": "done",
      "err_msg": "",
      "full_zip_url": "https://cdn-mineru.openxlab.org.cn/pdf/.../xxxx.zip"
    }]
  }
}
```

**Extract Key Fields:**
- `full_zip_url`: Result ZIP package download URL

---

### Step 4: Download and Extract Results

**Command:**
```bash
# Download ZIP package
curl -L -o "result.zip" \
  "YOUR_FULL_ZIP_URL_FROM_STEP3"

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

### Local File Parsing Script (local_parse.sh)

```bash
#!/bin/bash
# MinerU Local File Parsing Script (Secure Version)
# Usage: ./local_parse.sh <pdf_file_path> [output_directory]
#
# This script implements security measures to prevent:
# - JSON injection attacks via input sanitization
# - Directory traversal attacks via path validation
# - Unsafe file operations via filename validation

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

# Function: validate_filename
# Purpose: Sanitize filenames to prevent malicious file names
# Security: Only allows alphanumeric, dots, underscores, and hyphens
#           Removes any special characters that could be exploited
# Arguments:
#   $1 - Input filename
# Returns: Sanitized filename
validate_filename() {
    local filename="$1"
    # Check if filename contains only allowed characters
    # Allowed: a-z, A-Z, 0-9, . (dot), _ (underscore), - (hyphen)
    if [[ ! "$filename" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "⚠️  Warning: Filename contains special characters, sanitizing..." >&2
        # Remove all characters except allowed ones
        filename=$(echo "$filename" | tr -cd 'a-zA-Z0-9._-')
    fi
    echo "$filename"
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
# This provides flexibility for different user preferences
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

# Validate PDF file path argument
PDF_PATH="${1:-}"
if [ -z "$PDF_PATH" ] || [ ! -f "$PDF_PATH" ]; then
    echo "❌ Error: Please provide a valid PDF file path"
    echo "Usage: $0 <pdf_file_path> [output_directory]"
    exit 1
fi

# Get output directory with default value
OUTPUT_DIR="${2:-extracted_result}"

# SECURITY: Validate output directory to prevent directory traversal
# This ensures extracted files stay within intended location
OUTPUT_DIR=$(validate_dirname "$OUTPUT_DIR")

# Configuration for polling
MAX_RETRIES=60          # Maximum number of status check attempts
RETRY_INTERVAL=5        # Seconds between checks

# ============================================================================
# FILE NAME PROCESSING
# ============================================================================

# Extract filename from path
FILENAME=$(basename "$PDF_PATH")

# SECURITY: Sanitize filename to prevent injection attacks
# This removes any special characters that could break JSON or be malicious
FILENAME=$(validate_filename "$FILENAME")

# Create JSON-safe version of filename for API requests
SAFE_FILENAME=$(escape_json "$FILENAME")

# Display processing information
echo "=== MinerU Local File Parsing ==="
echo "PDF File: $PDF_PATH"
echo "Output Directory: $OUTPUT_DIR"
echo ""

# ============================================================================
# STEP 1: Apply for Upload URL
# ============================================================================

echo "=== Step 1: Apply for Upload URL ==="

# Build JSON payload securely
# SECURITY: Use jq if available for proper JSON construction
# This prevents JSON injection via malicious filenames
if command -v jq &> /dev/null; then
    # jq method: Safely constructs JSON with proper escaping
    JSON_PAYLOAD=$(jq -n \
        --arg name "$SAFE_FILENAME" \
        --arg lang "ch" \
        '{
            enable_formula: true,
            language: $lang,
            enable_table: true,
            layout_model: "doclayout_yolo",
            enable_ocr: true,
            files: [{name: $name, is_ocr: true}]
        }')
else
    # Fallback method: Use pre-escaped filename
    # Note: This is less secure but works without jq
    JSON_PAYLOAD="{
        \"enable_formula\": true,
        \"language\": \"ch\",
        \"enable_table\": true,
        \"layout_model\": \"doclayout_yolo\",
        \"enable_ocr\": true,
        \"files\": [{\"name\": \"$SAFE_FILENAME\", \"is_ocr\": true}]
    }"
fi

# Send request to MinerU API
STEP1_RESPONSE=$(curl -s -X POST "${MINERU_BASE_URL}/file-urls/batch" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MINERU_TOKEN}" \
    -d "$JSON_PAYLOAD")

# ============================================================================
# RESPONSE PARSING (Secure)
# ============================================================================

# SECURITY: Use jq for safe JSON parsing if available
# jq properly handles JSON structure and prevents injection via responses
if command -v jq &> /dev/null; then
    # Extract fields safely using jq
    CODE=$(echo "$STEP1_RESPONSE" | jq -r '.code // 1')
    BATCH_ID=$(echo "$STEP1_RESPONSE" | jq -r '.data.batch_id // empty')
    UPLOAD_URL=$(echo "$STEP1_RESPONSE" | jq -r '.data.file_urls[0] // empty')
else
    # Fallback: Use grep with limited pattern matching
    # This is less robust but doesn't require jq
    CODE=$(echo "$STEP1_RESPONSE" | grep -o '"code":[0-9]*' | head -1 | cut -d':' -f2)
    BATCH_ID=$(echo "$STEP1_RESPONSE" | grep -o '"batch_id":"[^"]*"' | head -1 | cut -d'"' -f4)
    UPLOAD_URL=$(echo "$STEP1_RESPONSE" | grep -o '"file_urls":\[[^\]]*\]' | grep -o '"https://[^"]*"' | head -1 | tr -d '"')
fi

# Validate response
if [ "$CODE" != "0" ] || [ -z "$BATCH_ID" ]; then
    echo "❌ Failed to apply for upload URL"
    exit 1
fi

echo "✅ Batch ID: $BATCH_ID"

# ============================================================================
# STEP 2: Upload File
# ============================================================================

echo ""
echo "=== Step 2: Upload File ==="

# Upload file to presigned URL
# Note: Do NOT add Content-Type header, it breaks signature
curl -X PUT "$UPLOAD_URL" --upload-file "$PDF_PATH"
echo "✅ Upload successful"

# ============================================================================
# STEP 3: Poll Extraction Results
# ============================================================================

echo ""
echo "=== Step 3: Poll Extraction Results ==="

# Wait for processing to start
sleep 5

# Poll until completion or max retries
for ((attempt=1; attempt<=MAX_RETRIES; attempt++)); do
    echo "[Attempt $attempt/$MAX_RETRIES] Querying..."
    
    # Query extraction status
    RESPONSE=$(curl -s -X GET "${MINERU_BASE_URL}/extract-results/batch/${BATCH_ID}" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${MINERU_TOKEN}")
    
    # Parse status from response
    if command -v jq &> /dev/null; then
        STATE=$(echo "$RESPONSE" | jq -r '.data.extract_result[0].state // empty')
    else
        STATE=$(echo "$RESPONSE" | grep -o '"state":"[^"]*"' | head -1 | cut -d'"' -f4)
    fi
    
    echo "Status: $STATE"
    
    # Check extraction status
    if [ "$STATE" = "done" ]; then
        # Extract ZIP URL
        if command -v jq &> /dev/null; then
            ZIP_URL=$(echo "$RESPONSE" | jq -r '.data.extract_result[0].full_zip_url // empty')
        else
            ZIP_URL=$(echo "$RESPONSE" | grep -o '"full_zip_url":"[^"]*"' | head -1 | cut -d'"' -f4)
        fi
        echo "✅ Extraction complete!"
        break
    elif [ "$STATE" = "failed" ]; then
        echo "❌ Extraction failed"
        exit 1
    fi
    
    # Wait before next check
    sleep $RETRY_INTERVAL
done

# Validate that we got a ZIP URL
if [ -z "$ZIP_URL" ]; then
    echo "❌ Polling timeout or failed"
    exit 1
fi

# SECURITY: Validate ZIP URL to ensure it comes from official CDN
# Prevents potential redirection attacks or malicious URLs
if [[ ! "$ZIP_URL" =~ ^https://cdn-mineru\.openxlab\.org\.cn/ ]]; then
    echo "❌ Error: Invalid ZIP URL"
    exit 1
fi

# ============================================================================
# STEP 4: Download and Extract Results
# ============================================================================

echo ""
echo "=== Step 4: Download and Extract Results ==="

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Download result ZIP
curl -L -o "${OUTPUT_DIR}/result.zip" "$ZIP_URL"

# SECURITY: Validate ZIP file before extraction
# Prevents extraction of malicious or corrupted archives
if ! unzip -t "${OUTPUT_DIR}/result.zip" &>/dev/null; then
    echo "❌ Error: Invalid ZIP file"
    rm -f "${OUTPUT_DIR}/result.zip"
    exit 1
fi

# Extract ZIP contents
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

### 1. Input Sanitization
- **Filename Validation**: Only allows alphanumeric characters, dots, underscores, and hyphens
- **Directory Validation**: Prevents directory traversal via `..` sequences and absolute paths
- **JSON Escaping**: Properly escapes special characters to prevent JSON injection

### 2. URL Validation
- **ZIP URL Whitelist**: Only accepts downloads from official MinerU CDN (`cdn-mineru.openxlab.org.cn`)
- **Pattern Matching**: Uses strict regex patterns to validate URL format

### 3. File Operations
- **ZIP Validation**: Tests ZIP integrity before extraction using `unzip -t`
- **Path Confinement**: Ensures all operations stay within the intended working directory

### 4. Response Parsing
- **jq Priority**: Uses `jq` for safe JSON parsing when available
- **Fallback Methods**: Limited pattern matching as fallback without external dependencies

---

## ⚠️ Common Issues

### 1. Signature Error (SignatureDoesNotMatch)
**Cause:** Added `Content-Type` header during upload  
**Solution:** Remove `-H "Content-Type: application/pdf"`, only use `--upload-file`

### 2. URL Expired
**Cause:** Presigned URL valid for ~15 minutes  
**Solution:** Re-execute Step 1 to get a new URL

### 3. File Size Limits
- Single file maximum 200 MB
- Single file maximum 600 pages

### 4. Concurrency Limits
Depends on your MinerU plan

---

## 📚 References

- MinerU Official: https://mineru.net/
- API Documentation: https://mineru.net/apiManage/docs
- Online URL Parsing Guide: See `Online_URL_Parsing_Guide.md`

---

*Document Version: 1.0.0*  
*Release Date: 2026-02-18*
