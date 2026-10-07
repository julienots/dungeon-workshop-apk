#!/usr/bin/env bash
# Construit l'APK et l'AAB (Google Play) de Dungeon Workshop à partir du jeu déjà compilé.
#
# Utilisé à l'identique par GitHub Actions et en local.
#   GAME_DIST      dossier dist/ du jeu compilé (défaut : game/dist)
#   VERSION_CODE   entier strictement croissant à chaque envoi sur Google Play
#   VERSION_NAME   version affichée (ex. 2.0.0)
# Signature (facultative : sans elle, seul un APK de debug est produit)
#   KEYSTORE_FILE      chemin du fichier .jks (clé d'importation Google Play)
#   KEYSTORE_PASSWORD  mot de passe du keystore
#   KEY_ALIAS          alias de la clé
#   KEY_PASSWORD       mot de passe de la clé
set -euo pipefail
cd "$(dirname "$0")/.."

GAME_DIST="${GAME_DIST:-game/dist}"
VERSION_CODE="${VERSION_CODE:-1}"
VERSION_NAME="${VERSION_NAME:-2.0.0}"
OUT="${OUT_DIR:-out}"

echo "▶ Contenu web depuis $GAME_DIST"
rm -rf www
cp -r "$GAME_DIST" www
# Les fichiers sont déjà embarqués dans l'application : le service worker PWA est inutile
rm -f www/sw.js

echo "▶ Capacitor"
npm install --no-audit --no-fund
[ -d android ] || npx cap add android
npx cap sync android

echo "▶ Icônes et écran de démarrage"
ICONS="${ICONS_DIR:-game/public/icons}"
if [ -f "$ICONS/icon-512.png" ]; then
  mkdir -p assets
  cp "$ICONS/icon-512.png" assets/icon.png
  cp "$ICONS/icon-maskable-512.png" assets/icon-foreground.png
  npx @capacitor/assets generate --android \
    --iconBackgroundColor '#0a0708' --iconBackgroundColorDark '#0a0708' \
    --splashBackgroundColor '#0a0708' --splashBackgroundColorDark '#0a0708' || echo "⚠️ icônes non générées"
fi

echo "▶ Manifeste : portrait"
MANIFEST=android/app/src/main/AndroidManifest.xml
grep -q 'screenOrientation' "$MANIFEST" || sed -i '0,/<activity/s//<activity android:screenOrientation="portrait"/' "$MANIFEST"

echo "▶ Version $VERSION_NAME ($VERSION_CODE)"
GRADLE=android/app/build.gradle
sed -i "s/versionCode [0-9]*/versionCode $VERSION_CODE/" "$GRADLE"
sed -i "s/versionName \"[^\"]*\"/versionName \"$VERSION_NAME\"/" "$GRADLE"

mkdir -p "$OUT"
cd android
chmod +x gradlew
if [ -n "${KEYSTORE_FILE:-}" ]; then
  echo "▶ Signature de publication"
  KEYSTORE_ABS="$(cd "$(dirname "$KEYSTORE_FILE")" && pwd)/$(basename "$KEYSTORE_FILE")"
  # Bloc de signature lu depuis les variables d'environnement (aucun secret écrit dans le projet)
  if ! grep -q 'signingConfigs' app/build.gradle; then
    python3 - <<'PY'
import re
p = 'app/build.gradle'
s = open(p).read()
block = '''
    signingConfigs {
        release {
            storeFile file(System.getenv("KEYSTORE_ABS"))
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }
'''
s = s.replace('android {', 'android {' + block, 1)
s = re.sub(r'(buildTypes\s*\{\s*release\s*\{)', r'\1\n            signingConfig signingConfigs.release', s, count=1)
open(p, 'w').write(s)
PY
  fi
  export KEYSTORE_ABS
  ./gradlew bundleRelease assembleRelease --no-daemon
  cp app/build/outputs/bundle/release/app-release.aab "../$OUT/DungeonWorkshop-$VERSION_NAME.aab"
  cp app/build/outputs/apk/release/app-release.apk "../$OUT/DungeonWorkshop-$VERSION_NAME.apk"
else
  echo "▶ Pas de clé : APK de debug uniquement"
  ./gradlew assembleDebug --no-daemon
  cp app/build/outputs/apk/debug/app-debug.apk "../$OUT/DungeonWorkshop-$VERSION_NAME-debug.apk"
fi
ls -la "../$OUT"
