#Requires -Version 5.1
<#
Pipeline complet : YAML Spriggit -> ESP, compilation Papyrus, deploiement vers un mod MO2 dedie
pour les tests en jeu (VelynTheNetch-dev). A relancer a chaque modification du YAML ou des scripts.
#>
param(
    [switch]$SkipDeserialize,
    [switch]$SkipCompile,
    [switch]$SkipDeploy
)

$ErrorActionPreference = "Stop"
$ProjectRoot   = $PSScriptRoot
$GameDir       = "E:\SteamLibrary\steamapps\common\Skyrim Special Edition"
$MO2Instance   = "C:\Users\Kevin\AppData\Local\ModOrganizer\Skyrim SE MODS"
$DevModName    = "VelynTheNetch-dev"

$SpriggitExe   = Join-Path $ProjectRoot "tools\spriggit\CLI\Spriggit.CLI.exe"
$SdkDir        = Join-Path $ProjectRoot "tools\dotnet-sdk"
$YamlDir       = Join-Path $ProjectRoot "Spriggit\VelynTheNetch.esp"
$DistDir       = Join-Path $ProjectRoot "dist"
$DistEsp       = Join-Path $DistDir "VelynTheNetch.esp"
$ScriptsSrc    = Join-Path $ProjectRoot "Scripts\Source"
$DistPex       = Join-Path $DistDir "Scripts"

$PapyrusCompiler = Join-Path $GameDir "Papyrus Compiler\PapyrusCompiler.exe"
$FlagsFile       = Join-Path $GameDir "Data\Source\Scripts\TESV_Papyrus_Flags.flg"
$ImportVanilla   = Join-Path $GameDir "Data\Scripts\Source"
$ImportPo3       = Join-Path $MO2Instance "mods\powerofthree's Papyrus Extender\Source\scripts"
# JsonUtil (liste blanche/noire de filtres, extension 2026-07-23bis) : IMPORT SEULEMENT pour compiler.
# PapyrusUtil reste une dependance OPTIONNELLE cote joueur (la fonctionnalite reste inerte sans elle),
# mais Papyrus doit resoudre JsonUtil.psc a la compilation quoi qu'il arrive.
$ImportPapyrusUtil = Join-Path $MO2Instance "mods\PapyrusUtil SE - Modders Scripting Utility Functions\Scripts\Source"
$ImportMcmSdk    = Join-Path $ProjectRoot "tools\mcm-sdk"
# Piggyback est un projet autonome voisin (mymods\Piggyback) : on importe son API Papyrus pour que les
# scripts de Velyn compilent contre Piggyback.Attach/Detach. C'est un IMPORT seulement - le .pex est
# compile et livre par le projet Piggyback lui-meme (mod MO2 separe, composant optionnel).
$ImportPiggyback = Join-Path (Split-Path $ProjectRoot -Parent) "Piggyback\Scripts\Source"

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Fail($msg) { Write-Host "ECHEC: $msg" -ForegroundColor Red; exit 1 }

# Spriggit.CLI.exe delegue la conversion a un outil dotnet (Spriggit.Yaml.Skyrim) installe a la
# volee via "dotnet tool install", qui exige le SDK .NET (pas seulement le runtime). On pointe donc
# le SDK local au projet (tools\dotnet-sdk) pour cet appel uniquement, sans toucher au PATH systeme.
if (-not $SkipDeserialize) {
    Write-Step "Spriggit : YAML -> ESP"
    if (-not (Test-Path $SdkDir)) { Fail "SDK .NET local introuvable : $SdkDir" }
    $env:PATH = "$SdkDir;$env:PATH"
    $env:DOTNET_ROOT = $SdkDir

    New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
    if (Test-Path $DistEsp) { Remove-Item $DistEsp }
    & $SpriggitExe deserialize -i "$YamlDir" -o "$DistEsp"
    if ($LASTEXITCODE -ne 0) { Fail "Spriggit deserialize a echoue (code $LASTEXITCODE)" }
    if (-not (Test-Path $DistEsp)) { Fail "ESP non genere : $DistEsp" }
    Write-Host "OK : $DistEsp ($((Get-Item $DistEsp).Length) octets)"
}

# MO2 redirige parfois "Papyrus Compiler" vers son dossier virtuel Overwrite\Root (observe apres
# des sessions Creation Kit lancees via MO2), ce qui le fait "disparaitre" du vrai dossier du jeu.
# On le restaure automatiquement si besoin avant de compiler.
function Restore-PapyrusCompilerFromOverwrite {
    if (Test-Path $PapyrusCompiler) { return }
    $overwriteSrc = Join-Path $MO2Instance "overwrite\Root\Papyrus Compiler"
    if (Test-Path $overwriteSrc) {
        Write-Host "Papyrus Compiler manquant, restauration depuis Overwrite..." -ForegroundColor Yellow
        $dst = Join-Path $GameDir "Papyrus Compiler"
        New-Item -ItemType Directory -Force -Path $dst | Out-Null
        Copy-Item -Path (Join-Path $overwriteSrc "*") -Destination $dst -Force
    }
}

if (-not $SkipCompile) {
    Write-Step "Compilation Papyrus"
    Restore-PapyrusCompilerFromOverwrite
    $pscFiles = Get-ChildItem $ScriptsSrc -Filter "*.psc" -ErrorAction SilentlyContinue
    if (-not $pscFiles -or $pscFiles.Count -eq 0) {
        Write-Host "Aucun script .psc dans $ScriptsSrc pour l'instant, etape ignoree."
    } else {
        foreach ($p in @($PapyrusCompiler, $FlagsFile, $ImportVanilla, $ImportPo3, $ImportMcmSdk, $ImportPiggyback, $ImportPapyrusUtil)) {
            if (-not (Test-Path $p)) { Fail "Chemin requis introuvable : $p" }
        }
        New-Item -ItemType Directory -Force -Path $DistPex | Out-Null
        $imports = "$ImportVanilla;$ImportPo3;$ImportMcmSdk;$ImportPiggyback;$ImportPapyrusUtil;$ScriptsSrc"
        & $PapyrusCompiler $ScriptsSrc -all -output="$DistPex" -import="$imports" -flags="$FlagsFile"
        if ($LASTEXITCODE -ne 0) { Fail "PapyrusCompiler a echoue (code $LASTEXITCODE)" }
        Write-Host "OK : $($pscFiles.Count) script(s) compile(s) dans $DistPex"
    }
}

if (-not $SkipDeploy) {
    Write-Step "Deploiement vers le mod MO2 '$DevModName'"
    $devModDir = Join-Path $MO2Instance "mods\$DevModName"
    New-Item -ItemType Directory -Force -Path $devModDir | Out-Null
    Copy-Item -Path (Join-Path $DistDir "*") -Destination $devModDir -Recurse -Force

    # Fichiers non generes, ecrits a la main : menu MCM et traductions. Ils vivent a la racine du
    # projet (pas dans dist\) mais doivent accompagner l'ESP dans le mod.
    foreach ($extra in @("MCM", "Interface")) {
        $extraPath = Join-Path $ProjectRoot $extra
        if (Test-Path $extraPath) {
            Copy-Item -Path $extraPath -Destination $devModDir -Recurse -Force
            Write-Host "OK : $extra\ copie"
        }
    }
    Write-Host "OK : copie dans $devModDir"
    Write-Host "Pensez a activer '$DevModName' dans la liste des mods MO2 si ce n'est pas deja fait."
}

Write-Step "Termine"
