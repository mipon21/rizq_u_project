@echo off
echo Testing Flutter Web App locally...
echo.

echo Building web app...
flutter build web --base-href "/RIZQ-APP-ADMIN/"

echo.
echo Starting local server...
echo The app will be available at: http://localhost:8080
echo.
echo Press Ctrl+C to stop the server
echo.

cd build/web
python -m http.server 8080 