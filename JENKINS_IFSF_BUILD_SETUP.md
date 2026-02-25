# Créer le job Jenkins « Build IFSF » (ReleasePackage-ITA0148-IFSF-TETRA)

Ce document décrit comment créer **dans votre Jenkins** le job qui **construit** IFSF et publie les artefacts .7z (DevProxy, IFSF_Lib, IFSF, XMLConfigDLL, XMLConfigLib), comme sur la capture d’écran **ReleasePackage-ITA0148-IFSF-TETRA** (#316).

Une fois ce job en place, le job **IFSF-install** (voir **JENKINS_IFSF_SETUP.md**) pourra récupérer le dernier build réussi (Copy Artifacts ou IFSF_JENKINS_URL) pour installer IFSF sur le terminal.

---

## 1. Prérequis

- **Jenkins** avec le plugin **Pipeline** et **Git**.
- **Credential** pour cloner le dépôt (si privé) : **Manage Jenkins** → **Credentials** → **Add** (Git SSH key ou Username/Password). Noter l’**ID** (ex. `github-ita-emb-app`).
- Sur l’**agent** qui exécutera le build : **Ant** (ou la commande de build utilisée par le dépôt ita-emb-app-ifsf), **Git**, et tout outil requis par le projet (ex. IngeDev si le build le demande).

---

## 2. Créer le job Pipeline

1. **Tableau de bord Jenkins** → **New Item**.
2. **Nom** : `ReleasePackage-ITA0148-IFSF-TETRA` (ou `IFSF-Build`).
3. Choisir **Pipeline** → **OK**.

---

## 3. Configurer le pipeline (Pipeline script from SCM)

1. Section **Pipeline** :
   - **Definition** : **Pipeline script from SCM**.
   - **SCM** : **Git**.
   - **Repository URL** : `https://github.com/ESLEM2000/qatcher-robot-tests.git` (préférer **HTTPS** pour éviter « Host key verification failed » en SSH).
   - **Credentials** : credential Jenkins (Username + Password ou token GitHub) si le dépôt est privé.
   - **Branche** : `*/main` (ou la branche qui contient le Jenkinsfile).
   - **Script Path** :  
     `resources/sample/tests/Jenkinsfile_IFSF_Build`  
     (adapter si votre dépôt a un autre chemin, ex. `QAtcher_v3 (2)/QAtcher_v3/2.28.0/Test_Infrastructure/Test Infrastructure delivery-2.3.0-1/resources/sample/tests/Jenkinsfile_IFSF_Build`).

2. **Save**.

Ainsi, Jenkins charge le **Jenkinsfile_IFSF_Build** depuis ce dépôt. Le pipeline lui-même fait un **checkout** du dépôt **ita-emb-app-ifsf** (paramètre **GIT_REPO_URL**) dans le workspace, puis lance le build et archive les **\*\*/\*.7z**.

---

## 4. Paramètres du build (Build with Parameters)

Lancer le job avec **Build with Parameters** et renseigner :

| Paramètre | Valeur recommandée | Description |
|-----------|---------------------|-------------|
| **GIT_REPO_URL** | `git@github.com:worldlineMSITA/ita-emb-app-ifsf.git` | Dépôt à construire (celui qui produit les .7z). |
| **GIT_BRANCH** | `main` | Branche à construire. |
| **GIT_CREDENTIALS_ID** | ID de la credential Git (ex. `github-ita-emb-app`) | Obligatoire si le dépôt est privé. |
| **BUILD_COMMAND** | *(vide ou commande spécifique)* | Commande de build (ex. `ant -f BuildPackage\Ant\build.xml`, ou `call build.bat`). Si vide, le pipeline tente `ant -f build.xml` ou `BuildPackage\Ant\build.xml` / `build.bat`. Si votre projet utilise une autre commande, la renseigner ici. |

Si le dépôt ita-emb-app-ifsf utilise **IngeDev** (antCmdLine.bat) ou un script particulier, demander à l’équipe la commande exacte et la mettre dans **BUILD_COMMAND**.

---

## 5. Résultat attendu

- **Checkout** : clone de ita-emb-app-ifsf dans le workspace.
- **Build** : exécution de la commande de build (Ant ou BUILD_COMMAND).
- **Archive** : publication des artefacts **\*\*/\*.7z** (DevProxy, IFSF_Lib, IFSF, XMLConfigDLL, XMLConfigLib).

Le job **IFSF-install** pourra ensuite :

- Soit utiliser **Copy Artifacts** depuis ce job (paramètre **IFSF_JENKINS_JOB_NAME** = `ReleasePackage-ITA0148-IFSF-TETRA` ou `IFSF-Build`).
- Soit utiliser **IFSF_JENKINS_URL** = `http://votre-jenkins/job/ReleasePackage-ITA0148-IFSF-TETRA/` pour télécharger les .7z du dernier build réussi.

---

## 6. Dépôt sans Jenkinsfile dans ce repo (script collé)

Si vous ne voulez pas utiliser « Pipeline script from SCM » avec le dépôt des tests :

1. **Definition** : **Pipeline script** (script collé).
2. Ouvrir le fichier **Jenkinsfile_IFSF_Build** dans ce dossier, copier tout le contenu, le coller dans le champ **Script**.
3. **Save**. À chaque **Build with Parameters**, renseigner **GIT_REPO_URL** (et **GIT_CREDENTIALS_ID**, **BUILD_COMMAND** si besoin).

Le pipeline fera alors le checkout du dépôt indiqué par **GIT_REPO_URL** et exécutera le build comme ci-dessus.

---

## 7. En cas d’échec du build

- **Checkout** : vérifier **GIT_REPO_URL**, **GIT_CREDENTIALS_ID** et l’accès réseau (SSH ou HTTPS) au dépôt.
- **Build** : vérifier la **Sortie de la console**. Si « aucun build.xml / build.bat trouvé », renseigner **BUILD_COMMAND** avec la commande utilisée par l’équipe pour construire ita-emb-app-ifsf (Ant, script batch, etc.).
- **Archive** : le build doit produire des fichiers **.7z** dans le workspace ; sinon adapter le motif dans le Jenkinsfile (étape « Archive artifacts ») ou corriger la commande de build pour qu’elle génère bien les .7z.

---

*Document Test Infrastructure — configuration du job Build IFSF (ReleasePackage-ITA0148-IFSF-TETRA) dans Jenkins.*
