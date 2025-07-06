@echo off
echo Building RIZQ Normal App for Web...

REM Build the web app in normal mode (default)
flutter build web --release --no-tree-shake-icons

echo.
echo Normal App build completed!
echo Files are in: build/web/
echo.
echo To serve the normal app locally, run:
echo flutter run -d chrome
echo.
pause 