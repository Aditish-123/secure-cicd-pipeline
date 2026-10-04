# ============================================
# SECURITY GATE
# ============================================

$ErrorActionPreference = "Stop"

$trivy = "C:\trivy\trivy.exe"

# ============================================
# INPUTS FROM JENKINS
# ============================================

$image = $args[0]
$detectedLanguage = $args[1]

if ([string]::IsNullOrWhiteSpace($image)) {
    Write-Host "ERROR: Docker image was not provided."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($detectedLanguage)) {
    Write-Host "ERROR: Application type was not provided."
    exit 1
}

Write-Host ""
Write-Host "============================================"
Write-Host "SECURITY GATE"
Write-Host "============================================"

Write-Host "Detected application: $detectedLanguage"
Write-Host "Docker image: $image"

# ============================================
# FILES
# ============================================

$report = "trivy-report.json"
$summary = "trivy-summary.txt"

# Application-specific baseline
$previous = "previous-security-$detectedLanguage.txt"

# ============================================
# CHECK TRIVY
# ============================================

if (-not (Test-Path $trivy)) {

    Write-Host ""
    Write-Host "ERROR: Trivy was not found."
    Write-Host "Expected location: $trivy"

    exit 1
}

# ============================================
# START TRIVY SCAN
# ============================================

Write-Host ""
Write-Host "============================================"
Write-Host "STARTING SECURITY SCAN"
Write-Host "============================================"

Write-Host "Application : $detectedLanguage"
Write-Host "Image       : $image"

& $trivy image `
    --scanners vuln `
    --format json `
    --output $report `
    $image

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "Trivy scan failed."
    exit 1
}

# ============================================
# READ TRIVY REPORT
# ============================================

if (-not (Test-Path $report)) {

    Write-Host "ERROR: Trivy report was not created."
    exit 1
}

$data = Get-Content $report -Raw | ConvertFrom-Json

$critical = 0
$high = 0
$medium = 0
$low = 0

foreach ($result in $data.Results) {

    if ($null -ne $result.Vulnerabilities) {

        foreach ($vulnerability in $result.Vulnerabilities) {

            switch ($vulnerability.Severity) {

                "CRITICAL" {
                    $critical++
                }

                "HIGH" {
                    $high++
                }

                "MEDIUM" {
                    $medium++
                }

                "LOW" {
                    $low++
                }
            }
        }
    }
}

# ============================================
# SECURITY SUMMARY
# ============================================

Write-Host ""
Write-Host "============================================"
Write-Host "SECURITY SUMMARY"
Write-Host "============================================"

Write-Host "Application : $detectedLanguage"
Write-Host "Docker Image: $image"
Write-Host ""

Write-Host "CRITICAL: $critical"
Write-Host "HIGH:     $high"
Write-Host "MEDIUM:   $medium"
Write-Host "LOW:      $low"

Write-Host "============================================"

# ============================================
# SECURITY COMPARISON
# ============================================

Write-Host ""
Write-Host "============================================"
Write-Host "SECURITY COMPARISON"
Write-Host "============================================"

$hasPrevious = Test-Path $previous

if ($hasPrevious) {

    $previousData = @{}

    Get-Content $previous | ForEach-Object {

        if ($_ -match "^(.+?)=(\d+)$") {

            $previousData[$matches[1]] = [int]$matches[2]
        }
    }

    $previousCritical = if ($previousData.ContainsKey("CRITICAL")) {
        $previousData["CRITICAL"]
    } else {
        0
    }

    $previousHigh = if ($previousData.ContainsKey("HIGH")) {
        $previousData["HIGH"]
    } else {
        0
    }

    $previousMedium = if ($previousData.ContainsKey("MEDIUM")) {
        $previousData["MEDIUM"]
    } else {
        0
    }

    $previousLow = if ($previousData.ContainsKey("LOW")) {
        $previousData["LOW"]
    } else {
        0
    }

    Write-Host ""
    Write-Host "                PREVIOUS     CURRENT"

    Write-Host "CRITICAL        $previousCritical          $critical"
    Write-Host "HIGH            $previousHigh          $high"
    Write-Host "MEDIUM          $previousMedium          $medium"
    Write-Host "LOW             $previousLow          $low"

    # ========================================
    # CALCULATE CHANGES
    # ========================================

    $criticalChange = $critical - $previousCritical
    $highChange = $high - $previousHigh
    $mediumChange = $medium - $previousMedium
    $lowChange = $low - $previousLow

    Write-Host ""
    Write-Host "============================================"
    Write-Host "SECURITY CHANGE"
    Write-Host "============================================"

    Write-Host "CRITICAL change: $criticalChange"
    Write-Host "HIGH change:     $highChange"
    Write-Host "MEDIUM change:   $mediumChange"
    Write-Host "LOW change:      $lowChange"

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

    $previousCritical = 0
    $previousHigh = 0
    $previousMedium = 0
    $previousLow = 0

    $criticalChange = 0
    $highChange = 0
    $mediumChange = 0
    $lowChange = 0
}

Write-Host "============================================"

# ============================================
# CREATE SECURITY SUMMARY
# ============================================

"===== SECURITY SUMMARY =====" | Out-File $summary

"Application: $detectedLanguage" |
    Out-File $summary -Append

"Docker Image: $image" |
    Out-File $summary -Append

"" | Out-File $summary -Append

"CRITICAL: $critical" |
    Out-File $summary -Append

"HIGH: $high" |
    Out-File $summary -Append

"MEDIUM: $medium" |
    Out-File $summary -Append

"LOW: $low" |
    Out-File $summary -Append

# ============================================
# SECURITY COMPARISON IN REPORT
# ============================================

"" | Out-File $summary -Append

"===== SECURITY COMPARISON =====" |
    Out-File $summary -Append

if ($hasPrevious) {

    "Previous CRITICAL: $previousCritical" |
        Out-File $summary -Append

    "Current CRITICAL:  $critical" |
        Out-File $summary -Append

    "" | Out-File $summary -Append

    "Previous HIGH: $previousHigh" |
        Out-File $summary -Append

    "Current HIGH:  $high" |
        Out-File $summary -Append

    "" | Out-File $summary -Append

    "Previous MEDIUM: $previousMedium" |
        Out-File $summary -Append

    "Current MEDIUM:  $medium" |
        Out-File $summary -Append

    "" | Out-File $summary -Append

    "Previous LOW: $previousLow" |
        Out-File $summary -Append

    "Current LOW:  $low" |
        Out-File $summary -Append

    "" | Out-File $summary -Append

    "CRITICAL change: $criticalChange" |
        Out-File $summary -Append

    "HIGH change: $highChange" |
        Out-File $summary -Append

    "MEDIUM change: $mediumChange" |
        Out-File $summary -Append

    "LOW change: $lowChange" |
        Out-File $summary -Append

}
else {

    "No previous security scan available." |
        Out-File $summary -Append

    "This build is the baseline." |
        Out-File $summary -Append
}

# ============================================
# HIGH / CRITICAL DETAILS
# ============================================

"" | Out-File $summary -Append

"===== HIGH / CRITICAL DETAILS =====" |
    Out-File $summary -Append

"" | Out-File $summary -Append

foreach ($result in $data.Results) {

    if ($null -ne $result.Vulnerabilities) {

        foreach ($vulnerability in $result.Vulnerabilities) {

            if (
                $vulnerability.Severity -eq "HIGH" -or
                $vulnerability.Severity -eq "CRITICAL"
            ) {

                "Severity: $($vulnerability.Severity)" |
                    Out-File $summary -Append

                "CVE: $($vulnerability.VulnerabilityID)" |
                    Out-File $summary -Append

                "Package: $($vulnerability.PkgName)" |
                    Out-File $summary -Append

                "Installed Version: $($vulnerability.InstalledVersion)" |
                    Out-File $summary -Append

                "Fixed Version: $($vulnerability.FixedVersion)" |
                    Out-File $summary -Append

                "----------------------------------------" |
                    Out-File $summary -Append
            }
        }
    }
}

Write-Host ""
Write-Host "Developer-friendly security report created: $summary"

# ============================================
# SAVE CURRENT SCAN AS BASELINE
# ============================================

@"
CRITICAL=$critical
HIGH=$high
MEDIUM=$medium
LOW=$low
"@ | Out-File $previous

# ============================================
# SECURITY POLICY
# ============================================

Write-Host ""
Write-Host "============================================"
Write-Host "SECURITY GATE DECISION"
Write-Host "============================================"

# ============================================
# RULE 1: CRITICAL
# ============================================

if ($critical -gt 0) {

    Write-Host ""
    Write-Host "SECURITY GATE: BLOCKED"
    Write-Host "Reason: Critical vulnerability found."
    Write-Host "CRITICAL vulnerabilities: $critical"

    exit 1
}

# ============================================
# RULE 2: HIGH > 50
# ============================================

if ($high -gt 50) {

    Write-Host ""
    Write-Host "SECURITY GATE: BLOCKED"
    Write-Host "Reason: High vulnerabilities exceed threshold of 50."
    Write-Host "HIGH vulnerabilities: $high"

    exit 1
}

# ============================================
# RULE 3: HIGH 1-50
# ============================================

if ($high -gt 0) {

    Write-Host ""
    Write-Host "SECURITY GATE: WARNING"
    Write-Host "High vulnerabilities found: $high"
    Write-Host "High vulnerability count is within allowed threshold of 50."
}

# ============================================
# RULE 4: NO HIGH / CRITICAL
# ============================================

if ($high -eq 0 -and $critical -eq 0) {

    Write-Host ""
    Write-Host "No HIGH or CRITICAL vulnerabilities found."
}

# ============================================
# FINAL DECISION
# ============================================

Write-Host ""
Write-Host "SECURITY GATE: PASSED"
Write-Host "============================================"

exit 0
