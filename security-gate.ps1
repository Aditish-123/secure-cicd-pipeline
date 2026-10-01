$trivy = "C:\trivy\trivy.exe"
$image = "secure-cicd-app:latest"
$report = "trivy-report.json"
$summary = "trivy-summary.txt"

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

# Create developer-friendly summary
"===== HIGH / CRITICAL VULNERABILITIES =====" | Out-File $summary
"" | Out-File $summary -Append

foreach ($result in $data.Results) {
    if ($null -ne $result.Vulnerabilities) {
        foreach ($vulnerability in $result.Vulnerabilities) {

            if ($vulnerability.Severity -eq "HIGH" -or $vulnerability.Severity -eq "CRITICAL") {

                "Severity: $($vulnerability.Severity)" | Out-File $summary -Append
                "CVE: $($vulnerability.VulnerabilityID)" | Out-File $summary -Append
                "Package: $($vulnerability.PkgName)" | Out-File $summary -Append
                "Installed Version: $($vulnerability.InstalledVersion)" | Out-File $summary -Append
                "Fixed Version: $($vulnerability.FixedVersion)" | Out-File $summary -Append
                "----------------------------------------" | Out-File $summary -Append
            }
        }
    }
}

Write-Host "Developer-friendly security report created: $summary"

if ($critical -gt 0) {
    Write-Host "SECURITY GATE: BLOCKED - Critical vulnerability found."
    exit 1
}

if ($high -gt 50) {
    Write-Host "SECURITY GATE: BLOCKED - More than 50 High vulnerabilities found."
    exit 1
}

if ($high -gt 0) {
    Write-Host "SECURITY GATE: WARNING - High vulnerabilities found, but within allowed threshold."
}

Write-Host "SECURITY GATE: PASSED"
exit 0
