# geliyor.tr Admin panel — Firebase Hosting deploy
# Kullanım: .\scripts\deploy_admin.ps1

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "Admin panel web build basliyor..." -ForegroundColor Cyan
flutter build web `
  -t lib/admin/main_admin.dart `
  --release `
  --no-wasm-dry-run

if ($LASTEXITCODE -ne 0) {
  Write-Host "Build basarisiz." -ForegroundColor Red
  exit 1
}

Write-Host "Firebase Hosting deploy basliyor..." -ForegroundColor Cyan
firebase deploy --only hosting --project geliyortrapp

if ($LASTEXITCODE -ne 0) {
  Write-Host "Deploy basarisiz. Once: firebase login" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "Admin panel yayinda:" -ForegroundColor Green
Write-Host "  https://geliyortrapp.web.app" -ForegroundColor Yellow
Write-Host "  https://geliyortrapp.firebaseapp.com" -ForegroundColor Yellow
Write-Host ""
Write-Host "Ozel domain (or. admin.geliyor.com.tr) icin Firebase Console > Hosting > Custom domain" -ForegroundColor DarkGray
