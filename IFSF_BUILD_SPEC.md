# IFSF Build – Spécification du job Jenkins

Ce document décrit le job Jenkins **IFSF Build** (ou équivalent) qui **produit** les 3 archives .7z utilisées par le pipeline **IFSF-install** pour mettre à jour le logiciel IFSF sur le terminal.

---

## Rôle du job IFSF Build

- **Produire** et **publier** (artefacts Jenkins) les **3 archives .7z** :
  - **DevProxy** (ex. `DevProxy*.7z`)
  - **IFSF** (ex. `IFSF*..7z`)
  - **XMLConfigDLL** (ex. `XMLConfigDLL*.7z`)

Ces 3 .7z contiennent les fichiers nécessaires pour l’upgrade IFSF sur le terminal. Le job **IFSF-install** récupère le **dernier build réussi** (téléchargement HTTP ou Copy Artifacts), extrait les archives, sélectionne les fichiers selon le type de terminal (TETRA / T2 / SELF), prépare le répertoire équivalent **APPL_IFSF.MXX**, puis installe via **Local Upgrade** (envoi `/package` et `/import`).

---

## Contenu attendu des 3 .7z

À partir du contenu extrait, les fichiers sont choisis selon le **type de terminal** et copiés dans le répertoire de sortie (celui qui contiendra les fichiers prêts pour l’upgrade, équivalent **APPL_IFSF.MXX**).

### Fichiers Package (envoyés vers `/package`)

| Component      | TETRA | T2 | SELF |
|----------------|-------|-----|------|
| DevProxy       | `Bin/GNU_ARM_RELEASE_TETRA/8515360465_DEV_PROXY.P3A` | `Bin/GNU_ARM_RELEASE_T2/8515360465.AGN` | `Bin/GNU_ARM_RELEASE_SELF/8515361465_DEV_PROXY.P3A` |
| IFSF           | `Bin/GNU_ARM_RELEASE_TETRA/8226760662_IFSF_0662.P3A` | `Bin/GNU_ARM_RELEASE_T2/8226760662.AGN` | `Bin/GNU_ARM_RELEASE_SELF/8226761662_IFSF_1662.P3A` |
| XMLConfigDLL   | `Bin/GNU_ARM_RELEASE_TETRA/8226750662_XMLCFG_DLL.P3L` | `Bin/GNU_ARM_RELEASE_T2/8226750662.LGN` | `Bin/GNU_ARM_RELEASE_SELF/8226751662_XMLCFG_DLL.P3L` |

### Fichiers Import (envoyés vers `/import`)

Six fichiers **HOST** dans l’archive **XMLConfigDLL**, dossier **HOST** :

- **Noms de base :** CRD_RQT, CRD_RSP, DVC_RQT, DVC_RSP, SVC_RQT, SVC_RSP  
- **TETRA et T2 :** extension **.V0662**  
- **SELF :** extension **.V1662**

---

## Jenkins : configuration du job IFSF Build

1. **Créer un job** (Freestyle ou Pipeline) qui construit IFSF et produit les 3 archives .7z (DevProxy, IFSF, XMLConfigDLL).
2. **Publier les artefacts** : dans la configuration du job, section **Post-build Actions** (ou équivalent), ajouter **Archive the artifacts** avec un motif du type :
   - `**/*.7z`  
   ou de façon plus cible :
   - `**/DevProxy*.7z`, `**/IFSF*.7z`, `**/XMLConfigDLL*.7z`  
   selon la structure de sortie de votre build.
3. **Nom du job** : utiliser un nom fixe (ex. **IFSF-Build**) et le renseigner dans le paramètre **IFSF_JENKINS_JOB_NAME** du job **IFSF-install** (mode Copy Artifacts), ou mettre l’URL de ce job dans **IFSF_JENKINS_URL** (mode téléchargement HTTP).

---

## Côté IFSF-install (consommation)

- **Téléchargement** : dernier build réussi (artefacts DevProxy, IFSF, XMLConfigDLL .7z) depuis Jenkins (**IFSF_JENKINS_URL** ou **Copy Artifacts** avec **IFSF_JENKINS_JOB_NAME**).
- **Extraction** : depuis **IFSF_BUILD_DIR** ou le dossier de sortie du script de téléchargement / Copy Artifacts.
- **Sélection** : selon le type de terminal (**IFSF_TERMINAL_TYPE** ou déduit de **QAtcherTerminalID**).
- **Répertoire de sortie** : fichiers prêts pour l’upgrade (équivalent APPL_IFSF.MXX).
- **Installation** : Local Upgrade – envoi des fichiers *Package* vers `/package` et des fichiers *Import* (HOST) vers `/import`.

Voir **IFSF_README.md** et **JENKINS_IFSF_SETUP.md** pour les paramètres et la configuration du job IFSF-install.
