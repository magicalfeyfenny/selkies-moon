param(
    [Parameter(Mandatory = $true)]
    [string]$BuildDirectory,

    [string]$BuildName = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$resultsDirectory = Join-Path $repoRoot "test-results"
$gameDirectory = Join-Path $resultsDirectory "github-actions-game"
$combinedLog = Join-Path $resultsDirectory "github-actions-gmtl.log"
$stdoutLog = Join-Path $resultsDirectory "github-actions-gmtl-stdout.log"
$stderrLog = Join-Path $resultsDirectory "github-actions-gmtl-stderr.log"
$runnerLog = Join-Path $gameDirectory "debug.log"

New-Item -ItemType Directory -Force -Path $resultsDirectory | Out-Null
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $gameDirectory
New-Item -ItemType Directory -Force -Path $gameDirectory | Out-Null
Remove-Item -Force -ErrorAction SilentlyContinue $combinedLog, $stdoutLog, $stderrLog

if (-not [System.IO.Path]::IsPathRooted($BuildDirectory)) {
    $BuildDirectory = Join-Path $repoRoot $BuildDirectory
}
$BuildDirectory = [System.IO.Path]::GetFullPath($BuildDirectory)

if (-not (Test-Path -LiteralPath $BuildDirectory)) {
    throw "GameMaker build directory does not exist: $BuildDirectory"
}

$archive = $null
if (-not [string]::IsNullOrWhiteSpace($BuildName)) {
    $namedArtifact = $BuildName
    if (-not [System.IO.Path]::IsPathRooted($namedArtifact)) {
        $namedArtifact = Join-Path $BuildDirectory $namedArtifact
    }

    if ((Test-Path -LiteralPath $namedArtifact -PathType Leaf) -and
        [System.IO.Path]::GetExtension($namedArtifact) -eq ".zip") {
        $archive = Get-Item -LiteralPath $namedArtifact
    }
}

if ($null -eq $archive) {
    $archive = Get-ChildItem -LiteralPath $BuildDirectory -Recurse -File -Filter "*.zip" |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1
}

if ($null -ne $archive) {
    Write-Host "Expanding GameMaker build $($archive.FullName)"
    Expand-Archive -LiteralPath $archive.FullName -DestinationPath $gameDirectory -Force
} else {
    Write-Host "No ZIP artifact found; using unpacked build output from $BuildDirectory"
    Get-ChildItem -LiteralPath $BuildDirectory -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $gameDirectory -Recurse -Force
    }
}

$gameExecutable = Get-ChildItem -LiteralPath $gameDirectory -Recurse -File -Filter "*.exe" |
    Where-Object { $_.Name -notmatch "(?i)(setup|unins|uninstall)" } |
    Sort-Object Length -Descending |
    Select-Object -First 1

if ($null -eq $gameExecutable) {
    throw "No runnable game executable was found under $gameDirectory"
}

Write-Host "Launching $($gameExecutable.FullName) in GMTL test mode"
$arguments = @(
    "-debugoutput",
    "`"$runnerLog`"",
    "-output",
    "`"$runnerLog`"",
    "--run-test"
)

$process = Start-Process `
    -FilePath $gameExecutable.FullName `
    -ArgumentList $arguments `
    -WorkingDirectory $gameExecutable.DirectoryName `
    -RedirectStandardOutput $stdoutLog `
    -RedirectStandardError $stderrLog `
    -PassThru

if (-not $process.WaitForExit(180000)) {
    $process.Kill()
    throw "The GMTL runner did not exit within 180 seconds."
}
$process.Refresh()
$exitCode = $process.ExitCode

$logLines = @()
foreach ($path in @($runnerLog, $stdoutLog, $stderrLog)) {
    if (Test-Path -LiteralPath $path) {
        $logLines += Get-Content -LiteralPath $path
    }
}

$logLines | Set-Content -LiteralPath $combinedLog
$logLines | ForEach-Object { Write-Host $_ }

$suiteSummaries = @($logLines | Where-Object { $_ -match "Test Suites:" })
$testSummaries = @($logLines | Where-Object { $_ -match "Tests:" })

if ($suiteSummaries.Count -eq 0 -or $testSummaries.Count -eq 0) {
    throw "GMTL summary lines were not found. See $combinedLog"
}

$suiteSummary = $suiteSummaries[-1]
$testSummary = $testSummaries[-1]
Write-Host $suiteSummary
Write-Host $testSummary

if ($testSummary -match "\b0 total\b") {
    throw "GMTL reported zero tests."
}

if ($suiteSummary -match "\bfailed\b" -or $testSummary -match "\bfailed\b") {
    throw "GMTL reported failing tests."
}

if ($exitCode -ne 0) {
    throw "The GameMaker test runner exited with status $exitCode."
}

if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
    @(
        "## GameMaker unit tests",
        "",
        "- $suiteSummary",
        "- $testSummary"
    ) | Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY
}
