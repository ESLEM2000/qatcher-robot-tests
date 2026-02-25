# Installation d’IngeDev 8.22.0.6

**IngeDev** est l’environnement de développement propriétaire **Ingenico**. Il n’est pas disponible en téléchargement public ; il est **fourni** par Ingenico (ou votre organisation) aux partenaires et équipes projet. Le package fourni contient déjà **`antCmdLine.bat`** à la racine du dossier d’installation ; inutile de le créer à partir d’un autre fichier.

Lorsque IngeDev est fourni par votre organisation, le package est en général **complet** (antCmdLine.bat et tous les composants nécessaires, dont les outils appelés par le script, par ex. lltc) et prêt pour le build en ligne de commande.

## Pourquoi on ne peut pas l’installer automatiquement

- Logiciel **propriétaire** Ingenico.
- Distribution via le **portail développeur** ou par votre contact Ingenico / IT.
- Aucun installateur public ou script d’installation dans ce dépôt.

## Si IngeDev n’est pas trouvé

Exécutez le script de préparation (depuis le dossier des tests) :

```powershell
.\setup_ingedev.ps1
```

Ce script :
- crée les dossiers `C:\Program Files\Ingenico\IngeDev_8.22.0.6` et `C:\Ingenico\IngeDev_8.22.0.6` ;
- recherche une installation existante (antCmdLine.bat) ;
- affiche les instructions pour copier ou installer IngeDev.

Le script **build_slfuelapp_ingenico.ps1** cherche ensuite IngeDev à plusieurs emplacements (et via la variable d’environnement `INGEDEV_ROOT`), donc pas besoin de modifier le script si vous installez au bon endroit.

---

## Comment obtenir et installer IngeDev

### 1. Obtenir le package (trois options)

#### Option A — Demander à votre IT / équipe Jenkins

- **Qui contacter** : équipe IT, équipe CI/CD ou toute équipe qui gère les jobs Jenkins (ex. ReleasePackage-ITA0148-WLFA). Ils ont en général IngeDev sur les agents de build.
- **Que demander** : « Je dois installer IngeDev 8.22.0.6 sur ma machine pour le build SLFuelApp. Pouvez-vous me fournir le package d’installation ou l’accès au dossier d’installation (contenant `antCmdLine.bat`) ? »
- **Format possible** : lien de téléchargement interne, partage réseau (UNC), ou copie du dossier `IngeDev_8.22.0.6` depuis un agent Jenkins.

#### Option B — Portail développeur Ingenico

- **URL** : [https://developer.ingenico.com/download](https://developer.ingenico.com/download)  
- **Accès** : réservé aux comptes partenaires (Solution Partner Program). Si vous n’avez pas de compte, faire demander un accès par votre organisation ou contacter Ingenico.
- **Sur le portail** : se connecter, chercher **IngeDev** (ou « IDE », « SDK »), télécharger la version **8.22.0.6** si disponible. Suivre ensuite l’assistant d’installation fourni par Ingenico, ou extraire/copier les fichiers vers `C:\Ingenico\IngeDev_8.22.0.6` (ou `C:\Program Files\Ingenico\IngeDev_8.22.0.6`) en vous assurant que **`antCmdLine.bat`** se trouve à la racine de ce dossier.

#### Option C — Copier depuis une machine où IngeDev est déjà installé

- **Sur la machine source** (autre PC, poste d’un collègue, ou agent Jenkins) : repérer le dossier d’installation, par exemple :
  - `C:\Ingenico\IngeDev_8.22.0.6`
  - `C:\Program Files\Ingenico\IngeDev_8.22.0.6`
- **Vérifier** que le dossier contient **`antCmdLine.bat`** à la racine.
- **Copier** tout le dossier **`IngeDev_8.22.0.6`** (avec son contenu) vers votre machine, par exemple :
  - clé USB ou disque externe ;
  - partage réseau (ex. `\\serveur\partage\IngeDev_8.22.0.6`) ;
  - outil de transfert (OneDrive, partage interne, etc.).
- **Sur votre machine** : placer le dossier copié dans `C:\Ingenico\` ou `C:\Program Files\Ingenico\` pour obtenir au final :
  - `C:\Ingenico\IngeDev_8.22.0.6\antCmdLine.bat`
  - ou `C:\Program Files\Ingenico\IngeDev_8.22.0.6\antCmdLine.bat`
- **Droits** : si vous copiez vers `C:\Program Files\Ingenico\`, exécuter l’explorateur ou PowerShell en **administrateur** pour pouvoir écrire dans ce dossier.

### 2. Installer au bon emplacement

Deux emplacements possibles :

| Emplacement | Chemin complet |
|-------------|----------------|
| **Recommandé (dossier Ingenico)** | `C:\Program Files\Ingenico\IngeDev_8.22.0.6` |
| **Alternatif** | `C:\Ingenico\IngeDev_8.22.0.6` |

- Créer le dossier parent (`C:\Program Files\Ingenico` ou `C:\Ingenico`) si besoin, puis y placer **IngeDev 8.22.0.6** dans le sous-dossier `IngeDev_8.22.0.6`. Le package fourni inclut déjà **`antCmdLine.bat`** à la racine.
- Vérifier que le fichier **`antCmdLine.bat`** est bien présent à la racine de ce répertoire.
- Vérifier que l’installation est complète (voir ci-dessous).

#### Installation complète et composant lltc

L’installation doit être **complète** : **`antCmdLine.bat`** utilise d’autres composants (par ex. **`lltc`**). En cas de message *« lltc n’est pas reconnu en tant que commande interne ou externe »*, le dossier est incomplet et il faut obtenir le **package IngeDev complet**.

**Comment s’assurer d’avoir l’installation complète :**

1. **Demander le package complet** à votre IT ou à Ingenico : préciser « package IngeDev 8.22.0.6 **complet** pour build en ligne de commande (avec `antCmdLine.bat` et tous les composants, dont les outils appelés par ce script) », ou demander une **copie du dossier entier** depuis un poste ou un agent Jenkins où le build SLFuelApp/ReleasePackage fonctionne déjà.
### 3. Vérifier l’installation

2. **Lors d’une copie** : copier **tout** le dossier `IngeDev_8.22.0.6` (tous les sous-dossiers et fichiers), pas seulement `antCmdLine.bat`. Ne pas omettre de dossiers cachés ou système si l’explorateur les affiche.
3. **Vérifier** : après copie, le dossier doit contenir de nombreux fichiers et sous-dossiers (outils, librairies, etc.). Si le dossier ne contient qu’un ou deux fichiers, l’installation est incomplète.

### 3. Vérifier l’installation

Dans PowerShell (adapter le chemin selon l’emplacement choisi) :

```powershell
# Si installé dans C:\Program Files\Ingenico
Test-Path "C:\Program Files\Ingenico\IngeDev_8.22.0.6\antCmdLine.bat"

# Ou si installé dans C:\Ingenico
Test-Path "C:\Ingenico\IngeDev_8.22.0.6\antCmdLine.bat"
```

Le résultat doit être `True`.

### 4. Lancer le build (ligne de commande)

**Si IngeDev est dans `C:\Program Files\Ingenico` :**

```powershell
cd "C:\Program Files\Ingenico\IngeDev_8.22.0.6"
.\antCmdLine.bat C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA C:\ProgramData\Jenkins\.jenkins\workspace\ReleasePackage-ITA0148-WLFA\BuildPackage\Ant\build.xml
```

**Si IngeDev est dans `C:\Ingenico` :**

```powershell
cd C:\Ingenico\IngeDev_8.22.0.6
.\antCmdLine.bat C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA C:\ProgramData\Jenkins\.jenkins\workspace\ReleasePackage-ITA0148-WLFA\BuildPackage\Ant\build.xml
```

#### Lancer depuis CMD (invite de commandes Windows)

En **CMD**, mettez les deux arguments entre guillemets pour éviter les erreurs de parsing :

```cmd
cd /d C:\Ingenico\IngeDev_8.22.0.6
antCmdLine.bat "C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA" "C:\ProgramData\Jenkins\.jenkins\workspace\ReleasePackage-ITA0148-WLFA\BuildPackage\Ant\build.xml"
```

- Utilisez **`cd /d`** pour changer de lecteur si besoin.
- Si le chemin du `build.xml` ou du workspace n’existe pas sur votre machine (par ex. vous n’êtes pas sur l’agent Jenkins), copiez le workspace et le dossier `BuildPackage\Ant` localement et adaptez les chemins dans la commande.

### 5. Lancer le build SLFuelApp (script PowerShell)

Une fois IngeDev en place :

```powershell
.\build_slfuelapp_ingenico.ps1
```

Si IngeDev est dans un emplacement non reconnu, définir la variable d’environnement avant de lancer le build :

```powershell
$env:INGEDEV_ROOT = "C:\Chemin\Vers\IngeDev_8.22.0.6"
.\build_slfuelapp_ingenico.ps1
```

---

*Document Test Infrastructure — installation IngeDev pour le build SLFuelApp.*
