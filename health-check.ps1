param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("python", "node", "java")]
    [string]$Application,

    [Parameter(Mandatory = $true)]
    [string]$EC2Host
)

$ErrorActionPreference = "Stop"

if ($Application -eq "python") {
    $port = 5000
    $path = "/health"
}
elseif ($Application -eq "node") {
    $port = 3000
    $path = "/health"
}
elseif ($Application -eq "java") {
    $port = 8081
    $path = "/health"
}

$url = "http://$EC2Host`:$port$path"

Write-Host "============================================"
Write-Host "APPLICATION HEALTH CHECK"
Write-Host "============================================"
Write-Host "Application : $Application"
Write-Host "Health URL  : $url"
Write-Host "============================================"

for ($attempt = 1; $attempt -le 12; $attempt++) {

    try {
        $response = Invoke-WebRequest `
            -Uri $url `
            -UseBasicParsing `
            -TimeoutSec 10

        Write-Host "Attempt $attempt"
        Write-Host "HTTP Status: $($response.StatusCode)"
        Write-Host "Response: $($response.Content)"

        if ($response.StatusCode -eq 200) {
            Write-Host "============================================"
            Write-Host "APPLICATION HEALTH CHECK PASSED"
            Write-Host "============================================"
            exit 0
        }
    }
    catch {
        Write-Host "Attempt $attempt failed: $($_.Exception.Message)"
    }

    if ($attempt -lt 12) {
        Start-Sleep -Seconds 5
    }
}

Write-Host "============================================"
Write-Host "APPLICATION HEALTH CHECK FAILED"
Write-Host "============================================"

exit 1
