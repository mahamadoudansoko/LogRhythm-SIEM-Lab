# ============================================================================
# Script de Test des Alarmes LogRhythm
# ============================================================================
# Description : Génère des scénarios d'attaque pour tester les alarmes
# ============================================================================

$LogFilePath = "C:\LogRhythmLogs\auth_logs"

# Fonction pour générer un log enrichi
function Generate-LogEntry {
    param(
        [string]$EventType,
        [string]$Username,
        [string]$Domain,
        [string]$SourceIP,
        [string]$HostName,
        [string]$ProcessName,
        [int]$ProcessID,
        [string]$SessionID,
        [string]$Status
    )
    
    $DateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $LogEntry = "$DateTime,$EventType,$Username,$Domain,$Username,$Domain,$SourceIP,$HostName,$ProcessName,$ProcessID,$SessionID,$Status"
    
    return $LogEntry
}

# Fonction pour afficher le menu
function Show-TestMenu {
    Clear-Host
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "          TEST DES ALARMES LOGRHYTHM - GÉNÉRATEUR D'ATTAQUES              " -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Fichier de sortie : $LogFilePath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Test ALARME 1 : 5 Failed Logins - MÊME utilisateur" -ForegroundColor Red
    Write-Host "2. Test ALARME 2 : 15 Failed Logins - PLUSIEURS utilisateurs (spray)" -ForegroundColor Red
    Write-Host "3. Test ALARME 1 + Succès : Attaque suivie d'une compromission" -ForegroundColor Magenta
    Write-Host "4. Test MIXTE : Activité normale + Attaque" -ForegroundColor Yellow
    Write-Host "5. Générer des logs normaux (baseline)" -ForegroundColor Green
    Write-Host "0. Quitter" -ForegroundColor White
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
}

# TEST ALARME 1 : 5 Failed Logins - Même utilisateur
function Test-Alarm1 {
    Clear-Host
    Write-Host "============================================================================" -ForegroundColor Red
    Write-Host "     TEST ALARME 1 : Brute Force Attack - 5 Failed Logins (admin)        " -ForegroundColor Red
    Write-Host "============================================================================" -ForegroundColor Red
    Write-Host ""
    
    $targetUser = Read-Host "Utilisateur cible (défaut: admin)"
    if ([string]::IsNullOrWhiteSpace($targetUser)) { $targetUser = "admin" }
    
    $attackerIP = Read-Host "IP de l'attaquant (défaut: 10.254.75.200)"
    if ([string]::IsNullOrWhiteSpace($attackerIP)) { $attackerIP = "10.254.75.200" }
    
    Write-Host ""
    Write-Host "[INFO] Génération de 5 tentatives échouées pour '$targetUser'..." -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 1; $i -le 5; $i++) {
        $log = Generate-LogEntry -EventType "Login" -Username $targetUser `
            -Domain "WIN-5JRTS511MJA" -SourceIP $attackerIP `
            -HostName "WORKSTATION01" -ProcessName "lsass.exe" `
            -ProcessID (Get-Random -Minimum 1000 -Maximum 9999) `
            -SessionID "0x$(Get-Random -Minimum 10000 -Maximum 99999)" `
            -Status "Failed"
        
        Add-Content -Path $LogFilePath -Value $log -Encoding UTF8
        Write-Host "[$i/5] $(Get-Date -Format 'HH:mm:ss') - $log" -ForegroundColor Red
        
        Start-Sleep -Seconds (Get-Random -Minimum 3 -Maximum 8)
    }
    
    Write-Host ""
    Write-Host "[SUCCÈS] 5 tentatives échouées générées !" -ForegroundColor Green
    Write-Host "[ATTENTE] L'alarme devrait se déclencher dans 30-60 secondes..." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Appuyez sur Entrée pour continuer"
}

# TEST ALARME 2 : 15 Failed Logins - Plusieurs utilisateurs
function Test-Alarm2 {
    Clear-Host
    Write-Host "============================================================================" -ForegroundColor Red
    Write-Host "     TEST ALARME 2 : Password Spray - 15 Failed Logins (différents)      " -ForegroundColor Red
    Write-Host "============================================================================" -ForegroundColor Red
    Write-Host ""
    
    $attackerIP = Read-Host "IP de l'attaquant (défaut: 10.254.75.201)"
    if ([string]::IsNullOrWhiteSpace($attackerIP)) { $attackerIP = "10.254.75.201" }
    
    $users = @(
        "admin", "administrator", "root", "user1", "user2", "john.doe", 
        "jane.smith", "test", "demo", "guest", "sysadmin", "backup",
        "operator", "support", "help"
    )
    
    Write-Host ""
    Write-Host "[INFO] Génération de 15 tentatives échouées (spray attack)..." -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt 15; $i++) {
        $targetUser = $users[$i]
        
        $log = Generate-LogEntry -EventType "Login" -Username $targetUser `
            -Domain "WIN-5JRTS511MJA" -SourceIP $attackerIP `
            -HostName "WORKSTATION02" -ProcessName "winlogon.exe" `
            -ProcessID (Get-Random -Minimum 1000 -Maximum 9999) `
            -SessionID "0x$(Get-Random -Minimum 10000 -Maximum 99999)" `
            -Status "Failed"
        
        Add-Content -Path $LogFilePath -Value $log -Encoding UTF8
        Write-Host "[$(($i+1))/15] $(Get-Date -Format 'HH:mm:ss') - Target: $targetUser" -ForegroundColor Red
        
        Start-Sleep -Seconds (Get-Random -Minimum 2 -Maximum 5)
    }
    
    Write-Host ""
    Write-Host "[SUCCÈS] 15 tentatives échouées générées (spray attack) !" -ForegroundColor Green
    Write-Host "[ATTENTE] L'alarme devrait se déclencher dans 30-60 secondes..." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Appuyez sur Entrée pour continuer"
}

# TEST ALARME 1 + Compromission
function Test-Alarm1WithSuccess {
    Clear-Host
    Write-Host "============================================================================" -ForegroundColor Magenta
    Write-Host "   TEST : Brute Force SUIVI de SUCCÈS (Compte Compromis Probable)        " -ForegroundColor Magenta
    Write-Host "============================================================================" -ForegroundColor Magenta
    Write-Host ""
    
    $targetUser = Read-Host "Utilisateur cible (défaut: admin)"
    if ([string]::IsNullOrWhiteSpace($targetUser)) { $targetUser = "admin" }
    
    $attackerIP = Read-Host "IP de l'attaquant (défaut: 10.254.75.202)"
    if ([string]::IsNullOrWhiteSpace($attackerIP)) { $attackerIP = "10.254.75.202" }
    
    Write-Host ""
    Write-Host "[PHASE 1] Génération de 7 tentatives échouées..." -ForegroundColor Yellow
    Write-Host ""
    
    # Phase 1 : 7 échecs
    for ($i = 1; $i -le 7; $i++) {
        $log = Generate-LogEntry -EventType "Login" -Username $targetUser `
            -Domain "WIN-5JRTS511MJA" -SourceIP $attackerIP `
            -HostName "LAPTOP-ATTACKER" -ProcessName "cmd.exe" `
            -ProcessID (Get-Random -Minimum 1000 -Maximum 9999) `
            -SessionID "0x$(Get-Random -Minimum 10000 -Maximum 99999)" `
            -Status "Failed"
        
        Add-Content -Path $LogFilePath -Value $log -Encoding UTF8
        Write-Host "[$i/7] $(Get-Date -Format 'HH:mm:ss') - Failed" -ForegroundColor Red
        
        Start-Sleep -Seconds (Get-Random -Minimum 3 -Maximum 8)
    }
    
    Write-Host ""
    Write-Host "[ALERTE] Alarme 1 devrait être déclenchée !" -ForegroundColor Red
    Write-Host ""
    Start-Sleep -Seconds 5
    
    Write-Host "[PHASE 2] Génération d'une connexion RÉUSSIE..." -ForegroundColor Magenta
    Write-Host ""
    
    # Phase 2 : 1 succès (COMPROMISSION)
    $logSuccess = Generate-LogEntry -EventType "Login" -Username $targetUser `
        -Domain "WIN-5JRTS511MJA" -SourceIP $attackerIP `
        -HostName "LAPTOP-ATTACKER" -ProcessName "cmd.exe" `
        -ProcessID (Get-Random -Minimum 1000 -Maximum 9999) `
        -SessionID "0x$(Get-Random -Minimum 10000 -Maximum 99999)" `
        -Status "Success"
    
    Add-Content -Path $LogFilePath -Value $logSuccess -Encoding UTF8
    Write-Host "[CRITIQUE] $(Get-Date -Format 'HH:mm:ss') - Success (COMPTE COMPROMIS!)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "[SUCCÈS] Scénario de compromission généré !" -ForegroundColor Green
    Write-Host "[INFO] Ceci devrait déclencher l'alarme 1 + une alerte de compromission" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Appuyez sur Entrée pour continuer"
}

# TEST MIXTE : Activité normale + Attaque
function Test-MixedActivity {
    Clear-Host
    Write-Host "============================================================================" -ForegroundColor Yellow
    Write-Host "        TEST MIXTE : Activité Normale + Attaque Camouflée                 " -ForegroundColor Yellow
    Write-Host "============================================================================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "[INFO] Génération d'activité mixte (30 événements)..." -ForegroundColor Yellow
    Write-Host ""
    
    $normalUsers = @("john.doe", "jane.smith", "ali.hamza", "mahamadou.dansoko")
    $attackerIP = "10.254.75.203"
    
    for ($i = 1; $i -le 30; $i++) {
        if ($i % 5 -eq 0) {
            # Toutes les 5 itérations : attaque sur admin
            $log = Generate-LogEntry -EventType "Login" -Username "admin" `
                -Domain "WIN-5JRTS511MJA" -SourceIP $attackerIP `
                -HostName "UNKNOWN" -ProcessName "powershell.exe" `
                -ProcessID (Get-Random -Minimum 1000 -Maximum 9999) `
                -SessionID "0x$(Get-Random -Minimum 10000 -Maximum 99999)" `
                -Status "Failed"
            
            Add-Content -Path $LogFilePath -Value $log -Encoding UTF8
            Write-Host "[$i/30] $(Get-Date -Format 'HH:mm:ss') - ATTAQUE: admin failed" -ForegroundColor Red
        }
        else {
            # Activité normale
            $user = Get-Random -InputObject $normalUsers
            $status = if ((Get-Random -Minimum 1 -Maximum 101) -le 90) { "Success" } else { "Failed" }
            
            $log = Generate-LogEntry -EventType "Login" -Username $user `
                -Domain "WIN-5JRTS511MJA" -SourceIP "10.254.75.189" `
                -HostName "WORKSTATION01" -ProcessName "winlogon.exe" `
                -ProcessID (Get-Random -Minimum 1000 -Maximum 9999) `
                -SessionID "0x$(Get-Random -Minimum 10000 -Maximum 99999)" `
                -Status $status
            
            Add-Content -Path $LogFilePath -Value $log -Encoding UTF8
            
            if ($status -eq "Success") {
                Write-Host "[$i/30] $(Get-Date -Format 'HH:mm:ss') - Normal: $user success" -ForegroundColor Green
            } else {
                Write-Host "[$i/30] $(Get-Date -Format 'HH:mm:ss') - Normal: $user failed" -ForegroundColor Yellow
            }
        }
        
        Start-Sleep -Seconds (Get-Random -Minimum 2 -Maximum 5)
    }
    
    Write-Host ""
    Write-Host "[SUCCÈS] Activité mixte générée (6 attaques camouflées parmi 24 normales)" -ForegroundColor Green
    Write-Host "[INFO] L'alarme 1 devrait se déclencher (6 > 5 échecs sur admin)" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Appuyez sur Entrée pour continuer"
}

# Générer des logs normaux
function Generate-NormalActivity {
    Clear-Host
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host "                GÉNÉRATION D'ACTIVITÉ NORMALE (BASELINE)                   " -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""
    
    $users = @("john.doe", "jane.smith", "ali.hamza", "mahamadou.dansoko", "ahmad", "aliou")
    
    Write-Host "[INFO] Génération de 20 événements normaux..." -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 1; $i -le 20; $i++) {
        $user = Get-Random -InputObject $users
        $eventType = Get-Random -InputObject @("Login", "Logout")
        $status = if ((Get-Random -Minimum 1 -Maximum 101) -le 95) { "Success" } else { "Failed" }
        
        $log = Generate-LogEntry -EventType $eventType -Username $user `
            -Domain "WIN-5JRTS511MJA" -SourceIP "10.254.75.189" `
            -HostName "WORKSTATION01" -ProcessName "winlogon.exe" `
            -ProcessID (Get-Random -Minimum 1000 -Maximum 9999) `
            -SessionID "0x$(Get-Random -Minimum 10000 -Maximum 99999)" `
            -Status $status
        
        Add-Content -Path $LogFilePath -Value $log -Encoding UTF8
        Write-Host "[$i/20] $(Get-Date -Format 'HH:mm:ss') - $user - $eventType - $status" -ForegroundColor Cyan
        
        Start-Sleep -Seconds 2
    }
    
    Write-Host ""
    Write-Host "[SUCCÈS] 20 événements normaux générés !" -ForegroundColor Green
    Write-Host ""
    Read-Host "Appuyez sur Entrée pour continuer"
}

# Menu principal
do {
    Show-TestMenu
    $choice = Read-Host "`nChoisissez une option"
    
    switch ($choice) {
        "1" { Test-Alarm1 }
        "2" { Test-Alarm2 }
        "3" { Test-Alarm1WithSuccess }
        "4" { Test-MixedActivity }
        "5" { Generate-NormalActivity }
        "0" { 
            Write-Host "`n[INFO] Arrêt du testeur d'alarmes..." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
        default {
            Write-Host "`n[ERREUR] Option invalide!" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($choice -ne "0")

Write-Host "`nMerci d'avoir utilisé le testeur d'alarmes LogRhythm !" -ForegroundColor Green
Write-Host "Au revoir!`n" -ForegroundColor Cyan
