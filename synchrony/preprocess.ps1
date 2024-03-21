param([string]$file)
$raw = (Get-Content -LiteralPath $file) -creplace '^.*"","","","","","","","","","".*$', ''
$raw = $raw | Where-Object {$_.trim() -ne "" }
Set-Content -LiteralPath $file -Value $raw