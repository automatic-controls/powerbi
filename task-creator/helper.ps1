if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
  $name = 'script-asana-ghost-clean'
  if ($null -eq (Get-ScheduledTask -TaskName $name -ErrorAction 'Ignore')){
    Write-Host "Installing $name..."
    $trigger = New-ScheduledTaskTrigger -Daily -At '12:30am'
    $principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 12) -MultipleInstances 'IgnoreNew' -Priority 7 -StartWhenAvailable -WakeToRun
    $action = New-ScheduledTaskAction -Execute (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'asana-ghost-clean\exec.bat')
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description 'Deletes ghost tasks and projects from Asana tables in the PostgreSQL database.'
    $null = Register-ScheduledTask -InputObject $task -Force -TaskName $name
  }else{
    Write-Host "Skipping $name."
  }
  $name = 'script-qqube-validate'
  if ($null -eq (Get-ScheduledTask -TaskName $name -ErrorAction 'Ignore')){
    Write-Host "Installing $name..."
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek 'Wednesday' -At '1am'
    $principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 4) -MultipleInstances 'IgnoreNew' -Priority 7 -StartWhenAvailable -WakeToRun
    $action = New-ScheduledTaskAction -Execute (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'qqube-validate\exec.bat')
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description 'Checks that the proposal and change order amounts add up appropriately in the QQube database, and send email notifications when errors are found.'
    $null = Register-ScheduledTask -InputObject $task -Force -TaskName $name
  }else{
    Write-Host "Skipping $name."
  }
  $name = 'script-zendesk-validate'
  if ($null -eq (Get-ScheduledTask -TaskName $name -ErrorAction 'Ignore')){
    Write-Host "Installing $name..."
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek 'Friday' -At '1am'
    $principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 4) -MultipleInstances 'IgnoreNew' -Priority 7 -StartWhenAvailable -WakeToRun
    $action = New-ScheduledTaskAction -Execute (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'zendesk-validate\exec.bat')
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description 'Checks Zendesk for job number errors and sends an email notification accordingly.'
    $null = Register-ScheduledTask -InputObject $task -Force -TaskName $name
  }else{
    Write-Host "Skipping $name."
  }
  $name = 'script-timeworksplus'
  if ($null -eq (Get-ScheduledTask -TaskName $name -ErrorAction 'Ignore')){
    Write-Host "Installing $name..."
    $trigger = New-ScheduledTaskTrigger -Daily -At '3am'
    $principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 8) -MultipleInstances 'IgnoreNew' -Priority 7 -StartWhenAvailable -WakeToRun
    $action = New-ScheduledTaskAction -Execute (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'timeworksplus\exec.bat')
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description 'Pulls data from the TimeWorksPlus API into the PostgreSQL database.'
    $null = Register-ScheduledTask -InputObject $task -Force -TaskName $name
  }else{
    Write-Host "Skipping $name."
  }
  $name = 'script-postgresql-backup'
  if ($null -eq (Get-ScheduledTask -TaskName $name -ErrorAction 'Ignore')){
    Write-Host "Installing $name..."
    $trigger = New-ScheduledTaskTrigger -Daily -At '4am'
    $principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 12) -MultipleInstances 'IgnoreNew' -Priority 7 -StartWhenAvailable -WakeToRun
    $action = New-ScheduledTaskAction -Execute (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'postgresql-backup\backup.bat')
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description 'Provides redundant daily backups for important PostgreSQL database tables.'
    $null = Register-ScheduledTask -InputObject $task -Force -TaskName $name
  }else{
    Write-Host "Skipping $name."
  }
  $name = 'script-cradlepoint'
  if ($null -eq (Get-ScheduledTask -TaskName $name -ErrorAction 'Ignore')){
    Write-Host "Installing $name..."
    $trigger = New-ScheduledTaskTrigger -Daily -At '5am'
    $principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 6) -MultipleInstances 'IgnoreNew' -Priority 7 -StartWhenAvailable -WakeToRun
    $action = New-ScheduledTaskAction -Execute (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'cradlepoint\exec.bat')
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description 'Pulls data from the Cradlepoint API into the PostgreSQL database.'
    $null = Register-ScheduledTask -InputObject $task -Force -TaskName $name
  }else{
    Write-Host "Skipping $name."
  }
  $name = 'script-qqube-checker'
  if ($null -eq (Get-ScheduledTask -TaskName $name -ErrorAction 'Ignore')){
    Write-Host "Installing $name..."
    $trigger = New-ScheduledTaskTrigger -Daily -At '5:30am'
    $principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 2) -MultipleInstances 'IgnoreNew' -Priority 7 -StartWhenAvailable -WakeToRun
    $action = New-ScheduledTaskAction -Execute (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'qqube-checker\exec.bat')
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description 'Checks whether QQube successfully synced data from Quickbooks to the SQL Anywhere database.'
    $null = Register-ScheduledTask -InputObject $task -Force -TaskName $name
  }else{
    Write-Host "Skipping $name."
  }
  $name = 'script-synchrony'
  if ($null -eq (Get-ScheduledTask -TaskName $name -ErrorAction 'Ignore')){
    Write-Host "Installing $name..."
    $trigger = New-ScheduledTaskTrigger -Daily -At '6am'
    $principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 4) -MultipleInstances 'IgnoreNew' -Priority 7 -StartWhenAvailable -WakeToRun
    $action = New-ScheduledTaskAction -Execute (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'synchrony\import.bat')
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description 'Imports reports from Synchrony into the PostgreSQL database.'
    $null = Register-ScheduledTask -InputObject $task -Force -TaskName $name
  }else{
    Write-Host "Skipping $name."
  }
  $name = 'script-verizon'
  if ($null -eq (Get-ScheduledTask -TaskName $name -ErrorAction 'Ignore')){
    Write-Host "Installing $name..."
    $trigger = New-ScheduledTaskTrigger -Daily -At '6:30am'
    $principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 8) -MultipleInstances 'IgnoreNew' -Priority 7 -StartWhenAvailable -WakeToRun
    $action = New-ScheduledTaskAction -Execute (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'verizon\import.bat')
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description 'Imports reports from Verizon into the PostgreSQL database.'
    $null = Register-ScheduledTask -InputObject $task -Force -TaskName $name
  }else{
    Write-Host "Skipping $name."
  }
  $name = 'script-regfox'
  if ($null -eq (Get-ScheduledTask -TaskName $name -ErrorAction 'Ignore')){
    Write-Host "Installing $name..."
    $trigger = New-ScheduledTaskTrigger -Daily -At '7am'
    $principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 4) -MultipleInstances 'IgnoreNew' -Priority 7 -StartWhenAvailable -WakeToRun
    $action = New-ScheduledTaskAction -Execute (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'regfox\import.bat')
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description 'Downloads and copies a RegFox report to Sharepoint.'
    $null = Register-ScheduledTask -InputObject $task -Force -TaskName $name
  }else{
    Write-Host "Skipping $name."
  }
  $name = 'script-qqube-sync'
  if ($null -eq (Get-ScheduledTask -TaskName $name -ErrorAction 'Ignore')){
    Write-Host "Installing $name..."
    $trigger = New-ScheduledTaskTrigger -Daily -At '12pm'
    $principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 12) -MultipleInstances 'IgnoreNew' -Priority 7 -StartWhenAvailable -WakeToRun
    $action = New-ScheduledTaskAction -Execute (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'qqube-sync\exec.bat')
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description 'Provides a one-way partial sync from QQube into the PostgreSQL database.'
    $null = Register-ScheduledTask -InputObject $task -Force -TaskName $name
  }else{
    Write-Host "Skipping $name."
  }
  $name = 'script-webctrl-monitor'
  if ($null -eq (Get-ScheduledTask -TaskName $name -ErrorAction 'Ignore')){
    Write-Host "Installing $name..."
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserID 'NT AUTHORITY\SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances 'IgnoreNew' -Priority 7 -StartWhenAvailable -WakeToRun
    $settings.ExecutionTimeLimit = 'PT0S'
    $action = New-ScheduledTaskAction -Execute (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'webctrl-monitor\webctrl_monitor.bat')
    $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -Description 'Monitors webserver URLs and sends email notifications when one goes online or offline.'
    $null = Register-ScheduledTask -InputObject $task -Force -TaskName $name
    Start-ScheduledTask -InputObject (Get-ScheduledTask -TaskName $name)
  }else{
    Write-Host "Skipping $name."
  }
  Write-Host 'Done.'
  exit 0
}else{
  Write-Host 'Please run this script as administrator.'
  exit 1
}