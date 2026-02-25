# Installation IFSF depuis Jenkins (Local Upgrade)

## Récapitulation des étapes

**3 archives .7z** contiennent les fichiers nécessaires pour mettre à jour le logiciel IFSF sur le terminal.

1. **Téléchargement** – Récupération du dernier build réussi depuis Jenkins (artefacts **DevProxy**, **IFSF**, **XMLConfigDLL** en .7z), en définissant **IFSF_JENKINS_URL**.
2. **Extraction** – Les archives sont extraites (depuis **IFSF_BUILD_DIR** ou dossier de sortie du script).
3. **Sélection par type de terminal** – Les fichiers sont choisis selon le type (**TETRA** / **T2** / **SELF**), défini par **IFSF_TERMINAL_TYPE** ou déduit de **QAtcherTerminalID**.
4. **Répertoire de sortie** – Les fichiers sélectionnés sont copiés dans un répertoire unique (celui qui contiendra les fichiers prêts pour l’upgrade, équivalent **APPL_IFSF.MXX**).
5. **Installation** – Envoi vers le terminal via **Local Upgrade** : fichiers *Package* vers `/package`, fichiers *Import* vers `/import`.

À partir du contenu extrait, les fichiers sont choisis selon le **type de terminal** et copiés dans le répertoire de sortie principal (liste plate de noms de fichiers).

---

## Variables d'environnement

| Variable | Obligatoire | Description |
|----------|-------------|-------------|
| **IFSF_JENKINS_URL** | Oui (si pas IFSF_BUILD_DIR) | URL du job Jenkins qui **construit** IFSF et publie les 3 .7z (DevProxy, IFSF, XMLConfigDLL). **Pas** le job « IFSF-install » (installation / Local Upgrade). Ex: `https://jenkins.company.com/job/IFSF-Build/`. Utilisé pour `lastSuccessfulBuild`. |
| **IFSF_BUILD_DIR** | Optionnel | Dossier de sortie des fichiers préparés. Par défaut : `./IFSF_Build` (dans le répertoire des tests). Si déjà rempli (package.txt, import.txt, fichiers), le test Robot n’effectue pas le téléchargement. |
| **IFSF_TERMINAL_TYPE** | Optionnel | Type de terminal : `TETRA`, `T2` ou `SELF`. Sinon déduit de **QAtcherTerminalID** (voir ci‑dessous). |
| **QAtcherTerminalID** | Pour l’installation | ID du terminal (ex: `Move3500_54227826`). |

### Déduction du type de terminal à partir de QAtcherTerminalID

- **SELF** si l’ID contient `SELF`
- **T2** si l’ID contient `T2`
- **TETRA** sinon (ex: Move3500_54227826 → TETRA)

## Fichiers utilisés par type de terminal

**Package (envoyés vers `/package`) :**

| Composant     | TETRA | T2 | SELF |
|---------------|-------|-----|------|
| DevProxy      | `Bin/GNU_ARM_RELEASE_TETRA/8515360465_DEV_PROXY.P3A` | `Bin/GNU_ARM_RELEASE_T2/8515360465.AGN` | `Bin/GNU_ARM_RELEASE_SELF/8515361465_DEV_PROXY.P3A` |
| IFSF          | `Bin/GNU_ARM_RELEASE_TETRA/8226760662_IFSF_0662.P3A` | `Bin/GNU_ARM_RELEASE_T2/8226760662.AGN` | `Bin/GNU_ARM_RELEASE_SELF/8226761662_IFSF_1662.P3A` |
| XMLConfigDLL  | `Bin/GNU_ARM_RELEASE_TETRA/8226750662_XMLCFG_DLL.P3L` | `Bin/GNU_ARM_RELEASE_T2/8226750662.LGN` | `Bin/GNU_ARM_RELEASE_SELF/8226751662_XMLCFG_DLL.P3L` |

**Import (envoyés vers `/import`) :**  
6 fichiers HOST (dossier HOST de l’archive XMLConfigDLL) : **CRD_RQT, CRD_RSP, DVC_RQT, DVC_RSP, SVC_RQT, SVC_RSP**  
- TETRA / T2 : extension **.V0662**  
- SELF : extension **.V1662**

## Scripts et test

- **ifsf_config.ps1** – Configuration et mapping des fichiers (sourcé par les autres scripts).
- **download_ifsf_from_jenkins.ps1** – Télécharge les 3 .7z depuis Jenkins, extrait (7-Zip requis), sélectionne les fichiers, remplit un répertoire de sortie et crée `package.txt` / `import.txt`.
- **Install_IFSF_From_Jenkins.robot** – Test Robot : si `IFSF_BUILD_DIR` est vide, lance le script de téléchargement ; puis Local Upgrade (connexion, envoi /package et /import, déconnexion, attente du terminal).
- **install_ifsf_from_jenkins.ps1** – Lance le test Robot avec les variables adaptées (optionnellement avec un `IFSF_BUILD_DIR` déjà préparé).
- **Jenkinsfile_IFSF_Install** – Pipeline Jenkins : téléchargement du dernier build (DevProxy, IFSF, XMLConfigDLL .7z) puis installation sur le terminal via Local Upgrade. Voir **JENKINS_IFSF_SETUP.md** pour créer le job et configurer les credentials.
- **Jenkinsfile_IFSF_Build** – Pipeline Jenkins pour le **build** IFSF (type ReleasePackage-ITA0148-IFSF-TETRA) : checkout ita-emb-app-ifsf, build, publication des .7z. Voir **JENKINS_IFSF_BUILD_SETUP.md** pour créer ce job dans votre Jenkins.

## Prérequis

- **7-Zip** (7z.exe) installé et dans le PATH (ou dans `C:\Program Files\7-Zip\`), pour l’extraction des .7z.
- Serveur **QAtcher** accessible (ex: localhost:8080).
- **Robot Framework** et **QAtcherLibrary** pour l’exécution du test.

## Trouver le bon job Jenkins (IFSF_JENKINS_URL)

IFSF_JENKINS_URL doit pointer vers le job qui **construit** IFSF et publie les 3 .7z (DevProxy, IFSF, XMLConfigDLL), **pas** vers le job IFSF-install. Pour le trouver : executer `.\find_ifsf_jenkins_job.ps1` (avec JENKINS_USER/JENKINS_PASSWORD si besoin). Le script affiche l'URL a utiliser.

## Utilisation

1. Définir l’URL Jenkins (une fois par session ou dans l’environnement) :
   ```powershell
   $env:IFSF_JENKINS_URL = "https://jenkins.company.com/job/IFSF-Build/"
   ```

2. Lancer l’installation (téléchargement + Local Upgrade) :
   ```powershell
   .\install_ifsf_from_jenkins.ps1 -QAtcherTerminalID Move3500_54227826
   ```

3. Ou seulement préparer les fichiers (sans installer sur le terminal) :
   ```powershell
   .\download_ifsf_from_jenkins.ps1 -QAtcherTerminalID Move3500_54227826
   ```
   Puis installer plus tard en passant le dossier :
   ```powershell
   .\install_ifsf_from_jenkins.ps1 -QAtcherTerminalID Move3500_54227826 -IFSF_BUILD_DIR .\IFSF_Build
   ```

4. Ou exécuter uniquement le test Robot (avec répertoire déjà préparé) :
   ```bash
   robot --variable "QAtcherTerminalID:Move3500_54227826" --variable "IFSF_BUILD_DIR:./IFSF_Build" --test "Install IFSF From Jenkins" Install_IFSF_From_Jenkins.robot
   ```

## Artefacts Jenkins

Par défaut, le script cherche des artefacts dont le nom correspond à :  
**DevProxy\*.7z**, **IFSF\*.7z**, **XMLConfigDLL\*.7z**.  
Pour d’autres noms, définir les variables d’environnement :  
**IFSF_ARTIFACT_DEVPROXY**, **IFSF_ARTIFACT_IFSF**, **IFSF_ARTIFACT_XMLCONFIGDLL** (motifs ou noms exacts).
