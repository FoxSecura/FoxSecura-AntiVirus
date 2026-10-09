# Architecture V0.5 et modèle de menace

## Flux

```text
Flutter UI (lib/main.dart)
  ├─ Inspection des URL ──► lib/security.dart (règles locales)
  ├─ Historique ──────────► minimisation + migration + TTL 30 j
  │                           └─ shared_preferences (local, non chiffré)
  ├─ Analyse d'un fichier ─► sélection volontaire + SHA-256 borné (25 Mio)
  │                           └─ catalogue EICAR de test (local)
  ├─ Vérification Ed25519 ─► SignedCatalogVerifier (pas d'activation distante)
  └─ Audit de l'appareil ─► MethodChannel foxsecura/device
                              ├─ Android / Kotlin : verrouillage, ADB,
                              │                   options développeur, correctif
                              └─ iOS / Swift : disponibilité authentification,
                                              version système
```

## Hypothèses et frontières de sécurité

- L'app ne dispose pas de droits root / jailbreak.
- Les données produites par l'OS sont des **indicateurs** et ne constituent
  pas une attestation d'intégrité.
- Sur iOS, le sandbox ne permet pas d'examiner librement les autres applications.
- Sur Android, la collecte de la liste des applications et les permissions
  spéciales sont soumises aux APIs et règles Google Play.
- Aucun backend ni service de réputation de domaine n'est intégré à la V0.1.

## Menaces hors périmètre

- Virus, chevaux de Troie et spyware inconnus ou non détectables par API.
- Contrôle des liens ouverts dans d'autres applications.
- Réseau, interception TLS, filtres VPN ou quarantaine.
- Jailbreak/root fiable, attestation distante, anti-tampering et
  détection de compromission avancée.
- Chiffrement de l'historique local (les détails sensibles hérités sont supprimés à l'ouverture).

## Améliorations candidates

1. Ajouter un historique chiffré et le nettoyage automatique des données sensibles.
2. Intégrer une réputation d'URL avec consentement, confidentialité et quotas.
3. Ajouter des analyses de fichiers sélectionnés explicitement sur Android.
4. Construire des benchmarks de faux positifs/faux négatifs vérifiables.
5. Publier une politique de mises à jour et des preuves de tests sur appareils.

**Ne jamais appeler l'application « antivirus complet » avant d'avoir
un moteur de détection réel et une validation de ses performances.**
