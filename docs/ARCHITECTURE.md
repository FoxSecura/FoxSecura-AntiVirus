# Architecture V0.1 et modèle de menace

## Flux

```text
Flutter UI (lib/main.dart)
  ├─ Inspection des URL ──► lib/security.dart (règles locales)
  ├─ Historique ──────────► shared_preferences (local, non chiffré)
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
- Protection cryptographique des URL enregistrées dans l'historique.

## Améliorations candidates

1. Ajouter un historique chiffré et le nettoyage automatique des données sensibles.
2. Intégrer une réputation d'URL avec consentement, confidentialité et quotas.
3. Ajouter des analyses de fichiers sélectionnés explicitement sur Android.
4. Construire des benchmarks de faux positifs/faux négatifs vérifiables.
5. Publier une politique de mises à jour et des preuves de tests sur appareils.

**Ne jamais appeler l'application « antivirus complet » avant d'avoir
un moteur de détection réel et une validation de ses performances.**
