# Patch script to fix ambiguous bigLargeIcon(null) call in flutter_local_notifications plugin
# Usage: From project root run: .\scripts\patch-flutter_local_notifications.ps1

$pubCache = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev"
if (-not (Test-Path $pubCache)) {
    Write-Error "Pub cache path not found: $pubCache"
    exit 1
}

# Find the newest flutter_local_notifications folder
$pluginDir = Get-ChildItem -Path $pubCache -Filter "flutter_local_notifications-*" -Directory | Sort-Object Name -Descending | Select-Object -First 1
if (-not $pluginDir) {
    Write-Error "flutter_local_notifications plugin not found in pub cache. Run 'flutter pub get' first."
    exit 1
}

$javaFile = Join-Path $pluginDir.FullName "android\src\main\java\com\dexterous\flutterlocalnotifications\FlutterLocalNotificationsPlugin.java"
if (-not (Test-Path $javaFile)) {
    Write-Error "Java file not found at expected path: $javaFile"
    exit 1
}

# Backup original file
$backup = $javaFile + ".bak"
if (-not (Test-Path $backup)) {
    Copy-Item -Path $javaFile -Destination $backup -ErrorAction Stop
    Write-Host "Backup created: $backup"
} else {
    Write-Host "Backup already exists: $backup"
}

# Replace ambiguous call: bigPictureStyle.bigLargeIcon(null); -> bigPictureStyle.bigLargeIcon((android.graphics.Bitmap) null);
(Get-Content $javaFile -Raw) -replace 'bigPictureStyle\.bigLargeIcon\(null\);', 'bigPictureStyle.bigLargeIcon((android.graphics.Bitmap) null);' | Set-Content $javaFile -Force

Write-Host "Patched $javaFile"
Write-Host "Run 'flutter clean' and then your build (flutter build apk or flutter run) to verify."

exit 0
