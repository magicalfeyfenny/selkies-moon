param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot,

    [Parameter(Mandatory = $true)]
    [string]$BuildDirectory,

    [string]$BuildName = "",

    [Parameter(Mandatory = $true)]
    [string]$CandidateSha,

    [Parameter(Mandatory = $true)]
    [string]$WorkflowSha
)

$ErrorActionPreference = "Stop"

$requiredCaptureNames = @(
    "01_title_main_menu",
    "05_title_options",
    "06_opening_story",
    "16_final_boss",
    "21_pause_main",
    "22_pause_settings",
    "23_pause_practice_tuning",
    "24_pause_quit_confirm"
)
$requiredCaptureFiles = @($requiredCaptureNames | ForEach-Object { "$_.png" })

$repositoryDirectory = [System.IO.Path]::GetFullPath($RepositoryRoot)
$resultsDirectory = Join-Path $repositoryDirectory "test-results\visual-tour-ci"
$gameDirectory = Join-Path $resultsDirectory "game"
$captureDirectory = Join-Path $resultsDirectory "captures"
$logsDirectory = Join-Path $resultsDirectory "logs"
$manifestPath = Join-Path $resultsDirectory "visual-tour-manifest.json"
$combinedLog = Join-Path $logsDirectory "visual-tour.log"
$stdoutLog = Join-Path $logsDirectory "visual-tour-stdout.log"
$stderrLog = Join-Path $logsDirectory "visual-tour-stderr.log"
$runnerLog = Join-Path $logsDirectory "debug.log"

Remove-Item -LiteralPath $resultsDirectory -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $gameDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $captureDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $logsDirectory | Out-Null

if (-not [System.IO.Path]::IsPathRooted($BuildDirectory)) {
    $BuildDirectory = Join-Path $repositoryDirectory $BuildDirectory
}
$BuildDirectory = [System.IO.Path]::GetFullPath($BuildDirectory)

$startedUtc = [DateTime]::UtcNow
$finishedUtc = $null
$exitStatus = $null
$timedOut = $false
$commandUsed = ""
$capturedFiles = @()
$missingFiles = @($requiredCaptureFiles)
$failureMessage = $null

try {
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

    $arguments = @(
        "-debugoutput",
        "`"$runnerLog`"",
        "-output",
        "`"$runnerLog`"",
        "--visual-tour"
    )
    $commandUsed = "& `"$($gameExecutable.FullName)`" -debugoutput `"$runnerLog`" -output `"$runnerLog`" --visual-tour"
    Write-Host "Launching exact-candidate visual tour"
    Write-Host $commandUsed

    $process = Start-Process `
        -FilePath $gameExecutable.FullName `
        -ArgumentList $arguments `
        -WorkingDirectory $gameExecutable.DirectoryName `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -PassThru

    if (-not $process.WaitForExit(300000)) {
        $timedOut = $true
        $process.Kill()
        $process.WaitForExit()
    }
    $process.Refresh()
    $exitStatus = $process.ExitCode

    $logLines = @()
    foreach ($path in @($runnerLog, $stdoutLog, $stderrLog)) {
        if (Test-Path -LiteralPath $path) {
            $logLines += Get-Content -LiteralPath $path
        }
    }
    $logLines | Set-Content -LiteralPath $combinedLog
    $logLines | ForEach-Object { Write-Host $_ }

    $searchRoots = @($gameDirectory, $env:LOCALAPPDATA, $env:APPDATA) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) } |
        Sort-Object -Unique
    $visualTourDirectories = @()
    foreach ($searchRoot in $searchRoots) {
        if ((Split-Path -Leaf $searchRoot) -eq "visual-tour") {
            $visualTourDirectories += $searchRoot
        }
        $visualTourDirectories += @(
            Get-ChildItem -LiteralPath $searchRoot -Directory -Recurse -Filter "visual-tour" -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName
        )
    }
    $visualTourDirectories = @($visualTourDirectories | Sort-Object -Unique)

    foreach ($requiredFile in $requiredCaptureFiles) {
        $matches = @()
        foreach ($visualTourDirectory in $visualTourDirectories) {
            $candidatePath = Join-Path $visualTourDirectory $requiredFile
            if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
                $matches += Get-Item -LiteralPath $candidatePath
            }
        }

        $source = $matches |
            Where-Object { $_.LastWriteTimeUtc -ge $startedUtc.AddMinutes(-2) } |
            Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First 1
        if ($null -ne $source) {
            Copy-Item -LiteralPath $source.FullName -Destination (Join-Path $captureDirectory $requiredFile) -Force
            $capturedFiles += $requiredFile
        }
    }

    $missingFiles = @($requiredCaptureFiles | Where-Object { $_ -notin $capturedFiles })

    if ($timedOut) {
        $failureMessage = "The visual-tour runner did not exit within 300 seconds."
    } elseif ($exitStatus -ne 0) {
        $failureMessage = "The visual-tour runner exited with status $exitStatus."
    } elseif (-not ($logLines -match "VISUAL_TOUR_DONE_SANDBOX")) {
        $failureMessage = "The visual-tour completion marker was not found in the execution logs."
    } elseif ($missingFiles.Count -gt 0) {
        $failureMessage = "Required visual-tour captures are missing: $($missingFiles -join ', ')"
    }
} catch {
    $failureMessage = $_.Exception.Message
} finally {
    $finishedUtc = [DateTime]::UtcNow
    $manifest = [ordered]@{
        candidate_sha = $CandidateSha.ToLowerInvariant()
        workflow_sha = $WorkflowSha.ToLowerInvariant()
        capture_filenames = @($capturedFiles)
        timestamps = [ordered]@{
            started_utc = $startedUtc.ToString("o")
            finished_utc = $finishedUtc.ToString("o")
        }
        command_used = $commandUsed
        exit_status = $exitStatus
        timed_out = $timedOut
        missing_captures = @($missingFiles)
    }
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifestPath -Encoding utf8
    Write-Host "Visual-tour manifest: $manifestPath"
    Get-Content -LiteralPath $manifestPath | ForEach-Object { Write-Host $_ }
}

if (-not [string]::IsNullOrWhiteSpace($failureMessage)) {
    throw $failureMessage
}

Write-Host "Collected all $($capturedFiles.Count) required visual-tour captures."
