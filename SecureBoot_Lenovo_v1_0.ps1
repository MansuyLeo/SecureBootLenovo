<#

Auteur: MANSUY Léo
Date: 03/05/2024
Version : 1.0
Description : Script d'activation du Secure Boot sur les ordinateurs Lenovo

Changelog v1.0 :

- Nouveaux modèles ThinkPad théoriques ajoutés
- Ajout vérification mot de passe BIOS 
- En commentaire sur la partie 6. : Détection du Platerform mode
- Ajout d'un pop-up lors de l'execution du script

#>

####Script#########

# Définir le chemin du fichier log
$logPath = "C:\Windows\Temp\Log_Script.txt"

# Effacer le contenu du fichier log au début du programme s'il existe
if (Test-Path $logPath) {
    # Effacer le contenu du fichier log
    Clear-Content -Path $logPath
}
# Fonction pour ajouter des logs
function Add-Log {
    param(
        [string]$message
    )

    # Obtenir la date et l'heure actuelles
    $dateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    # Construire le message avec la date et l'heure
    $logMessage = "$dateTime - $message"

    # Pour écrire dans un fichier avec l'encodage UTF-8
    Add-Content -Path $logPath -Value $logMessage
}

# Nécessaire pour l'affichage du pop-up
Add-Type -AssemblyName PresentationFramework

# Définition du message à afficher dans la boîte de dialogue
$message = "Le poste redemarrera a l'issue du script. Veuillez enregistrer tous vos documents en cours. Voulez-vous continuer?"

# Création de la boîte de dialogue avec deux boutons "Oui" et "Annuler"
$result = [System.Windows.MessageBox]::Show($message, "Confirmation", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)

# Vérification du bouton cliqué par l'utilisateur
if ($result -eq "Yes") {
    # Action si l'utilisateur clique sur "Oui"
    Write-Host "Demarrage du script..."

    # 1. Vérifier si le fabricant est Lenovo
    $manufacturer = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
    if ($manufacturer -notmatch "LENOVO") {
        Write-Host "Ce script est fonctionne uniquement sur les postes Lenovo. Le Fabricant actuel du poste est : $manufacturer"
        Add-Log "Fabricant: NOK Pas Lenovo ($manufacturer)"
        exit
    } else {
        Add-Log "Fabricant: OK Lenovo"
        }
 
    # 2. Vérifier si le mode BIOS est UEFI
    try {
        $uefi = Confirm-SecureBootUEFI
        Add-Log "Mode UEFI: OK"
    } catch {
        Write-Host "Le mode BIOS n'est pas UEFI ou le Secure Boot n'est pas disponible sur ce poste."
        Add-Log "Mode BIOS UEFI: NOK (ou Secure Boot non supporté)"
        exit
    }
 
    # 3. Vérifier l'état du Secure Boot
    if ($uefi) {
        Write-Host "Le Secure Boot est deja actif sur ce poste."
        Add-Log "Secure Boot: OK (déjà activé)"
        exit
    }else{
        Write-Host "Le Secure Boot n'est pas actif. Procedure d'activation en cours..."
        Add-Log "Procédure d'activation du Secure Boot en cours..."
    }

    # 4. Vérification si un mot de passe BIOS est présent
    $IsPasswordSet = (gwmi -Class Lenovo_BiosPasswordSettings -Namespace root\wmi).PasswordState

    If($IsPasswordSet -eq 1){
        Write-Host "Un mot de passe BIOS est present, arret du script"
        Add-Log "Mot de passe BIOS détecté, arrêt du script"
        Exit 1 }
 
    # 5. Vérifier l'état de BitLocker
    $bitLockerStatus = Get-BitLockerVolume -MountPoint "C:"
    if ($bitLockerStatus.ProtectionStatus -eq 'On') {
        # Suspendre BitLocker pour un redémarrage
        Suspend-BitLocker -MountPoint "C:" -RebootCount 1
        Write-Host "Suspension du BitLocker pour un redemarrage."
        Add-Log "BitLocker suspendu: OK"
    }else{
        Write-Host "BitLocker n'est pas actif ou est deja suspendu."
        Add-Log "BitLocker suspendu ou pas actif: OK"
    }

    <# 
	
	6. Vérification du Plateform mode Secure Boot (problèmes de faux positifs) NON INCLUS DANS LE SCRIPT POUR LE MOMENT
    $PlatformMode = (Get-SecureBootUEFI -Name SetupMode).Bytes
    # si le $PlatformMode = 1 le Secure Boot est en Setup Mode. si le PlatformMode = 0 le Secure Boot est en User Mode

    if ($PlatformMode -eq 1) {
        Write-Host "Le Secure Boot est en Setup Mode, faire le necessaire dans le BIOS pour qu'il soit en User Mode, arret du script"
        Add-Log "Platform mode = SETUP MODE: NOK, arrêt du script"
        exit 1
    }else{
        Write-Host "Le Secure Boot est en User Mode
        Add-Log "Platform mode = USER MODE: OK"
		
    #>
 
    # Liste des modèles et des commandes correspondantes pour activer le Secure Boot
    $modelCommands = @{
        "SecureBoot,Enable" = @("ThinkPad E15 Gen 2", "ThinkPad L380", "ThinkPad L14 Gen 3", "ThinkPad L14 Gen1", "ThinkPad L390", "ThinkPad X270 W10G", "ThinkPad E14 Gen 3", "ThinkPad L390 Yoga", "ThinkPad L470 W10DG", "ThinkPad L380 Yoga", "ThinkPad L14 Gen 1", "ThinkPad L14", "ThinkPad", "ThinkPad L470 W10DG", "ThinkPad P1 Gen 2", "ThinkPad P1 Gen 3", "ThinkPad T15 Gen 1", "ThinkPad T580", "ThinkPad X12 Detachable Gen 1", "ThinkPad E15 Gen 4", "ThinkPad L570 W10DG", "ThinkPad L580", "ThinkPad P50", "ThinkPad P53", "ThinkPad T580");
        "SecureBoot,Enabled" = @("ThinkCentre M75q Gen 2");
        "Secure Boot,Enabled" = @("ThinkStation P320", "ThinkCentre M715q", "ThinkCentre M710q", "P320", "ThinkStation P330", "ThinkStation P300", "ThinkStation P310");
    }
 
    # Récupérer la version du produit de l'ordinateur comme identifiant du modèle
    $modelVersion = Get-WmiObject Win32_ComputerSystemProduct | Select-Object -ExpandProperty Version
    Write-Host "Le modele est $modelVersion"
    Add-Log "Le modèle est $modelVersion"
 
    # Déterminer la commande à utiliser en fonction du modèle/version
    $secureBootCommand = "SecureBoot,Enable" # Valeur par défaut
    foreach ($command in $modelCommands.Keys) {
        if ($modelVersion -in $modelCommands[$command]) {
            $secureBootCommand = $command
            break
        }
    }

    # 7. Activer le Secure Boot sur les systèmes Lenovo
    try {
        $setResult = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("$secureBootCommand")
        if ($setResult.return -eq "Success") {
            Add-Log "SetBiosSetting $secureBootCommand : OK"
            Write-Host "Changement du parametre BIOS Secure Boot, Sauvegarde du changement en cours..."
        
            # Tenter de sauvegarder les paramètres du BIOS, si mot de passe BIOS, il faut remplir le champ dans SaveBiosSettings
            $saveResult = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings("")
            if ($saveResult.return -eq "Success") {
                Add-Log "SaveBiosSetting: OK"
                Write-Host "Succes de la sauvegarde du changement du parametre BIOS Secure Boot, redemarrage du poste dans 10 secondes..."
                Start-Sleep -Seconds 10
                Add-Log "Initialisation du redémarrage"
                Add-Log "Activation SecureBoot: OK"
                Restart-Computer -Force
            } else {
                Write-Host "Echec lors de la sauvegarde du changement du parametre BIOS Secure Boot"
                Add-Log "SaveBiosSetting: NOK"
                Add-Log "Activation SecureBoot: NOK"
            }
        } else {
            Write-Host "Echec lors du changement du parametre BIOS Secure Boot"
            Add-Log "SetBiosSetting $secureBootCommand : NOK"
            Add-Log "Activation SecureBoot: NOK"
        }
    } catch {
        Write-Host "Une erreur s'est produite lors de la tentative d'activation du Secure Boot"
        Add-Log "Activation SecureBoot: NOK"
    }
} else {
    # Action si l'utilisateur clique sur "NON" lors du pop-up
    Write-Host "Annulation du script"
    Add-Log "Script annulé par l'utilisateur lors du popup"
    exit
}

#
#
#
