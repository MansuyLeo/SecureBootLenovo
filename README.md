# Script PowerShell d'activation du Secure Boot sur les ordinateurs Lenovo

Ceci est un script d'automatisation qui permet d'activer le Secure Boot sur les ordinateurs Lenovo à l'aide de commandes spécifiques powershell.

## Instructions:

1. Télécharger le fichier run.bat et le fichier SecureBoot_Lenovo_v1.1.ps1
2. Lancez le fichier run.bat en tant qu'administrateur (le script .ps1 doit être dans le même dossier que le fichier .bat)

## Informations utiles:

- Le script peut être éxecutable en prise en main à distance, en session powershell ou directement sur le poste en question.
- Aucune action dans le BIOS est nécessaire, tout est fait automatiquement sur la session utilisateur. 
- Un redémarrage est forcé à la suite du script s'il est concluant.
- Un fichier log nommé "Log_Script.txt" sera crée dans le C:\Windows\Temp de l'utilisateur après l'éxecution du script qui peut être consulté en cas d'erreurs ou pour vérifier si le script a bien fonctionné.
- En cas d'erreurs, contact: MANSUY Léo - mansuy.leo.mz@gmail.com

Version tout public du script effectué lors de mon stage à la SNCF.

Script par MANSUY Léo.
