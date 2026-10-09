# Confidentialité de l'historique

Depuis la prochaine version, les nouvelles vérifications d'URL ne conservent
que le schéma, le domaine et le port dans l'historique. Les noms des fichiers
choisis pour le scan EICAR ne sont plus conservés.

Les résultats restent enregistrés avec `shared_preferences` sur l'appareil :
cette méthode ne constitue pas un coffre-fort chiffré. En particulier,
les entrées écrites par les versions antérieures peuvent encore contenir
des URL complètes ou des noms de fichiers.

**Action conseillée après mise à niveau :** ouvrir l'onglet Historique et
sélectionner **Effacer** pour supprimer ces anciennes entrées.

La prochaine évolution devra utiliser un stockage chiffré avec stratégie de
rétention et migration explicites.
