# Paramètres exacts pour le job Jenkins IFSF-Build

Valeurs à renseigner dans **Build with Parameters** (sans Git).

**Important :** Saisir les chemins **sans backticks** (\`). Si vous copiez-collez, vérifier qu’il n’y a pas de \` avant/après le chemin (sinon le build reçoit un mauvais chemin).

---

## Chemins exacts (d’après le dépôt et build_slfuelapp_ingenico.ps1)

| Paramètre | Valeur exacte | Remarque |
|-----------|---------------|-----------|
| **BUILD_SOURCE_DIR** | `C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA` | Répertoire des sources du package (workspace IngeDev). Doit contenir `BuildPackage\Ant\build.xml` ou à la racine un `build.xml`. |
| **BUILD_XML_PATH** | `C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA\BuildPackage\Ant\build.xml` | Chemin complet vers le script Ant. À utiliser si la détection auto échoue. |
| **BUILD_COMMAND** | *(laisser vide)* | Si vide, le pipeline utilise IngeDev (`antCmdLine.bat`) avec BUILD_SOURCE_DIR + BUILD_XML_PATH. Sinon, mettre la commande complète (ex. `call antCmdLine.bat "..." "..."` ou `ant -f ...`). |

---

## Variante : Jenkins installé sous le profil utilisateur

Si Jenkins est dans `C:\Users\eslem.hajamor\.jenkins` (workspace du job = `C:\Users\eslem.hajamor\.jenkins\workspace\IFSF-Build`) :

- **BUILD_SOURCE_DIR** : soit `C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA`, soit le chemin où se trouve **réellement** le projet (contenant `BuildPackage\Ant\build.xml`).
- **BUILD_XML_PATH** : chemin **complet** vers `build.xml`, par exemple :
  - `C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA\BuildPackage\Ant\build.xml`
  - ou, si le projet est dans le workspace d’un autre job :  
    `C:\Users\eslem.hajamor\.jenkins\workspace\<NomDuJob>\BuildPackage\Ant\build.xml`

---

## Exemple de BUILD_COMMAND (si vous ne passez pas par BUILD_SOURCE_DIR / BUILD_XML_PATH)

Commande équivalente à ce que fait le pipeline avec IngeDev :

```bat
call "C:\Ingenico\IngeDev_8.22.0.6\antCmdLine.bat" "C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA" "C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA\BuildPackage\Ant\build.xml"
```

(Adapter les chemins si INGEDEV_ROOT ou le projet sont ailleurs.)

---

## Vérification sur votre machine

- Le dossier **`C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA`** existe.
- **`BuildPackage\Ant\build.xml`** n’a pas été trouvé dedans : le projet est peut‑être incomplet ou le `build.xml` est ailleurs (autre branche, autre job Jenkins).

À faire : obtenir une copie du projet qui contient **BuildPackage\Ant\build.xml** (clone Git ita-emb-app-ifsf, copie depuis un collègue ou depuis un workspace Jenkins où le build IFSF fonctionne), puis utiliser le chemin de **ce** répertoire pour **BUILD_SOURCE_DIR** et **BUILD_XML_PATH**.

---

## Résumé pour « Build with Parameters »

| Paramètre | Valeur à saisir |
|-----------|------------------|
| USE_GIT | `false` |
| BUILD_SOURCE_DIR | `C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA` |
| BUILD_XML_PATH | `C:\Ingedev_Workspaces\ReleasePackage-ITA0148-WLFA\BuildPackage\Ant\build.xml` (ou chemin réel vers build.xml) |
| BUILD_COMMAND | *(vide)* |
| INGEDEV_ROOT | `C:\Ingenico\IngeDev_8.22.0.6` (ou chemin de votre IngeDev complet avec lltc) |
