$trivy = "C:\trivy\trivy.exe"

# Select Docker image based on detected project language
if ($env:DETECTED_LANGUAGE -eq "node") {
    $image = "secure-cicd-node-app:latest"
}
else {
    $image = "secure-cicd-app:latest"
}

$report = "trivy-report.json"
$summary = "trivy-summary.txt"
$previous = "previous-security.txt"

Write-Host "Starting security scan..."
Write-Host "Scanning image: $image"

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


# ==========================================
# BEFORE vs AFTER COMPARISON
# ==========================================

Write-Host ""
Write-Host "===== SECURITY COMPARISON ====="

if (Test-Path $previous) {

    $previousData = @{}

    Get-Content $previous | ForEach-Object {

        if ($_ -match "^(.+?)=(\d+)$") {
            $previousData[$matches[1]] = [int]$matches[2]
        }
    }

    $previousCritical = $previousData["CRITICAL"]
    $previousHigh = $previousData["HIGH"]
    $previousMedium = $previousData["MEDIUM"]
    $previousLow = $previousData["LOW"]

    Write-Host ""
    Write-Host "                PREVIOUS     CURRENT"
    Write-Host "CRITICAL        $previousCritical          $critical"
    Write-Host "HIGH            $previousHigh         $high"
    Write-Host "MEDIUM          $previousMedium         $medium"
    Write-Host "LOW             $previousLow         $low"

    Write-Host ""
    Write-Host "===== CHANGE ====="

    $criticalChange = $critical - $previousCritical
    $highChange = $high - $previousHigh
    $mediumChange = $medium - $previousMedium
    $lowChange = $low - $previousLow

    Write-Host "CRITICAL change: $criticalChange"
    Write-Host "HIGH change:     $highChange"
    Write-Host "MEDIUM change:   $mediumChange"
    Write-Host "LOW change:      $lowChange"

    Write-Host ""

    if ($criticalChange -lt 0) {
        Write-Host "CRITICAL vulnerabilities decreased."
    }
    elseif ($criticalChange -gt 0) {
        Write-Host "WARNING: CRITICAL vulnerabilities increased."
    }
    else {
        Write-Host "CRITICAL vulnerabilities unchanged."
    }

    if ($highChange -lt 0) {
        Write-Host "HIGH vulnerabilities decreased."
    }
    elseif ($highChange -gt 0) {
        Write-Host "WARNING: HIGH vulnerabilities increased."
    }
    else {
        Write-Host "HIGH vulnerabilities unchanged."
    }

}
else {

    Write-Host ""
    Write-Host "No previous security scan available."
    Write-Host "This build will be used as the baseline."
}

Write-Host "================================"


# ==========================================
# CREATE DEVELOPER-FRIENDLY SUMMARY
# ==========================================

"===== HIGH / CRITICAL VULNERABILITIES =====" | Out-File $summary
"" | Out-File $summary -Append

"CRITICAL: $critical" | Out-File $summary -Append
"HIGH: $high" | Out-File $summary -Append
"MEDIUM: $medium" | Out-File $summary -Append
"LOW: $low" | Out-File $summary -Append

"" | Out-File $summary -Append
"===== SECURITY COMPARISON =====" | Out-File $summary -Append

if (Test-Path $previous) {

    "Previous CRITICAL: $previousCritical" | Out-File $summary -Append
    "Current CRITICAL:  $critical" | Out-File $summary -Append

    "Previous HIGH: $previousHigh" | Out-File $summary -Append
    "Current HIGH:  $high" | Out-File $summary -Append

    "Previous MEDIUM: $previousMedium" | Out-File $summary -Append
    "Current MEDIUM:  $medium" | Out-File $summary -Append

    "Previous LOW: $previousLow" | Out-File $summary -Append
    "Current LOW:  $low" | Out-File $summary -Append

    "" | Out-File $summary -Append

    "HIGH change: $highChange" | Out-File $summary -Append
    "CRITICAL change: $criticalChange" | Out-File $summary -Append
}
else {
    "No previous security scan available." | Out-File $summary -Append
    "This build is the baseline." | Out-File $summary -Append
}

"" | Out-File $summary -Append
"===== HIGH / CRITICAL DETAILS =====" | Out-File $summary -Append
"" | Out-File $summary -Append


foreach ($result in $data.Results) {

    if ($null -ne $result.Vulnerabilities) {

        foreach ($vulnerability in $result.Vulnerabilities) {

            if (
                $vulnerability.Severity -eq "HIGH" -or
                $vulnerability.Severity -eq "CRITICAL"
            ) {

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


# ==========================================
# SAVE CURRENT RESULT FOR NEXT BUILD
# ==========================================

@"
CRITICAL=$critical
HIGH=$high
MEDIUM=$medium
LOW=$low
"@ | Out-File $previous


# ==========================================
# SECURITY GATE
# ==========================================

if ($critical -gt 0) {

    Write-Host ""
    Write-Host "SECURITY GATE: BLOCKED - Critical vulnerability found."

    exit 1
}

if ($high -gt 50) {

    Write-Host ""
    Write-Host "SECURITY GATE: BLOCKED - More than 50 High vulnerabilities found."

    exit 1
}

if ($high -gt 0) {

    Write-Host ""
    Write-Host "SECURITY GATE: WARNING - High vulnerabilities found, but within allowed threshold."
}

Write-Host ""
Write-Host "SECURITY GATE: PASSED"

exit 0
