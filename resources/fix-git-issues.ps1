# Script to fix Git line ending warnings and long path issues
# Run this script from PowerShell (may require admin rights for long paths)

Write-Host "=== Fixing Git Issues ===" -ForegroundColor Cyan

# 1. Fix line ending warnings
Write-Host "`n1. Configuring Git line endings..." -ForegroundColor Yellow
Write-Host "   Setting core.autocrlf to 'true' (recommended for Windows)"
Write-Host "   Run this command: git config --global core.autocrlf true"
Write-Host "   Or for this repo only: git config core.autocrlf true"

# 2. Fix long path issue
Write-Host "`n2. Fixing long path issue..." -ForegroundColor Yellow
Write-Host "   Option A: Enable long paths in Git (Recommended)"
Write-Host "   Run: git config --global core.longpaths true"
Write-Host "   Or for this repo only: git config core.longpaths true"
Write-Host ""
Write-Host "   Option B: Enable long paths in Windows (Requires Admin)"
Write-Host "   Run PowerShell as Administrator and execute:"
Write-Host "   New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force"
Write-Host "   Then restart your computer."

# 3. Remove problematic file from Git index
Write-Host "`n3. Removing cache directory from Git tracking..." -ForegroundColor Yellow
Write-Host "   The .gitignore file has been created to ignore the cache directory."
Write-Host "   If the file is already tracked, run:"
Write-Host "   git rm -r --cached 'resources/[standalone]/cache'"
Write-Host "   git commit -m 'Remove cache directory from tracking'"

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "1. .gitignore file created to ignore cache directory"
Write-Host "2. Run the Git commands above to fix line endings and long paths"
Write-Host "3. If files are already tracked, remove them from Git index"

