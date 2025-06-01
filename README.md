# Red Team Lab - Auto Deployment System

**Vagrant + Ansible 기반 보안 교육 환경**

이 프로젝트는 Windows와 Linux 환경에서 실제적인 침투 테스트 실습을 위한 자동화된 레드팀 랩 환경을 제공합니다.

## 📋 과제 요구사항

✅ **Windows 및 Linux 레드팀 랩 생성**  
✅ **Vagrant와 Ansible을 사용한 완전 자동화**  
✅ **초기 침투와 권한 상승을 포함한 다단계 공격 시나리오**  
✅ **1-day 취약점 및 SUID 권한 상승 기법 포함**  

## 🎯 공격 시나리오

### Windows Lab
**2단계 공격 체인: Web Command Injection → AlwaysInstallElevated**

1. **초기 침투**: OS Command Injection (웹 애플리케이션)
   - 대상: `http://localhost:8082/webapp/cmd_injection.aspx`
   - 방법: URL 파라미터를 통한 명령어 삽입
   - 예시: `?cmd=whoami`

2. **권한 상승**: AlwaysInstallElevated
   - 방법: MSI 패키지를 SYSTEM 권한으로 실행
   - 도구: `msfvenom -p windows/exec CMD="..." -f msi`

### Linux Lab
**3단계 공격 체인: SQL Injection → Command Injection → Sudo Privilege Escalation**

1. **초기 침투**: SQL Injection (인증 우회)
   - 대상: `http://localhost:8081`
   - 페이로드: `admin' OR '1'='1'--`

2. **명령어 실행**: Command Injection (네트워크 진단 도구)
   - 페이로드: `localhost; whoami`

3. **권한 상승**: Sudo SUID 악용
   - 명령어: `sudo /usr/bin/env /bin/sh`

## 🚀 빠른 시작

### 1단계: 환경 설정
```powershell
# PowerShell을 관리자 권한으로 실행
.\setup-environment.ps1
```

### 2단계: 랩 배포
```powershell
.\start-labs.ps1 -Action Start
```

### 3단계: 접속 정보
- **Linux Lab**: http://localhost:8081
- **Windows Lab**: http://localhost:8082/webapp/cmd_injection.aspx
- **RDP (Windows)**: localhost:8085 (lowpriv/User123!)

## 🗂️ 프로젝트 구조

```
redteamLab-for-learn/
├── setup-environment.ps1      # 환경 설정 스크립트
├── start-labs.ps1            # 랩 관리 스크립트
├── requirements.txt          # Python 의존성
├── ansible.cfg              # Ansible 전역 설정
├── README.md               # 프로젝트 문서
├── linux-lab/
│   ├── Vagrantfile         # Linux VM 정의
│   └── ansible/
│       ├── inventory       # SSH 연결 설정
│       └── linux-setup.yml # LAMP + 취약점 구성
└── windows-lab/
    ├── Vagrantfile         # Windows VM 정의
    └── ansible/
        ├── inventory       # WinRM 연결 설정
        ├── windows-setup.yml # IIS + 취약점 구성
        └── files/
            └── cmd_injection.aspx # 취약한 웹 페이지
```

## 🛠️ 관리 명령어

```powershell
# VM 상태 확인
.\start-labs.ps1 -Action Status

# VM 중지
.\start-labs.ps1 -Action Stop

# VM 삭제
.\start-labs.ps1 -Action Destroy

# 개별 랩 재프로비저닝
.\start-labs.ps1 -Action ReProvisionWIN
.\start-labs.ps1 -Action ReProvisionNIX
```

## 🏁 학습 목표

### Windows 환경
- **웹 애플리케이션 취약점**: Command Injection
- **권한 상승**: Windows Registry 기반 권한 상승 (AlwaysInstallElevated)
- **지속성**: 레지스트리 기반 공격

### Linux 환경
- **웹 애플리케이션 취약점**: SQL Injection, Command Injection
- **권한 상승**: Sudo 및 SUID 악용
- **시스템 침투**: 웹에서 시스템 레벨까지

## 🚩 플래그 정보

### Windows Lab
- User Flag: `RT{CMD_INJECTION_USER_FLAG_2025}`
- Privesc Flag: `RT{ALWAYS_INSTALL_ELEVATED_SUCCESS_2025}`
- Admin Flag: `RT{WINDOWS_FULL_COMPROMISE_ALWAYSINSTALLELEVATED_2025}`

### Linux Lab
- Auth Bypass: `RT{SQL_AUTH_BYPASS_2025}`
- Root Flag: `RT{ROOT_PRIVILEGE_ESCALATION_SUCCESS_2025}`

## ⚠️ 주의사항

- 이 랩은 **교육 목적**으로만 사용해야 합니다
- 실제 시스템에 대한 무단 침투 테스트는 불법입니다
- 모든 취약점은 **의도적으로 설계**된 것입니다

## 📖 문제 해결

일반적인 문제와 해결책:

1. **VirtualBox PATH 문제**: 스크립트가 자동으로 해결합니다
2. **Ansible Python 인터프리터**: inventory 파일에서 Python3 지정됨
3. **Windows WinRM 연결**: `StefanScherer/windows_2019` 박스 사용

---
**Happy Red Teaming! 🔴🛡️** 