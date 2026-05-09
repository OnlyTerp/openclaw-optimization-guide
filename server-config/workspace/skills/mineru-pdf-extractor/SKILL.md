---
name: mineru-pdf-extractor
description: Extract PDF content to Markdown using MinerU API. Supports formulas, tables, OCR. Provides both local file and online URL parsing methods.
author: Community
version: 1.0.0
homepage: https://mineru.net/
source: https://github.com/opendatalab/MinerU
env:
  - name: MINERU_TOKEN
    description: "MinerU API token for authentication (primary)"
    required: true
  - name: MINERU_API_KEY
    description: "Alternative API token if MINERU_TOKEN is not set"
    required: false
  - name: MINERU_BASE_URL
    description: "API base URL (optional, defaults to https://mineru.net/api/v4)"
    required: false
    default: "https://mineru.net/api/v4"
tools:
  required:
    - name: curl
      description: "HTTP client for API requests and file downloads"
    - name: unzip
      description: "Archive extraction tool for result ZIP files"
  optional:
    - name: jq
      description: "JSON processor for enhanced parsing and security (recommended)"
---

# MinerU PDF Extractor

Extract PDF documents to structured Markdown using the MinerU API. Supports formula recognition, table extraction, and OCR.

> **Note**: This is a community skill, not an official MinerU product. You need to obtain your own API key from [MinerU](https://mineru.net/).

---

## 📁 Skill Structure

```
mineru-pdf-extractor/
├── SKILL.md                          # English documentation
├── SKILL_zh.md                       # Chinese documentation
├── docs/                             # Documentation
│   ├── Local_File_Parsing_Guide.md   # Local PDF parsing detailed guide (English)
│   ├── Online_URL_Parsing_Guide.md   # Online PDF parsing detailed guide (English)
│   ├── MinerU_本地文档解析完整流程.md  # Local parsing complete guide (Chinese)
│   └── MinerU_在线文档解析完整流程.md  # Online parsing complete guide (Chinese)
└── scripts/                          # Executable scripts
    ├── local_file_step1_apply_upload_url.sh    # Local parsing Step 1
    ├── local_file_step2_upload_file.sh         # Local parsing Step 2
    ├── local_file_step3_poll_result.sh         # Local parsing Step 3
    ├── local_file_step4_download.sh            # Local parsing Step 4
    ├── online_file_step1_submit_task.sh        # Online parsing Step 1
    └── online_file_step2_poll_result.sh        # Online parsing Step 2
```

---

## 🔧 Requirements

### Required Environment Variables

Scripts automatically read MinerU Token from environment variables (choose one):

```bash
# Option 1: Set MINERU_TOKEN
export MINERU_TOKEN="your_api_token_here"

# Option 2: Set MINERU_API_KEY
export MINERU_API_KEY="your_api_token_here"
```

### Required Command-Line Tools

- `curl` - For HTTP requests (usually pre-installed)
- `unzip` - For extracting results (usually pre-installed)

### Optional Tools

- `jq` - For enhanced JSON parsing and security (recommended but not required)
  - If not installed, scripts will use fallback methods
  - Install: `apt-get install jq` (Debian/Ubuntu) or `brew install jq` (macOS)

### Optional Configuration

```bash
# Set API base URL (default is pre-configured)
export MINERU_BASE_URL="https://mineru.net/api/v4"
```

> 💡 **Get Token**: Visit https://mineru.net/apiManage/docs to register and obtain an API Key

---

## 📄 Feature 1: Parse Local PDF Documents

For locally stored PDF files. Requires 4 steps.

### Quick Start

```bash
cd scripts/

# Step 1: Apply for upload URL
./local_file_step1_apply_upload_url.sh /path/to/your.pdf
# Output: BATCH_ID=xxx UPLOAD_URL=xxx

# Step 2: Upload file
./local_file_step2_upload_file.sh "$UPLOAD_URL" /path/to/your.pdf

# Step 3: Poll for results
./local_file_step3_poll_result.sh "$BATCH_ID"
# Output: FULL_ZIP_URL=xxx

# Step 4: Download results
./local_file_step4_download.sh "$FULL_ZIP_URL" result.zip extracted/
```

### Script Descriptions

#### local_file_step1_apply_upload_url.sh

Apply for upload URL and batch_id.

**Usage:**
```bash
./local_file_step1_apply_upload_url.sh <pdf_file_path> [language] [layout_model]
```

**Parameters:**
- `language`: `ch` (Chinese), `en` (English), `auto` (auto-detect), default `ch`
- `layout_model`: `doclayout_yolo` (fast), `layoutlmv3` (accurate), default `doclayout_yolo`

**Output:**
```
BATCH_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
UPLOAD_URL=https://mineru.oss-cn-shanghai.aliyuncs.com/...
```

---

#### local_file_step2_upload_file.sh

Upload PDF file to the presigned URL.

**Usage:**
```bash
./local_file_step2_upload_file.sh <upload_url> <pdf_file_path>
```

---

#### local_file_step3_poll_result.sh

Poll extraction results until completion or failure.

**Usage:**
```bash
./local_file_step3_poll_result.sh <batch_id> [max_retries] [retry_interval_seconds]
```

**Output:**
```
FULL_ZIP_URL=https://cdn-mineru.openxlab.org.cn/pdf/.../xxx.zip
```

---

#### local_file_step4_download.sh

Download result ZIP and extract.

**Usage:**
```bash
./local_file_step4_download.sh <zip_url> [output_zip_filename] [extract_directory_name]
```

**Output Structure:**
```
extracted/
├── full.md              # 📄 Markdown document (main result)
├── images/              # 🖼️ Extracted images
├── content_list.json    # Structured content
└── layout.json          # Layout analysis data
```

### Detailed Documentation

📚 **Complete Guide**: See `docs/Local_File_Parsing_Guide.md`

---

## 🌐 Feature 2: Parse Online PDF Documents (URL Method)

For PDF files already available online (e.g., arXiv, websites). Only 2 steps, more concise and efficient.

### Quick Start

```bash
cd scripts/

# Step 1: Submit parsing task (provide URL directly)
./online_file_step1_submit_task.sh "https://arxiv.org/pdf/2410.17247.pdf"
# Output: TASK_ID=xxx

# Step 2: Poll results and auto-download/extract
./online_file_step2_poll_result.sh "$TASK_ID" extracted/
```

### Script Descriptions

#### online_file_step1_submit_task.sh

Submit parsing task for online PDF.

**Usage:**
```bash
./online_file_step1_submit_task.sh <pdf_url> [language] [layout_model]
```

**Parameters:**
- `pdf_url`: Complete URL of the online PDF (required)
- `language`: `ch` (Chinese), `en` (English), `auto` (auto-detect), default `ch`
- `layout_model`: `doclayout_yolo` (fast), `layoutlmv3` (accurate), default `doclayout_yolo`

**Output:**
```
TASK_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

#### online_file_step2_poll_result.sh

Poll extraction results, automatically download and extract when complete.

**Usage:**
```bash
./online_file_step2_poll_result.sh <task_id> [output_directory] [max_retries] [retry_interval_seconds]
```

**Output Structure:**
```
extracted/
├── full.md              # 📄 Markdown document (main result)
├── images/              # 🖼️ Extracted images
├── content_list.json    # Structured content
└── layout.json          # Layout analysis data
```

### Detailed Documentation

📚 **Complete Guide**: See `docs/Online_URL_Parsing_Guide.md`

---

## 📊 Comparison of Two Parsing Methods

| Feature | **Local PDF Parsing** | **Online PDF Parsing** |
|---------|----------------------|------------------------|
| **Steps** | 4 steps | 2 steps |
| **Upload Required** | ✅ Yes | ❌ No |
| **Average Time** | 30-60 seconds | 10-20 seconds |
| **Use Case** | Local files | Files already online (arXiv, websites, etc.) |
| **File Size Limit** | 200MB | Limited by source server |

---

## ⚙️ Advanced Usage

### Batch Process Local Files

```bash
for pdf in /path/to/pdfs/*.pdf; do
    echo "Processing: $pdf"
    
    # Step 1
    result=$(./local_file_step1_apply_upload_url.sh "$pdf" 2>&1)
    batch_id=$(echo "$result" | grep BATCH_ID | cut -d= -f2)
    upload_url=$(echo "$result" | grep UPLOAD_URL | cut -d= -f2)
    
    # Step 2
    ./local_file_step2_upload_file.sh "$upload_url" "$pdf"
    
    # Step 3
    zip_url=$(./local_file_step3_poll_result.sh "$batch_id" | grep FULL_ZIP_URL | cut -d= -f2)
    
    # Step 4
    filename=$(basename "$pdf" .pdf)
    ./local_file_step4_download.sh "$zip_url" "${filename}.zip" "${filename}_extracted"
done
```

### Batch Process Online Files

```bash
for url in \
  "https://arxiv.org/pdf/2410.17247.pdf" \
  "https://arxiv.org/pdf/2409.12345.pdf"; do
    echo "Processing: $url"
    
    # Step 1
    result=$(./online_file_step1_submit_task.sh "$url" 2>&1)
    task_id=$(echo "$result" | grep TASK_ID | cut -d= -f2)
    
    # Step 2
    filename=$(basename "$url" .pdf)
    ./online_file_step2_poll_result.sh "$task_id" "${filename}_extracted"
done
```

---

## ⚠️ Notes

1. **Token Configuration**: Scripts prioritize `MINERU_TOKEN`, fall back to `MINERU_API_KEY` if not found
2. **Token Security**: Do not hard-code tokens in scripts; use environment variables
3. **URL Accessibility**: For online parsing, ensure the provided URL is publicly accessible
4. **File Limits**: Single file recommended not exceeding 200MB, maximum 600 pages
5. **Network Stability**: Ensure stable network when uploading large files
6. **Security**: This skill includes input validation and sanitization to prevent JSON injection and directory traversal attacks
7. **Optional jq**: Installing `jq` provides enhanced JSON parsing and additional security checks

---

## 📚 Reference Documentation

| Document | Description |
|----------|-------------|
| `docs/Local_File_Parsing_Guide.md` | Detailed curl commands and parameters for local PDF parsing |
| `docs/Online_URL_Parsing_Guide.md` | Detailed curl commands and parameters for online PDF parsing |

External Resources:
- 🏠 **MinerU Official**: https://mineru.net/
- 📖 **API Documentation**: https://mineru.net/apiManage/docs
- 💻 **GitHub Repository**: https://github.com/opendatalab/MinerU

---

*Skill Version: 1.0.0*  
*Release Date: 2026-02-18*  
*Community Skill - Not affiliated with MinerU official*
