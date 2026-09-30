$trivy = "C:\trivy\trivy.exe"
$image = "secure-cicd-app:latest"
$report = "trivy-report.json"

Write-Host "Starting security scan..."

& $trivy image --format json --output $report $image

if ($LASTEXITCODE -ne 0) {
    Write-Host "Trivy scan failed."
    exit 1
}

$data = Get-Content $report | ConvertFrom-Json

$critical = 0
$high = 0
$medium = 0
$low = 0

foreach ($result in $data.Results) {
    if ($null -ne $result.Vulnerabilities) {
        foreach ($vulnerability in $result.Vulnerabilities) {

            switch ($vulnerability.Severity) {
                "CRITICAL" { $critical++ }
                "HIGH"     { $high++ }
                "MEDIUM"   { $medium++ }
                "LOW"      { $low++ }
            }
        }
    }
}

Write-Host ""
Write-Host "===== SECURITY SUMMARY ====="
Write-Host "CRITICAL: $critical"
Write-Host "HIGH:     $high"
Write-Host "MEDIUM:   $medium"
Write-Host "LOW:      $low"
Write-Host "============================"

if ($critical -gt 0) {
    Write-Host "SECURITY GATE: BLOCKED - Critical vulnerability found."
    exit 1
}

if ($high -gt 3) {
    Write-Host "SECURITY GATE: BLOCKED - More than 3 High vulnerabilities found."
    exit 1
}

if ($high -gt 0) {
    Write-Host "SECURITY GATE: WARNING - High vulnerabilities found, but within allowed threshold."
}

Write-Host "SECURITY GATE: PASSED"
exit 0
