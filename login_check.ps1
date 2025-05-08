$baseUrl = 'https://helpdesk.paessler.com'
$url = "https://helpdesk.paessler.com/en/support/login"
$logoutUrl = "$baseUrl/en/support/home"
$username = 'id'
$password = 'pw'
$checkString = 'here'

$response = Invoke-WebRequest -Uri "$url" -SessionVariable PRTG -UseBasicParsing

$LoginForm = @{
    "authenticity_token" = $authToken
    "user_session[email]" = $username
    "user_session[password]" = $password
    "user_session[remember_me]" = "1"
}

$result = Invoke-WebRequest -Uri "$url" -WebSession $PRTG -Method POST -Body $LoginForm -ContentType "application/x-www-form-urlencoded" -UseBasicParsing

$response_code = $result.StatusCode

if ($result.Content.Contains($checkString)) {
    $message = "$response_code, Login successful - '$checkString' found."
    Write-Output $message,"0:OK"
    Invoke-WebRequest -Uri $logoutUrl -WebSession $PRTG -UseBasicParsing | Out-Null
    Remove-Variable PRTG
    Exit 0
} else {
    $message = "$response_code, Login failed or checkstring not found."
    Write-Output $message,"1:WARNING"
    Invoke-WebRequest -Uri $logoutUrl -WebSession $PRTG -UseBasicParsing | Out-Null
    Remove-Variable PRTG
    Exit 1
}
