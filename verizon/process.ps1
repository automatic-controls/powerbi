$file = $Env:processThisReport
if (-not (Test-Path -Path $file)) {
  exit 1
}
$s = Get-Content -Path $file -First 1
if ($s.Contains('Notes')){
  Rename-Item -Path $file -NewName 'Maintenance History Report.csv' -Force
}