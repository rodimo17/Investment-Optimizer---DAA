# Flutter Automated Setup Script

Write-Host "--- Starting Flutter Setup ---" -ForegroundColor Cyan

# 1. Create source directory
$srcDir = "C:\src"
if (!(Test-Path $srcDir)) {
    Write-Host "Creating $srcDir..."
    New-Item -ItemType Directory -Path $srcDir | Out-Null
}

# 2. Clone Flutter SDK
$flutterPath = "C:\src\flutter"
if (!(Test-Path $flutterPath)) {
    Write-Host "Downloading Flutter (this may take a few minutes)..." -ForegroundColor Yellow
    git clone https://github.com/flutter/flutter.git -b stable $flutterPath
} else {
    Write-Host "Flutter SDK already exists at $flutterPath" -ForegroundColor Green
}

# 3. Add to User PATH
Write-Host "Updating Environment Variables..."
$binPath = "C:\src\flutter\bin"
$oldPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($oldPath -notlike "*$binPath*") {
    $newPath = "$oldPath;$binPath"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = "$env:Path;$binPath" # Update current session
    Write-Host "Added Flutter to PATH successfully." -ForegroundColor Green
} else {
    Write-Host "Flutter is already in your PATH." -ForegroundColor Green
}

# 4. Verify
Write-Host "Running initial check..." -ForegroundColor Cyan
& flutter doctor

Write-Host "`n--- Setup Script Finished ---" -ForegroundColor Cyan
Write-Host "Please RESTART Android Studio to apply changes." -ForegroundColor Yellow
