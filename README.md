# FoxSecura AntiVirus — Mobile V0.1

Projet Flutter Android et iOS avec interface Material 3 sombre.

> **Statut : prototype d'audit de sécurité.** Ce logiciel n'est pas encore un antivirus à signatures, et ne garantit pas qu'un téléphone ou qu'une URL est exempt de menace.

## Installer

Prérequis : Flutter stable, Android Studio/SDK ; sur macOS, Xcode pour iOS.

```bash
git clone https://github.com/FoxSecura/FoxSecura-AntiVirus.git
cd FoxSecura-AntiVirus
git switch feat/mobile-v0.1
bash bootstrap.sh
flutter run
```

Le dépôt conserve les sources propres ; `flutter create` génère les autres fichiers de plateforme avant analyse et tests. Ne pas utiliser `flutter create --overwrite` après personnalisation.

## Ce que fait la V0.1

- Audit Android via Kotlin : code de verrouillage, ADB, options développeur et date de correctif annoncée par l'OS.
- Audit iOS via Swift : disponibilité de l'authentification propriétaire et version iOS.
- Vérification **hors ligne** des indicateurs URL : HTTP, userinfo, punycode, IP directe, ports atypiques, domaines complexes.
- Interface Flutter et historique local de trente derniers contrôles, stocké dans `shared_preferences`.

## Limitations et confidentialité

Aucune analyse malware, détection par signature, protection réseau en temps réel, blocage de navigation ou mise en quarantaine. L'inspection d'URL est heuristique : faux positifs et faux négatifs possibles. Les URL de l'historique sont stockées localement sans chiffrement ; ne pas y saisir de secrets. Aucune API externe n'est contactée par les contrôles.

Sur iOS, le sandbox interdit une analyse arbitraire des autres applications. Sur Android, l'inventaire complet des applications nécessite un examen préalable des règles Google Play avant d'envisager `QUERY_ALL_PACKAGES`.

## Développement

```bash
flutter analyze
flutter test
flutter run
```

L'exécution sur appareils physiques Android/iOS doit être validée avant toute distribution publique.
