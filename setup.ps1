$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

trap {
    Write-Host "Chyba: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMddHHmmss'
$configRoot = Join-Path $env:USERPROFILE '.config'
$ompDir = Join-Path $configRoot 'oh-my-posh'
$ffDir = Join-Path $configRoot 'fastfetch'
$fontFamily = 'JetBrainsMono Nerd Font Mono'
$fontZipUrl = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip'

function Step($m) { Write-Host "-> $m" -ForegroundColor Cyan }
function Ok($m) { Write-Host "   $m" -ForegroundColor Green }
function Test-Cmd($n) { [bool](Get-Command $n -ErrorAction SilentlyContinue) }

function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

function Install-WingetPackage($id) {
    & winget.exe install --id $id --exact --source winget --silent --accept-package-agreements --accept-source-agreements
    Update-SessionPath
}

function Backup-File($p) {
    if (Test-Path $p) { Copy-Item $p "$p.$stamp.bak" -Force }
}

function Read-Text($p) { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) }
function Write-Text($p, $t) { [System.IO.File]::WriteAllText($p, $t, $utf8) }

Step 'Kontrola souboru vedle skriptu'
foreach ($f in 'settings.json', 'config.json', 'config.jsonc', 'Microsoft.PowerShell_profile.ps1') {
    if (-not (Test-Path (Join-Path $root $f))) { throw "Chybi soubor $f ve slozce skriptu." }
}
Ok 'Vse na miste'

Step 'Winget'
Update-SessionPath
if (-not (Test-Cmd winget.exe)) {
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope CurrentUser | Out-Null
    Repair-WinGetPackageManager -Latest -Force
    Update-SessionPath
    if (-not (Test-Cmd winget.exe)) { throw 'Winget se nepodarilo nainstalovat.' }
}
Ok 'Winget je pripraven'

Step 'PowerShell 7'
if (-not (Test-Cmd pwsh.exe)) { Install-WingetPackage 'Microsoft.PowerShell' }
$pwsh = (Get-Command pwsh.exe -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $pwsh) {
    $candidate = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
    if (Test-Path $candidate) { $pwsh = $candidate }
}
if (-not $pwsh) { throw 'PowerShell 7 se nepodarilo nainstalovat.' }
Ok $pwsh

Step 'Windows Terminal'
if (-not (Test-Cmd wt.exe)) { Install-WingetPackage 'Microsoft.WindowsTerminal' }
Ok 'Hotovo'

Step 'Oh My Posh'
if (-not (Test-Cmd oh-my-posh)) { Install-WingetPackage 'JanDeDobbeleer.OhMyPosh' }
if (-not (Test-Cmd oh-my-posh)) { throw 'Oh My Posh se nepodarilo nainstalovat.' }
Ok 'Hotovo'

Step 'Fastfetch'
if (-not (Test-Cmd fastfetch)) { Install-WingetPackage 'Fastfetch-cli.Fastfetch' }
Ok 'Hotovo'

Step 'Font JetBrainsMono Nerd Font'
$fontsDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$fontFile = 'JetBrainsMonoNerdFontMono-Regular.ttf'
$fontPresent = (Test-Path (Join-Path $fontsDir $fontFile)) -or (Test-Path (Join-Path $env:WINDIR "Fonts\$fontFile"))
if ($fontPresent) {
    Ok 'Font uz je nainstalovan'
}
else {
    $tmp = Join-Path $env:TEMP "jbmnf_$stamp"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $zip = Join-Path $tmp 'JetBrainsMono.zip'
    $localZip = Join-Path $root 'JetBrainsMono.zip'
    if (Test-Path $localZip) {
        Copy-Item $localZip $zip -Force
    }
    else {
        Invoke-WebRequest -UseBasicParsing -Uri $fontZipUrl -OutFile $zip
    }
    $extract = Join-Path $tmp 'x'
    Expand-Archive -Path $zip -DestinationPath $extract -Force
    New-Item -ItemType Directory -Path $fontsDir -Force | Out-Null
    $reg = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    $count = 0
    Get-ChildItem -Path $extract -Filter 'JetBrainsMonoNerdFontMono-*.ttf' -Recurse | ForEach-Object {
        $dest = Join-Path $fontsDir $_.Name
        if (-not (Test-Path $dest)) { Copy-Item $_.FullName $dest -Force }
        New-ItemProperty -Path $reg -Name "$($_.BaseName) (TrueType)" -Value $dest -PropertyType String -Force | Out-Null
        $count++
    }
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    if ($count -eq 0) { throw 'V archivu fontu nebyly nalezeny soubory JetBrainsMonoNerdFontMono.' }
    Ok "Zpracovano souboru: $count"
}

Step 'Terminal-Icons'
$tiScript = Join-Path $env:TEMP "ti_$stamp.ps1"
Set-Content -Path $tiScript -Encoding UTF8 -Value @'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if (Get-Module -ListAvailable -Name Terminal-Icons) { exit 0 }
try {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
}
catch {}
try {
    Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force -AllowClobber -AcceptLicense
}
catch {
    Write-Host "Install-Module selhal: $($_.Exception.Message)"
    Install-PSResource -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -TrustRepository -Reinstall
}
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) { exit 1 }
'@
& $pwsh -NoProfile -ExecutionPolicy Bypass -File $tiScript
$tiExit = $LASTEXITCODE
Remove-Item $tiScript -Force -ErrorAction SilentlyContinue
if ($tiExit -eq 0) {
    Ok 'Terminal-Icons je nainstalovan'
}
else {
    Write-Host '   Terminal-Icons se nepodarilo nainstalovat. Zkus rucne v pwsh: Install-Module Terminal-Icons -Scope CurrentUser -Force' -ForegroundColor Yellow
}

Step 'Execution policy'
$policy = (& $pwsh -NoProfile -Command 'Get-ExecutionPolicy' | Select-Object -First 1)
if ($policy -in 'Restricted', 'AllSigned') {
    & $pwsh -NoProfile -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force"
    Ok 'Nastaveno RemoteSigned pro aktualniho uzivatele'
}
else {
    Ok "Ponechano: $policy"
}

Step 'Slozky v .config'
foreach ($d in $configRoot, $ompDir, $ffDir) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}
Ok $configRoot

Step 'Oh My Posh konfigurace'
Copy-Item (Join-Path $root 'config.json') (Join-Path $ompDir 'config.json') -Force
Unblock-File (Join-Path $ompDir 'config.json')
Ok (Join-Path $ompDir 'config.json')

Step 'Fastfetch konfigurace'
$ffText = Read-Text (Join-Path $root 'config.jsonc')
$ascii = Join-Path $root 'ascii.txt'
if (Test-Path $ascii) {
    Copy-Item $ascii (Join-Path $ffDir 'ascii.txt') -Force
    $asciiPath = (Join-Path $ffDir 'ascii.txt') -replace '\\', '/'
    $ffText = $ffText -replace '("source"\s*:\s*")[^"]*(")', "`${1}$asciiPath`${2}"
}
else {
    $ffText = $ffText -replace '"type"\s*:\s*"file"\s*,\s*"source"\s*:\s*"[^"]*"\s*,', '"type": "auto",'
    Write-Host '   ascii.txt nenalezen, pouzije se vestavene logo' -ForegroundColor Yellow
}
Write-Text (Join-Path $ffDir 'config.jsonc') $ffText
Ok (Join-Path $ffDir 'config.jsonc')

Step 'Nastaveni Windows Terminal'
$tsText = Read-Text (Join-Path $root 'settings.json')
$pwshJson = $pwsh.Replace('\', '\\')
$tsText = $tsText -replace '("commandline"\s*:\s*")[^"]*pwsh\.exe(")', ('${1}' + $pwshJson + '${2}')
$icon = Join-Path $root 'powershell-black.png'
if (Test-Path $icon) {
    Copy-Item $icon (Join-Path $configRoot 'powershell-black.png') -Force
    $iconJson = (Join-Path $configRoot 'powershell-black.png').Replace('\', '\\')
    $tsText = $tsText -replace '("icon"\s*:\s*")[^"]*(")', ('${1}' + $iconJson + '${2}')
}
else {
    $tsText = $tsText -replace '[ \t]*"icon"[ \t]*:[ \t]*"[^"]*",[ \t]*\r?\r\n', ''
}
$targets = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal')
)
$existing = @($targets | Where-Object { Test-Path $_ })
if ($existing.Count -eq 0 -and (Test-Cmd wt.exe)) {
    New-Item -ItemType Directory -Path $targets[0] -Force | Out-Null
    $existing = @($targets[0])
}
if ($existing.Count -eq 0) {
    Write-Host '   Slozka Windows Terminal nenalezena, settings.json preskocen. Spust Windows Terminal jednou a skript zopakuj.' -ForegroundColor Yellow
}
foreach ($dir in $existing) {
    $target = Join-Path $dir 'settings.json'
    Backup-File $target
    Write-Text $target $tsText
    Ok $target
}

Step 'PowerShell profil'
$profilePath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
New-Item -ItemType Directory -Path (Split-Path $profilePath) -Force | Out-Null
Backup-File $profilePath
Copy-Item (Join-Path $root 'Microsoft.PowerShell_profile.ps1') $profilePath -Force
Unblock-File $profilePath
Ok $profilePath

Write-Host ''
Write-Host 'Hotovo. Zavri vsechna okna Windows Terminal a otevri ho znovu.' -ForegroundColor Green