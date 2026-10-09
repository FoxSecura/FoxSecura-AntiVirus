# Format de mises à jour signé (prototype V0.4)

Ce module introduit **la vérification de manifestes signés Ed25519**, sans
activer de mises à jour réseau ni prétendre disposer d'une infrastructure
de signatures de malwares réels.

Un manifeste est un fichier UTF-8 JSON, signé sur les **octets exacts**
du fichier. La signature est détachée (64 octets Ed25519).

Exemple conceptuel :

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

`SignedCatalogVerifier.verify` contrôle la signature **avant**
`jsonDecode`, la taille (128 Kio maximum), le schéma des entrées,
l'unicité des empreintes et `sequence > minimumSequence`.

## Avant toute activation en production

1. Générer une paire de clés **hors de l'application**, en conservant la clé
   privée dans une infrastructure de signature protégée.
2. Distribuer la **vraie clé publique FoxSecura authentifiée et épinglée**
   dans une version de l'application.
3. Stocker durablement le plus grand numéro de séquence accepté et empêcher
   les retours en arrière, y compris après redémarrage.
4. Prévoir la rotation/révocation des clés, l'expiration des manifestes,
   le transport HTTPS, les limites de requêtes et un cache atomique.
5. Auditer et tester la chaîne complète sur Android et iOS avant d'autoriser
   un catalogue distant.

La V0.4 **ne télécharge pas** et **n'active pas** de nouveaux manifestes.
Aucun secret privé ni clé d'éditeur inventée n'est embarqué dans le code.
Le scanner continue de se limiter à la signature de test EICAR.
