#!/usr/bin/env bash
set -euo pipefail
command -v flutter >/dev/null || { echo "Flutter SDK introuvable"; exit 1; }
flutter create --platforms=android,ios --org com.foxsecura --project-name foxsecura_mobile .
flutter pub get
flutter analyze
flutter test
echo "Prêt : flutter run"
