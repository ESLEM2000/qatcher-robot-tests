# Construire les fichiers IFSF dans Jenkins (guide rapide)

Ce guide permet de construire dans Jenkins les mêmes artefacts que le build **ReleasePackage-ITA0148-IFSF-TETRA** (#316) : archives .7z (DevProxy, IFSF_Lib, IFSF, XMLConfigDLL, XMLConfigLib).

---

## 1. Créer le job

1. Jenkins → **New Item**
2. Nom : `ReleasePackage-ITA0148-IFSF-TETRA` ou `IFSF-Build`
3. Type : **Pipeline** → **OK**

---

## 2. Configurer le pipeline

**Option A – Depuis le dépôt (recommandé)**

- **Pipeline** → Definition : **Pipeline script from SCM**
- SCM : **Git**
- Repository URL : URL du dépôt qui contient `Jenkinsfile_IFSF_Build`
- Branch : `*/main`
- Script Path : `resources/sample/tests/Jenkinsfile_IFSF_Build` (adapter au chemin réel dans votre repo)

**Option B – Script collé**

- **Pipeline** → Definition : **Pipeline script**
- Copier-coller tout le contenu de **Jenkinsfile_IFSF_Build** dans le champ Script

---

## 3. Lancer le build (Build with Parameters)

| Paramètre | Valeur |
|-----------|--------|
| **USE_GIT** | `true` |
| **GIT_REPO_URL** | `git@github.com:worldlineMSITA/ita-emb-app-ifsf.git` |
| **GIT_BRANCH** | `main` |
| **GIT_CREDENTIALS_ID** | ID de la credential Git (si dépôt privé) |
| **BUILD_COMMAND** | Vide (sauf si commande spécifique requise) |
| **INGEDEV_ROOT** | Ex. `C:\Ingenico\IngeDev_8.22.0.6` (si build IngeDev) |

---

## 4. Résultat

- **Checkout** : clone de `ita-emb-app-ifsf`
- **Build** : exécution Ant / IngeDev
- **Artefacts** : DevProxy, IFSF_Lib, IFSF, XMLConfigDLL, XMLConfigLib (.7z) dans « Artefacts du build »

---

---

## 5. Construire sans intervention (script)

Pour déclencher le build **sans ouvrir Jenkins** (ligne de commande, planification, CI) :

1. **Définir les variables d'environnement** (une fois par session ou dans l'ordinateur) :
   - `JENKINS_URL` ou `IFSF_BUILD_JENKINS_URL` : URL de Jenkins (ex. `http://10.3.2.184:49680`)
   - `JENKINS_USER` : utilisateur Jenkins
   - `JENKINS_PASSWORD` ou `JENKINS_API_TOKEN` : mot de passe ou token API (recommandé)

2. **Lancer le script** (depuis le dossier des tests) :
   ```powershell
   .\trigger_ifsf_build_jenkins.ps1
   ```
   Par défaut, le script déclenche le build puis **attend la fin** (succès ou échec). Pour déclencher sans attendre :
   ```powershell
   .\trigger_ifsf_build_jenkins.ps1 -NoWait
   ```

3. **Options utiles** :
   - `-JenkinsUrl "http://10.3.2.184:49680"` si vous ne définissez pas les variables
   - `-JobName "IFSF-Build"` si le job a un autre nom
   - `-SkipCertificateCheck` si Jenkins est en HTTPS avec certificat auto-signé
   - `-IngeDevRoot "C:\Ingenico\IngeDev_8.22.0.6"` pour passer le chemin IngeDev au build

4. **Fichier .cmd** : `trigger_ifsf_build_jenkins.cmd` appelle le script PowerShell avec les mêmes variables d'environnement (pratique pour un raccourci ou une tâche planifiée).

**Codes de sortie** : 0 = succès, 1 = build en échec, 2 = erreur API (401/404), 3 = build annulé, 4 = timeout.

---

## En cas de problème

- **Clone** : vérifier **GIT_CREDENTIALS_ID** et accès réseau (SSH/HTTPS).
- **Build** : consulter **Sortie de la console** ; si erreur « lltc n'est pas reconnu », utiliser IngeDev dans un chemin sans espaces (voir **INSTALL_INGEDEV.md**).
- **Script** : en cas de 401, utiliser un token API (Jenkins → Utilisateur → Configure → Add new Token) dans `JENKINS_API_TOKEN`.
- Détails complets : **JENKINS_IFSF_BUILD_SETUP.md**.
