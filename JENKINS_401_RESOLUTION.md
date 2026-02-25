# Résoudre l'erreur 401 – S'identifier [Jenkins]

Si `check_jenkins_login.ps1` ou le téléchargement IFSF renvoie **401 Non autorisé**, appliquez une ou plusieurs des solutions suivantes.

## 1. Vérifier l'URL Jenkins

Par défaut le script utilise `http://localhost:8081`. Si votre Jenkins est ailleurs :

```powershell
$env:JENKINS_URL = "https://votre-jenkins.company.com"
$env:JENKINS_USER = "ITAGuetUser"
$env:JENKINS_PASSWORD = 'ITAGuetUser2025$'
.\check_jenkins_login.ps1
```

Pour IFSF, **IFSF_JENKINS_URL** est l’URL du job ; **JENKINS_URL** est l’URL de base (pour la connexion).

## 2. Utiliser un token API (recommandé en cas de 401)

Jenkins exige souvent un **token API** pour l’accès à l’API (au lieu du mot de passe) :

1. Dans Jenkins : clic sur votre nom (en haut à droite) → **Configure** → **Add new Token**.
2. Copier le token généré.
3. Dans PowerShell :

```powershell
$env:JENKINS_URL = "https://votre-jenkins.company.com"
$env:JENKINS_USER = "ITAGuetUser"
$env:JENKINS_API_TOKEN = "votre_token_genere"
.\check_jenkins_login.ps1
```

## 3. Mot de passe contenant le caractère `$`

Utiliser des **guillemets simples** pour que PowerShell n’interprète pas `$` :

```powershell
$env:JENKINS_PASSWORD = 'ITAGuetUser2025$'
```

## 4. Jenkins en HTTPS avec certificat non fiable

Si l’erreur concerne le certificat SSL :

```powershell
.\check_jenkins_login.ps1 -SkipCertificateCheck
```

## Vérification rapide

```powershell
$env:JENKINS_URL = "https://votre-url-jenkins"
$env:JENKINS_USER = "ITAGuetUser"
$env:JENKINS_PASSWORD = 'ITAGuetUser2025$'
# ou : $env:JENKINS_API_TOKEN = "votre_token"
.\check_jenkins_login.ps1
```

En cas de succès : `OK - Acces Jenkins reussi.`
