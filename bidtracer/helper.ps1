$excel = New-Object -ComObject excel.application
foreach ($old_name in $args){
    $new_name = $old_name -replace '\.xlsx?$', '.csv'
    $book = $excel.Workbooks.Open($old_name)
    $book.SaveAs($new_name, 6)
    $book.Close()
}
$excel.Quit()