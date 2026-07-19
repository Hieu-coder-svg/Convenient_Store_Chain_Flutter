param(
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"

$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path -LiteralPath $adb)) {
    throw "ADB was not found at $adb. Check the Android SDK installation."
}

$connectedDevices = @(
    & $adb devices |
        Select-Object -Skip 1 |
        ForEach-Object {
            if ($_ -match "^(\S+)\s+device$") { $Matches[1] }
        } |
        Where-Object { $_ }
)

if (-not $DeviceId) {
    if ($connectedDevices.Count -eq 0) {
        throw "No authorized Android device found. Enable USB debugging and reconnect USB."
    }
    $DeviceId = $connectedDevices[0]
}

if ($connectedDevices -notcontains $DeviceId) {
    throw "Device '$DeviceId' is not available through ADB."
}

Write-Host "Forwarding device $DeviceId port 8080 to the Docker API..."
& $adb -s $DeviceId reverse tcp:8080 tcp:8080
if ($LASTEXITCODE -ne 0) {
    throw "Could not create ADB reverse for port 8080."
}

Write-Host "Starting Flutter on the physical Android device..."
flutter run -d $DeviceId --dart-define=API_BASE_URL=http://127.0.0.1:8080/api
