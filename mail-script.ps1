[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
if (-Not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)){
  Install-Module -Force Microsoft.Graph.Authentication
}
if (-Not (Get-Module -ListAvailable -Name Microsoft.Graph.Users.Actions)){
  Install-Module -Force Microsoft.Graph.Users.Actions
}
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($Env:email_keystore,$Env:email_keystore_password)
Connect-MgGraph -ClientId $Env:email_app_id -TenantId $Env:email_tenant_id -Certificate $cert -NoWelcome
$emails = $Env:email_to
$recipients = @()
foreach ($email in $emails.Split(";")) {
  $recipients += @{ emailAddress = @{ address = $email.Trim() } }
}
$body = $Env:email_body
$body = $body.Replace('`r`n',"`r`n")
$msg = @{
  subject = $Env:email_subject
  body = @{
    contentType = "Text"
    content = $body
  }
  toRecipients = $recipients
}
$attach = $Env:email_attachment
if ($attach) {
  $ctype = $Env:email_attachment_type
  if (-Not $ctype) {
    $ctype = "text/plain"
  }
  $msg.attachments = @(
    @{
      '@odata.type' = "#microsoft.graph.fileAttachment"
      name = Split-Path -Path $Env:email_attachment -Leaf
      contentType = $ctype
      contentBytes = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($attach))
    }
  )
}
$params = @{
	message = $msg
	saveToSentItems = "false"
}
Send-MgUserMail -UserId $Env:pbi_email -BodyParameter $params
$ret = $?
$null = Disconnect-MgGraph
if ( $ret ){ exit 0 }else{ exit 1 }