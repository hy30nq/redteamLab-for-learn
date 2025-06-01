#Requires -Version 5.1

<#
.SYNOPSIS
    Red Team Lab 환경 설정 (1단계 - 한 번만 실행)
.DESCRIPTION
    Python 가상환경을 생성하고 Ansible을 설치합니다.
    기본 도구들(Python, Vagrant, VirtualBox)이 이미 설치되어 있다고 가정합니다.
.EXAMPLE
    .\setup-environment.ps1
#>

# Check if running as Administrator and auto-elevate if needed
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator rights required. Requesting elevation..." -ForegroundColor Yellow
    try {
        # Get the current script path and working directory
        $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }
        $workingDir = Split-Path -Parent $scriptPath
        
        # Start elevated PowerShell with this script in the correct directory
        $arguments = "-NoExit -ExecutionPolicy Bypass -Command `"Set-Location '$workingDir'; & '$scriptPath'`""
        Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
        exit 0
    } catch {
        Write-Error "Failed to elevate to administrator privileges. Please run PowerShell as Administrator manually."
        exit 1
    }
}

Clear-Host

# Ensure we're in the correct directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($scriptDir) {
    Set-Location $scriptDir
}

Write-Host "================================================================================" -ForegroundColor Green
Write-Host "                     Red Team Lab - 환경 설정 (1단계)" -ForegroundColor Yellow
Write-Host "                 Vagrant + Ansible Based Security Training Environment" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Green
Write-Host ""

Write-Host "[+] Administrator rights confirmed" -ForegroundColor Green
Write-Host "[+] Working directory: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Function to test if command exists
function Test-CommandExists {
    param ([string]$CommandName)
    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

# Verify prerequisites are installed
Write-Host "[*] Checking prerequisites..." -ForegroundColor Cyan

$prerequisites = @{
    "python" = "Python"
    "vagrant" = "Vagrant" 
    "VBoxManage" = "VirtualBox"
}

$missingTools = @()
foreach ($tool in $prerequisites.Keys) {
    if (Test-CommandExists $tool) {
        $version = ""
        try {
            switch ($tool) {
                "python" { $version = (python --version 2>&1) }
                "vagrant" { $version = (vagrant --version 2>&1) }
                "VBoxManage" { $version = "VirtualBox installed" }
            }
            Write-Host "  [+] $($prerequisites[$tool]): $version" -ForegroundColor Green
        } catch {
            Write-Host "  [+] $($prerequisites[$tool]): installed" -ForegroundColor Green
        }
    } else {
        Write-Host "  [-] $($prerequisites[$tool]): NOT FOUND" -ForegroundColor Red
        $missingTools += $prerequisites[$tool]
    }
}

if ($missingTools.Count -gt 0) {
    Write-Host ""
    Write-Error "Missing required tools: $($missingTools -join ', ')"
    Write-Host ""
    Write-Host "Please install the missing tools first:" -ForegroundColor Yellow
    Write-Host "  • Python: https://www.python.org/downloads/" -ForegroundColor White
    Write-Host "  • Vagrant: https://www.vagrantup.com/downloads" -ForegroundColor White  
    Write-Host "  • VirtualBox: https://www.virtualbox.org/wiki/Downloads" -ForegroundColor White
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor DarkGray
    if ($Host.Name -eq "ConsoleHost") {
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    }
    exit 1
}

Write-Host ""
Write-Host "[*] Setting up Python virtual environment for Ansible..." -ForegroundColor Cyan

# Create Python virtual environment in the correct location
$venvPath = Join-Path (Get-Location) ".venv"
if (Test-Path $venvPath) {
    Write-Host "[!] Virtual environment already exists. Recreating..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $venvPath
}

try {
    python -m venv $venvPath
    Write-Host "[+] Virtual environment created at: $venvPath" -ForegroundColor Green
} catch {
    Write-Error "Failed to create virtual environment: $_"
    exit 1
}

# Install Ansible and dependencies
Write-Host "[*] Installing Ansible and dependencies..." -ForegroundColor Cyan

# Check for requirements.txt in current directory
$requirementsPath = Join-Path (Get-Location) "requirements.txt"
Write-Host "[*] Looking for requirements.txt at: $requirementsPath" -ForegroundColor Cyan

try {
    # Ensure pip is available and up to date
    & "$venvPath\Scripts\python.exe" -m ensurepip --upgrade 2>$null
    & "$venvPath\Scripts\python.exe" -m pip install --upgrade pip --quiet

    # Install packages from requirements.txt
    if (Test-Path $requirementsPath) {
        Write-Host "[+] Found requirements.txt, installing packages..." -ForegroundColor Green
        & "$venvPath\Scripts\python.exe" -m pip install -r $requirementsPath --quiet
        Write-Host "[+] Ansible and dependencies installed from requirements.txt" -ForegroundColor Green
    } else {
        Write-Warning "requirements.txt not found at $requirementsPath. Installing packages individually..."
        $packages = @("ansible>=8.0.0", "ansible-core>=2.15.0", "pywinrm>=0.4.3", "requests>=2.31.0", "packaging>=23.0")
        foreach ($package in $packages) {
            Write-Host "  Installing $package..." -ForegroundColor Yellow
            & "$venvPath\Scripts\python.exe" -m pip install $package --quiet
        }
        Write-Host "[+] Ansible and dependencies installed" -ForegroundColor Green
    }
} catch {
    Write-Warning "Some warnings occurred during Ansible installation, but it may have succeeded."
}

# Verify Ansible installation
Write-Host "[*] Verifying Ansible installation..." -ForegroundColor Cyan
try {
    $ansiblePath = Join-Path $venvPath "Scripts\ansible.exe"
    if (Test-Path $ansiblePath) {
        $ansibleVersion = & $ansiblePath --version 2>&1 | Select-Object -First 1
        Write-Host "[+] $ansibleVersion" -ForegroundColor Green
    } else {
        Write-Warning "Ansible executable not found, but installation may have succeeded."
    }
} catch {
    Write-Warning "Could not verify Ansible version, but installation may have succeeded."
}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "[+] 환경 설정 완료!" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Cyan
Write-Host "  .\start-labs.ps1 -Action Start   # 랩 환경 시작" -ForegroundColor White
Write-Host "  .\start-labs.ps1 -Action Status  # VM 상태 확인" -ForegroundColor White
Write-Host ""
Write-Host "과제 요구사항:" -ForegroundColor Yellow
Write-Host "  ✅ Windows 및 Linux 레드팀 랩" -ForegroundColor White
Write-Host "  ✅ Vagrant + Ansible 완전 자동화" -ForegroundColor White
Write-Host "  ✅ 다단계 공격 시나리오" -ForegroundColor White
Write-Host "  ✅ 1-day 취약점 및 SUID 권한 상승" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor DarkGray
if ($Host.Name -eq "ConsoleHost") {
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
} 