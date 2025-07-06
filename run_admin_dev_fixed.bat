@echo off
echo Starting RIZQ Admin Panel in Development Mode (Fixed Version)...

REM Clean and get dependencies
echo Cleaning and getting dependencies...
flutter clean
flutter pub get

REM Run the app in admin panel mode for development with disabled icon tree shaking
echo Starting development server...
flutter run -d chrome --dart-define=ADMIN_PANEL_ONLY=true --no-tree-shake-icons

pause 