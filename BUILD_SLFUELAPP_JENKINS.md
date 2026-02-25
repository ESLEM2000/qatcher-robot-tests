# Build SLFuelApp sous Jenkins

Ce document décrit comment **SLFuelApp** est construit dans l’environnement Jenkins.

## Prérequis

- **IngeDev 8.22.0.6** : **sera fourni** (par Ingenico / votre organisation ou par l’environnement Jenkins). Voir [INSTALL_INGEDEV.md](INSTALL_INGEDEV.md) pour l’installer en local (répertoire recommandé : `C:\Ingenico\IngeDev_8.22.0.6`).

## Comment c’est construit sous Jenkins

Sur l’agent Jenkins, le build SLFuelApp s’effectue ainsi :

```batch
cd C:\Ingenico\IngeDev_8.22.0.6
.\antCmdLine.bat C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA C:\ProgramData\Jenkins\.jenkins\workspace\ReleasePackage-ITA0148-WLFA\BuildPackage\Ant\build.xml
```

- **IngeDev_8.22.0.6** est fourni sur l’agent (installation ou copie dans `C:\Ingenico\IngeDev_8.22.0.6`).
- Premier argument : workspace du package (**ReleasePackage-ITA0148-WLFA**).
- Deuxième argument : **build.xml** du job (dans le workspace Jenkins du job).

## Commande de build en local

### Option 1 : script PowerShell (recommandé)

Une fois IngeDev installé dans `C:\Ingenico\IngeDev_8.22.0.6` :

```powershell
.\build_slfuelapp_ingenico.ps1
```

Le script vérifie la présence d’IngeDev et de `antCmdLine.bat`, puis lance le build.

### Option 2 : commandes manuelles

Exécuter depuis un invité de commandes (ou une étape Jenkins) :

```batch
cd C:\Ingenico\IngeDev_8.22.0.6
.\antCmdLine.bat C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA C:\ProgramData\Jenkins\.jenkins\workspace\ReleasePackage-ITA0148-WLFA\BuildPackage\Ant\build.xml
```

## Paramètres

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| Répertoire IngeDev | `C:\Ingenico\IngeDev_8.22.0.6` | Installation IngeDev utilisée pour le build |
| Workspace IngeDev | `C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA` | Premier argument de `antCmdLine.bat` — workspace du package |
| Script Ant | `C:\ProgramData\Jenkins\.jenkins\workspace\ReleasePackage-ITA0148-WLFA\BuildPackage\Ant\build.xml` | Deuxième argument — fichier `build.xml` du job Jenkins |

## Résumé

- **Projet / package** : ReleasePackage-ITA0148-WLFA  
- **Outil** : IngeDev 8.22.0.6 (`antCmdLine.bat`)  
- **Build** : Ant, via le `build.xml` du workspace Jenkins.

---

*Document créé pour la Test Infrastructure — build SLFuelApp sous Jenkins.*
