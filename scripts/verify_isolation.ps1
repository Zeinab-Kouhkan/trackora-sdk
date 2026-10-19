# Script: verify_isolation.ps1
# Automates the verification of Build-Time Store Isolation for Trackora SDK

$ErrorActionPreference = "Stop"

$workspaceDir = "E:\workspace\attribution"
$tempAppDir = "$workspaceDir\scratch\isolation_test_app"

Write-Host "=== Starting Trackora Store Isolation Verification ===" -ForegroundColor Cyan

if (Test-Path $tempAppDir) {
    Remove-Item -Recurse -Force $tempAppDir
}

# Create a clean minimal Flutter project
& flutter create --org com.trackora.test --project-name isolation_test_app $tempAppDir | Out-Null

$results = @()

function Test-Configuration {
    param (
        [string]$ConfigName,
        [string[]]$Adapters
    )

    Write-Host "`nTesting Configuration: $ConfigName" -ForegroundColor Yellow

    $pubspecPath = "$tempAppDir\pubspec.yaml"
    
    $dependenciesBlock = @"
name: isolation_test_app
description: "Test app for store isolation"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
  trackora: ^0.1.0
"@

    foreach ($adapter in $Adapters) {
        $dependenciesBlock += "`n  ${adapter}: ^0.1.0"
    }

    $dependenciesBlock += @"

dependency_overrides:
  trackora:
    path: $workspaceDir\packages\trackora
"@

    foreach ($adapter in $Adapters) {
        $dependenciesBlock += "`n  ${adapter}:`n    path: $workspaceDir\packages\${adapter}"
    }

    $dependenciesBlock += @"

dev_dependencies:
  flutter_test:
    sdk: flutter
"@

    Set-Content -Path $pubspecPath -Value $dependenciesBlock

    # Run flutter pub get
    Push-Location $tempAppDir
    & flutter pub get | Out-Null
    Pop-Location

    # Inspect pubspec.lock
    $lockContent = Get-Content "$tempAppDir\pubspec.lock" -Raw

    # Inspect .flutter-plugins-dependencies
    $pluginsDepFile = "$tempAppDir\.flutter-plugins-dependencies"
    $pluginsContent = if (Test-Path $pluginsDepFile) { Get-Content $pluginsDepFile -Raw } else { "{}" }

    $allAdapters = @("trackora_google_play", "trackora_cafebazaar", "trackora_myket")
    $unexpectedFound = @()
    $expectedFound = @()

    foreach ($store in $allAdapters) {
        $inLock = $lockContent.Contains($store)
        $inPlugins = $pluginsContent.Contains($store)
        $shouldBePresent = $Adapters -contains $store

        if ($shouldBePresent) {
            if ($inLock -and $inPlugins) {
                $expectedFound += $store
            } else {
                $unexpectedFound += "MISSING_EXPECTED:$store"
            }
        } else {
            if ($inLock -or $inPlugins) {
                $unexpectedFound += "UNEXPECTED_PRESENT:$store"
            }
        }
    }

    $isIsolated = ($unexpectedFound.Count -eq 0)

    Write-Host "Expected present: $($Adapters -join ', ')" -ForegroundColor Gray
    $color = if ($isIsolated) { "Green" } else { "Red" }
    Write-Host "Unexpected violations: $($unexpectedFound.Count)" -ForegroundColor $color

    [PSCustomObject]@{
        Configuration = $ConfigName
        SelectedAdapters = ($Adapters -join ", ")
        ExpectedFound = ($expectedFound -join ", ")
        Violations = ($unexpectedFound -join ", ")
        Passed = $isIsolated
    }
}

$results += Test-Configuration -ConfigName "1. Core Only" -Adapters @()
$results += Test-Configuration -ConfigName "2. Google Play Only" -Adapters @("trackora_google_play")
$results += Test-Configuration -ConfigName "3. CafeBazaar Only" -Adapters @("trackora_cafebazaar")
$results += Test-Configuration -ConfigName "4. Myket Only" -Adapters @("trackora_myket")
$results += Test-Configuration -ConfigName "5. Multi-Store (All)" -Adapters @("trackora_google_play", "trackora_cafebazaar", "trackora_myket")

Write-Host "`n=== Final Isolation Verification Results ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Clean up temporary test app
if (Test-Path $tempAppDir) {
    Remove-Item -Recurse -Force $tempAppDir
}

if (($results | Where-Object { -not $_.Passed }).Count -gt 0) {
    Write-Error "Store isolation verification failed!"
    exit 1
} else {
    Write-Host "`nAll 5 store isolation configurations PASSED verification!" -ForegroundColor Green
}
