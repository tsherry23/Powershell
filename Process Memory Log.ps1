# 1. Define paths for your script and log files
$ScriptFolder = "C:\Scripts"
$LogFolder   = "C:\Logs\ProcessMemory"
$ScriptPath  = Join-Path -Path $ScriptFolder -ChildPath "Log-MemoryUsage.ps1"

# Create directories if they do not exist
New-Item -ItemType Directory -Force -Path $ScriptFolder, $LogFolder | Out-Null

# 2. Write the process collection script to a file
# This script grabs all running processes, sorts by WorkingSet (RAM) descending,
# and exports them to a dated daily text file.
$ScriptContent = @'
$Date = Get-Date -Format 'yyyy-MM-dd'
$LogFile = "C:\Logs\ProcessMemory\Processes_$Date.txt"

"---Process Memory Log: $(Get-Date) ---`r`n" | Out-File -FilePath $LogFile -Encoding utf8

Get-Process |
    Sort-Object -Property WorkingSet64 -Descending |
    Select-Object -Property Id, ProcessName, @{Name='Memory(MB)'; Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}} |
    Format-Table -AutoSize |
    Out-File -FilePath $LogFile -Append -Encoding utf8
'@

Set-Content -Path $ScriptPath -Value $ScriptContent -Force -Encoding utf8

# 3. Create the automated Windows Scheduled Task
$TaskName = "DailyProcessMemoryLog"
$Trigger  = New-ScheduledTaskTrigger -Daily -At 8:00AM
$Action   = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""

Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -Action $Action -User "NT AUTHORITY\SYSTEM" -RunLevel Highest -Force

Get-ScheduledTask -TaskName $TaskName

