# Contribuer à FoxSecura AntiVirus

Merci de contribuer à FoxSecura ! Ce projet est un **prototype de sécurité mobile**
et non un antivirus exhaustif. Nous privilégions les résultats vérifiables,
la confidentialité et des messages de sécurité qui n'exagèrent pas les capacités réelles.

## Avant de commencer

- Consultez le [code de conduite](CODE_OF_CONDUCT.md).
- Pour une vulnérabilité exploitable ou une donnée sensible, suivez
  [SECURITY.md](SECURITY.md) **sans créer d'issue publique**.
- Vérifiez les [issues](https://github.com/FoxSecura/FoxSecura-AntiVirus/issues)
  et les pull requests existantes pour éviter les doublons.
- Pour une fonctionnalité importante, ouvrez une issue de proposition et
  expliquez la menace, l'API accessible et les limitations Android/iOS.

## Développement local

1. Forkez le dépôt, puis créez une branche courte : `feat/<sujet>`,
   `fix/<sujet>` ou `docs/<sujet>`.
2. Installez Flutter stable et les outils Android ; Xcode sur macOS pour iOS.
3. À la racine du projet : `bash bootstrap.sh`.
4. Vérifiez `flutter analyze` et `flutter test`.
5. Testez sur un appareil réel si vous modifiez une fonction native Android/iOS.
6. Ouvrez une pull request vers `main` avec les preuves de test et les limites connues.

La structure, les commandes et les contraintes de plateforme figurent dans
[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md). Ne commitez pas de clés API,
identifiants, journaux contenant des URL sensibles, certificats de signature
ni échantillons de malwares actifs.

## Standards de qualité

- Le code Flutter/Dart suit `flutter_lints`; privilégiez les petits changements.
- Ajoutez des tests aux règles heuristiques et aux corrections de bogues.
- Distinguez clairement **heuristique**, **réputation** et **détection malware**.
- Les alertes doivent rester explicables et ne jamais annoncer « appareil sain »
  quand les contrôles ne peuvent pas garantir ce résultat.
- Évitez les permissions invasives, la collecte superflue et les transmissions réseau
  silencieuses. Toute télémétrie future doit faire l'objet d'une revue de sécurité
  et de confidentialité.
- Pour les nouveaux packages, justifiez leur nécessité, leur maintenance
  et leur licence ; n'introduisez pas de dépendance incompatible avec l'AGPL.
- Documentez les différences de capacité entre Android et iOS.

## Pull requests

Utilisez le modèle de pull request ; indiquez : objectif, limites, tests,
captures d'écran si l'UI change, et effets sur permissions/confidentialité.
Une revue mainteneur est attendue avant fusion. La CI est utile, mais
**ne remplace pas** la validation sur appareils physiques.

## Types de contributions utiles

Les tests, la documentation, l'accessibilité, les audits de permissions,
l'internationalisation, les performances et la recherche de faux positifs
sont aussi précieux que les nouvelles fonctionnalités.

## Droits d'auteur et licence

Les contributions proposées sont destinées à être distribuées selon
[AGPL-3.0-only](LICENSE). Ne soumettez que du code dont vous possédez les
droits ou que vous êtes autorisé à réutiliser sous ces conditions.
Vous conservez vos droits d'auteur ; une contribution n'implique pas une
cession automatique de propriété intellectuelle à FoxSecura.
Le code tiers reste soumis à ses propres notices et conditions compatibles.
Pour une modification substantielle de licence, ouvrez une discussion préalable.

---

Copyright © 2026 FoxSecura contributors.
