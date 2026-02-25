# Configurer le job Jenkins « Installation IFSF »

> **Construire les artefacts IFSF dans Jenkins** : pour créer le job qui **build** IFSF (type ReleasePackage-ITA0148-IFSF-TETRA) et publie les .7z, voir **[JENKINS_IFSF_BUILD_SETUP.md](JENKINS_IFSF_BUILD_SETUP.md)**.

Ce document décrit comment créer et configurer le pipeline Jenkins qui :

1. **Télécharge** le dernier build réussi (artefacts DevProxy, IFSF, XMLConfigDLL .7z) depuis un job Jenkins (**IFSF_JENKINS_URL**).
2. **Extrait** les archives, **sélectionne** les fichiers selon le type de terminal (TETRA / T2 / SELF), prépare le répertoire (fichiers pour **APPL_IFSF.MXX**).
3. **Installe** sur le terminal via **Local Upgrade** : envoi des fichiers *Package* vers `/package` et des fichiers *Import* (HOST) vers `/import`.

---

## 1. Créer la credential Jenkins (accès au Jenkins source des .7z)

Pour que le pipeline puisse télécharger les artefacts .7z, Jenkins a besoin d’un identifiant et d’un mot de passe (ou token API) pour accéder au job qui publie ces artefacts.

1. Dans Jenkins : **Manage Jenkins** → **Credentials** → **(Global)** → **Add Credentials**.
2. Choisir **Username with password**.
3. Renseigner :
   - **Username** : votre utilisateur Jenkins (ex. `eslem_hajamor`).
   - **Password** : votre mot de passe Jenkins (ou un **token API** : *Utilisateur* → *Configure* → *Add new Token*).
   - **ID** : `jenkins-ifsf-credentials` (ou un autre ID que vous indiquerez dans le paramètre **IFSF_CREDENTIALS_ID** du job).
   - **Description** : ex. « Jenkins user pour téléchargement IFSF ».
4. Valider avec **Create**.

> Ne mettez jamais le mot de passe en clair dans un fichier du dépôt. Utilisez toujours les **Credentials** Jenkins.

---

## 2. Créer le job Pipeline

1. **New Item** → nom (ex. `IFSF-Install-LocalUpgrade`) → **Pipeline** → OK.
2. Dans **Pipeline** :
   - **Definition** : **Pipeline script from SCM** (obligatoire — pas « Pipeline script » / script collé, sinon l’erreur *checkout scm is only available when using Pipeline script from SCM* apparaît).
   - **SCM** : **Git**.
   - **Repository URL** : l’URL de votre dépôt (contenant ce dossier de tests).
   - **Script Path** :  
     `QAtcher_v3 (2)/QAtcher_v3/2.28.0/Test_Infrastructure/Test Infrastructure delivery-2.3.0-1/resources/sample/tests/Jenkinsfile_IFSF_Install`
3. **Save**.

---

## 3. Paramètres du build

Lancer le job avec **Build with Parameters** et renseigner :

| Paramètre | Description | Exemple |
|-----------|-------------|---------|
| **IFSF_JENKINS_URL** | URL du job Jenkins qui **construit** IFSF et publie les 3 .7z (DevProxy, IFSF, XMLConfigDLL). **Pas** le job « IFSF-install » (installation / Local Upgrade). | `https://votre-jenkins/job/IFSF-Build/` |
| **QAtcherTerminalID** | ID du terminal QAtcher | `Move3500_54227826` |
| **IFSF_TERMINAL_TYPE** | Vide = déduit de l’ID (SELF si « SELF », T2 si « T2 », sinon TETRA). Sinon : TETRA, T2 ou SELF | *(vide)* ou `TETRA` |
| **QAtcherHost** | Hôte du serveur QAtcher | `localhost` |
| **QAtcherPort** | Port QAtcher | `8080` |
| **IFSF_CREDENTIALS_ID** | ID de la credential créée à l’étape 1 | `jenkins-ifsf-credentials` |

---

## 4. Prérequis sur l’agent Jenkins

- **7-Zip** (7z.exe) installé et dans le PATH (ou dans `C:\Program Files\7-Zip\`) pour extraire les .7z.
- **PowerShell** (Windows) ou **pwsh** (Linux) pour exécuter `download_ifsf_from_jenkins.ps1`.
- **Robot Framework** et **QAtcherLibrary** pour le test d’installation (Local Upgrade).
- **QAtcher** accessible depuis l’agent (QAtcherHost:QAtcherPort) et terminal connecté (QAtcherTerminalID).

---

## 5. Fichiers utilisés (rappel)

**Package (envoyés vers `/package`)** : selon le type de terminal, les fichiers DevProxy, IFSF et XMLConfigDLL sont choisis dans les archives (chemins GNU_ARM_RELEASE_TETRA, T2 ou SELF).

**Import (envoyés vers `/import`)** : 6 fichiers HOST (CRD_RQT, CRD_RSP, DVC_RQT, DVC_RSP, SVC_RQT, SVC_RSP) avec extension `.V0662` (TETRA/T2) ou `.V1662` (SELF).

Voir **IFSF_README.md** et **ifsf_config.ps1** pour le détail des chemins et variables.

---

## 6. En cas d’erreur 401 (téléchargement)

Si le téléchargement des .7z renvoie **401 Unauthorized** :

- Vérifier que la credential (IFSF_CREDENTIALS_ID) correspond bien à un utilisateur autorisé sur le Jenkins cible (IFSF_JENKINS_URL).
- Préférer un **token API** au mot de passe : dans le Jenkins source, *Utilisateur* → *Configure* → *Add new Token*, puis utiliser ce token comme **Password** dans la credential Jenkins.

Voir aussi **JENKINS_401_RESOLUTION.md**.

---

## 7. Erreur « checkout scm is only available when using Pipeline script from SCM »

Si le build échoue avec ce message, le job est configuré en **Pipeline script** (script collé) au lieu de **Pipeline script from SCM**.

**À faire :**
1. Ouvrir le job **IFSF-install** → **Configure**.
2. Section **Pipeline** → **Definition** : choisir **Pipeline script from SCM** (pas « Pipeline script »).
3. **SCM** : **Git**.
4. **Repository URL** : URL de votre dépôt Git (ex. `file:///C:/Users/eslem.hajamor/Desktop/...` ou une URL Git distante).
5. **Script Path** : `QAtcher_v3 (2)/QAtcher_v3/2.28.0/Test_Infrastructure/Test Infrastructure delivery-2.3.0-1/resources/sample/tests/Jenkinsfile_IFSF_Install`
6. **Save**, puis relancer un **Build**.
