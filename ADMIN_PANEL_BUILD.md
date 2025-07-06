# RIZQ Admin Panel Build Configuration

This document explains how to build and run the RIZQ app in different modes for admin panel and normal app.

## App Modes

The app supports two modes:

1. **Normal Mode** (default): Full app with customer/restaurant features
2. **Admin Panel Mode**: Admin-only interface

## Configuration

The app mode is controlled by the `ADMIN_PANEL_ONLY` environment variable:

- `ADMIN_PANEL_ONLY=true`: Admin Panel Mode
- `ADMIN_PANEL_ONLY=false` or not set: Normal Mode

## Build Scripts

### For Production Builds

#### Admin Panel Only
```bash
# Windows
build_admin_web.bat

# Manual command
flutter build web --dart-define=ADMIN_PANEL_ONLY=true --release
```

#### Normal App
```bash
# Windows
build_normal_web.bat

# Manual command
flutter build web --release
```

### For Development

#### Admin Panel Development
```bash
# Windows
run_admin_dev.bat

# Manual command
flutter run -d chrome --dart-define=ADMIN_PANEL_ONLY=true
```

#### Normal App Development
```bash
# Windows
run_normal_dev.bat

# Manual command
flutter run -d chrome
```

## Mode Differences

### Admin Panel Mode (`ADMIN_PANEL_ONLY=true`)
- **Initial Route**: `/admin/login`
- **App Title**: "RIZQ Admin Panel"
- **Login Page**: Admin login only
- **Navigation**: Direct to admin dashboard after login
- **UI**: Hides "Back to Main Login" button

### Normal Mode (`ADMIN_PANEL_ONLY=false`)
- **Initial Route**: `/splash`
- **App Title**: "RIZQ APP"
- **Login Page**: Regular login with admin option
- **Navigation**: Full app flow with role-based routing
- **UI**: Shows all navigation options

## Manual Commands

### Build Commands
```bash
# Admin Panel (Fixed - handles icon tree shaking issues)
flutter build web --dart-define=ADMIN_PANEL_ONLY=true --release --no-tree-shake-icons

# Normal App (Fixed - handles icon tree shaking issues)
flutter build web --release --no-tree-shake-icons

# With custom base href (for GitHub Pages)
flutter build web --base-href "/your-repo-name/" --dart-define=ADMIN_PANEL_ONLY=true --no-tree-shake-icons

# Alternative renderer if still having issues
flutter build web --dart-define=ADMIN_PANEL_ONLY=true --release --no-tree-shake-icons --web-renderer html
```

### Run Commands
```bash
# Admin Panel Development (Fixed - handles icon tree shaking issues)
flutter run -d chrome --dart-define=ADMIN_PANEL_ONLY=true --no-tree-shake-icons

# Normal App Development
flutter run -d chrome

# With custom port
flutter run -d chrome --web-port 8080 --dart-define=ADMIN_PANEL_ONLY=true --no-tree-shake-icons
```

## Configuration File

The app configuration is managed in `lib/app/utils/constants/app_config.dart`:

```dart
class AppConfig {
  static const bool isAdminPanelOnly = bool.fromEnvironment(
    'ADMIN_PANEL_ONLY',
    defaultValue: false,
  );
  
  static AppMode get currentMode {
    if (isAdminPanelOnly) {
      return AppMode.adminPanel;
    }
    return AppMode.normal;
  }
}
```

## Deployment

### Admin Panel Deployment
1. Run `build_admin_web.bat` or use the manual command
2. Upload `build/web/` contents to your web server
3. The app will start directly at the admin login page

### Normal App Deployment
1. Run `build_normal_web.bat` or use the manual command
2. Upload `build/web/` contents to your web server
3. The app will start at the splash screen

## Debug Information

When running in debug mode, the app will print configuration information:

```
=== APP CONFIGURATION ===
Admin Panel Only: true
Current Mode: AppMode.adminPanel
Initial Route: /admin/login
App Title: RIZQ Admin Panel
========================
```

## Troubleshooting

### Icon Tree Shaking Issues
If you encounter `IconTreeShakerException: Font subsetting failed` errors:

1. **Use the fixed build scripts**: `build_admin_web_fixed.bat` or `run_admin_dev_fixed.bat`
2. **Add `--no-tree-shake-icons` flag** to all build commands
3. **Alternative renderer**: Use `--web-renderer html` if issues persist

### Common Build Issues
- **Font subsetting errors**: Caused by `iconsax_plus` package, fixed with `--no-tree-shake-icons`
- **Memory issues**: Try `flutter clean` before building
- **Dependency issues**: Run `flutter pub get` before building

## Notes

- The admin panel mode is designed for separate deployment
- Both modes use the same Firebase backend
- Admin authentication is handled separately from regular user authentication
- The configuration is compile-time, so different builds are needed for different modes
- Icon tree shaking is disabled due to font compatibility issues with `iconsax_plus` package 