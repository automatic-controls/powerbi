try{
  Add-Type -AssemblyName System.Windows.Forms
  $FileDialog = New-Object System.Windows.Forms.OpenFileDialog
  $FileDialog.InitialDirectory = (Join-Path -Path $Env:UserProfile -ChildPath 'Downloads')
  $FileDialog.Title = 'Select Your Data File'
  $FileDialog.Filter = 'XLS Files|*.xls'
  $response = $FileDialog.ShowDialog()
  if ($response -eq 'OK'){
    $old_name = $FileDialog.FileName
    $FileDialog = $null
    $new_name = $old_name -replace '\.xls$', '.xml'
    Copy-Item -LiteralPath $old_name -Destination $new_name -Force
    $old_name = $new_name
    $new_name = Join-Path -Path (Split-Path -Path $old_name -Parent) -ChildPath 'temporary.csv'
    $excel = New-Object -ComObject excel.application
    $book = $excel.Workbooks.Open($old_name)
    $book.SaveAs($new_name, 6)
    $book.Close()
    $excel.Quit()
    Remove-Item -LiteralPath $old_name -Force
    Write-Host $new_name
  }
}catch{}
Return