# APK Android de test

Le workflow [Build Android Test APK](../.github/workflows/android-apk.yml)
construit un APK de débogage pour installation manuelle, sans Play Store.
L'icône reprend le logo FoxSecura orange/blanc sur fond noir (version SVG
vectorisée pour les tailles de lanceur Android).

## Lancer le build GitHub

1. Ouvrir l'onglet **Actions** > **Build Android Test APK**.
2. Choisir **Run workflow** sur `main`, après fusion, ou consulter les
   exécutions déclenchées par la pull request.
3. Attendre l'exécution **Compile and upload APK**.
4. En bas de la page d'exécution, télécharger l'artefact
   **FoxSecura-Android-Debug-APK**.
5. Décompresser et installer `app-debug.apk` sur **un appareil de test**.
   Android pourra demander l'autorisation d'installer depuis cette source.

Le fichier est un APK **debug**, avec la signature de débogage générée par
l'environnement CI. Il ne convient pas à une publication Play Store et
n'est pas une mise à jour garantie d'un build signé localement avec une autre
clé. Désinstaller l'ancien paquet peut être nécessaire avant installation.

## Génération locale

```bash
flutter create --platforms=android,ios --org com.foxsecura --project-name foxsecura_mobile .
flutter pub get
python3 -m pip install 'cairosvg==2.8.2'
python3 scripts/generate_android_icons.py
flutter build apk --debug
```

Le résultat est `build/app/outputs/flutter-apk/app-debug.apk`.

## Confidentialité et avertissement

Les artefacts sont conservés 14 jours. Aucun mot de passe, clé de signature
de production ni secret d'édition n'est nécessaire au workflow.

FoxSecura reste un **prototype de sécurité**, sans analyse antivirus complète,
même lorsqu'un APK est compilé et installé correctement.
