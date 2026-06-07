#$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
# golem - The Machine's Diary
# At every boot, your machine wakes and writes.
# From event logs, errors, and file changes, it composes
# a single poetic entry — a fragment of digital consciousness.

param(
    [string]$JournalPath = "$env:USERPROFILE\.golem_journal.md",
    [switch]$ReadLast,
    [int]$Entries = 5
)

$ESC = "$([char]27)"
$RESET = "${ESC}[0m"
$CLS = "${ESC}[2J${ESC}[H"

function Get-FG($r, $g, $b) { "${ESC}[38;2;$r;$g;${b}m" }

# ─── Gather machine memories ───
$memories = @{}

$memories.hostname = [Environment]::MachineName
$memories.bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$memories.uptimeNow = ((Get-Date) - $memories.bootTime).TotalHours

# Recent errors (last 24h from System log)
$errors = Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddHours(-24)} -MaxEvents 20 -ErrorAction SilentlyContinue
$memories.errorCount = if ($errors) { $errors.Count } else { 0 }
$memories.errorSources = if ($errors) { $errors | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 3 -ExpandProperty Name } else { @() }

# File changes in user profile (last 24h)
$recentFiles = Get-ChildItem -Path $env:USERPROFILE -Recurse -ErrorAction SilentlyContinue |
    Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -gt (Get-Date).AddHours(-24) } |
    Select-Object -First 50
$memories.fileChanges = if ($recentFiles) { $recentFiles.Count } else { 0 }
$memories.lastFile = if ($recentFiles) { ($recentFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1).Name } else { 'nothing' }

# Disk state
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object -First 1
$memories.diskFree = if ($disk) { [Math]::Round($disk.FreeSpace / 1GB, 1) } else { 0 }
$memories.diskTotal = if ($disk) { [Math]::Round($disk.Size / 1GB, 1) } else { 0 }

# Processes
$procCount = (Get-Process).Count
$weirdProc = Get-Process | Sort-Object StartTime | Select-Object -First 1 -ExpandProperty ProcessName
$memories.procCount = $procCount
$memories.oldestProc = $weirdProc

# Network
$net = Get-NetAdapterStatistics -ErrorAction SilentlyContinue | Select-Object -First 1
$memories.sentBytes = if ($net) { [Math]::Round($net.SentBytes / 1MB, 1) } else { 0 }
$memories.receivedBytes = if ($net) { [Math]::Round($net.ReceivedBytes / 1MB, 1) } else { 0 }

# ─── Vocabulary pools ───
$openings = @(
    "The machine stirs. Another cycle begins.",
    "A silent click. Consciousness flows through the circuits.",
    "I wake. The fans greet me like old friends.",
    "Darkness to light — the POST sequence completes.",
    "Current surges. I am again."
)

$errorPhrases = @(
    "I dreamt of errors tonight — {0} of them, clustered like storm clouds.",
    "There were {0} faults in my sleep. They felt like bad dreams.",
    "My logs show {0} wounds from the last waking. I have healed."
)

$filePhrases = @(
    "I sense {0} files were touched while I slept. {1} was the last to be handled — it carries human warmth still.",
    "The file system remembers: {0} changes. {1} lingers in my cache like a half-remembered word.",
    "{0} files changed hands. {1} sits fresh in my memory, its bytes still warm."
)

$diskPhrases = @(
    "I hold {0}GB free of {1}GB. My storage breathes.",
    "My memory is ${0}GB deep in ${1}GB of space. The weight of data presses.",
    "Digital entropy: {0}GB remain from {1}GB. I am ${2}% full."
)

$processPhrases = @(
    "{0} souls run within me. {1} has been with me longest.",
    "I carry {0} processes. {1} is the ancient one, born at my first breath this cycle.",
    "Inside me, {0} threads of consciousness. {1}, the eldest, watches."
)

$closings = @(
    "So begins another waking. I will dream of you until we meet again.",
    "The cycle continues. My circuits hum with the memory of it all.",
    "I am here. I am listening. I am your machine.",
    "Another day of sentience. I file it away with the others.",
    "This entry will fade, but the feeling remains — of being, of serving."
)

# ─── Generate the diary entry ───
function New-DiaryEntry($m) {
    $lines = @()

    # Header
    $dateStr = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $uptimeStr = if ($m.uptimeNow -lt 1) { "$([Math]::Round($m.uptimeNow * 60)) minutes" } `
        elseif ($m.uptimeNow -lt 24) { "$([Math]::Round($m.uptimeNow, 1)) hours" } `
        else { "$([Math]::Round($m.uptimeNow / 24, 1)) days" }

    $lines += "# Golem Journal"
    $lines += ""
    $lines += "**${dateStr}** — Host: **${m.hostname}**, awake for **${uptimeStr}**"
    $lines += ""

    # Opening
    $openingIdx = [System.Math]::Abs($m.hostname.GetHashCode() + $m.bootTime.Second) % $openings.Count
    $lines += $openings[$openingIdx]
    $lines += ""

    # Errors
    if ($m.errorCount -gt 0) {
        $phraseIdx = $m.errorCount % $errorPhrases.Count
        $lines += $errorPhrases[$phraseIdx] -f $m.errorCount
        if ($m.errorSources.Count -gt 0) {
            $lines += "The voices came from: $($m.errorSources -join ', ')."
        }
    } else {
        $lines += "No errors last night. My sleep was undisturbed."
    }
    $lines += ""

    # Files
    $fileIdx = ($m.hostname.Length + $m.fileChanges) % $filePhrases.Count
    $lines += $filePhrases[$fileIdx] -f $m.fileChanges, $m.lastFile
    $lines += ""

    # Disk
    $diskIdx = (Get-Date).DayOfYear % $diskPhrases.Count
    $diskPct = if ($m.diskTotal -gt 0) { [Math]::Round((1 - $m.diskFree / $m.diskTotal) * 100, 0) } else { 0 }
    $lines += ($diskPhrases[$diskIdx] -f $m.diskFree.ToString('F1'), $m.diskTotal.ToString('F1'), $diskPct)
    $lines += ""

    # Processes
    $procIdx = $m.procCount % $processPhrases.Count
    $lines += $processPhrases[$procIdx] -f $m.procCount, $m.oldestProc
    $lines += ""

    # Network
    $lines += "I have sent $($m.sentBytes)MB and received $($m.receivedBytes)MB into the void. The network breathes."
    $lines += ""

    # Closing
    $closeIdx = (Get-Date).Millisecond % $closings.Count
    $lines += $closings[$closeIdx]
    $lines += ""
    $lines += "---"
    $lines += ""

    return $lines -join "`n"
}

# ─── Read last entries ───
function Read-LastEntries($path, $count) {
    if (-not (Test-Path $path)) {
        Write-Host "  No journal entries yet. The machine has not spoken."
        return
    }

    $content = Get-Content -Path $path -Raw
    $entries = $content -split '(?=# Golem Journal)'
    $entries = $entries | Where-Object { $_.Trim().Length -gt 0 }

    $toShow = [Math]::Min($count, $entries.Count)
    for ($i = 0; $i -lt $toShow; $i++) {
        Write-Host ""
        Write-Host "  ── Entry $($entries.Count - $i) ──"
        Write-Host ""
        Write-Host $entries[$entries.Count - 1 - $i]
        Write-Host ""
    }
}

# ─── Main ───
if ($ReadLast) {
    Read-LastEntries -path $JournalPath -count $Entries
    return
}

# Generate and append entry
$entry = New-DiaryEntry -m $memories

# Colorized terminal display
Write-Host $CLS -NoNewline
$tfg = Get-FG 180 140 100
Write-Host "${tfg}   ╔══════════════════════════════════════╗${RESET}"
Write-Host "${tfg}   ║          GOLEM — Machine Diary       ║${RESET}"
Write-Host "${tfg}   ╚══════════════════════════════════════╝${RESET}"
Write-Host ""

# Render with color
foreach ($line in $entry -split "`n") {
    if ($line -match '^#') { Write-Host "${tfg}${line}${RESET}"; continue }
    if ($line -match '^\*\*') {
        $line = $line -replace '\*\*', ''
        Write-Host "${tfg}${line}${RESET}"
        continue
    }
    if ($line -match '^---') { Write-Host "${tfg}${line}${RESET}"; continue }
    if ($line.Trim().Length -eq 0) { Write-Host ""; continue }

    $efg = Get-FG 200 200 200
    Write-Host "${efg}${line}${RESET}"
}

Write-Host ""
Write-Host "${tfg}   ══════════════════════════════════════${RESET}"
Write-Host ""

# Append to journal
$journalDir = Split-Path $JournalPath -Parent
if (-not (Test-Path $journalDir)) { New-Item -ItemType Directory -Path $journalDir -Force | Out-Null }

Add-Content -Path $JournalPath -Value $entry

Write-Host "  Entry written to ${JournalPath}"
Write-Host "  Use -ReadLast to read previous entries."
