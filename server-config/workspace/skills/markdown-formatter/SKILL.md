---
name: markdown-formatter
description: Format and beautify markdown documents with configurable styles. Preserve structure, fix formatting, ensure consistency.
metadata:
  {
    "openclaw":
      {
        "version": "1.0.0",
        "author": "Vernox",
        "license": "MIT",
        "tags": ["markdown", "formatter", "beautifier", "text", "formatting", "documentation"],
        "category": "tools"
      }
  }
---

# Markdown-Formatter - Beautify Your Markdown

**Vernox Utility Skill - Make your markdown look professional.**

## Overview

Markdown-Formatter is a powerful tool for formatting, linting, and beautifying markdown documents. Supports multiple style guides (CommonMark, GitHub Flavored Markdown, custom rules) and handles everything from simple cleanup to complex reformatting.

## Features

### ✅ Formatter Engine
- Multiple style guides (CommonMark, GitHub, custom)
- Preserves document structure
- Handles nested lists, code blocks, tables
- Configurable line width and indentation
- Smart heading normalization
- Link reference optimization

### ✅ Linting & Cleanup
- Remove trailing whitespace
- Normalize line endings (LF vs CRLF)
- Fix inconsistent list markers
- Remove empty lines at end
- Fix multiple consecutive blank lines

### ✅ Beautification
- Improve heading hierarchy
- Optimize list formatting
- Format code blocks with proper spacing
- Wrap long lines at configured width
- Add proper spacing around emphasis

### ✅ Validation
- Check markdown syntax validity
- Report linting errors
- Suggest improvements
- Validate links and references

## Installation

```bash
clawhub install markdown-formatter
```

## Quick Start

### Format a Document

```javascript
const result = await formatMarkdown({
  markdown: '# My Document\n\n\n## Section 1\nContent here...',
  style: 'github',
  options: {
    maxWidth: 80,
    headingStyle: 'atx'
  }
});

console.log(result.formattedMarkdown);
```

### Beautify Multiple Files

```javascript
const results = await formatBatch({
  markdownFiles: ['./doc1.md', './doc2.md', './README.md'],
  style: 'github',
  options: { wrapWidth: 80 }
});

results.forEach(result => {
  console.log(`${result.file}: ${result.warnings} warnings`);
});
```

### Lint and Fix

```javascript
const result = await lintMarkdown({
  markdown: '# My Document\n\n\nBad list\n\n- item 1\n- item 2',
  style: 'github'
});

console.log(`Errors found: ${result.errors}`);
console.log(`Fixed: ${result.fixed}`);
```

## Tool Functions

### `formatMarkdown`
Format markdown content according to style guide.

**Parameters:**
- `markdown` (string, required): Markdown content to format
- `style` (string, required): Style guide name ('commonmark', 'github', 'commonmark', 'custom')
- `options` (object, optional):
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
- `lintResult` (object): Linting errors and fixes
- `originalLength` (number): Original character count
- `formattedLength` (number): Formatted character count

### `formatBatch`
Format multiple markdown files at once.

**Parameters:**
- `markdownFiles` (array, required): Array of file paths
- `style` (string): Style guide name
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
- `style` (string): Style guide name
- `options` (object, optional): Additional linting options
  - `checkLinks` (boolean): Validate links (default: true)
  - `checkHeadingLevels` (boolean): Check heading hierarchy (default: true)
  - `checkListConsistency` (boolean): Check list marker consistency (default: true)
  - `checkEmphasisBalance` (boolean): Check emphasis pairing (default: false)

**Returns:**
- `errors` (array): Array of error objects
- `warnings` (array): Array of warning objects
- `stats` (object): Linting statistics
- `suggestions` (array): Suggested fixes

## Style Guides

### CommonMark (default)
- Standard CommonMark specification
- ATX headings (ATX-style)
- Reference-style links [text]
- Underscore emphasis
- Asterisk emphasis

### GitHub Flavored Markdown
- Fenced code blocks with \`\`\`
- Tables with pipes
- Task lists [ ] with x
- Strikethrough `~~text~~`
- Autolinks with <https://url>

### Consistent (default)
- Consistent ATX heading levels
- Consistent list markers
- Consistent emphasis style
- Consistent code block style

### Custom
- User-defined rules
- Regex-based transformations
- Custom heading styles

## Use Cases

### Documentation Cleanup
- Fix inconsistent formatting in README files
- Normalize heading styles
- Fix list markers
- Clean up extra whitespace

### Content Creation
- Format articles with consistent style
- Beautify blog posts before publishing
- Ensure consistent heading hierarchy

### Technical Writing
- Format code documentation
- Beautify API specs
- Clean up messy markdown from LLMs

### README Generation
- Format and beautify project README files
- Ensure consistent structure
- Professional appearance for open source

### Markdown Conversion
- Convert HTML to markdown
- Reformat from one style to another
- Extract and format markdown from other formats

## Configuration

### Edit `config.json`:
```json
{
  "defaultStyle": "github",
  "maxWidth": 80,
  "headingStyle": "atx",
  "listStyle": "consistent",
  "codeStyle": "fenced",
  "emphasisStyle": "asterisk",
  "linkStyle": "inline",
  "customRules": [],
  "linting": {
    "checkLinks": true,
    "checkHeadingLevels": true,
    "checkListConsistency": true
  }
}
```

## Examples

### Simple Formatting
```javascript
const result = await formatMarkdown({
  markdown: '# My Title\n\n\nThis is content.',
  style: 'github'
});

console.log(result.formattedMarkdown);
```

### Complex Beautification
```javascript
const result = await formatMarkdown({
  markdown: '# Header 1\n## Header 2\n\nParagraph...',
  style: 'github',
  options: {
    fixLists: true,
    normalizeSpacing: true,
    wrapWidth: 80
  }
});

console.log(result.formattedMarkdown);
```

### Linting and Fixing
```javascript
const result = await lintMarkdown({
  markdown: '# Title\n\n- Item 1\n- Item 2\n\n## Section 2',
  style: 'github'
});

console.log(`Errors: ${result.errors.length}`);
result.errors.forEach(err => {
  console.log(`  - ${err.message} at line ${err.line}`);
});

// Fix automatically
const fixed = await formatMarkdown({
  markdown: result.fixed,
  style: 'github'
});
```

### Batch Processing
```javascript
const results = await formatBatch({
  markdownFiles: ['./doc1.md', './doc2.md', './README.md'],
  style: 'github'
});

console.log(`Processed ${results.totalFiles} files`);
console.log(`Total warnings: ${results.totalWarnings}`);
```

## Performance

### Speed
- **Small documents** (<1000 words): <50ms
- **Medium documents** (1000-5000 words): 50-200ms
- **Large documents** (5000+ words): 200-500ms

### Accuracy
- **Structure preservation:** 100%
- **Style guide compliance:** 95%+
- **Whitespace normalization:** 100%

## Error Handling

### Invalid Input
- Clear error message
- Suggest checking file path
- Validate markdown content before formatting

### Markdown Parsing Errors
- Report parsing issues clearly
- Suggest manual fixes
- Graceful degradation on errors

### File I/O Errors
- Clear error with file path
- Check file existence
- Suggest permissions fix
- Batch processing continues on errors

## Troubleshooting

### Format Not Applied
- Check if style is correct
- Verify options are respected
- Check for conflicting rules
- Test with simple example

### Linting Shows Too Many Errors
- Some errors are style choices, not real issues
- Consider disabling specific checks
- Use custom rules for specific needs

## Tips

### Best Results
- Use consistent style guide
- Enable fixLists, normalizeSpacing options
- Set maxWidth appropriate for your output medium
- Test on small samples first

### Performance Optimization
- Process large files in batches
- Disable unused linting checks
- Use simpler rules for common patterns

## License

MIT

---

**Format markdown. Keep your docs beautiful.** 🔮
