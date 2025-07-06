@echo off
echo Quick Fix: Building Admin Panel with Icon Tree Shaking Disabled

REM Clean everything first
flutter clean

REM Get dependencies
flutter pub get

REM Build with admin panel mode and disabled icon tree shaking
flutter build web --dart-define=ADMIN_PANEL_ONLY=true --release --no-tree-shake-icons

echo.
echo Build completed! Check build/web/ folder
pause 