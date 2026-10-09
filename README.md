# FoxSecura AntiVirus
[![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![License: AGPL v3](https://img.shields.io/badge/AGPL_v3-663399.svg?logo=gnu&logoColor=white)](https://github.com/FoxSecura/FoxSecura-AntiVirus/blob/main/LICENSE)

Projet Flutter Android et iOS avec interface Material 3 sombre.

> **Statut : prototype d'audit de sécurité.** Ce logiciel n'est pas encore un antivirus à signatures, et ne garantit pas qu'un téléphone ou qu'une URL est exempt de menace.

## Installer

Prérequis : Flutter stable, Android Studio/SDK ; sur macOS, Xcode pour iOS.

```bash
git clone https://github.com/FoxSecura/FoxSecura-AntiVirus.git
cd FoxSecura-AntiVirus
bash bootstrap.sh
flutter run
```

Le dépôt conserve les sources propres ; `flutter create` génère les autres fichiers de plateforme avant analyse et tests. Ne pas utiliser `flutter create --overwrite` après personnalisation.

## Limitations et confidentialité

Aucune détection générale de malware, aucune base de signatures de menaces réelles, protection réseau en temps réel, blocage de navigation ou mise en quarantaine. L'inspection d'URL est heuristique : faux positifs et faux négatifs possibles. L'historique local reste non chiffré, mais les URL sont réduites aux domaines, les noms de fichiers sont supprimés, et les anciennes données sont nettoyées à la lecture. L'historique est limité à 30 jours et 30 entrées ; ne pas y saisir de secrets. Aucune API externe n'est contactée par les contrôles.

Sur iOS, le sandbox interdit une analyse arbitraire des autres applications. Sur Android, l'inventaire complet des applications nécessite un examen préalable des règles Google Play avant d'envisager `QUERY_ALL_PACKAGES`.

## Scanner et confidentialité (V0.5)

- Le contrôle de fichiers volontaires utilise SHA-256 local avec une limite de
  25 Mio surveillée même pendant la lecture, et ne connaît toujours que la
  signature de test EICAR. Un non-match **ne signifie pas** que le fichier est sain.
- À la première ouverture, les anciens historiques de navigation et de fichiers
  sont nettoyés avant affichage : seuls domaine/protocole/port, catégorie,
  date et indicateur d'alerte peuvent rester.
- Conservation maximale : **30 jours et 30 entrées**, sans chiffrement au repos.
  Consultez [docs/PRIVACY.md](docs/PRIVACY.md) pour les limitations.

## V0.6 — Catalogues de signatures signés

Le moteur peut vérifier un catalogue Ed25519 signé, appliquer une séquence
strictement croissante et restaurer hors ligne un cache revérifié.
Il ne télécharge jamais les fichiers analysés par l'utilisateur.

**Aucune clé publique officielle ni base de signatures malware réelles
ne sont livrées** : le build standard reste limité au test EICAR et
n'active pas les mises à jour automatiques.

Lire [le protocole signé](docs/SIGNED_UPDATES.md) avant tout déploiement.

## Développement

```bash
flutter analyze
flutter test
flutter run
```

L'exécution sur appareils physiques Android/iOS doit être validée avant toute distribution publique.

## Contribuer

Les contributions sont les bienvenues. Commencer par
[CONTRIBUTING.md](CONTRIBUTING.md) et [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).
Voir également [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) et
[SECURITY.md](SECURITY.md) avant de déclarer un problème sensible.

Les propositions passent par une pull request et les vérifications
automatisées de `Flutter checks`.

## Licence

FoxSecura AntiVirus est diffusé sous **GNU Affero General Public License v3.0 only**
(`AGPL-3.0-only`). Le texte complet figure dans [LICENSE](LICENSE).
Les dépendances tierces conservent leurs licences respectives.
L'AGPL-3.0 prévoit notamment des obligations de mise à disposition du code
source pour les versions distribuées et certaines utilisations via un réseau.
La licence du code ne constitue pas une autorisation d'utiliser les marques
de FoxSecura.

Copyright © 2026 FoxSecura contributors.
