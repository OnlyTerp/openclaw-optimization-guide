# OpenClaw Optimization Setup Script (Windows)
# Run: powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Continue"

$Workspace = if ($env:OPENCLAW_WORKSPACE) { $env:OPENCLAW_WORKSPACE } else { "$env:USERPROFILE\.openclaw\workspace" }
$Config = "$env:USERPROFILE\.openclaw\openclaw.json"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  OpenClaw Optimization Setup" -ForegroundColor Cyan
Write-Host "  By Terp AI Labs (@OnlyTerp)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Backup
Write-Host "[1/5] Backing up config..." -ForegroundColor Yellow
if (Test-Path $Config) {
    Copy-Item $Config "$Config.bak" -Force
    Write-Host "  OK Backed up to $Config.bak" -ForegroundColor Green
} else {
    Write-Host "  WARN No config found — skipping backup" -ForegroundColor DarkYellow
}

# Step 2: Create vault structure
Write-Host "[2/5] Creating vault directory structure..." -ForegroundColor Yellow
$dirs = @("vault\projects","vault\people","vault\decisions","vault\lessons","vault\reference","vault\research","memory")
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path "$Workspace\$d" -Force | Out-Null
}
Write-Host "  OK vault/ and memory/ directories created" -ForegroundColor Green

# Step 3: Install template files
Write-Host "[3/5] Installing optimized workspace files..." -ForegroundColor Yellow

function Install-Template {
    param($FileName, $MaxKB)
    $target = "$Workspace\$FileName"
    $source = "$ScriptDir\templates\$FileName"
    
    if (-not (Test-Path $target)) {
        Copy-Item $source $target
        Write-Host "  OK Created $FileName" -ForegroundColor Green
    } else {
        $size = (Get-Item $target).Length
        $maxBytes = $MaxKB * 1024
        if ($size -gt $maxBytes) {
            Copy-Item $target "$target.pre-optimize" -Force
            Copy-Item $source $target -Force
            $sizeKB = [math]::Round($size/1024)
            Write-Host "  OK Optimized $FileName (was ${sizeKB}KB, backed up)" -ForegroundColor Green
        } else {
            Write-Host "  SKIP $FileName already under ${MaxKB}KB" -ForegroundColor DarkGray
        }
    }
}

Install-Template "SOUL.md" 2
Install-Template "AGENTS.md" 3
Install-Template "MEMORY.md" 4
Install-Template "TOOLS.md" 2

# Step 4: Ollama
Write-Host "[4/5] Setting up Ollama + nomic-embed-text..." -ForegroundColor Yellow

$ollamaPath = Get-Command ollama -ErrorAction SilentlyContinue
if ($ollamaPath) {
    Write-Host "  OK Ollama already installed" -ForegroundColor Green
} else {
    Write-Host "  Installing Ollama..." -ForegroundColor Yellow
    winget install Ollama.Ollama --accept-package-agreements --accept-source-agreements 2>$null
    Write-Host "  OK Ollama installed (restart terminal to use)" -ForegroundColor Green
}

$models = ollama list 2>$null
if ($models -match "nomic-embed-text") {
    Write-Host "  OK nomic-embed-text already available" -ForegroundColor Green
} else {
    Write-Host "  Pulling nomic-embed-text (300MB)..." -ForegroundColor Yellow
    ollama pull nomic-embed-text
    Write-Host "  OK nomic-embed-text ready" -ForegroundColor Green
}

# Step 5: Verify
Write-Host "[5/5] Verifying setup..." -ForegroundColor Yellow
Write-Host ""

$totalSize = 0
foreach ($f in @("SOUL.md","AGENTS.md","MEMORY.md","TOOLS.md")) {
    $path = "$Workspace\$f"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        $totalSize += $size
        Write-Host "  $f`: $size bytes"
    }
}
Write-Host "  --------------------"
$totalKB = [math]::Round($totalSize/1024)
Write-Host "  Total context: $totalSize bytes (${totalKB}KB)"
Write-Host ""

if ($totalSize -lt 8192) {
    Write-Host "  OK Context under 8KB — you're optimized!" -ForegroundColor Green
} else {
    Write-Host "  WARN Context over 8KB — consider trimming further" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. Restart gateway: openclaw gateway stop; openclaw gateway start"
Write-Host "  2. Move detailed docs from MEMORY.md to vault/ files"
Write-Host "  3. Test: ask your bot about a past project"
Write-Host "==========================================" -ForegroundColor Cyan
