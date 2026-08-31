# geliyor.tr Admin panel — Firebase Hosting deploy
# Kullanım: .\scripts\deploy_admin.ps1

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$stamp = Get-Date -Format "yyyyMMddHHmmss"
Write-Host "Admin panel web build basliyor (v=$stamp)..." -ForegroundColor Cyan
flutter build web `
  -t lib/admin/main_admin.dart `
  --release `
  --no-wasm-dry-run `
  --web-define=CACHE_BUST=$stamp

if ($LASTEXITCODE -ne 0) {
  Write-Host "Build basarisiz." -ForegroundColor Red
  exit 1
}

$killSwitch = @'
'use strict';
self.addEventListener('install', function () { self.skipWaiting(); });
self.addEventListener('activate', function (event) {
  event.waitUntil((async function () {
    try {
      var keys = await caches.keys();
      await Promise.all(keys.map(function (k) { return caches.delete(k); }));
    } catch (e) {}
    try { await self.registration.unregister(); } catch (e) {}
    try {
      var clients = await self.clients.matchAll({ type: 'window' });
      await Promise.all(clients.map(function (client) {
        if (client.url && client.navigate) return client.navigate(client.url);
      }));
    } catch (e) {}
  })());
});
'@
[System.IO.File]::WriteAllText(
  (Join-Path (Get-Location) "build\web\flutter_service_worker.js"),
  $killSwitch
)

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
