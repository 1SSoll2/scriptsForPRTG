param(
    [string]$sensor,
    [string]$sensorid,
    [string]$status,
    [string]$message,
    [string]$device,
    [string]$deviceid,
    [string]$since,
    [string]$lastup,
    [string]$sensorURL = "https://PRTG_IP/sensor.htm?id=$sensorid",
    [string]$deviceURL = "https://PRTG_IP/device.htm?id=$deviceid",
    [string]$serviceURL = "https://PRTG_IP"
)


$PRTGUsername = "PRTG_ID"
$PRTGPasshash  = "PRTG_PassHas"

$ackmessage = "Problem has been acknowledged via Discord"

$logDirectory = "C:\ProgramData\Paessler\PRTG Network Monitor\Logs\prtg-notifications-discord.log"

$uri = "https://Dischord_Webhook_URL"

$ackURL = [string]::Format("{0}/api/acknowledgealarm.htm?id={1}&ackmsg={2}&username={3}&passhash={4}",$serviceURL,$sensorID,[uri]::EscapeDataString($ackmessage),$PRTGUsername,$PRTGPasshash);

if($status -ne "Up")
{ $title = [string]::Format("{0} on {1} is in a {2} state!", $sensor, $device, $status) }
elseif($status -eq "Up")
{ $title = [string]::Format("{0} on {1} is up again!", $sensor, $device); $ackURL = ""; }
elseif($status -eq "Acknowledged")
{ $title = [string]::Format("The problem with {0} on {1} has been acknowledged.", $sensor, $device); $ackURL = ""; }

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$body = ConvertTo-Json -Depth 6 @{
    content = $($title)
    embeds = @(
        @{
            title = 'Details'
            description = "[Sensor Page]($sensorURL) - [Device Page]($deviceURL) - [Acknowledge Alert]($ackURL)"
            fields = @(
                @{
                name = 'Current State'
                value = $($status)
                },
                @{
                name = 'Message'
                value = $($message)
                },
                @{
                name = 'Since'
                value = $($since)
                },
                @{
                name = 'Last up'
                value = $($lastup)
                }
            )
        }
    )
}

$enc = [system.Text.Encoding]::UTF8
$encodedBody = $enc.GetBytes($body)

try 
{ Invoke-RestMethod -uri $uri -Method Post -body $encodedBody -ContentType 'application/json'; exit 0; }
Catch
{
    $ErrorMessage = $_.Exception.Message
    (Get-Date).ToString() +" - "+ $ErrorMessage | Out-File -FilePath $LogDirectory -Append
    exit 2;
}