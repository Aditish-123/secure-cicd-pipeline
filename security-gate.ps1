$trivy = "C:\trivy\trivy.exe"
$image = "secure-cicd-app:latest"
$report = "trivy-report.json"
$summary = "trivy-summary.txt"

Write-Host ""
Write-Host "=========================================="
Write-Host "        STARTING SECURITY SCAN"
Write-Host "=========================================="
Write-Host ""

& $trivy image --format json --output $report $image

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ SECURITY SCAN FAILED"
    Write-Host "Trivy could not complete the image scan."
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

# ==========================================
# SECURITY SUMMARY
# ==========================================

Write-Host ""
Write-Host "=========================================="
Write-Host "           SECURITY SUMMARY"
Write-Host "=========================================="

Write-Host "CRITICAL : $critical"
Write-Host "HIGH     : $high"
Write-Host "MEDIUM   : $medium"
Write-Host "LOW      : $low"

Write-Host "=========================================="

# ==========================================
# CREATE DEVELOPER REPORT
# ==========================================

"==========================================" | Out-File $summary
"        DEVELOPER SECURITY REPORT" | Out-File $summary -Append
"==========================================" | Out-File $summary -Append
"" | Out-File $summary -Append

"CRITICAL : $critical" | Out-File $summary -Append
"HIGH     : $high" | Out-File $summary -Append
"MEDIUM   : $medium" | Out-File $summary -Append
"LOW      : $low" | Out-File $summary -Append

"" | Out-File $summary -Append
"==========================================" | Out-File $summary -Append
"       HIGH / CRITICAL ISSUES" | Out-File $summary -Append
"==========================================" | Out-File $summary -Append
"" | Out-File $summary -Append

$issueCount = 0

foreach ($result in $data.Results) {

    if ($null -ne $result.Vulnerabilities) {

        foreach ($vulnerability in $result.Vulnerabilities) {

            if (
                $vulnerability.Severity -eq "HIGH" -or
                $vulnerability.Severity -eq "CRITICAL"
            ) {

                $issueCount++

                # Show detailed issue in Jenkins Console

                Write-Host ""
                Write-Host "------------------------------------------"
                Write-Host "Issue #$issueCount"
                Write-Host "Severity : $($vulnerability.Severity)"
                Write-Host "CVE      : $($vulnerability.VulnerabilityID)"
                Write-Host "Package  : $($vulnerability.PkgName)"
                Write-Host "Installed: $($vulnerability.InstalledVersion)"
                Write-Host "Fixed    : $($vulnerability.FixedVersion)"
                Write-Host "------------------------------------------"

                # Also save the same information to report

                "Issue #$issueCount" | Out-File $summary -Append
                "Severity : $($vulnerability.Severity)" | Out-File $summary -Append
                "CVE      : $($vulnerability.VulnerabilityID)" | Out-File $summary -Append
                "Package  : $($vulnerability.PkgName)" | Out-File $summary -Append
                "Installed: $($vulnerability.InstalledVersion)" | Out-File $summary -Append
                "Fixed    : $($vulnerability.FixedVersion)" | Out-File $summary -Append
                "" | Out-File $summary -Append
            }
        }
    }
}

Write-Host ""
Write-Host "Developer-friendly security report created: $summary"

# ==========================================
# SECURITY DECISION
# ==========================================

Write-Host ""
Write-Host "=========================================="
Write-Host "          SECURITY DECISION"
Write-Host "=========================================="

if ($critical -gt 0) {

    Write-Host "❌ SECURITY GATE: BLOCKED"
    Write-Host ""
    Write-Host "Reason: Critical vulnerabilities were found."
    Write-Host ""
    Write-Host "Recommended Action:"
    Write-Host "1. Check the vulnerable package."
    Write-Host "2. Update it to the fixed version when available."
    Write-Host "3. If the issue comes from the base image, update the Docker base image."
    Write-Host "4. Commit the changes and push to GitHub."
    Write-Host "5. Jenkins will run the security check again."

    "SECURITY GATE: BLOCKED" | Out-File $summary -Append
    "Reason: Critical vulnerabilities were found." | Out-File $summary -Append

    exit 1
}

if ($high -gt 50) {

    Write-Host "❌ SECURITY GATE: BLOCKED"
    Write-Host ""
    Write-Host "Reason: More than 50 High vulnerabilities were found."
    Write-Host ""
    Write-Host "Recommended Action:"
    Write-Host "Review the vulnerable packages and update the affected dependencies or base image."

    "SECURITY GATE: BLOCKED" | Out-File $summary -Append
    "Reason: More than 50 High vulnerabilities were found." | Out-File $summary -Append

    exit 1
}

if ($high -gt 0) {

    Write-Host "⚠ SECURITY GATE: WARNING"
    Write-Host ""
    Write-Host "High vulnerabilities were found, but they are within the allowed threshold."
    Write-Host "The pipeline is allowed to continue."

    "SECURITY GATE: WARNING" | Out-File $summary -Append
}

Write-Host ""
Write-Host "✅ SECURITY GATE: PASSED"
Write-Host ""
Write-Host "The Docker image passed the configured security policy."

"SECURITY GATE: PASSED" | Out-File $summary -Append

Write-Host "=========================================="
Write-Host "      SECURITY SCAN COMPLETED"
Write-Host "=========================================="

exit 0
