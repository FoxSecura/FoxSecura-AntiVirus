# Changelog

Toutes les modifications notables de FoxSecura AntiVirus sont consignées dans ce fichier.

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) ;
versions suivant [Semantic Versioning](https://semver.org/lang/fr/) lorsque cela
sera possible. Les fonctionnalités sont encore expérimentales.

## [Unreleased]

### V0.5 — Renforcement confidentialité et scanner (en développement)
- Corrections de revue : nouvelles dates en UTC, conversion des horodatages
  avec fuseau et suppression des anciens horodatages ambigus sans fuseau.
- Réapplication de la rétention à l'ouverture de l'historique et à la reprise
  de l'application ; opérations d'historique sérialisées contre les courses.
- Migration automatique des anciens historiques : URL réduite à origine
  (protocole/domaine/port), suppression des noms de fichiers et détails inconnus.
- Expiration des évènements de plus de 30 jours et limite de 30 entrées.
- Contrôle de taille par flux pendant le SHA-256, pour les fichiers modifiés
  entre la vérification de taille et la lecture.
- Tests de migration et de régression de la confidentialité.

**Limites conservées :** l'historique n'est pas chiffré, et le seul motif
reconnu est encore le test inoffensif EICAR.


### Added
- CI GitHub Actions pour construire et publier un APK Android debug de test.
- Icône de lancement FoxSecura dérivée du logo du projet, et script de génération.
- Guide pour installer et récupérer l'APK de test.

### Security
- Aucun secret de signature de production utilisé : APK debug uniquement.


### Added
- Vérificateur expérimental de manifestes de signatures Ed25519 : validation
  avant lecture du JSON, limites de taille, schéma strict, séquence croissante.
- Tests cryptographiques contre falsification, clé incorrecte et ancien numéro.
- Documentation de sécurité et plan de gestion des clés.

### Security
- Le chargement réseau et l'activation de manifestes distants restent
  désactivés tant qu'une clé publique authentique et une protection
  persistante contre le rollback ne sont pas déployées.

## [0.3.0] - 2026-10-09

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
