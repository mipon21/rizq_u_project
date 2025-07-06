@echo off
echo Building RIZQ Admin Panel for Web (Fixed Version)...

REM Clean previous build
echo Cleaning previous build...
flutter clean

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Build the web app with admin panel configuration and disabled icon tree shaking
echo Building admin panel...
flutter build web --dart-define=ADMIN_PANEL_ONLY=true --release --no-tree-shake-icons

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Admin Panel build completed successfully!
    echo Files are in: build/web/
    echo.
    echo To serve the admin panel locally, run:
    echo flutter run -d chrome --dart-define=ADMIN_PANEL_ONLY=true
    echo.
) else (
    echo.
    echo ❌ Build failed! Trying alternative approach...
    echo.
    echo Attempting build without icon optimization...
    flutter build web --dart-define=ADMIN_PANEL_ONLY=true --release --no-tree-shake-icons --web-renderer html
)

pause 