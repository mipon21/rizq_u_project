@echo off
echo Building Flutter Web App for GitHub Pages...
echo.

echo Cleaning previous build...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building web app with correct base href...
flutter build web --base-href "/RIZQ-APP-ADMIN/" --dart-define=ADMIN_PANEL_ONLY=true --no-tree-shake-icons

echo.
echo Build completed! Files are in build/web/
echo You can test locally by running: flutter run -d chrome --web-port 8080 --dart-define=ADMIN_PANEL_ONLY=true
pause 