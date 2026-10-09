# Guide de développement

## Environnement

- Flutter SDK stable et Dart correspondant à `pubspec.yaml`.
- Android Studio et Android SDK ; appareil ou émulateur Android.
- Pour la compilation iOS : macOS, Xcode et configuration de signature Apple.
- Git et un éditeur compatible Dart/Flutter.

## Démarrage

```bash
git clone https://github.com/FoxSecura/FoxSecura-AntiVirus.git
cd FoxSecura-AntiVirus
flutter doctor
bash bootstrap.sh
flutter run
```

Le projet versionne les **sources** natives Kotlin et Swift ; les autres
fichiers de plateforme sont générés par `flutter create`. Le script
`bootstrap.sh` lance cette génération, télécharge les dépendances puis
exécute l'analyse statique et les tests Dart. Les tests natifs sur appareils
ne sont pas encore automatisés.

## Validation avant PR

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Pour une modification liée aux plateformes :
- Android : vérifier le niveau de sécurité Android déclaré, l'ADB et le verrouillage
  sur des configurations connues ; ne pas demander de permissions excessives.
- iOS : vérifier les chemins autorisés par les API publiques et la compilation Xcode.
- UI : contrôler les petits écrans et l'accessibilité (tailles de police, contraste).

## Arborescence utile

- `lib/main.dart` : interface et historique.
- `lib/security.dart` : objets de résultat, heuristiques URL, pont Flutter.
- `android/app/src/main/kotlin/...` : contrôles natifs Android.
- `ios/Runner/AppDelegate.swift` : contrôles natifs iOS.
- `test/` : tests unitaires Dart.
- `.github/workflows/flutter-ci.yml` : tests Flutter sur GitHub.

## Règles de sécurité

- Pas de promesse d'« appareil protégé » sans preuve ni couverture adéquate.
- Pas de partage de données d'audit sans consentement explicite.
- Ne pas sauvegarder en clair des identifiants ou liens à jetons.
- Ne pas commiter d'échantillons malveillants actifs.
- Les vérifications d'URL actuelles sont **hors ligne** et ne consultent
  pas de réputation externe.

Se référer au [schéma d'architecture](ARCHITECTURE.md).
