# POST method: $req

$requestBody = Get-Content $req -Raw | ConvertFrom-Json
$pinghost = $requestBody.host

$testping = Test-Connection -TargetName $pinghost

Out-File -Encoding Ascii -FilePath $return -inputObject "$testping"