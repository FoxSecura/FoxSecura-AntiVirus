# Changelog

Toutes les modifications notables de FoxSecura AntiVirus sont consignées dans ce fichier.

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) ;
versions suivant [Semantic Versioning](https://semver.org/lang/fr/) lorsque cela
sera possible. Les fonctionnalités sont encore expérimentales.

## [Unreleased]

### Added
- Catalogue de signatures local versionné (`SignatureCatalog`), actuellement
  limité à l'empreinte SHA-256 du fichier de test inoffensif EICAR.
- Tests du catalogue de signatures et de la réduction des données conservées.

### Changed
- L'historique des vérifications d'URL enregistre uniquement le schéma,
  le domaine et le port, sans chemin, paramètres, fragment ni identifiants.
- L'historique des fichiers sélectionnés n'enregistre plus leur nom.
- La détection EICAR consulte maintenant le catalogue local.
- Les descriptions de la portée expérimentale du scanner sont clarifiées.

### Security
- Réduction des nouvelles données potentiellement sensibles enregistrées
  dans l'historique local. **Les anciennes entrées ne sont pas effacées
  automatiquement** : l'utilisateur peut effacer son historique dans l'application.
- Aucun envoi de fichier ou d'URL à un service tiers.

## [0.2.0] - 2026-10-09

### Added
- Sélection volontaire d'un fichier depuis le système (Android et iOS).
- Calcul SHA-256 local par flux, avec limite de taille à 25 Mio.
- Reconnaissance de la signature du fichier de test EICAR.
- Tests de sélection/empreinte du scanner de fichiers.

### Changed
- Section licence déplacée à la fin de `CONTRIBUTING.md`, suivie de
  « Copyright © 2026 FoxSecura contributors. »

## [0.1.0] - 2026-10-09

### Added
- Interface Flutter Material 3 pour Android et iOS.
- Audit local Android (verrouillage, ADB, options développeur,
  date du correctif) et iOS (authentification, version de l'OS).
- Inspection heuristique hors ligne des URL.
- Historique local et tests unitaires.
- Licence AGPL-3.0-only, guides de contribution, politique de sécurité,
  modèles GitHub et workflow Flutter CI.

### Fixed
- Détection des ports explicites en fonction du protocole HTTP/HTTPS.
- Test widget Flutter et automatisation de la validation via GitHub Actions.

---

**Limite :** FoxSecura reste un prototype expérimental, et la non-détection
d'une signature ne garantit jamais qu'un appareil ou un fichier soit sain.

Copyright © 2026 FoxSecura contributors.
