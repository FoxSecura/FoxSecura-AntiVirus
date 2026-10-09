# V0.6 — Activation de catalogues Ed25519 (pré-production)

La V0.6 contient un gestionnaire de catalogues SHA-256 **signés** et un
transport HTTPS borné. Le build fourni reste limité au **test EICAR** :
pas de clé publique de publication officielle ni de signatures de menaces
réelles. Il ne constitue pas un antivirus opérationnel.

## Format et publication

Sous un dossier HTTPS fixe, publier **deux fichiers** :

- `catalog.json` : manifeste UTF-8 JSON de **128 Kio maximum** ;
- `catalog.json.sig` : signature détachée Ed25519 brute de **64 octets**
  sur les **octets exacts** de `catalog.json` (pas un texte en base64).

Exemple de `catalog.json` :

```json
{
  "sequence": 1,
  "version": "2026.10-test.2",
  "entries": [{
    "id": "EICAR-TEST-FILE",
    "sha256": "275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f",
    "description": "Test EICAR inoffensif",
    "isTestOnly": true
  }]
}
```

Le vérificateur valide **la signature avant le décodage JSON**, puis le
schéma, les empreintes et un numéro de séquence strictement supérieur au
dernier accepté. Les octets du manifeste et de la signature sont enregistrés
ensemble et **revérifiés après redémarrage**.

## Activer la chaîne de confiance

Une vraie équipe de publication doit, au préalable :

1. Générer et gérer **hors du dépôt** la clé privée Ed25519 ; sauvegardes,
   rotation, révocation et contrôle d'accès à prévoir.
2. Faire authentifier la clé publique par un canal indépendant, et l'épingler
   dans un **binaire officiel signé**.
3. Configurer le binaire avec les paramètres de compilation publics suivants :

```bash
flutter build apk --dart-define=FOXSECURA_CATALOG_ED25519_PUBLIC_KEY_HEX=VOTRE_CLE_PUBLIQUE_HEX_64_CARACTERES --dart-define=FOXSECURA_CATALOG_UPDATE_BASE_URL=https://updates.example.org/catalogs/
```

Ce sont des exemples de configuration, **pas des clés ou un serveur
officiels**. Ne jamais injecter de clé privée dans les binaires ni
dans GitHub Actions. Une clé de test peut servir dans un environnement
de test isolé, pas dans une version de production.

Sans clé valide, les mises à jour sont **désactivées** et le scanner utilise
le seul catalogue EICAR intégré. Le bouton de mise à jour n'apparaît
que si la clé et l'URL sont configurées. Le transport refuse les origines
non-HTTPS, les ports non standards, les identifiants dans l'URL, les
redirections et les réponses non-200 ; limites de taille et délais d'attente
pour les deux fichiers. Le fichier analysé n'est jamais téléchargé.

## Cache et retour en arrière

Le plus grand numéro de séquence accepté est enregistré en premier, avant
l'enregistrement des octets signés. Après redémarrage, une signature valide
et une séquence **identique** au compteur sont requises. Une interruption
entre ces deux écritures désactive le catalogue actif jusqu'à réception
d'une version ultérieure ; l'application revient au test EICAR.

**Attention :** le compteur et le cache sont dans `shared_preferences`.
Il s'agit d'une défense **contre les mises à jour périmées accidentelles**,
et non d'une résistance cryptographique au rollback. Un attaquant ayant
accès à l'ensemble du stockage peut restaurer les deux valeurs. Ce stockage
n'assure pas de transaction atomique ni de compteur monotone matériel.

## Travaux indispensables avant une version antivirus publique

Authentification de la clé éditeur, signatures de menaces de provenance et
licence vérifiées, expiration des catalogues, transparence, rotation et
révocation de clés, politique de sauvegarde/rollback, tests de reprise réseau,
tests Android/iOS physiques et audit de sécurité indépendant.

La seule couverture fournie dans ce dépôt reste celle des fichiers
volontairement sélectionnés ; un non-match SHA-256 n'est pas une preuve
qu'un fichier est sain.
