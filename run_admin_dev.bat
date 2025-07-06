@echo off
echo Starting RIZQ Admin Panel in Development Mode...

REM Run the app in admin panel mode for development
flutter run -d chrome --dart-define=ADMIN_PANEL_ONLY=true

pause 