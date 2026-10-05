# Dungeon Workshop — APK Android

Ce dépôt compile automatiquement le jeu [DUNGEON-WORKSHOP](https://github.com/julienots/DUNGEON-WORKSHOP)
en application Android (Capacitor) grâce à GitHub Actions.

## Obtenir l'APK

1. Onglet **Actions** → **Compiler l'APK** → **Run workflow** (choisissez la branche du jeu si besoin).
2. Après ~5 minutes, l'APK est publié dans **Releases** (et en artefact du workflow).
3. Sur le téléphone : ouvrez la page Releases, téléchargez `DungeonWorkshop-x.y.z.apk`, ouvrez-le et autorisez
   l'installation depuis le navigateur si Android le demande.

Le jeu fonctionne entièrement hors ligne ; l'application ne demande aucune permission.

## Déclenchement automatique (optionnel)

Le workflow réagit aussi à un événement `repository_dispatch` de type `game-updated`, ce qui permet au dépôt du jeu
de relancer la compilation à chaque modification (nécessite un jeton d'accès personnel dans le dépôt du jeu).

## Version Google Play

L'APK produit est signé avec la clé de débogage (parfait pour installer et tester). Pour Google Play, il faudra
une clé de signature de publication et un bundle `bundleRelease` (AAB).
