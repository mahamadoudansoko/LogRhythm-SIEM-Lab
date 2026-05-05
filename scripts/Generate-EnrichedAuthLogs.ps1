# ============================================================================
# Script de Génération de Logs d'Authentification ENRICHIS pour LogRhythm
# ============================================================================
# Description : Génère des logs d'authentification au format CSV enrichi
#               Compatible avec les champs du parser Windows Event XML
# Version     : 2.0 (CSV Enrichi - 12 colonnes)
# ============================================================================

# Configuration
$LogFilePath = "C:\LogRhythmLogs\auth_logs"
$LogDirectory = "C:\LogRhythmLogs"

# Créer le répertoire s'il n'existe pas
if (-not (Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    Write-Host "[INFO] Répertoire créé : $LogDirectory" -ForegroundColor Green
}

# Initialiser le fichier avec l'en-tête enrichi s'il n'existe pas
$CsvHeader = "DateTime,EventType,SubjectUser,SubjectDomain,TargetUser,TargetDomain,SourceIP,HostName,ProcessName,ProcessID,SessionID,Status"

if (-not (Test-Path $LogFilePath)) {
    $CsvHeader | Out-File -FilePath $LogFilePath -Encoding UTF8
    Write-Host "[INFO] Fichier de log créé avec en-tête enrichi : $LogFilePath" -ForegroundColor Green
}

# Listes de données pour la génération aléatoire
$Usernames = @(
    "mahamadou.dansoko",
    "admin",
    "john.doe",
    "jane.smith",
    "ali.hamza",
    "guest",
    "root",
    "svc.backup",
    "svc.monitor",
    "ahmad",
    "aliou",
    "fatima.kane",
    "omar.diallo",
    "aissatou.ba",
    "administrator"
)

$Domains = @(
    "WIN-5JRTS511MJA",
    "WORKGROUP",
    "DOMAIN01",
    "LOCALHOST"
)

$SourceIPs = @(
    "10.254.75.189",  # IP principale (utilisateurs légitimes)
    "10.254.75.50",   # IP services
    "10.254.75.100",  # IP invités
    "10.254.75.101",
    "10.254.75.102",
    "10.254.75.103",
    "10.254.75.104",
    "10.254.75.200",  # IP suspectes
    "10.254.75.201",
    "10.254.75.202",
    "10.254.75.203",
    "10.254.75.204"
)

$HostNames = @(
    "WIN-5JRTS511MJA",
    "WORKSTATION01",
    "WORKSTATION02",
    "SERVER01",
    "LAPTOP-USER01"
)

$ProcessNames = @(
    "winlogon.exe",
    "lsass.exe",
    "svchost.exe",
    "explorer.exe",
    "powershell.exe",
    "cmd.exe",
    "taskmgr.exe",
    "services.exe",
    "rundll32.exe"
)

$EventTypes = @("Login", "Logout")
$Status = @("Success", "Failed")

# Fonction pour générer un Session ID aléatoire
function Generate-SessionID {
    $hex = "0x" + (Get-Random -Minimum 100000 -Maximum 999999).ToString("x")
    return $hex
}

# Fonction pour générer un Process ID aléatoire
function Generate-ProcessID {
    return Get-Random -Minimum 1000 -Maximum 9999
}

# Fonction pour générer un événement de log ENRICHI
function Generate-EnrichedLogEvent {
    param (
        [string]$EventType = "Random",
        [string]$SubjectUser = "Random",
        [string]$TargetUser = "Random",
        [string]$SourceIP = "Random",
        [string]$StatusValue = "Random"
    )
    
    # Sélection aléatoire si non spécifié
    if ($EventType -eq "Random") {
        $EventType = Get-Random -InputObject $EventTypes
    }
    
    if ($SubjectUser -eq "Random") {
        $SubjectUser = Get-Random -InputObject $Usernames
    }
    
    # Pour les logins normaux, SubjectUser = TargetUser
    if ($TargetUser -eq "Random") {
        if ((Get-Random -Minimum 1 -Maximum 101) -le 80) {
            # 80% du temps, c'est le même utilisateur
            $TargetUser = $SubjectUser
        } else {
            # 20% du temps, c'est un autre utilisateur (elevation, impersonation)
            $TargetUser = Get-Random -InputObject $Usernames
        }
    }
    
    # Domaines (généralement le même pour les deux)
    $SubjectDomain = Get-Random -InputObject $Domains
    if ((Get-Random -Minimum 1 -Maximum 101) -le 90) {
        $TargetDomain = $SubjectDomain
    } else {
        $TargetDomain = Get-Random -InputObject $Domains
    }
    
    if ($SourceIP -eq "Random") {
        $SourceIP = Get-Random -InputObject $SourceIPs
    }
    
    # Hostname
    $HostName = Get-Random -InputObject $HostNames
    
    # Process
    $ProcessName = Get-Random -InputObject $ProcessNames
    $ProcessID = Generate-ProcessID
    
    # Session ID
    $SessionID = Generate-SessionID
    
    if ($StatusValue -eq "Random") {
        # Logout est toujours Success dans un système normal
        if ($EventType -eq "Logout") {
            $StatusValue = "Success"
        } else {
            # 70% Success, 30% Failed pour les logins
            $StatusValue = if ((Get-Random -Minimum 1 -Maximum 101) -le 70) { "Success" } else { "Failed" }
        }
    }
    
    # Générer le timestamp actuel
    $DateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Créer la ligne de log enrichie (12 colonnes)
    $LogEntry = "$DateTime,$EventType,$SubjectUser,$SubjectDomain,$TargetUser,$TargetDomain,$SourceIP,$HostName,$ProcessName,$ProcessID,$SessionID,$StatusValue"
    
    return $LogEntry
}

# Fonction pour simuler une attaque par force brute
function Generate-BruteForceAttack {
    param (
        [int]$NumberOfAttempts = 5,
        [string]$TargetUsername = "admin",
        [string]$AttackerIP = "10.254.75.200"
    )
    
    Write-Host "`n[ALERTE] Simulation d'une attaque par force brute!" -ForegroundColor Red
    Write-Host "         Utilisateur cible : $TargetUsername" -ForegroundColor Yellow
    Write-Host "         IP attaquant      : $AttackerIP" -ForegroundColor Yellow
    Write-Host "         Tentatives        : $NumberOfAttempts`n" -ForegroundColor Yellow
    
    for ($i = 1; $i -le $NumberOfAttempts; $i++) {
        $LogEntry = Generate-EnrichedLogEvent -EventType "Login" -SubjectUser $TargetUsername -TargetUser $TargetUsername -SourceIP $AttackerIP -StatusValue "Failed"
        Add-Content -Path $LogFilePath -Value $LogEntry -Encoding UTF8
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $LogEntry" -ForegroundColor Red
        Start-Sleep -Seconds (Get-Random -Minimum 5 -Maximum 15)
    }
}

# Fonction pour afficher le menu
function Show-Menu {
    Clear-Host
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host "   GÉNÉRATEUR DE LOGS ENRICHIS (12 COLONNES) - LogRhythm SIEM           " -ForegroundColor Cyan
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Fichier de sortie : $LogFilePath" -ForegroundColor Yellow
    Write-Host "Format CSV : 12 colonnes (compatible Windows Event XML mapping)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Mode Automatique (génération continue toutes les 10-30 secondes)" -ForegroundColor Green
    Write-Host "2. Mode Manuel (générer un événement à la demande)" -ForegroundColor Green
    Write-Host "3. Simuler une attaque par force brute" -ForegroundColor Red
    Write-Host "4. Générer un lot d'événements (10 événements)" -ForegroundColor Green
    Write-Host "5. Afficher les 10 derniers logs" -ForegroundColor Cyan
    Write-Host "6. Afficher le format CSV (en-tête)" -ForegroundColor Cyan
    Write-Host "7. Réinitialiser le fichier de log" -ForegroundColor Yellow
    Write-Host "0. Quitter" -ForegroundColor White
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Cyan
}

# Fonction principale
function Start-LogGenerator {
    do {
        Show-Menu
        $choice = Read-Host "`nChoisissez une option"
        
        switch ($choice) {
            "1" {
                # Mode Automatique
                Clear-Host
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host "                        MODE AUTOMATIQUE ACTIVÉ                            " -ForegroundColor Cyan
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Génération de logs enrichis en cours... (Appuyez sur Ctrl+C pour arrêter)" -ForegroundColor Yellow
                Write-Host ""
                
                $counter = 0
                try {
                    while ($true) {
                        $counter++
                        $LogEntry = Generate-EnrichedLogEvent
                        Add-Content -Path $LogFilePath -Value $LogEntry -Encoding UTF8
                        
                        # Afficher avec couleur selon le statut
                        if ($LogEntry -like "*,Failed") {
                            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$counter] $LogEntry" -ForegroundColor Red
                        } elseif ($LogEntry -like "*Login*") {
                            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$counter] $LogEntry" -ForegroundColor Green
                        } else {
                            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$counter] $LogEntry" -ForegroundColor Cyan
                        }
                        
                        # Attendre entre 10 et 30 secondes
                        $waitTime = Get-Random -Minimum 10 -Maximum 31
                        Start-Sleep -Seconds $waitTime
                        
                        # Simuler occasionnellement une attaque (5% de chance)
                        if ((Get-Random -Minimum 1 -Maximum 101) -le 5) {
                            $attackerIP = Get-Random -InputObject @("10.254.75.200", "10.254.75.201", "10.254.75.202", "10.254.75.203", "10.254.75.204")
                            Generate-BruteForceAttack -NumberOfAttempts (Get-Random -Minimum 3 -Maximum 8) -TargetUsername "admin" -AttackerIP $attackerIP
                        }
                    }
                }
                catch {
                    Write-Host "`n`n[INFO] Mode automatique arrêté." -ForegroundColor Yellow
                    Read-Host "`nAppuyez sur Entrée pour continuer"
                }
            }
            
            "2" {
                # Mode Manuel
                Clear-Host
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host "                           MODE MANUEL                                     " -ForegroundColor Cyan
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host ""
                
                $LogEntry = Generate-EnrichedLogEvent
                Add-Content -Path $LogFilePath -Value $LogEntry -Encoding UTF8
                Write-Host "[SUCCÈS] Événement enrichi généré :" -ForegroundColor Green
                Write-Host "         $LogEntry" -ForegroundColor White
                Write-Host ""
                Read-Host "Appuyez sur Entrée pour continuer"
            }
            
            "3" {
                # Simuler attaque
                Clear-Host
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host "                   SIMULATION D'ATTAQUE PAR FORCE BRUTE                   " -ForegroundColor Cyan
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host ""
                
                $attempts = Read-Host "Nombre de tentatives (défaut: 5)"
                if ([string]::IsNullOrWhiteSpace($attempts)) { $attempts = 5 }
                
                $targetUser = Read-Host "Utilisateur cible (défaut: admin)"
                if ([string]::IsNullOrWhiteSpace($targetUser)) { $targetUser = "admin" }
                
                $attackIP = Read-Host "IP attaquant (défaut: 10.254.75.200)"
                if ([string]::IsNullOrWhiteSpace($attackIP)) { $attackIP = "10.254.75.200" }
                
                Generate-BruteForceAttack -NumberOfAttempts $attempts -TargetUsername $targetUser -AttackerIP $attackIP
                
                Write-Host "`n[SUCCÈS] Attaque simulée avec succès!" -ForegroundColor Green
                Read-Host "`nAppuyez sur Entrée pour continuer"
            }
            
            "4" {
                # Générer un lot
                Clear-Host
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host "                      GÉNÉRATION PAR LOT                                   " -ForegroundColor Cyan
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Génération de 10 événements enrichis..." -ForegroundColor Yellow
                Write-Host ""
                
                for ($i = 1; $i -le 10; $i++) {
                    $LogEntry = Generate-EnrichedLogEvent
                    Add-Content -Path $LogFilePath -Value $LogEntry -Encoding UTF8
                    Write-Host "[$i/10] $LogEntry" -ForegroundColor Green
                    Start-Sleep -Milliseconds 500
                }
                
                Write-Host "`n[SUCCÈS] 10 événements enrichis générés!" -ForegroundColor Green
                Read-Host "`nAppuyez sur Entrée pour continuer"
            }
            
            "5" {
                # Afficher les derniers logs
                Clear-Host
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host "                      10 DERNIERS ÉVÉNEMENTS                               " -ForegroundColor Cyan
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host ""
                
                if (Test-Path $LogFilePath) {
                    $lastLogs = Get-Content $LogFilePath -Tail 10
                    foreach ($log in $lastLogs) {
                        if ($log -like "*,Failed") {
                            Write-Host $log -ForegroundColor Red
                        } elseif ($log -like "*Login*") {
                            Write-Host $log -ForegroundColor Green
                        } elseif ($log -like "DateTime,*") {
                            Write-Host $log -ForegroundColor Yellow
                        } else {
                            Write-Host $log -ForegroundColor Cyan
                        }
                    }
                } else {
                    Write-Host "[ERREUR] Le fichier de log n'existe pas encore." -ForegroundColor Red
                }
                
                Write-Host ""
                Read-Host "Appuyez sur Entrée pour continuer"
            }
            
            "6" {
                # Afficher le format CSV
                Clear-Host
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host "                      FORMAT CSV ENRICHI (12 COLONNES)                     " -ForegroundColor Cyan
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "En-tête CSV :" -ForegroundColor Yellow
                Write-Host $CsvHeader -ForegroundColor White
                Write-Host ""
                Write-Host "Description des colonnes :" -ForegroundColor Yellow
                Write-Host "  1.  DateTime        : Timestamp (YYYY-MM-DD HH:MM:SS)" -ForegroundColor Cyan
                Write-Host "  2.  EventType       : Login ou Logout" -ForegroundColor Cyan
                Write-Host "  3.  SubjectUser     : Utilisateur source (qui fait l'action)" -ForegroundColor Cyan
                Write-Host "  4.  SubjectDomain   : Domaine de l'utilisateur source" -ForegroundColor Cyan
                Write-Host "  5.  TargetUser      : Utilisateur cible (sur qui l'action est faite)" -ForegroundColor Cyan
                Write-Host "  6.  TargetDomain    : Domaine de l'utilisateur cible" -ForegroundColor Cyan
                Write-Host "  7.  SourceIP        : Adresse IP source" -ForegroundColor Cyan
                Write-Host "  8.  HostName        : Nom de l'hôte/machine" -ForegroundColor Cyan
                Write-Host "  9.  ProcessName     : Nom du processus (ex: winlogon.exe)" -ForegroundColor Cyan
                Write-Host "  10. ProcessID       : ID du processus" -ForegroundColor Cyan
                Write-Host "  11. SessionID       : ID de session (format: 0xXXXXX)" -ForegroundColor Cyan
                Write-Host "  12. Status          : Success ou Failed" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "Exemple de ligne :" -ForegroundColor Yellow
                $exampleLog = Generate-EnrichedLogEvent
                Write-Host $exampleLog -ForegroundColor White
                Write-Host ""
                Read-Host "Appuyez sur Entrée pour continuer"
            }
            
            "7" {
                # Réinitialiser
                Clear-Host
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host "                    RÉINITIALISATION DU FICHIER                            " -ForegroundColor Cyan
                Write-Host "============================================================================" -ForegroundColor Cyan
                Write-Host ""
                
                $confirm = Read-Host "Êtes-vous sûr de vouloir réinitialiser le fichier de log? (O/N)"
                if ($confirm -eq "O" -or $confirm -eq "o") {
                    $CsvHeader | Out-File -FilePath $LogFilePath -Encoding UTF8
                    Write-Host "`n[SUCCÈS] Fichier réinitialisé avec le nouvel en-tête enrichi!" -ForegroundColor Green
                } else {
                    Write-Host "`n[INFO] Opération annulée." -ForegroundColor Yellow
                }
                
                Read-Host "`nAppuyez sur Entrée pour continuer"
            }
            
            "0" {
                Write-Host "`n[INFO] Arrêt du générateur de logs..." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
            
            default {
                Write-Host "`n[ERREUR] Option invalide!" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($choice -ne "0")
}

# Démarrer le script
Write-Host ""
Write-Host "Démarrage du générateur de logs enrichis..." -ForegroundColor Green
Write-Host "Format CSV : 12 colonnes (compatible mapping Windows Event XML)" -ForegroundColor Cyan
Start-Sleep -Seconds 1
Start-LogGenerator

Write-Host "`nMerci d'avoir utilisé le générateur de logs enrichis!" -ForegroundColor Green
Write-Host "Au revoir!`n" -ForegroundColor Cyan
