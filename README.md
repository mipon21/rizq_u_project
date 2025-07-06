# rizq_u

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Web Deployment

### GitHub Pages Deployment

This project is configured to deploy to GitHub Pages automatically. The web app is deployed at: https://mipon21.github.io/RIZQ-APP-ADMIN/

#### Automatic Deployment
- Push to the `main` branch to trigger automatic deployment
- The GitHub Actions workflow will build and deploy the app

#### Manual Local Build
To build the web app locally for testing:

1. **Windows**: Run `build_web.bat`
2. **Manual**: Run these commands:
   ```bash
   flutter clean
   flutter pub get
   flutter build web --base-href "/RIZQ-APP-ADMIN/"
   ```

#### Testing Locally
After building, test locally with:
```bash
flutter run -d chrome --web-port 8080
```

### Important Notes
- The app is configured with base href `/RIZQ-APP-ADMIN/` for GitHub Pages
- Firebase is configured for web deployment
- All assets and dependencies are properly configured for web deployment
