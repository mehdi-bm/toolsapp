param(
  [Parameter(Mandatory=$true)][string]$Adb,
  [string]$OutputDirectory = 'artifacts/audit/device'
)

# Run with the app's Home tab visible. Uses display 0 explicitly because some
# phones expose a secondary display. No form is submitted and no data is cleared.
$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
$tools = [ordered]@{
  ruler='خط‌کش'; protractor='نقاله'; level='تراز';
  qr_scanner='اسکن QR'; barcode_scanner='بارکد'; color_detector='تشخیص رنگ';
  magnifier='ذره‌بین'; flashlight='چراغ‌قوه'; compass='قطب‌نما'; sound_meter='صدا';
  password_generator='تولید رمز'; random_generator='کد تصادفی'; qr_generator='ساخت QR';
  char_counter='شمارش حروف'; speech_text_converter='گفتار و متن';
  text_case_converter='تغییر حروف'; text_cleaner='پاکسازی متن'
}
function Read-AuditUi([bool]$AllowBusy = $false) {
  $dumpResult = & $Adb shell uiautomator dump /sdcard/toolbax-audit-ui.xml 2>&1
  if (($dumpResult -join ' ') -match 'ERROR:') {
    if ($AllowBusy) { return [xml]'<hierarchy status="unavailable-sensor-screen-not-idle" />' }
    throw 'UI capture failed; no stale XML will be used.'
  }
  & $Adb pull /sdcard/toolbax-audit-ui.xml (Join-Path $OutputDirectory 'ui.xml') 2>&1 | Out-Null
  return [xml](Get-Content -Encoding utf8 (Join-Path $OutputDirectory 'ui.xml'))
}
function Tap-Node($node) {
  $numbers = [regex]::Matches($node.bounds, '\d+') | ForEach-Object { [int]$_.Value }
  $x = [int](($numbers[0]+$numbers[2])/2)
  $y = [int](($numbers[1]+$numbers[3])/2)
  & $Adb shell input -d 0 tap $x $y
  Start-Sleep -Milliseconds 350
}
$index = 0
foreach ($entry in $tools.GetEnumerator()) {
  $index++
  $ui = Read-AuditUi
  $clear = $ui.SelectNodes('//node') | Where-Object { $_.'content-desc' -eq 'پاک کردن جستجو' } | Select-Object -First 1
  if ($clear) { Tap-Node $clear; $ui = Read-AuditUi }
  $search = $ui.SelectNodes('//node') | Where-Object { $_.class -eq 'android.widget.EditText' } | Select-Object -First 1
  if (-not $search) { throw 'Home search field not visible; return to Home before running.' }
  Tap-Node $search
  & $Adb shell input -d 0 text $entry.Key
  & $Adb shell input -d 0 keyevent KEYCODE_BACK
  Start-Sleep -Milliseconds 350
  $ui = Read-AuditUi
  $card = $ui.SelectNodes('//node') | Where-Object { $_.'content-desc'.StartsWith($entry.Value + "`n") -and $_.clickable -eq 'true' } | Select-Object -First 1
  if (-not $card) { throw "Search did not expose tool $($entry.Key)" }
  Tap-Node $card
  Start-Sleep -Milliseconds 1500
  $ui = Read-AuditUi -AllowBusy $true
  $prefix = '{0:D2}-{1}' -f $index,$entry.Key
  $ui.Save((Join-Path (Resolve-Path $OutputDirectory) ($prefix+'.xml')))
  & $Adb shell screencap -p /sdcard/toolbax-audit-capture.png
  & $Adb pull /sdcard/toolbax-audit-capture.png (Join-Path $OutputDirectory ($prefix+'.png')) 2>&1 | Out-Null
  Write-Output "Captured $prefix"
  & $Adb shell input -d 0 keyevent KEYCODE_BACK
  Start-Sleep -Milliseconds 400
}
