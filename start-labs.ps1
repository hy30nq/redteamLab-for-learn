#Requires -Version 5.1

<#
.SYNOPSIS
    Red Team Lab VM 관리 (2단계 - 필요시마다 실행)
.DESCRIPTION
    Vagrant VM들을 생성, 시작, 중지, 삭제하고 상태를 확인합니다.
    먼저 setup-environment.ps1을 실행해야 합니다.
.PARAMETER Action
    수행할 작업:
    - Start: VM 생성 및 시작
    - Stop: VM 중지
    - Status: VM 상태 확인
    - Destroy: VM 삭제
    - ReProvisionWIN: Windows VM 재프로비저닝
    - ReProvisionNIX: Linux VM 재프로비저닝
.EXAMPLE
    .\start-labs.ps1 -Action Start
.EXAMPLE
    .\start-labs.ps1 -Action Status
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Start", "Stop", "Status", "Destroy", "ReProvisionWIN", "ReProvisionNIX")]
    [string]$Action
)

# Check if running as Administrator and auto-elevate if needed
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator rights required. Requesting elevation..." -ForegroundColor Yellow
    try {
        # Get the current script path and working directory
        $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }
        $workingDir = Split-Path -Parent $scriptPath
        
        # Start elevated PowerShell with this script and parameters in correct directory
        $arguments = "-NoExit -ExecutionPolicy Bypass -Command `"Set-Location '$workingDir'; & '$scriptPath' -Action '$Action'`""
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
Write-Host "                     Red Team Lab - VM 관리 (2단계)" -ForegroundColor Yellow
Write-Host "                 Vagrant + Ansible Based Security Training Environment" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Green
Write-Host ""

Write-Host "[+] Administrator rights confirmed" -ForegroundColor Green
Write-Host "[+] Working directory: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# --- Configuration ---
$ProjectRoot = $PSScriptRoot
if (-not $ProjectRoot) { $ProjectRoot = Get-Location }

# Check for virtual environment (try .venv-new first, then .venv)
$VenvPath = $null
if (Test-Path (Join-Path $ProjectRoot ".venv-new")) {
    $VenvPath = Join-Path $ProjectRoot ".venv-new"
    Write-Host "[*] Using virtual environment: .venv-new" -ForegroundColor Cyan
} elseif (Test-Path (Join-Path $ProjectRoot ".venv")) {
    $VenvPath = Join-Path $ProjectRoot ".venv"
    Write-Host "[*] Using virtual environment: .venv" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Error "Python virtual environment not found! Please run setup-environment.ps1 first."
    Write-Host ""
    Write-Host "First run:" -ForegroundColor Yellow
    Write-Host "  .\setup-environment.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

$WindowsLabPath = Join-Path $ProjectRoot "windows-lab"
$LinuxLabPath = Join-Path $ProjectRoot "linux-lab"

# --- Prerequisites Check ---
Write-Host "[*] Checking prerequisites..." -ForegroundColor Cyan

# Check if Ansible is available in venv
$ansiblePath = Join-Path $VenvPath "Scripts\ansible.exe"
if (-not (Test-Path $ansiblePath)) {
    Write-Host ""
    Write-Error "Ansible not found in virtual environment! Please run setup-environment.ps1 first."
    Write-Host ""
    Write-Host "First run:" -ForegroundColor Yellow
    Write-Host "  .\setup-environment.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "[+] Virtual environment found: $VenvPath" -ForegroundColor Green
Write-Host "[+] Ansible installation verified" -ForegroundColor Green

# --- Function to check if a command exists ---
function Test-CommandExists {
    param ([string]$CommandName)
    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

# --- Function to add VirtualBox to PATH if not present ---
function Add-VirtualBoxToPath {
    if (-not (Test-CommandExists "VBoxManage")) {
        Write-Host "[*] VBoxManage not found in PATH. Attempting to find and add VirtualBox directory..." -ForegroundColor Yellow
        $virtualBoxPath = ""
        if ($env:ProgramFiles) {
            $potentialPath = Join-Path $env:ProgramFiles "Oracle\VirtualBox"
            if (Test-Path (Join-Path $potentialPath "VBoxManage.exe")) {
                $virtualBoxPath = $potentialPath
            }
        }
        if (-not $virtualBoxPath -and $env:ProgramW6432) { # For 32-bit PS on 64-bit OS
            $potentialPath = Join-Path $env:ProgramW6432 "Oracle\VirtualBox"
            if (Test-Path (Join-Path $potentialPath "VBoxManage.exe")) {
                $virtualBoxPath = $potentialPath
            }
        }

        if ($virtualBoxPath) {
            Write-Host "[+] Found VirtualBox at: $virtualBoxPath" -ForegroundColor Green
            $env:Path += ";$virtualBoxPath"
            Write-Host "[+] VirtualBox directory added to PATH for this session." -ForegroundColor Green
        } else {
            Write-Warning "[!] Could not automatically find VirtualBox installation path. Please add it to your PATH manually."
            return $false
        }
    } else {
        Write-Host "[+] VBoxManage found in PATH." -ForegroundColor Green
    }
    return $true
}

# --- Function to activate Python virtual environment ---
function Invoke-Venv {
    param ([string]$VenvDirectory)
    $activateScript = Join-Path $VenvDirectory "Scripts\activate.ps1"
    if (Test-Path $activateScript) {
        Write-Host "[*] Activating Python virtual environment..." -ForegroundColor Cyan
        try {
            Invoke-Expression "& `"$activateScript`""
            Write-Host "[+] Python virtual environment activated." -ForegroundColor Green
        } catch {
            Write-Error "Failed to activate Python virtual environment: $_"
            exit 1
        }
    } else {
        Write-Error "Python virtual environment activation script not found. Please run setup-environment.ps1."
        exit 1
    }
}

# --- Main Logic ---

# Add VirtualBox to PATH
if (-not (Add-VirtualBoxToPath)) {
    Write-Error "Exiting due to VBoxManage not being available."
    exit 1
}

Write-Host ""

if ($Action -eq "Start") {
    Write-Host "🚀 Starting Red Team Lab deployment..." -ForegroundColor Cyan
    Write-Host ""

    # Deploy Linux Lab
    Write-Host "🐧 Deploying Linux Red Team Lab..." -ForegroundColor Cyan
    Write-Host "Attack Scenario: SQL Injection → Command Injection → Sudo Privilege Escalation" -ForegroundColor Yellow
    Push-Location $LinuxLabPath
    Invoke-Venv $VenvPath # Activate venv for ansible_local if it uses host ansible
    Write-Host "[*] Creating Ubuntu VM with Vagrant and running Ansible provisioning..." -ForegroundColor White
    vagrant up --provision
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[-] Linux Lab deployment failed"
    } else {
        Write-Host "[+] Linux Lab deployed successfully!" -ForegroundColor Green
        Write-Host "    → Access: http://localhost:8081" -ForegroundColor White
    }
    Pop-Location
    Write-Host ""

    # Deploy Windows Lab  
    Write-Host "🪟 Deploying Windows Red Team Lab..." -ForegroundColor Cyan
    Write-Host "Attack Scenario: Web OS Command Injection → AlwaysInstallElevated Privilege Escalation" -ForegroundColor Yellow
    Push-Location $WindowsLabPath
    Write-Host "[*] Creating Windows Server VM with Vagrant and running Ansible provisioning..." -ForegroundColor White
    Write-Host "[!] First run may take time due to Windows Server image download..." -ForegroundColor Yellow
    vagrant up --provision
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[-] Windows Lab deployment failed"
    } else {
        Write-Host "[+] Windows Lab deployed successfully!" -ForegroundColor Green
        Write-Host "    → Web: http://localhost:8082/webapp/cmd_injection.aspx" -ForegroundColor White
        Write-Host "    → RDP: localhost:8085 (lowpriv/User123!)" -ForegroundColor White
    }
    Pop-Location
    Write-Host ""

    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host "🎯 Red Team Lab Deployment Complete!" -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "접속 정보:" -ForegroundColor Cyan
    Write-Host "  🐧 Linux Lab:  http://localhost:8081" -ForegroundColor Green
    Write-Host "  🪟 Windows Lab: http://localhost:8082/webapp/cmd_injection.aspx" -ForegroundColor Green
    Write-Host "  🔐 Windows RDP: localhost:8085 (lowpriv/User123!)" -ForegroundColor Green
    Write-Host ""
    Write-Host "학습 목표:" -ForegroundColor Yellow
    Write-Host "  ✅ SQL Injection → Command Injection → Privilege Escalation (Linux)" -ForegroundColor White
    Write-Host "  ✅ Web Command Injection → AlwaysInstallElevated (Windows)" -ForegroundColor White
    Write-Host ""
    Write-Host "관리 명령어:" -ForegroundColor Cyan
    Write-Host "  .\start-labs.ps1 -Action Status   # VM 상태 확인"
    Write-Host "  .\start-labs.ps1 -Action Stop     # VM 중지"
    Write-Host "  .\start-labs.ps1 -Action Destroy  # VM 삭제"
    Write-Host ""

} elseif ($Action -eq "Stop") {
    Write-Host "⏹️ Stopping all labs..." -ForegroundColor Cyan
    Push-Location $LinuxLabPath
    vagrant halt
    Pop-Location
    Push-Location $WindowsLabPath
    vagrant halt
    Pop-Location
    Write-Host "[+] All labs stopped." -ForegroundColor Green

} elseif ($Action -eq "Status") {
    Write-Host "📊 Checking lab status..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "--- 🐧 Linux Lab Status ---" -ForegroundColor Yellow
    Push-Location $LinuxLabPath
    vagrant status
    Pop-Location
    Write-Host ""
    Write-Host "--- 🪟 Windows Lab Status ---" -ForegroundColor Yellow
    Push-Location $WindowsLabPath
    vagrant status
    Pop-Location

} elseif ($Action -eq "Destroy") {
    Write-Host "🗑️ Destroying all labs..." -ForegroundColor Cyan
    Write-Warning "This will delete all VMs and their data. Are you sure?"
    $confirmation = Read-Host "Type 'yes' to confirm"
    if ($confirmation -eq 'yes') {
        Push-Location $LinuxLabPath
        vagrant destroy -f
        Pop-Location
        Push-Location $WindowsLabPath
        vagrant destroy -f
        Pop-Location
        Write-Host "[+] All labs destroyed." -ForegroundColor Green
    } else {
        Write-Host "[-] Destruction cancelled." -ForegroundColor Yellow
    }
} elseif ($Action -eq "ReProvisionWIN") {
    Write-Host "🔄 Re-provisioning Windows Lab..." -ForegroundColor Cyan
    Push-Location $WindowsLabPath
    vagrant provision
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[-] Windows Lab re-provisioning failed"
    } else {
        Write-Host "[+] Windows Lab re-provisioned successfully!" -ForegroundColor Green
    }
    Pop-Location
} elseif ($Action -eq "ReProvisionNIX") {
    Write-Host "🔄 Re-provisioning Linux Lab..." -ForegroundColor Cyan
    Push-Location $LinuxLabPath
    Invoke-Venv $VenvPath # Activate venv for ansible_local if it uses host ansible
    vagrant provision
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[-] Linux Lab re-provisioning failed"
    } else {
        Write-Host "[+] Linux Lab re-provisioned successfully!" -ForegroundColor Green
    }
    Pop-Location
}

Write-Host ""
if ($Action -ne "Status") { # Don't pause for status check
    Write-Host "[*] Press any key to exit..." -ForegroundColor DarkGray
    if ($Host.Name -eq "ConsoleHost") {
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    }
} 