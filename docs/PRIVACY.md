# Confidentialité de l'historique — V0.5

FoxSecura conserve un historique **local et non chiffré** via
`shared_preferences`. Ce mécanisme n'est pas un coffre sécurisé ; il
n'est pas adapté aux données personnelles sensibles ni aux secrets.

## Données conservées

- Contrôle d'URL : **schéma, hôte et port** uniquement, sans nom d'utilisateur,
  mot de passe, chemin, paramètres de requête ni fragment.
- Contrôle de fichier : catégorie et résultat, sans nom ou chemin du fichier.
- Audit de l'appareil : nom et version du système si le format est reconnu.
- Évènements : date et indicateur d'alerte.

## Migration et rétention

Au démarrage, les entrées écrites par les anciennes versions sont **traitées
avant leur affichage** : les champs non reconnus et les détails suspects sont
effacés ; les URL sont réduites à leur domaine ; les noms de fichiers sont
retirés. Les entrées corrompues ou anciennes sont supprimées du stockage local.

La conservation est limitée à **30 jours et 30 évènements maximum**.
Une suppression manuelle reste disponible dans l'onglet Historique.

Ces opérations n'effacent **pas forcément** les traces restant dans des
sauvegardes système, des instantanés ou un stockage forensique antérieur.
Pour une confidentialité plus forte, une version future devra utiliser
un stockage chiffré, une migration de sauvegardes et une politique
d'exclusion de sauvegarde documentée.

Aucune URL ou contenu de fichier n'est envoyé à une API par le scanner
actuel. Les améliorations futures nécessiteront une revue de consentement,
des permissions et des traitements de données.
