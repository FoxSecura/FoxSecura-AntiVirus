# Politique de sécurité

FoxSecura traite les signalements de sécurité avec prudence. La V0.1 reste
un prototype d'audit, sans moteur antivirus ni blocage de menaces en temps réel.

## Versions prises en charge

| Version | Maintien de sécurité |
| --- | --- |
| Branche `main` | Revue au cas par cas (prototype) |
| `feat/mobile-v0.1` | Développement ; corrections non garanties |
| Versions anciennes / forks | Aucune garantie de maintenance |

Aucune durée de support ni délai fixe de correction n'est promis à ce stade.

## Signalement privé

**N'ouvrez pas d'issue publique pour une vulnérabilité non corrigée.**

1. Vérifiez si le dépôt propose **Report a vulnerability** dans l'onglet
   [Security](https://github.com/FoxSecura/FoxSecura-AntiVirus/security).
   Si l'option est disponible, utilisez une GitHub Security Advisory privée.
2. Si cette option n'est pas disponible, demandez aux mainteneurs un canal
   de contact privé via les coordonnées officielles de l'organisation,
   **sans publier les détails de la faille**.
3. Incluez le composant affecté, les versions, les étapes minimales de
   reproduction, l'impact et une mitigation éventuelle ; supprimez les
   données personnelles, secrets et échantillons dangereux inutiles.

Nous examinerons les rapports selon les moyens disponibles et coordonnerons
la publication d'un correctif avec le déclarant lorsque c'est possible.
N'interprétez pas l'absence de réponse immédiate comme une autorisation de
publier des données sensibles.

## Périmètre

Sont particulièrement utiles : contournements de règles de sécurité,
fuites de données locales, exécution de code non prévue, mauvaise utilisation
des permissions Android/iOS et risques introduits par des dépendances.

Les faux positifs / faux négatifs d'heuristiques sans exploitation directe
peuvent être signalés via une issue ordinaire **avec des exemples non sensibles**.

Merci de ne pas effectuer de tests intrusifs sur des appareils, comptes,
serveurs ou utilisateurs sans autorisation.
