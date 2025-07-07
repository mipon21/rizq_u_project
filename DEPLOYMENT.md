# Flutter Web Deployment Guide

## Issues Fixed

The following issues have been resolved:

1. **Firebase SDK Compatibility**: Updated from Firebase SDK v10.8.0 (modular) to v9.23.0 (compat) for better Flutter integration
2. **Base Href Configuration**: Properly configured for GitHub Pages deployment
3. **GitHub Actions Workflow**: Automated deployment pipeline
4. **Dependency Conflicts**: Removed problematic dependency overrides

## Deployment Steps

### 1. Automatic Deployment (Recommended)

1. **Push to main branch**: The GitHub Actions workflow will automatically build and deploy
2. **Check deployment**: Visit https://mipon21.github.io/RIZQ-APP-ADMIN/

### 2. Manual Local Build

#### Windows
```bash
# Option 1: Use the provided script
build_web.bat

# Option 2: Manual commands
flutter clean
flutter pub get
flutter build web --base-href "/RIZQ-APP-ADMIN/"
```

#### macOS/Linux
```bash
flutter clean
flutter pub get
flutter build web --base-href "/RIZQ-APP-ADMIN/"
```

### 3. Local Testing

#### Windows
```bash
# Use the provided script
test_web.bat

# Or manual commands
flutter build web --base-href "/RIZQ-APP-ADMIN/"
cd build/web
python -m http.server 8080
```

#### macOS/Linux
```bash
flutter build web --base-href "/RIZQ-APP-ADMIN/"
cd build/web
python3 -m http.server 8080
```

Then visit: http://localhost:8080

## Configuration Details

### Firebase Configuration
- **SDK Version**: 9.23.0 (compat version)
- **Services**: Auth, Firestore, Storage, Database, Analytics
- **Configuration**: Automatically loaded from `firebase_options.dart`

### Base Href
- **Development**: `/` (root)
- **Production**: `/RIZQ-APP-ADMIN/` (GitHub Pages)

### GitHub Pages Settings
1. Go to your repository settings
2. Navigate to "Pages"
3. Set source to "GitHub Actions"
4. The workflow will automatically deploy to the `gh-pages` branch

## Troubleshooting

### Common Issues

1. **404 Errors**: Ensure base href is correctly set to `/RIZQ-APP-ADMIN/`
2. **Firebase Errors**: Check that Firebase SDK is properly loaded
3. **Build Failures**: Run `flutter clean` and `flutter pub get` before building

### Debug Steps

1. **Check Console**: Open browser dev tools and check for JavaScript errors
2. **Verify Firebase**: Ensure Firebase is initialized before Flutter loads
3. **Check Network**: Verify all assets are loading correctly

### Firebase Web Configuration

The Firebase configuration is automatically handled by:
- `lib/firebase_options.dart` - Flutter configuration
- `web/index.html` - Web SDK initialization

## File Structure

```
web/
├── index.html          # Main HTML file with Firebase config
├── manifest.json       # PWA manifest
└── icons/             # App icons

.github/workflows/
└── deploy.yml         # GitHub Actions deployment workflow

build_web.bat          # Windows build script
test_web.bat           # Windows test script
```

## Notes

- The app uses Firebase v9.23.0 compat version for better Flutter integration
- All Firebase services are properly configured for web deployment
- The GitHub Actions workflow handles the complete build and deployment process
- Local testing is available for development and debugging

# RIZQ App Deployment Guide

## GitHub Actions Workflows

This project has two GitHub Actions workflows for deploying to GitHub Pages:

### 1. Normal App Deployment (`deploy.yml`)
- **Trigger**: Push to `main` branch
- **Build**: Normal app mode (default)
- **URL**: `https://[username].github.io/rizq_u_project/`

### 2. Admin Panel Deployment (`deploy-admin.yml`)
- **Trigger**: Push to `main` branch (with path filters)
- **Build**: Admin panel mode
- **URL**: `https://[username].github.io/rizq_u_project/admin/`

## Build Configuration

### Environment Variables
- `CI=true`: Disables Firebase App Check during CI/CD builds
- `ADMIN_PANEL_ONLY=true`: Builds admin panel version
- `FLUTTER_WEB_USE_SKIA=true`: Uses Skia renderer for better performance

### Build Commands

**Normal App:**
```bash
flutter build web --release --no-tree-shake-icons --base-href "/rizq_u_project/" --dart-define=CI=true
```

**Admin Panel:**
```bash
flutter build web --release --no-tree-shake-icons --base-href "/rizq_u_project/" --dart-define=ADMIN_PANEL_ONLY=true --dart-define=CI=true
```

## Troubleshooting Build Failures

### Common Issues and Solutions

1. **Firebase App Check Errors**
   - **Problem**: reCAPTCHA verification fails in CI/CD
   - **Solution**: App Check is automatically disabled when `CI=true`

2. **Flutter Version Issues**
   - **Problem**: Version mismatch between local and CI
   - **Solution**: Update Flutter version in workflow if needed

3. **Dependency Issues**
   - **Problem**: Missing or incompatible packages
   - **Solution**: Run `flutter pub get` locally to verify dependencies

4. **Base Href Issues**
   - **Problem**: Assets not loading correctly on GitHub Pages
   - **Solution**: Ensure base href matches repository name

### Manual Build Testing

To test builds locally before pushing:

```bash
# Test normal app build
flutter build web --release --no-tree-shake-icons --base-href "/rizq_u_project/" --dart-define=CI=true

# Test admin panel build
flutter build web --release --no-tree-shake-icons --base-href "/rizq_u_project/" --dart-define=ADMIN_PANEL_ONLY=true --dart-define=CI=true
```

### GitHub Pages Configuration

1. Go to repository Settings > Pages
2. Set source to "GitHub Actions"
3. Ensure repository is public (or you have GitHub Pro for private repos)

## Local Development

### Running Locally

**Normal App:**
```bash
flutter run -d chrome
```

**Admin Panel:**
```bash
flutter run -d chrome --dart-define=ADMIN_PANEL_ONLY=true
```

### Build Scripts

Use the provided batch files for local builds:

- `build_normal_web.bat` - Build normal app
- `build_admin_web.bat` - Build admin panel

## Firebase Configuration

The app uses Firebase with the following services:
- Firebase Core
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase App Check (disabled in CI/CD)

Ensure all Firebase configuration is properly set up in `lib/firebase_options.dart`.

