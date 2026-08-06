# Install scheduled task: Mon-Fri 17:40 auto run
# Run as Administrator in PowerShell:
#   & "D:\Claudeee\highDivided_highValue_lowPrice\网格高市值高股息率\2%-3%看板识股\setup_task.ps1"

$taskName = "HighDividendDailyReport"
$wrapper  = "C:\Users\HD07\run_report.ps1"

# Remove old task
Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# Use PowerShell wrapper at pure-English path to avoid Chinese encoding issues
$action   = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$wrapper`""
$trigger  = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 8:30
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -WakeToRun -MultipleInstances IgnoreNew

try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "HighDividendDailyReport - Mon-Fri 15:30" -ErrorAction Stop
} catch {
    Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings
}

Write-Host ""
Write-Host "=== Task Created ===" -ForegroundColor Green
Write-Host "  Name : $taskName"
$bjTime = [DateTime]::Parse($trigger.StartBoundary).ToLocalTime()
Write-Host "  Time : Mon-Fri $($bjTime.ToString('HH:mm'))"
Write-Host "  Exec : $wrapper"
Write-Host ""
Write-Host "View : taskschd.msc -> $taskName"
Write-Host "Test : schtasks /run /tn $taskName"
