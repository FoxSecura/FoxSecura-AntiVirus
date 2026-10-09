# FoxSecura AntiVirus — Mobile V0.2

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

## Ce que fait la V0.2

- Audit Android via Kotlin : code de verrouillage, ADB, options développeur et date de correctif annoncée par l'OS.
- Audit iOS via Swift : disponibilité de l'authentification propriétaire et version iOS.
- Vérification **hors ligne** des indicateurs URL : HTTP, userinfo, punycode, IP directe, ports atypiques, domaines complexes.
- Interface Flutter et historique local de trente derniers contrôles, stocké dans `shared_preferences`.
- Sélection explicite d'un fichier et calcul SHA-256 local (jusqu'à 25 Mio), détection de la **seule** signature EICAR (chaîne de test inoffensive) sur Android et iOS.

## Limitations et confidentialité

Aucune détection générale de malware, aucune base de signatures de menaces réelles, protection réseau en temps réel, blocage de navigation ou mise en quarantaine. L'inspection d'URL est heuristique : faux positifs et faux négatifs possibles. Les URL de l'historique sont stockées localement sans chiffrement ; ne pas y saisir de secrets. Aucune API externe n'est contactée par les contrôles.

Sur iOS, le sandbox interdit une analyse arbitraire des autres applications. Sur Android, l'inventaire complet des applications nécessite un examen préalable des règles Google Play avant d'envisager `QUERY_ALL_PACKAGES`.

## Développement

```bash
flutter analyze
flutter test
flutter run
```

L'exécution sur appareils physiques Android/iOS doit être validée avant toute distribution publique.

## Licence

FoxSecura AntiVirus est diffusé sous **GNU Affero General Public License v3.0 only**
(`AGPL-3.0-only`). Le texte complet figure dans [LICENSE](LICENSE).
Les dépendances tierces conservent leurs licences respectives.
L'AGPL-3.0 prévoit notamment des obligations de mise à disposition du code
source pour les versions distribuées et certaines utilisations via un réseau.
La licence du code ne constitue pas une autorisation d'utiliser les marques
de FoxSecura.

## Contribuer

Les contributions sont les bienvenues. Commencer par
[CONTRIBUTING.md](CONTRIBUTING.md) et [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).
Voir également [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) et
[SECURITY.md](SECURITY.md) avant de déclarer un problème sensible.

Les propositions passent par une pull request et les vérifications
automatisées de `Flutter checks`.

## Scanner expérimental V0.2

L'utilisateur choisit un fichier depuis le sélecteur de fichiers système ; aucun accès global aux autres applications ni balayage complet du téléphone. Le contenu n'est pas envoyé sur Internet. Le fichier est lu par flux pour calculer son SHA-256 et vérifier uniquement la signature de test EICAR. Une non-correspondance n'est **pas** une preuve d'innocuité. Le nom du fichier (mais pas son contenu ni son chemin complet) est enregistré dans l'historique local non chiffré : ne sélectionnez pas un fichier au nom sensible. Les grands fichiers (>25 Mio) sont refusés. Ce module doit encore être testé sur appareils physiques.
