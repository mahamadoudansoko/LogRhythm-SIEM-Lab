# ============================================================================
#  Generate-FirewallLogs-JSON.ps1 - VERSION STABLE
# ============================================================================

param(
    [string]$OutputFile = "C:\LogRhythmLogs\firewall_logs.json",
    [int]$IntervalSeconds = 5,
    [switch]$Continuous
)

# Configuration du dossier
$LogDir = Split-Path $OutputFile
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Données de simulation
$InternalIPs = @("10.0.1.10","10.0.1.11","10.0.1.20","10.254.75.100","10.254.75.189")
$ExternalIPs = @("203.0.113.5","198.51.100.10","185.220.101.45","91.108.4.1")
$Protocols = @("TCP","UDP","ICMP")
$Actions    = @("ALLOW","DENY","DROP")
$Firewalls  = @("FW-CORE-01","FW-EDGE-01")

$WellKnownPorts = @{ 80="HTTP"; 443="HTTPS"; 22="SSH"; 23="TELNET"; 3389="RDP"; 445="SMB"; 21="FTP"; 1433="MSSQL" }

# Fonctions techniques
function Get-RandomPort {
    param([switch]$KnownPort)
    if ($KnownPort -or (Get-Random -Min 0 -Max 3) -eq 0) {
        return @(80,443,22,23,3389,445,21,1433) | Get-Random
    }
    return Get-Random -Minimum 1024 -Maximum 65535
}

function New-FirewallLogEntry {
    param([string]$OverrideAction=$null, [string]$OverrideSrcIP=$null, [string]$OverrideDstIP=$null, [int]$OverrideDstPort=0)

    $ts      = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fff") + "Z"
    $action  = if ($OverrideAction) { $OverrideAction } else { $Actions | Get-Random }
    $srcIP   = if ($OverrideSrcIP)  { $OverrideSrcIP }  else { $InternalIPs | Get-Random }
    $dstIP   = if ($OverrideDstIP)  { $OverrideDstIP }  else { $ExternalIPs | Get-Random }
    $dstPrt  = if ($OverrideDstPort -gt 0) { $OverrideDstPort } else { Get-RandomPort }

    $entry = [ordered]@{
        timestamp        = $ts
        firewall_name    = $Firewalls | Get-Random
        action           = $action
        result           = if ($action -eq "ALLOW") { "Success" } else { "Failure" }
        status           = if ($action -eq "ALLOW") { "permitted" } else { "denied" }
        source_ip        = $srcIP
        destination_ip   = $dstIP
        destination_port = $dstPrt
        protocol         = "TCP"
        event_type       = if ($action -eq "ALLOW") { "firewall_allow" } else { "firewall_deny" }
    }
    return ($entry | ConvertTo-Json -Compress)
}

function Write-LogEntry {
    param([string]$JsonLine)
    Add-Content -Path $OutputFile -Value $JsonLine -Encoding UTF8
    Write-Host "[$(Get-Date -Format 'HH:mm:ss.fff')] $JsonLine" -ForegroundColor Cyan
}

# Options du Menu
function Invoke-Option3 {
    $attacker = "185.220.101.99"; $target = "10.0.1.20"
    Write-Host "--- TEST ALARME 1 : PORT SCAN ---" -ForegroundColor Red
    for ($i=20; $i -lt 70; $i++) {
        Write-LogEntry (New-FirewallLogEntry -OverrideAction "DENY" -OverrideSrcIP $attacker -OverrideDstIP $target -OverrideDstPort $i)
        Start-Sleep -Milliseconds 50
    }
}

function Invoke-Option4 {
    $src = "203.0.113.99"; $target = "10.0.1.30"
    Write-Host "--- TEST ALARME 2 : TRAFIC MASSIF ---" -ForegroundColor Red
    for ($i=1; $i -le 105; $i++) {
        Write-LogEntry (New-FirewallLogEntry -OverrideAction "DENY" -OverrideSrcIP $src -OverrideDstIP $target -OverrideDstPort 80)
        Start-Sleep -Milliseconds 30
    }
}

function Invoke-Option5 {
    $src = "185.220.101.77"
    Write-Host "--- TEST ALARME 3 : PORTS SENSIBLES ---" -ForegroundColor DarkRed
    foreach ($p in @(3389, 23, 21, 445)) {
        for ($j=0; $j -lt 3; $j++) {
            Write-LogEntry (New-FirewallLogEntry -OverrideAction "DENY" -OverrideSrcIP $src -OverrideDstPort $p)
            Start-Sleep -Milliseconds 100
        }
    }
}

# Menu Principal
do {
    Clear-Host
    Write-Host "=== GENERATEUR LOGRHYTHM - VERSION STABLE ===" -ForegroundColor Blue
    Write-Host "[3] Test Alarme 1 (Port Scan)"
    Write-Host "[4] Test Alarme 2 (Massive Blocked)"
    Write-Host "[5] Test Alarme 3 (Sensitive Ports)"
    Write-Host "[7] Vider le fichier log"
    Write-Host "[0] Quitter"
    $choice = Read-Host "`nChoisissez une option"

    switch ($choice) {
        "3" { Invoke-Option3; Read-Host "Fini. Entree..." }
        "4" { Invoke-Option4; Read-Host "Fini. Entree..." }
        "5" { Invoke-Option5; Read-Host "Fini. Entree..." }
        "7" { Set-Content -Path $OutputFile -Value $null; Write-Host "Fichier vide." }
        "0" { break }
    }
} while ($choice -ne "0")