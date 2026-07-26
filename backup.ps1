#Requires -Version 5.1
<#
Sauvegarde manuelle du projet (pas de git ici, sur demande de Kevin). Copie horodatee de tout ce qui
est source ecrit a la main : Spriggit\ (YAML), Scripts\Source\ (Papyrus), docs\ (journal/plan local).
Ne copie PAS dist\ (regenerable via build.ps1) ni tools\ (outillage tiers/gros).
A lancer avant toute operation risquee (renommage/suppression de records, restructuration) et apres
tout build confirme bon.
#>
param(
    [string]$Label = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$Timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$BackupName = if ($Label) { "$Timestamp`_$Label" } else { $Timestamp }
$BackupDir = Join-Path $ProjectRoot "backups\$BackupName"

New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
foreach ($src in @("Spriggit", "Scripts", "docs")) {
    $srcPath = Join-Path $ProjectRoot $src
    if (Test-Path $srcPath) {
        Copy-Item -Path $srcPath -Destination (Join-Path $BackupDir $src) -Recurse -Force
    }
}

Write-Host "OK : sauvegarde dans $BackupDir"
