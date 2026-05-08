# OCR Skill 发布清单

## 文件结构

```
ocr/
├── SKILL.md           # OpenClaw 技能定义（必需）
├── package.json       # NPM 配置和依赖
├── README.md          # 使用说明
├── .gitignore         # Git 忽略文件
├── scripts/
│   └── ocr.js         # OCR 主脚本
└── PUBLISH.md         # 本文件
```

## 发布步骤

### 1. 确认文件完整
- [x] SKILL.md - 技能定义
- [x] package.json - NPM 配置
- [x] README.md - 使用文档
- [x] scripts/ocr.js - 主脚本
- [x] .gitignore - Git 配置

### 2. 清理不必要文件
已删除：
- ❌ node_modules/ - 用户安装时会自动下载
- ❌ *.traineddata - Tesseract 语言数据（运行时自动下载）
- ❌ package-lock.json - 让用户使用最新版本

### 3. 发布到 ClawHub

**方式 A：使用 CLI**
```bash
cd ~/.openclaw/workspace/skills/ocr
clawhub publish . --changelog "Initial release - OCR skill with Tesseract.js support for Chinese and English text recognition"
```

**方式 B：通过网站**
1. 访问 https://clawhub.com
2. 登录账号
3. 点击 "Publish Skill"
4. 上传整个 `ocr` 文件夹

### 4. 发布后验证

```bash
# 搜索技能
clawhub search ocr

# 安装测试
clawhub install ocr

# 测试使用
node ~/.openclaw/workspace/skills/ocr/scripts/ocr.js test-image.jpg
```

## 技能信息

- **名称**: OCR - Image Text Recognition
- **版本**: 1.0.0
- **作者**: OpenClaw Community
- **许可**: MIT
- **分类**: Productivity
- **标签**: ocr, image, text-recognition, tesseract, chinese, image-to-text

## 功能特性

✅ 支持简体中文识别
✅ 支持繁体中文识别
✅ 支持英文识别
✅ 多语言混合识别
✅ 纯本地运行（无需 API Key）
✅ 支持 JSON 格式输出

## 依赖

- Node.js >= 18.0.0
- tesseract.js ^7.0.0

## 首次运行说明

用户首次使用时会下载 Tesseract 语言数据（约 20MB/语言），后续运行使用缓存。

---

**准备就绪，可以发布！** 🚀
