# ============================================================================
#  Generate-FIM-Activity.ps1
#  Générateur d'activité fichiers pour tester les alarmes FIM LogRhythm
#  Répertoire surveillé : C:\FIM_TEST
# ============================================================================

param(
    [string]$FimDir = "C:\FIM_TEST"
)

# ============================================================================
#  CONFIGURATION
# ============================================================================
if (-not (Test-Path $FimDir)) {
    New-Item -ItemType Directory -Path $FimDir -Force | Out-Null
    Write-Host "[INFO] Dossier créé : $FimDir" -ForegroundColor Green
}

$Noms = @("rapport","analyse","config","backup","document","note",
          "log","data","export","import","user","admin","system",
          "audit","security","network","server","client","test","prod")

$Extensions = @(".txt",".log",".csv",".ini",".cfg",".dat",".bak")

function Get-RandomFileName {
    $nom = $Noms | Get-Random
    $ext = $Extensions | Get-Random
    $num = Get-Random -Min 1 -Max 999
    return "${nom}_${num}${ext}"
}

function Write-Status {
    param([string]$Msg, [string]$Color = "Cyan")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Msg" -ForegroundColor $Color
}

# ============================================================================
#  MENU
# ============================================================================
function Show-Menu {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Blue
    Write-Host "   GÉNÉRATEUR D'ACTIVITÉ FIM - LogRhythm File Monitor       " -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor Blue
    Write-Host "  Dossier surveillé : $FimDir" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [1] TEST ALARME ADD    - Créer 5 fichiers                 " -ForegroundColor Green
    Write-Host "  [2] TEST ALARME MODIFY - Modifier 5 fichiers existants    " -ForegroundColor Yellow
    Write-Host "  [3] TEST ALARME DELETE - Supprimer 5 fichiers             " -ForegroundColor Red
    Write-Host "  [4] TEST COMPLET       - ADD + MODIFY + DELETE en séquence" -ForegroundColor Magenta
    Write-Host "  [5] Activité continue  - Simulation réaliste (Ctrl+C)     " -ForegroundColor DarkCyan
    Write-Host "  [6] Nettoyer le dossier (tout supprimer)                  " -ForegroundColor DarkRed
    Write-Host "  [0] Quitter                                               " -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Blue
    return (Read-Host "  Choisissez une option")
}

# ============================================================================
#  OPTION 1 : TEST ALARME ADD - Créer des fichiers
# ============================================================================
function Invoke-TestAdd {
    param([int]$Count = 5)
    Write-Host "`n[ADD] Création de $Count fichiers dans $FimDir..." -ForegroundColor Green
    Write-Host "[INFO] Chaque création doit déclencher un événement FIM ADD" -ForegroundColor Yellow
    Write-Host ""

    $created = @()
    for ($i = 1; $i -le $Count; $i++) {
        $fileName = Get-RandomFileName
        $filePath = Join-Path $FimDir $fileName
        $content  = "Fichier de test FIM`nCréé le : $(Get-Date)`nNuméro : $i`nContenu aléatoire : $(Get-Random)"

        Set-Content -Path $filePath -Value $content -Encoding UTF8
        $created += $filePath
        Write-Status "[$i/$Count] CRÉÉ : $fileName" "Green"
        Start-Sleep -Milliseconds 800
    }

    Write-Host "`n[OK] $Count fichiers créés !" -ForegroundColor Green
    Write-Host "[ATTENTE] Vérifiez dans LogRhythm Investigator -> Common Event = File Monitoring Event - Add" -ForegroundColor Cyan
    Write-Host "[ATTENTE] L'alarme 'Add - Alerte FIM' devrait se déclencher..." -ForegroundColor Yellow
    return $created
}

# ============================================================================
#  OPTION 2 : TEST ALARME MODIFY - Modifier des fichiers
# ============================================================================
function Invoke-TestModify {
    param([int]$Count = 5)

    # Trouver des fichiers existants
    $existingFiles = Get-ChildItem -Path $FimDir -File -ErrorAction SilentlyContinue
    if ($existingFiles.Count -eq 0) {
        Write-Host "[INFO] Aucun fichier existant - création de fichiers d'abord..." -ForegroundColor Yellow
        Invoke-TestAdd -Count 3 | Out-Null
        Start-Sleep -Seconds 2
        $existingFiles = Get-ChildItem -Path $FimDir -File
    }

    Write-Host "`n[MODIFY] Modification de $Count fichiers dans $FimDir..." -ForegroundColor Yellow
    Write-Host "[INFO] Chaque modification doit déclencher un événement FIM MODIFY" -ForegroundColor Yellow
    Write-Host ""

    $toModify = $existingFiles | Get-Random -Count ([Math]::Min($Count, $existingFiles.Count))
    $idx = 1
    foreach ($file in $toModify) {
        $newContent = "MODIFIÉ le $(Get-Date)`nModification numéro : $idx`nNouvelle valeur : $(Get-Random -Min 1000 -Max 9999)"
        Add-Content -Path $file.FullName -Value "`n$newContent" -Encoding UTF8
        Write-Status "[$idx] MODIFIÉ : $($file.Name)" "Yellow"
        $idx++
        Start-Sleep -Milliseconds 800
    }

    Write-Host "`n[OK] $($toModify.Count) fichiers modifiés !" -ForegroundColor Green
    Write-Host "[ATTENTE] L'alarme 'Modify - Alerte FIM' devrait se déclencher..." -ForegroundColor Yellow
}

# ============================================================================
#  OPTION 3 : TEST ALARME DELETE - Supprimer des fichiers
# ============================================================================
function Invoke-TestDelete {
    param([int]$Count = 5)

    $existingFiles = Get-ChildItem -Path $FimDir -File -ErrorAction SilentlyContinue
    if ($existingFiles.Count -eq 0) {
        Write-Host "[INFO] Aucun fichier à supprimer - création de fichiers d'abord..." -ForegroundColor Yellow
        Invoke-TestAdd -Count 5 | Out-Null
        Start-Sleep -Seconds 2
        $existingFiles = Get-ChildItem -Path $FimDir -File
    }

    $toDelete = $existingFiles | Get-Random -Count ([Math]::Min($Count, $existingFiles.Count))

    Write-Host "`n[DELETE] Suppression de $($toDelete.Count) fichiers dans $FimDir..." -ForegroundColor Red
    Write-Host "[INFO] Chaque suppression doit déclencher un événement FIM DELETE" -ForegroundColor Yellow
    Write-Host ""

    $idx = 1
    foreach ($file in $toDelete) {
        Remove-Item -Path $file.FullName -Force
        Write-Status "[$idx] SUPPRIMÉ : $($file.Name)" "Red"
        $idx++
        Start-Sleep -Milliseconds 800
    }

    Write-Host "`n[OK] $($toDelete.Count) fichiers supprimés !" -ForegroundColor Green
    Write-Host "[ATTENTE] L'alarme 'Delete - Alerte FIM' devrait se déclencher..." -ForegroundColor Yellow
}

# ============================================================================
#  OPTION 4 : TEST COMPLET - Séquence ADD + MODIFY + DELETE
# ============================================================================
function Invoke-TestComplet {
    Write-Host "`n============================================================" -ForegroundColor Magenta
    Write-Host "  TEST COMPLET FIM - ADD + MODIFY + DELETE" -ForegroundColor Magenta
    Write-Host "============================================================`n" -ForegroundColor Magenta

    # PHASE 1 : ADD
    Write-Host "--- PHASE 1 : ADD (création de 5 fichiers) ---" -ForegroundColor Green
    $created = Invoke-TestAdd -Count 5
    Write-Host "[PAUSE] 5 secondes avant la phase MODIFY..." -ForegroundColor Gray
    Start-Sleep -Seconds 5

    # PHASE 2 : MODIFY
    Write-Host "`n--- PHASE 2 : MODIFY (modification de 5 fichiers) ---" -ForegroundColor Yellow
    Invoke-TestModify -Count 5
    Write-Host "[PAUSE] 5 secondes avant la phase DELETE..." -ForegroundColor Gray
    Start-Sleep -Seconds 5

    # PHASE 3 : DELETE
    Write-Host "`n--- PHASE 3 : DELETE (suppression de 3 fichiers) ---" -ForegroundColor Red
    Invoke-TestDelete -Count 3

    Write-Host "`n============================================================" -ForegroundColor Magenta
    Write-Host "  TEST COMPLET TERMINÉ !" -ForegroundColor Magenta
    Write-Host "  Vérifiez dans LogRhythm Console -> Alarms" -ForegroundColor Cyan
    Write-Host "  Les 3 alarmes (Add/Modify/Delete) devraient être visibles" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Magenta
}

# ============================================================================
#  OPTION 5 : Activité continue réaliste
# ============================================================================
function Invoke-ActiviteContinue {
    Write-Host "`n[INFO] Activité continue. Ctrl+C pour arrêter.`n" -ForegroundColor Cyan
    $counter = 0
    $filesInDir = @()

    while ($true) {
        $counter++
        $action = Get-Random -Min 1 -Max 10

        if ($action -le 4 -or $filesInDir.Count -eq 0) {
            # ADD (40% du temps ou si pas de fichiers)
            $fileName = Get-RandomFileName
            $filePath = Join-Path $FimDir $fileName
            Set-Content -Path $filePath -Value "Auto-generated $(Get-Date)" -Encoding UTF8
            $filesInDir += $filePath
            Write-Status "[$counter] ADD : $fileName" "Green"

        } elseif ($action -le 7 -and $filesInDir.Count -gt 0) {
            # MODIFY (30% du temps)
            $target = $filesInDir | Get-Random
            if (Test-Path $target) {
                Add-Content -Path $target -Value "Modified $(Get-Date)" -Encoding UTF8
                Write-Status "[$counter] MODIFY : $(Split-Path $target -Leaf)" "Yellow"
            }

        } else {
            # DELETE (30% du temps)
            $target = $filesInDir | Get-Random
            if (Test-Path $target) {
                Remove-Item -Path $target -Force
                $filesInDir = $filesInDir | Where-Object { $_ -ne $target }
                Write-Status "[$counter] DELETE : $(Split-Path $target -Leaf)" "Red"
            }
        }

        Start-Sleep -Seconds (Get-Random -Min 2 -Max 6)
    }
}

# ============================================================================
#  OPTION 6 : Nettoyer
# ============================================================================
function Invoke-Nettoyer {
    $confirm = Read-Host "Supprimer TOUS les fichiers de $FimDir ? (O/N)"
    if ($confirm -eq "O" -or $confirm -eq "o") {
        Get-ChildItem -Path $FimDir -File | Remove-Item -Force
        Write-Host "[OK] Dossier nettoyé." -ForegroundColor Green
    } else {
        Write-Host "[Annulé]" -ForegroundColor Gray
    }
}

# ============================================================================
#  BOUCLE PRINCIPALE
# ============================================================================
do {
    $choice = Show-Menu
    switch ($choice) {
        "1" { Invoke-TestAdd -Count 5; Read-Host "`nEntree pour continuer" }
        "2" { Invoke-TestModify -Count 5; Read-Host "`nEntree pour continuer" }
        "3" { Invoke-TestDelete -Count 5; Read-Host "`nEntree pour continuer" }
        "4" { Invoke-TestComplet; Read-Host "`nEntree pour continuer" }
        "5" { Invoke-ActiviteContinue }
        "6" { Invoke-Nettoyer; Read-Host "`nEntree pour continuer" }
        "0" { Write-Host "`nAu revoir !" -ForegroundColor Green; break }
        default { Write-Host "Option invalide." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($choice -ne "0")
