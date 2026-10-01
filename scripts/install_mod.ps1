# Link this repo into Noita's mods folder (Windows junction — no duplicate copy).
# Run from PowerShell:
#   .\scripts\install_mod.ps1 -NoitaRoot "C:\Program Files (x86)\Steam\steamapps\common\Noita"

param(
    [Parameter(Mandatory = $false)]
    [string]$NoitaRoot = ""
)

$ErrorActionPreference = "Stop"

function Find-NoitaRoots {
    $roots = @()
    $candidates = @(
        "${env:ProgramFiles(x86)}\Steam\steamapps\common\Noita",
        "$env:ProgramFiles\Steam\steamapps\common\Noita"
    )
    foreach ($c in $candidates) { if ($c) { $roots += $c } }

    $vdf = "${env:ProgramFiles(x86)}\Steam\steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        $text = Get-Content $vdf -Raw
        foreach ($m in [regex]::Matches($text, '"path"\s+"((?:\\.|[^"\\])*)"')) {
            $lib = $m.Groups[1].Value -replace '\\\\', '\'
            if ($lib.Length -gt 3) {
                $roots += Join-Path $lib "steamapps\common\Noita"
            }
        }
    }

    $found = @()
    foreach ($r in ($roots | Select-Object -Unique)) {
        if (Test-Path (Join-Path $r "Noita.exe")) { $found += $r }
    }
    return $found
}

if (-not $NoitaRoot) {
    $auto = Find-NoitaRoots
    if ($auto.Count -eq 1) {
        $NoitaRoot = $auto[0]
        Write-Host "Auto-detected Noita: $NoitaRoot"
    } elseif ($auto.Count -gt 1) {
        Write-Host "Multiple Noita installs found:"
        for ($i = 0; $i -lt $auto.Count; $i++) { Write-Host "  [$i] $($auto[$i])" }
        Write-Error "Re-run with: .\scripts\install_mod.ps1 -NoitaRoot `"PATH_FROM_LIST`""
    } else {
        Write-Error @"
Noita.exe not found on this PC under any Steam library.

1. Install Noita from Steam (Library → Noita → Install), then run this script again.
2. Or: Steam → Noita → Manage → Browse local files — copy that folder path and run:
   .\scripts\install_mod.ps1 -NoitaRoot "FULL_PATH_TO_FOLDER_CONTAINING_Noita.exe"
"@
    }
}

$NoitaRoot = $NoitaRoot.TrimEnd('\')
$NoitaExe = Join-Path $NoitaRoot "Noita.exe"
if (-not (Test-Path $NoitaExe)) {
    Write-Error "Noita.exe not found at: $NoitaExe`nUse Steam → Noita → Manage → Browse local files for the correct folder."
}

$ModsDir = Join-Path $NoitaRoot "mods"
$Target  = Join-Path $ModsDir "noitarl"
$Source  = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if (-not (Test-Path $ModsDir)) {
    New-Item -ItemType Directory -Path $ModsDir | Out-Null
}

if (Test-Path $Target) {
    $item = Get-Item $Target
    if ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink") {
        Write-Host "Mod junction already exists: $Target"
    } else {
        Write-Error "mods\noitarl already exists and is not a junction. Remove or rename it first."
    }
} else {
    cmd /c mklink /J "$Target" "$Source" | Out-Null
    Write-Host "Created junction:`n  $Target`n  -> $Source"
}

Write-Host "`nNext steps:"
Write-Host "  1. cd $Source"
Write-Host "  2. python -m pip install -r requirements.txt"
Write-Host "  3. python wait_for_noita.py"
Write-Host "  4. Launch Noita → Mods → enable 'RL Agent MVP' (folder noitarl)"
Write-Host "  5. When wait_for_noita says OK, run: python train.py --fresh"
