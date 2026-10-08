# Windows Terminal Setup

Jeden skript, který na čistém Windows nainstaluje a nakonfiguruje kompletní terminálové prostředí: Windows Terminal, PowerShell 7, Oh My Posh, Fastfetch, JetBrainsMono Nerd Font a modul Terminal-Icons. Konfigurace je v repozitáři, takže nový počítač je hotový během jednoho spuštění.

## Obsah

- [Co skript dělá](#co-skript-dělá)
- [Požadavky](#požadavky)
- [Struktura repozitáře](#struktura-repozitáře)
- [Instalace](#instalace)
- [Vzhled a stylování](#vzhled-a-stylování)
- [Co se kam nainstaluje](#co-se-kam-nainstaluje)
- [Zálohy a bezpečnost](#zálohy-a-bezpečnost)
- [Přizpůsobení](#přizpůsobení)
- [Řešení problémů](#řešení-problémů)

## Co skript dělá

`setup.ps1` běží sekvenčně a každý krok je idempotentní, takže ho lze bezpečně spouštět opakovaně. Už nainstalované komponenty přeskakuje.

1. Zkontroluje, že vedle skriptu leží všechny potřebné konfigurační soubory.
2. Ověří dostupnost `winget`, případně ho doinstaluje přes modul `Microsoft.WinGet.Client`.
3. Nainstaluje přes winget: PowerShell 7 (`Microsoft.PowerShell`), Windows Terminal (`Microsoft.WindowsTerminal`), Oh My Posh (`JanDeDobbeleer.OhMyPosh`), Fastfetch (`Fastfetch-cli.Fastfetch`).
4. Nainstaluje font JetBrainsMono Nerd Font Mono do uživatelského profilu a zaregistruje ho v registrech (bez nutnosti administrátorských práv). Použije lokální `JetBrainsMono.zip`, pokud leží vedle skriptu, jinak stáhne nejnovější release z projektu Nerd Fonts.
5. Nainstaluje modul Terminal-Icons v samostatném procesu `pwsh` (s fallbackem na `Install-PSResource`).
6. Pokud je execution policy `Restricted` nebo `AllSigned`, nastaví pro aktuálního uživatele `RemoteSigned`. Jinak ji nechá beze změny.
7. Vytvoří složky `~/.config/oh-my-posh` a `~/.config/fastfetch` a nakopíruje do nich konfigurace.
8. Upraví a nasadí `settings.json` pro Windows Terminal: dosadí skutečnou cestu k `pwsh.exe` a cestu k ikoně profilu (pokud existuje `powershell-black.png`, jinak řádek s ikonou odstraní).
9. Nasadí PowerShell profil, který při každém startu inicializuje Oh My Posh a spustí Fastfetch.

## Požadavky

- Windows 10 nebo 11
- Připojení k internetu (winget, PowerShell Gallery, GitHub)
- Windows PowerShell 5.1 nebo PowerShell 7 pro spuštění samotného skriptu
- Administrátorská práva nejsou nutná, font i moduly se instalují do uživatelského profilu. Instalace některých winget balíčků může vyvolat UAC dotaz.

## Struktura repozitáře

| Soubor | Účel |
|---|---|
| `setup.ps1` | Hlavní instalační skript |
| `settings.json` | Konfigurace Windows Terminal (profily, barevná schémata, písmo, zkratky) |
| `config.json` | Téma Oh My Posh |
| `config.jsonc` | Konfigurace Fastfetch |
| `Microsoft.PowerShell_profile.ps1` | PowerShell profil načítaný při startu `pwsh` |
| `ascii.txt` (volitelný) | Vlastní ASCII logo pro Fastfetch |
| `powershell-black.png` (volitelný) | Ikona profilu PowerShell v Windows Terminal |
| `JetBrainsMono.zip` (volitelný) | Lokální kopie fontu pro offline instalaci |

Soubor profilu se musí jmenovat přesně `Microsoft.PowerShell_profile.ps1` (s tečkou za `Microsoft`), jinak skript skončí chybou o chybějícím souboru.

## Instalace

```powershell
git clone https://github.com/UZIVATEL/REPOZITAR.git
cd REPOZITAR
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

Po dokončení zavři všechna okna Windows Terminal a otevři je znovu. Pokud skript hlásí, že složka Windows Terminal nebyla nalezena, spusť terminál jednou a skript zopakuj.

Volitelné soubory (`ascii.txt`, `powershell-black.png`, `JetBrainsMono.zip`) stačí položit vedle `setup.ps1`. Skript je automaticky použije. Bez nich se použije vestavěné logo Fastfetch, profil bez ikony a font se stáhne z internetu.

## Vzhled a stylování

### Windows Terminal

- Barevné schéma Catppuccin Mocha jako výchozí, v souboru jsou navíc schémata Dracula a Color Scheme 15
- Písmo JetBrainsMono Nerd Font Mono, velikost 13, tloušťka `extra-black`, výška buňky 1.2, vestavěné glyfy a barevné glyfy zapnuté
- Průhlednost: výchozí `opacity` 80, hlavní profil PowerShell 50, s efektem akrylu (`useAcrylic`, `useAcrylicInTabRow`)
- Kurzor `filledBox`, padding 8, `intenseTextStyle: all`
- Výchozí profil: PowerShell 7 (cesta k `pwsh.exe` se při instalaci dosadí automaticky)

### Klávesové zkratky

| Zkratka | Akce |
|---|---|
| `Ctrl+C` | Kopírovat |
| `Ctrl+V` | Vložit |
| `Ctrl+Shift+F` | Hledat |
| `Alt+Shift+D` | Rozdělit panel (duplikace aktuálního profilu) |

### Oh My Posh

Minimalistické téma v modrých a tyrkysových odstínech, ve verzi 4 schématu. Prompt je rozdělen do tří bloků:

- Levý horní řádek: uživatelské jméno, den a čas, stav gitu (větev, upstream ikona, změny v pracovním stromu a staging, počet stashů)
- Pravý blok: doba trvání posledního příkazu, indikátor administrátora (`root`), využití paměti v procentech a GB
- Druhý řádek: aktuální cesta ve stylu `agnoster_full` v ozdobných závorkách

Transient prompt po provedení příkazu zredukuje předchozí prompty na jedinou ikonu, takže historie zůstává přehledná.

### Fastfetch

Systémové informace se zobrazí při každém otevření terminálu: uživatel a hostitel, OS, CPU, základní deska, paměť, disk a paleta barev. Barvy odpovídají Catppuccin Mocha. Logo se načítá ze souboru `ascii.txt`, případně se použije vestavěné.

### PowerShell profil

- Načte Terminal-Icons (ikony souborů a složek ve výpisech)
- Nastaví UTF-8 pro vstup, výstup i kódovou stránku
- Vyčistí obrazovku, inicializuje Oh My Posh s konfigurací z `~/.config/oh-my-posh/config.json`
- Spustí Fastfetch s explicitní cestou ke konfiguraci, pokud je Fastfetch nainstalován

## Co se kam nainstaluje

| Komponenta | Cíl |
|---|---|
| Oh My Posh téma | `%USERPROFILE%\.config\oh-my-posh\config.json` |
| Fastfetch konfigurace | `%USERPROFILE%\.config\fastfetch\config.jsonc` |
| Logo a ikona | `%USERPROFILE%\.config\fastfetch\ascii.txt`, `%USERPROFILE%\.config\powershell-black.png` |
| Windows Terminal | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` (a varianty pro Preview a nebalíčkovanou verzi) |
| PowerShell profil | `Dokumenty\PowerShell\Microsoft.PowerShell_profile.ps1` |
| Font | `%LOCALAPPDATA%\Microsoft\Windows\Fonts` |

## Zálohy a bezpečnost

- Před přepsáním se `settings.json` Windows Terminal i PowerShell profil zálohují jako `<soubor>.<časové razítko>.bak` ve stejné složce.
- Konfigurace Oh My Posh a Fastfetch se přepisují bez zálohy. Pokud je ručně upravuješ, ulož si je předem.
- Skript mění execution policy jen pro aktuálního uživatele a jen pokud je přísnější než `RemoteSigned`.
- Před spuštěním si skript přečti. Stahuje balíčky z winget, PowerShell Gallery a GitHubu a zapisuje do uživatelského profilu.

## Přizpůsobení

- Barvy promptu: uprav hexadecimální hodnoty `foreground` v `config.json`, nebo vyzkoušej jiná témata z dokumentace Oh My Posh.
- Vzhled terminálu: uprav `colorScheme`, `opacity`, `font` v sekci `profiles.defaults` v `settings.json`.
- Zobrazené informace ve Fastfetchi: uprav pole `modules` v `config.jsonc`.
- Vlastní logo: vlož textový soubor `ascii.txt` vedle skriptu a spusť instalaci znovu.
- Po úpravě souborů v repozitáři skript spusť znovu, nasadí je do cílových umístění.

## Řešení problémů

| Problém | Řešení |
|---|---|
| V promptu se místo ikon zobrazují čtverečky | Ověř, že je v `settings.json` nastaveno `JetBrainsMono Nerd Font Mono` a že jsi terminál restartoval |
| Skript hlásí chybějící soubor | Všechny povinné soubory musí ležet ve stejné složce jako `setup.ps1`, včetně přesného názvu `Microsoft.PowerShell_profile.ps1` |
| Terminal-Icons se nenainstaloval | V `pwsh` spusť `Install-Module Terminal-Icons -Scope CurrentUser -Force` |
| Skript se zastaví na wingetu | Aktualizuj App Installer z Microsoft Store a spusť skript znovu |
| Nastavení Windows Terminal se neprojevilo | Spusť Windows Terminal jednou, zavři ho a zopakuj skript |
| Fastfetch se nespustí | Zkontroluj `fastfetch --version` v novém okně terminálu, PATH se obnoví až po restartu |

## Použité nástroje

- [Windows Terminal](https://github.com/microsoft/terminal)
- [PowerShell](https://github.com/PowerShell/PowerShell)
- [Oh My Posh](https://ohmyposh.dev)
- [Fastfetch](https://github.com/fastfetch-cli/fastfetch)
- [Nerd Fonts](https://www.nerdfonts.com) a JetBrains Mono
- [Terminal-Icons](https://github.com/devblackops/Terminal-Icons)
- [Catppuccin](https://catppuccin.com)
