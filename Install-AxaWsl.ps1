<#
    .Synopsis
        Installs WSL for AXA Switzerland Developers enabling required Windows Features, installing vpnKit for networking and the AXA default distro as well as mandatory security features and agents.
    .Description
        This PowerShell script installs WSL for AXA Developers. It must be run in an administrative shell using OpenPC.
        To be able to run WSL you need to be member of the group CHDOLENINET\M_GPO_WSL and request it via Silva.
        WSL Order: https://silva.service-now.com/ssp?id=sc_cat_item_new&sys_id=77f235b61b55b9103b69edf2b24bcbeb
        Open PC Order: https://silva.service-now.com/ssp?id=sc_cat_item_new&sys_id=9af46ef8dba3af88938e3b4ffe9619d0
                
        Please note:
         - You have to install a proxy facade like Fiddler listening on $FiddlerPort (default 8888) before you install a 
           Linux distribution.
         - A reboot might be required if the Windows features 'Windows Subsystem For Linux'  and 'Virtual Machine Platform'
          have not been enabled yet.

        The script will setup the default AXA distro with mandatory security agents and configuration.

    .Parameter SetWslConfigDefaults
        Update $env:USERPROFILE/.wslconfig to these settings limiting resource consumption.
        [wsl2]
        memory=5G              # Limits VM memory to use no more than 5GB, this can be set as whole numbers using GB or MB
        processors=2           # Sets the VM to use no more than two virtual processors
        guiApplications=false  # Boolean to turn on or off support for GUI applications (WSLg) in WSL.
    .Parameter EditWslConfig
       Open notepad to edit $env:USERPROFILE/.wslconfig directly.
    .Parameter FiddlerPort
       Setting the port of the proxy facade, 8888 (default)
    .Parameter DistributionName
       The distribution to install, only approved one at the moment is Ubuntu (default)
    .Parameter InstallTerminal
       Download and install the Windows Terminal from the AXA CH repository.
    .Parameter InstallNerdFont
       Download and install the default Nerd Font Meslo
    .Parameter ConfigureTerminal
       Configure the Terminal and push some defaults.
    .Example
       Install-AxaWsl
       Sets up a AXA Switzerland compliant WSL installation and distribution.
    .Example
       Install-AxaWsl -SetWslConfigDefaults
       Sets some defaults in $env:USERPROFILE/.wslconfig

    .Link
       https://github.axa.com/wsl/ubuntu
    .Link
       https://teams.microsoft.com/l/channel/19%3abslVd3NBisdpq65dNJpsSE2Fd-kQZzoNcIjy3NT1yRk1%40thread.tacv2/General?groupId=4463cb82-ca16-4793-b20a-16b97d12ef43&tenantId=396b38cc-aa65-492b-bb0e-3d94ed25a97b
#>
param(
    [alias('h')][switch] $Help = $false,
    [switch] $SetWslConfigDefaults = $false,
    [switch] $EditWslConfig = $false,
    [string] $FiddlerPort = "8888",
    [string] $DistributionName = "Ubuntu-22.04",
    [switch] $InstallTerminal = $false,
    [switch] $InstallNerdFont = $false,
    [switch] $ConfigureTerminal = $false
)

if ($DistributionName -ne "Ubuntu-22.04" -and $DistributionName -ne "Debian") {
    throw "Distribution name not allowed, only 'Ubuntu-22.04' and 'Debian' are allowed"
}

# Defaults
$configLines = @(
    "[wsl2]",
    "memory=5G              # Limits VM memory to use no more than 5GB, this can be set as whole numbers using GB or MB",
    "processors=2           # Sets the VM to use no more than two virtual processors",
    "guiApplications=false  # Boolean to turn on or off support for GUI applications (WSLg) in WSL.",
    "kernelCommandLine=cgroup_no_v1=all",
    "[experimental]",
    "autoMemoryReclaim=gradual",
    "sparseVhd=true"
)
$configPath = "$env:USERPROFILE/.wslconfig"
$hostname = [Environment]::MachineName
#$proxy_url = "http://host.containers.internal:$FiddlerPort"
$proxy_url = "http://$hostname.local:$FiddlerPort"
$wslGroupName = "CHDOLENINET\M_GPO_WSL"
$wslGPORegex = "WSL_Enabled"
$openpcGroupName = "CHDOLENINET\M_V_OPENPC"
$executableGroupName = "CHDOLENINET\P_I-EXECUTABLE_DOWNLOADS"
$baseRepoUrl = "https://apt-repository.axa-ch-dev-int.red.switzerlandnorth.azure.openpaas.axa-cloud.com/repo"
$NoEntry = $([char]0x26D4)
$Ghost = [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("1F47B", 16))
$Runner = [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("1F3C3", 16))
$Warning = $([char]0x26A0)
$Check = $([char]0x2714)
#$User = [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("1F464", 16))
#$Token = [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("1F511", 16))

function Write-Error {
    Write-Host "$Ghost $($args[0])" -ForegroundColor Red
}

function Write-Debug {
    Write-Host "   $($args[0])"
}

function Write-Info {
    Write-Host "$Runner $($args[0])" -ForegroundColor Cyan
}

function Write-Warning {
    Write-Host "$Warning  $($args[0])" -ForegroundColor Yellow
}

function Write-Success {
    Write-Host "$Check  $($args[0])" -ForegroundColor Green
}

function Write-Fail {
    Write-Host "$NoEntry $($args[0])" -ForegroundColor Magenta
}


function Install-WindowsFeature {
    if ($env:DEV_SKIP_CHECKS -eq "1") {
        return $false
    }
    Write-Info "Installing Windows features 'Microsoft-Windows-Subsystem-Linux' and 'VirtualMachinePlatform' ..."
    if ((Get-WindowsOptionalFeature -FeatureName "Microsoft-Windows-Subsystem-Linux" -Online).State -eq "Enabled" -and (Get-WindowsOptionalFeature -FeatureName "VirtualMachinePlatform" -Online).State -eq "Enabled") {
        Write-Success "already installed"
        return $false
    }
    else {
        try {
            Write-Debug "You will need to be member of of the group $wslGroupName. See Get-Help $PSCommandPath"
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
        }
        catch {
            throw "Failed to install WSL Windows feature, with error: $_"
        }
        Write-Success "done"
        return $true
    }
}


function Update-WSL {
    if ($env:DEV_SKIP_CHECKS -eq "1") {
        return
    }
    Write-Info "Updating WSL to latest version ..."
    try {
        $global:LASTEXITCODE = 0
        wsl --update --web-download
        if ($null -ne $global:LASTEXITCODE -and $global:LASTEXITCODE -ne 0) {
            throw "$global:LASTEXITCODE"
        }
    }
    catch {
        throw "Failed to update WSL: 'wsl --update --web-download' returned exit code $_"
    }
    Write-Success "done"
}


function Install-Distribution {
    Write-Info "Installing distribution $DistributionName ..."
    try {
        if (Confirm-WslDistributionInstalled) {
            Write-Debug "WSL distribution $DistributionName is already installed, skip download."
        }
        else {
            Write-Info "Use WSL2 for $DistributionName ..."
            wsl --set-default-version 2
            if ($null -ne $global:LASTEXITCODE -and $global:LASTEXITCODE -ne 0) {
                throw "Setting WSL2 failed with exit code $global:LASTEXITCODE"
            }
            Write-Info "Start downloading distribution $DistributionName ..."
            wsl --install $DistributionName --web-download --no-launch
            if ($null -ne $global:LASTEXITCODE -and $global:LASTEXITCODE -ne 0) {
                throw "Download failed with exit code $global:LASTEXITCODE"
            }
            Write-Debug ""
            Write-Info "During the distribution setup, enter your preferred username and use a secure password."
            Write-Debug "Do not forget to save these credentials in your Keepass and add Auto-Type "
            Write-Debug "with target windows '*@$env:COMPUTERNAME*' and custom keystroke sequence {PASSWORD}{ENTER}"
            Write-Debug "for convenience. But Auto-Type does not work in the administrative shell you are right now."
            Write-Debug ""
            Write-Warning "IMPORTANT:"
            Write-Warning "Exit the distribution after the initial login for further configuration."
            wsl --install $DistributionName
            if ($null -ne $global:LASTEXITCODE -and $global:LASTEXITCODE -ne 0) {
                throw "Install failed with exit code $global:LASTEXITCODE"
            }
        }
    }
    catch {
        throw "Failed to install WSL distribution $DistributionName, with error: $_"
    }
    Write-Success "done"
}


function Confirm-WslDistributionInstalled {
    try {
        $isSystemDeployed = wsl -d "$DistributionName" -e pwd | grep -c '/mnt/'
        if ("$isSystemDeployed" -gt 0) {
            return $true
        }
    }
    catch {}
    return $false
}


function Install-WslVpnKit {
    if ($env:DEV_SKIP_CHECKS -eq "1") {
        return
    }
    Write-Info "Installing vpnKit ..."
    try {
        $vpnKitInstalled = wsl -l | Where-Object { $_.Replace("`0", "") -match '^wsl-vpnkit' }
        if ($vpnKitInstalled) {
            Write-Success "vpnKit already installed" -ForegroundColor Green
            return
        }
        $vpnKitVersion = "v0.4.1"
        Write-Debug "Downloading $vpnKitVersion from GitHub ..."
        # $vpnKitUrl = "https://github.com/sakai135/wsl-vpnkit/releases/download/$vpnKitVersion/wsl-vpnkit.tar.gz"
        # Using local mirror as Proxy is preventing direct download
        $vpnKitUrl = "{0}/misc/wsl-vpnkit/wsl-vpnkit.tar.gz" -f $baseRepoUrl
        $vpnKitTarget = "$env:OneDrive\Downloads\wsl-vpnkit.tar.gz"
        if (-Not (Test-Path -Path $vpnKitTarget -PathType Leaf)) {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $vpnKitUrl -OutFile $vpnKitTarget -Proxy http://localhost:$FiddlerPort
        }
        wsl --import wsl-vpnkit --version 2 $env:USERPROFILE\wsl-vpnkit $vpnKitTarget
        if ($global:LASTEXITCODE -ne 0) {
            throw "$global:LASTEXITCODE"
        }
        wsl -d wsl-vpnkit true # Ensure wsl-vpnkit is started
        Remove-Item $vpnKitTarget
    }
    catch {
        throw "Failed to install vpnKit, with error: $_"
    }
    Write-Success "vpnKit successfully installed"
}


function Update-WSLconf {
    Write-Info "Updating wsl.conf to enable systemd and remove Windows path from Linux environment ..."
    try {

        wsl -d $DistributionName -u root sh -c "echo '[boot]' > /etc/wsl.conf"
        wsl -d $DistributionName -u root sh -c "echo 'systemd=true' >> /etc/wsl.conf"
        wsl -d $DistributionName -u root sh -c "echo '' >> /etc/wsl.conf"
        wsl -d $DistributionName -u root sh -c "echo '[interop]' >> /etc/wsl.conf"
        wsl -d $DistributionName -u root sh -c "echo 'appendWindowsPath=false' >> /etc/wsl.conf"

        if ($global:LASTEXITCODE -ne 0) {
            throw "$global:LASTEXITCODE"
        }
        # Unfortunately wsl --shutdown is required
        # https://learn.microsoft.com/en-us/windows/wsl/wsl-config#systemd-support
        Write-Debug "Stopping Windows Subsystem for Linux (WSL) ..."
        wsl --shutdown
        if ($global:LASTEXITCODE -ne 0) {
            throw "$global:LASTEXITCODE"
        }

        Write-Debug "Killing all wsl-vpnkit / wsl-gvproxy.exe instances ..."
        Stop-Process -Name "wsl-gvproxy" -Force -ErrorAction SilentlyContinue
        
        Write-Debug "Starting Windows Subsystem for Linux (WSL) again ..."
        wsl -d $DistributionName -u root bash -c "echo '... restarted successfully!'"
        if ($global:LASTEXITCODE -ne 0) {
            throw "$global:LASTEXITCODE"
        }
    }
    catch {
        throw "Failed to update /etc/wsl.conf, with error: $_"
    }
    Write-Success "done"
}


function Install-axach-apt-repo {
    Write-Info "Configuring axa apt repo ..."
    try {
        if ($DistributionName -eq "Debian") {
            # Debian ships without curl and ca-certificates, so we need to install them manually.
            $opts = "-o 'Acquire::https::Verify-Peer=false' -o 'Acquire::http::Proxy=`"$proxy_url`"'"
            wsl -d $DistributionName -u root bash -c "apt $opts update && apt install $aptOpts -y curl ca-certificates gpg"
            if ($global:LASTEXITCODE -ne 0) {
                throw "$global:LASTEXITCODE"
            }
            $codename = "bookworm"
        }
        elseif ($DistributionName -eq "Ubuntu-22.04") {
            $codename = "jammy"
        }
        else {
            throw "Invalid distro, only 'Debian' and 'Ubuntu-22.04' allowed: $DistributionName"
        }

        wsl -d $DistributionName -u root -- bash -c "curl --retry 10 --retry-max-time 120 -ksS $baseRepoUrl/misc/axa-ch-apt-repo.gpg.key | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/axa-ch-apt-repo.gpg"
        if ($global:LASTEXITCODE -ne 0) {
            throw "$global:LASTEXITCODE"
        }
        
        wsl -d $DistributionName -u root -- bash -c "echo 'deb $baseRepoUrl $codename main' | sudo tee /etc/apt/sources.list.d/axa-ch-apt-repo.list"
        if ($global:LASTEXITCODE -ne 0) {
            throw "$global:LASTEXITCODE"
        }
    }
    catch {
        throw "Failed to configure axa apt repo, with error: $_"
    }
    Write-Success "done"
}

function Install-wsl-base {
    Write-Info "Installing axach-wsl-base - a deb package containing basic connectivity settings ..."
    try {
        # Pre-seed Fiddler port to debconf to not display the dialog
        wsl -d $DistributionName -u root bash -c "echo 'axach-wsl-base axach-wsl-base/fiddlerport string $FiddlerPort' | debconf-set-selections"
        wsl -d $DistributionName -u root bash -c "echo 'axach-wsl-base axach-wsl-base/fiddlerport seen true' | debconf-set-selections"
        # Install axach-wsl-base
        wsl -d $DistributionName -u root bash -c "apt -o 'Acquire::https::Verify-Peer=false' -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/axa-ch-apt-repo.list update && apt install -o 'Acquire::https::Verify-Peer=false' -y axach-wsl-base"
        if ($global:LASTEXITCODE -ne 0) {
            throw "$global:LASTEXITCODE"
        }
    }
    catch {
        throw "Failed to install axach-wsl-base with error: $_"
    }
    Write-Success "done"
}

function Install-wsl-compliance {
    Write-Info "Installing axach-wsl-compliance - a deb package setting up axa ch wsl compliance ..."
    try {
        Write-Debug "Ensuring wsl-vpnkit is up and running as well as networking is working ..."
        Write-Warning "IMPORTANT:"
        Write-Warning "Be patient as it can take multiple retries until the internal apt-repository is accessible via wsl-vpnkit."
        wsl -d $DistributionName -u root /opt/axach-wsl-base/connection-test.sh
        wsl -d $DistributionName -u root apt update # for zstd
        wsl -d $DistributionName -u root apt install -y axach-wsl-compliance
        if ($global:LASTEXITCODE -ne 0) {
            throw "$global:LASTEXITCODE"
        }
    }
    catch {
        throw "Failed to install axach-wsl-compliance with error: $_"
    }
    Write-Success "done"
}

function Install-wsl-optional-and-updates {
    Write-Info "Updating all Packages in $DistributionName ..."
    try {
        $gitRoot = Split-Path -parent (Split-Path -parent (Get-Command git).Path)
        wsl -d $DistributionName -u root bash -c "apt update && apt dist-upgrade -y && apt upgrade -y && apt install -y axach-wsl-optional axach-wsl-openshift-cli axach-wsl-ohmyposh"
        if ($global:LASTEXITCODE -ne 0) {
            throw "$global:LASTEXITCODE"
        }
        wsl -d $DistributionName -u root /opt/axach-wsl-optional/setup.sh -g "$gitRoot" -f
        if ($global:LASTEXITCODE -ne 0) {
            throw "$global:LASTEXITCODE"
        }
    }
    catch {
        throw "Failed to install axach-wsl-optional with error: $_"
    }
    Write-Success "done"
}

function Get-IniContent {
    param(
        [parameter(mandatory = $true)][string] $FilePath
    )
    $ini = @{}
    switch -regex -file $FilePath {
        "^\[(.+)\]" {
            # Section
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        "^(; .*)$" {
            # Comment
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = "Comment" + $CommentCount
            $ini[$section][$name] = $value
        }
        "(.+?)\s*=(.*)" {
            # Key
            $name, $value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}


function Out-IniFile {
    param(
        [parameter(mandatory = $true)][string] $FilePath,
        [parameter(mandatory = $true)][Hashtable] $InputObject
    )
    $outFile = New-Item -ItemType file -Path $FilePath -Force
    foreach ($i in $InputObject.keys) {
        if (!($($InputObject[$i].GetType().Name) -eq "Hashtable")) {
            #No Sections
            Add-Content -Path $outFile -Value "$i=$($InputObject[$i])"
        }
        else {
            #Sections
            Add-Content -Path $outFile -Value "[$i]"
            Foreach ($j in ($InputObject[$i].keys | Sort-Object)) {
                if ($j -match "^Comment[\d]+") {
                    Add-Content -Path $outFile -Value "$($InputObject[$i][$j])"
                }
                else {
                    Add-Content -Path $outFile -Value "$j=$($InputObject[$i][$j])"
                }

            }
            Add-Content -Path $outFile -Value ""
        }
    }
}


function Initialize-WslConfig {
    Write-Info "Initializing WSL config $configPath ..."
    Write-Debug "$($configLines -join "`n   ")"
    try {
        if (-not (Test-Path $configPath)) {
            New-Item -Path $configPath -ItemType "file"
        }
        $iniContent = Get-IniContent -FilePath $configPath
        $sectionHeader = ""
        foreach ($line in $configLines) {
            # Check if the line is a section header (e.g. [wsl2])
            if ($line -match "^\[.*\]$") {
                $sectionHeader = $line.trim('[]')
                if (!$iniContent.ContainsKey($sectionHeader)) {
                    $iniContent[$sectionHeader] = @{}
                }
            }
            else {
                $key, $value = $line -split "=", 2
                $iniContent[$sectionHeader][$key] = $value
            }
        }
        Out-IniFile -FilePath $configPath -InputObject $iniContent
    }
    catch {
        throw "Failed to initialize wsl.conf, with error: $_"
    }
    Write-Success "done"
}


function Install-WindowsTerminal {
    $packageName = "Windows Terminal"
    Write-Info "Installing $packageName ..."
    try {
        # Winget was rendered useless by security and GPO
        # winget settings –enable BypassCertificatePinningForMicrosoftStore
        # Dieser Vorgang wird von Gruppenrichtlinie deaktiviert: Einstellungen des Windows-Paket-Manager aktivieren

        # winget list $packageName --accept-source-agreements | Out-Null
        #if ($global:LASTEXITCODE -ne 0) {
        #    Write-Info "Installing $packageName ..."
        #    winget install $packageName --silent --disable-interactivity --accept-package-agreements --accept-source-agreements
        #}
        #else {
        #    Write-Info "Upgrading $packageName ..."
        #    winget upgrade $packageName --silent --disable-interactivity --accept-package-agreements --accept-source-agreements
        #    return
        #}

        if (-Not (Test-Path -Path $env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe -PathType Leaf)) {
            $terminalVersion = "1.19.10821.0_8wekyb3d8bbwe"
            Write-Debug $("Downloading Terminal v{0} ..." -f $terminalVersion)
            $terminalUrl = "{0}/misc/WindowsTerminal/Microsoft.WindowsTerminal_{1}.msixbundle" -f $baseRepoUrl, $terminalVersion
            $terminalTarget = "$env:OneDrive\Downloads\Microsoft.WindowsTerminal_{0}.msixbundle" -f $terminalVersion
            if (-Not (Test-Path -Path $terminalTarget -PathType Leaf)) {
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $terminalUrl -OutFile $terminalTarget -Proxy http://localhost:$FiddlerPort
            }
            if ($PSVersionTable.PSVersion.Major -lt 7) {
                Import-Module Appx
            }
            else {
                Import-Module -Name Appx -UseWindowsPowerShell
            }

            Write-Info "Installing package $terminalTarget ..."
            Add-AppxPackage -Path $terminalTarget
            if ($global:LASTEXITCODE -ne 0) {
                Write-Fail "Installation of Windows Terminal failed. You will have to manually install it. Starting explorer.exe $terminalTarget"
                Start-Process explorer.exe $terminalTarget
                Start-Sleep -Seconds 15
                while ($true) {
                    if (-not (Get-Process -Name "AppInstaller" -ErrorAction SilentlyContinue)) {
                        Write-Host "AppInstaller process has stopped."
                        break
                    }
                    Start-Sleep -Seconds 1
                }
            }
            Write-Info "Starting Terminal to write initial settings.json ..."
            Start-Process -FilePath $env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe -WindowStyle Hidden; Start-Sleep -Seconds 3; Get-Process "WindowsTerminal" | Stop-Process
        }
    }
    catch {
        throw "Failed to install $packageName : $_"
    }
    Write-Success "done"
}


function Install-NerdFont {
    Write-Info "Installing default Nerd Font ..."
    try {
        $fontDestination = (New-Object -ComObject Shell.Application).Namespace(0x14)
        foreach ($font in @("MesloLGSNerdFont-Regular.ttf")) {
            Invoke-WebRequest -Uri "$baseRepoUrl/misc/fonts/$font" -Outfile "$env:OneDrive\Downloads\$font" -Proxy http://localhost:$FiddlerPort
            $fontDestination.CopyHere("$env:OneDrive\Downloads\$font", 0x10)
            Remove-Item "$env:OneDrive\Downloads\$font"
        }
    }
    catch {
        throw "Failed to install default Nerd Font : $_"
    }
    Write-Success "done"
}

function Update-TerminalConfiguration {
    $packageName = "Windows Terminal"
    $settingsFile = "$env:localappdata\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    Write-Info "Configuring $packageName ..."
    try {
        $fontTemplate = @'
{
    "face": "MesloLGS Nerd Font",
    "size": 10.0,
    "weight": "normal"
}
'@

        $schemaCatppuccin = @'
{
    "background": "#1E1E2E",
    "black": "#45475A",
    "blue": "#89B4FA",
    "brightBlack": "#585B70",
    "brightBlue": "#89B4FA",
    "brightCyan": "#94E2D5",
    "brightGreen": "#A6E3A1",
    "brightPurple": "#F5C2E7",
    "brightRed": "#F38BA8",
    "brightWhite": "#A6ADC8",
    "brightYellow": "#F9E2AF",
    "cursorColor": "#F5E0DC",
    "cyan": "#94E2D5",
    "foreground": "#CDD6F4",
    "green": "#A6E3A1",
    "name": "Catppuccin Mocha",
    "purple": "#F5C2E7",
    "red": "#F38BA8",
    "selectionBackground": "#585B70",
    "white": "#BAC2DE",
    "yellow": "#F9E2AF"
}
'@

        $themeCatppucchin = @'
{
    "name": "Catppuccin Mocha",
    "tab": 
    {
        "background": "#1E1E2EFF",
        "showCloseButton": "always",
        "unfocusedBackground": null
    },
    "tabRow": 
    {
        "background": "#181825FF",
        "unfocusedBackground": "#11111BFF"
    },
    "window": 
    {
        "applicationTheme": "dark",
        "useMica": false
    }
}
'@

        $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
        $scheme = $settings.schemes | Where-Object { $_.name -eq "Catppuccin Mocha" }
        if ($null -eq $scheme) {
            $settings.schemes += (Convertfrom-Json $schemaCatppuccin)
        }
        $theme = $settings.themes | Where-Object { $_.name -eq "Catppuccin Mocha" }
        if ($null -eq $theme) {
            $settings.themes += (Convertfrom-Json $themeCatppucchin)
        }

        $settings | Add-Member -Name "useAcrylicInTabRow" -value $true -MemberType NoteProperty -Force
        $settings | Add-Member -Name "startOnUserLogin" -value $true -MemberType NoteProperty -Force
        $settings | Add-Member -Name "theme" -value "Catppuccin Mocha" -MemberType NoteProperty -Force
        $settings | Add-Member -Name "initialRows" -value 50 -MemberType NoteProperty -Force
        $settings | Add-Member -Name "copyOnSelect" -value $true -MemberType NoteProperty -Force
        $settings | Add-Member -Name "copyFormatting" -value "rtf" -MemberType NoteProperty -Force

        $settings.profiles.defaults | Add-Member -Name "antialiasingMode" -value "cleartype" -MemberType NoteProperty -Force
        $settings.profiles.defaults | Add-Member -Name "bellStyle" -value "none" -MemberType NoteProperty -Force
        $settings.profiles.defaults | Add-Member -Name "colorScheme" -value "Catppuccin Mocha" -MemberType NoteProperty -Force
        $settings.profiles.defaults | Add-Member -Name "experimental.retroTerminalEffect" -value $false -MemberType NoteProperty -Force
        $settings.profiles.defaults | Add-Member -Name "historySize" -value 12000 -MemberType NoteProperty -Force
        $settings.profiles.defaults | Add-Member -Name "intenseTextStyle" -value "all" -MemberType NoteProperty -Force
        $settings.profiles.defaults | Add-Member -Name "useAcrylic" -value $false -MemberType NoteProperty -Force
        $settings.profiles.defaults | Add-Member -Name "useAtlasEngine" -value $false -MemberType NoteProperty -Force
        $settings.profiles.defaults | Add-Member -Name "font"-value (Convertfrom-Json $fontTemplate) -MemberType NoteProperty -Force
        $settings.profiles.defaults | Add-Member -Name "backgroundImageOpacity" -value 0.69 -MemberType NoteProperty -Force

        $settings | ConvertTo-Json -Depth 32 | Set-Content $settingsFile
    }
    catch {
        throw "Failed to configure $packageName : $_"
    }
    Write-Success "done"
}

if ($env:DEV_SKIP_CHECKS -eq "1") {
    Write-Warning "DEV_SKIP_CHECKS ENABLED"
    Write-Warning "This script will skip several checks and installations to make it faster"
    Write-Warning "Only use this when you already have WSL installed and are working on the WSL scripts"
}

if ($Help) {
    Get-Help $PSCommandPath
    exit 0
}

if ($DistributionName -eq "Debian") {
    Write-Warning "Debian support is experimental"
}

if ($SetWslConfigDefaults) {
    Initialize-WslConfig
    exit 0
}

if ($EditWslConfig) {
    notepad $env:USERPROFILE/.wslconfig
    exit 0
}

if ($InstallTerminal) {
    Install-WindowsTerminal
    exit 0
}

if ($InstallNerdFont) {
    Install-NerdFont
    exit 0
}

if ($ConfigureTerminal) {
    Update-TerminalConfiguration
    exit 0
}

if ($env:DEV_SKIP_CHECKS -ne "1") {
    # Have OpenPC rights
    $openpcGroup = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups | Select-Object @{Name = "value"; Expression = { $_.Translate([System.Security.Principal.NTAccount]).Value } } | Where-Object { $_.value -eq $openpcGroupName }
    if ([string]::IsNullOrEmpty($openpcGroup)) {
        Write-Fail "You must request OpenPC and receive the AD group membership to $openpcGroupName."
        Write-Fail "If you did get the right and it does not work while working remote, check"
        Write-Debug "https://teams.microsoft.com/l/chat/0/0?users=28:10d8ccb9-00a2-4e11-bc68-ebcabfe633df&message=Wie%20mache%20ich%20einen%20VPN%20Domain%20Login"
        exit 1
    }
    # Have P_I-EXECUTABLE_DOWNLOADS
    $executableGroup = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups | Select-Object @{Name = "value"; Expression = { $_.Translate([System.Security.Principal.NTAccount]).Value } } | Where-Object { $_.value -eq $executableGroupName }
    if ([string]::IsNullOrEmpty($executableGroup)) {
        Write-Fail "You must have $executableGroupName rights."
        Write-Fail "Request this group membership via IIQ"
        Write-Debug "https://work.axa-ch.intraxa/identityiq/accessRequest/accessRequest.jsf#/accessRequestSelf/add?quickLink=Request%20Access"
        exit 1
    }
    Write-Info "Update Windows Group Policy and verify rights for $wslGroupName ..."
    # Have WSL rigts
    $gpo = gpresult /R /SCOPE COMPUTER
    if ( -not $gpo | Where-Object { $_ -match $wslGPORegex } ) {
        Write-Fail "You must request WSL and receive the AD group membership to $wslGroupName."
        Write-Fail "If you recently got the rights, run 'gpupdate /Force' to update it"
        Write-Fail "If you did get the right and it does not work while working remote, check"
        Write-Debug "https://teams.microsoft.com/l/chat/0/0?users=28:10d8ccb9-00a2-4e11-bc68-ebcabfe633df&message=Wie%20mache%20ich%20einen%20VPN%20Domain%20Login"
        exit 1
    }
    # Have no running Ubuntu WSL 1 distro
    $runningDistros = $(wsl --list --verbose) -split "`r`n" -replace "`0" | Where-Object { $_ -ne "" }
    if ( $runningDistros | Where-Object { $_ -match "[ ]+$DistributionName[ ]+" -and $_ -like "*1" } ) {
        Write-Fail "A WSL 1 distro $DistributionName already exists. Please delete it (all data will be lost) before setting up new WSL 2 AXA installation."
        Write-Debug "wsl --terminate $DistributionName"
        Write-Debug "wsl --unregister $DistributionName"
        exit 1
    }
}
if ( $runningDistros | Where-Object { $_ -match "[ ]+$DistributionName[ ]+" -and $_ -like "*2" } ) {
    Write-Warning "A WSL 2 distro $DistributionName already exists. Re-running setup inside."
}
# Run as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fail "This script must be run in an administrative PowerShell you must have Open PC rights"
    exit 1
}

try {
    $result = Invoke-WebRequest -Uri https://www.axa.ch/robots.txt -Proxy http://localhost:$FiddlerPort -EA SilentlyContinue
    if ($result.StatusCode -ne 200) {
        throw "Fiddler not running."
    }
}
catch {
    Write-Fail "This script needs Fiddler or a similar proxy facade tool. Please start it or change -FiddlerPort parameter to the right port (default 8888)"
    exit 1
}

try {
    $reboot = Install-WindowsFeature
    if ($reboot) {
        Write-Error ">>> A RESTART OF YOUR PC IS REQUIRED <<<"
        exit 0
    }
    Update-WSL
    Install-Distribution
    Install-WslVpnKit
    Update-WSLconf
    Install-axach-apt-repo
    Install-wsl-base
    Install-wsl-compliance
    Install-wsl-optional-and-updates
    Install-WindowsTerminal
    Install-NerdFont
    Update-TerminalConfiguration
}
catch {
    Write-Error "$_"
    exit 9
}
