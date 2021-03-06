function Install-KiwiPrinter {

    param (
        [Parameter(Mandatory=$false, HelpMessage="Path to the custom 32-bit DLL.")]
        [String]$DLL32,

        [Parameter(Mandatory=$false, HelpMessage="Path to the custom 64-bit DLL.")]
        [String]$DLL64
    )

    $printerName     = 'Kiwi Legit Printer'
    $system32        = $env:systemroot + '\system32'
    $drivers         = $system32 + '\spool\drivers'
    $RegStartPrinter = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers\' + $printerName
    $tmpFolder       = '.\tmp'

    if ( $DLL32 -And $DLL64 ) {
        Copy-Item -Force -Path $DLL64   -Destination ($drivers  + '\x64\3\mimispool.dll')
        Copy-Item -Force -Path $DLL32 -Destination ($drivers  + '\W32X86\3\mimispool.dll')
    } else {
        New-Item -Path $tmpFolder -ItemType "Directory" -Force | Out-Null

        $DLL32 = "$tmpFolder\mimispool32.dll"
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/xbufu/Mimispool/main/dll/mimispool32.dll' -OutFile $DLL32

        $DLL64 = "$tmpFolder\mimispool64.dll"
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/xbufu/Mimispool/main/dll/mimispool64.dll' -OutFile $DLL64
    }

    Copy-Item -Force -Path ($system32 + '\mscms.dll')             -Destination ($system32 + '\mimispool.dll')
    Copy-Item -Force -Path $DLL64   -Destination ($drivers  + '\x64\3\mimispool.dll')
    Copy-Item -Force -Path $DLL32 -Destination ($drivers  + '\W32X86\3\mimispool.dll')

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

    if ( Test-Path -Path $tmpFolder ) {
        Remove-Item -Recurse -Force $tmpFolder
    }
}

function Uninstall-KiwiPrinter {
    $printerName     = 'Kiwi Legit Printer'
    $system32        = $env:systemroot + '\system32'
    $drivers         = $system32 + '\spool\drivers'

    Remove-Printer       -Name $printerName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Remove-PrinterDriver -Name 'Generic / Text Only' -ErrorAction SilentlyContinue

    Remove-Item -Force -Path ($drivers  + '\x64\3\mimispool.dll') -ErrorAction SilentlyContinue
    Remove-Item -Force -Path ($drivers  + '\W32X86\3\mimispool.dll') -ErrorAction SilentlyContinue
    Remove-Item -Force -Path ($system32 + '\mimispool.dll') -ErrorAction SilentlyContinue
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
    Remove-Printer -Name $fullprinterName -ErrorAction SilentlyContinue
    Remove-PrinterDriver -Name $driver -ErrorAction SilentlyContinue
    Uninstall-KiwiPrinter
}
