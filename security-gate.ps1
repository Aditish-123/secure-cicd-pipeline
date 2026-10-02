# ============================================
# SECURITY GATE
# ============================================

$trivy = "C:\trivy\trivy.exe"


# ============================================
# SELECT DOCKER IMAGE
# ============================================

if ($env:DETECTED_LANGUAGE -eq "node") {

    $image = "secure-cicd-node-app:latest"

}
elseif ($env:DETECTED_LANGUAGE -eq "java") {

    $image = "secure-cicd-java-app:latest"

}
elseif ($env:DETECTED_LANGUAGE -eq "python") {

    $image = "secure-cicd-app:latest"

}
else {

    Write-Host "No application selected for security scanning."
    Write-Host "Security Gate will be skipped."

    exit 0
}


$report = "trivy-report.json"
$summary = "trivy-summary.txt"
$previous = "previous-security.txt"


# ============================================
# START TRIVY SCAN
# ============================================

Write-Host ""
Write-Host "============================================"
Write-Host "STARTING SECURITY SCAN"
Write-Host "============================================"

Write-Host "Detected application: $env:DETECTED_LANGUAGE"
Write-Host "Scanning Docker image: $image"


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

$data = Get-Content $report | ConvertFrom-Json


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

Write-Host "Application : $env:DETECTED_LANGUAGE"
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


    # ========================================
    # CRITICAL CHANGE MESSAGE
    # ========================================

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


    # ========================================
    # HIGH CHANGE MESSAGE
    # ========================================

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


Write-Host "============================================"


# ============================================
# CREATE SECURITY SUMMARY FILE
# ============================================

"===== SECURITY SUMMARY =====" | Out-File $summary

"Application: $env:DETECTED_LANGUAGE" |
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


if (Test-Path $previous) {

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

    "HIGH change: $highChange" |
        Out-File $summary -Append

    "CRITICAL change: $criticalChange" |
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
