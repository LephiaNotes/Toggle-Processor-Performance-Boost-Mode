# Toggle Processor Performance Boost Mode (Disabled <-> Enabled)

# GUIDs
$subProcessor = "54533251-82be-4824-96c1-47b60b740d00"
$settingBoost = "be337238-0d82-4146-a960-4f3749d470c7"

# Get active scheme GUID only
$activeText = powercfg /getactivescheme
if ($activeText -match 'GUID:\s*([0-9a-fA-F\-]+)') {
    $schemeGuid = $Matches[1]
} else {
    Write-Error "Could not parse active power scheme GUID."
    exit 1
}
Write-Host "Active Power Scheme GUID: $schemeGuid"

# Query current setting text
$raw = powercfg /query $schemeGuid $subProcessor $settingBoost

# Extract AC/DC values safely
$acLine = ($raw | Select-String "Current AC Power Setting Index").ToString()
$dcLine = ($raw | Select-String "Current DC Power Setting Index").ToString()

$acHex = if ($acLine) { ($acLine -split "0x")[1].Trim() } else { $null }
$dcHex = if ($dcLine) { ($dcLine -split "0x")[1].Trim() } else { $null }

$ac = if ($acHex) { [convert]::ToInt32($acHex,16) } else { $null }
$dc = if ($dcHex) { [convert]::ToInt32($dcHex,16) } else { $null }

# Prefer AC if present, else DC
$currentValue = if ($null -ne $ac) { $ac } elseif ($null -ne $dc) { $dc } else { 0 }
Write-Host "Detected Boost Mode Value: $currentValue"

# Toggle: 0 -> 1, else -> 0
if ($currentValue -eq 0) {
    Write-Host "Current Boost Mode: Disabled. Enabling Boost Mode..."
    $newValue = 1
} else {
    Write-Host "Current Boost Mode: Enabled/Aggressive. Disabling Boost Mode..."
    $newValue = 0
}

# Apply to both AC/DC and re-activate scheme
powercfg /setacvalueindex $schemeGuid $subProcessor $settingBoost $newValue
powercfg /setdcvalueindex $schemeGuid $subProcessor $settingBoost $newValue
powercfg /S $schemeGuid

Write-Host "Boost Mode set to $newValue."
Write-Host "Processor Performance Boost Mode toggled successfully."
