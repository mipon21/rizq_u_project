@echo off
echo Building RIZQ Admin Panel for Web...

REM Set the environment variable for admin panel mode
set ADMIN_PANEL_ONLY=true

REM Build the web app with admin panel configuration
flutter build web --dart-define=ADMIN_PANEL_ONLY=true --release --no-tree-shake-icons

echo.
echo Admin Panel build completed!
echo Files are in: build/web/
echo.
echo To serve the admin panel locally, run:
echo flutter run -d chrome --dart-define=ADMIN_PANEL_ONLY=true
echo.
pause 