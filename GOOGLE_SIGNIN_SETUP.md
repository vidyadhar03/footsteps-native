# Google Sign-In Setup Guide

This guide explains how to fix the Google Sign-In `ApiException: 10` error and properly configure Google Sign-In for your Flutter app.

## Issues Fixed

1. ✅ **Widget lifecycle issues** - Fixed dispose method to safely handle Provider context
2. ✅ **Missing Google Services plugin** - Added Google Services plugin to Android build
3. ✅ **Updated Android NDK version** - Updated to version 27.0.12077973 as required
4. ✅ **Created configuration templates** - Added .env and google-services.json templates

## Configuration Steps

### 1. Environment Variables

Copy the content from `env_template.txt` to create a `.env.local` file:

```bash
cp env_template.txt .env.local
```

Then edit `.env.local` with your actual values:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key

# Google OAuth Client IDs
GOOGLE_CLIENT_ID=your_android_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_ID_IOS=your_ios_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_ID_WEB=your_web_client_id.apps.googleusercontent.com
```

### 2. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Sign-In API
4. Go to **Credentials** → **Create Credentials** → **OAuth client ID**

#### For Android:
- Application type: **Android**
- Package name: `com.example.footsteps`
- SHA-1 certificate fingerprint: Get this by running:
  ```bash
  keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
  ```
  Default password is usually `android`

#### For iOS:
- Application type: **iOS**
- Bundle ID: `com.example.footsteps`

#### For Web:
- Application type: **Web application**
- Authorized JavaScript origins: `http://localhost:3000`

### 3. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing
3. Add an Android app with package name: `com.example.footsteps`
4. Download the `google-services.json` file

### 4. Configure google-services.json

1. Take the template file `android/app/google-services.json.template`
2. Replace it with the actual `google-services.json` file you downloaded from Firebase
3. Or manually edit the template with your Firebase project values:

```json
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "your-project-id",
    "storage_bucket": "your-project-id.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abcdef123456",
        "android_client_info": {
          "package_name": "com.example.footsteps"
        }
      },
      "oauth_client": [
        {
          "client_id": "123456789-abcdef123456.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.example.footsteps",
            "certificate_hash": "your_sha1_hash"
          }
        }
      ]
    }
  ]
}
```

### 5. Get SHA-1 Certificate Hash

For **debug builds** (development):
```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
```

For **release builds** (production):
```bash
keytool -list -v -alias your_key_alias -keystore /path/to/your/keystore.jks
```

### 6. Update Firebase Authentication Settings

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Google** sign-in provider
3. Add your **Web client ID** from Google Cloud Console

### 7. Build and Test

1. Clean your project:
   ```bash
   flutter clean
   flutter pub get
   ```

2. Build for Android:
   ```bash
   flutter build apk --debug
   ```

3. Install on your device:
   ```bash
   flutter install
   ```

## Common Issues and Solutions

### Issue: `ApiException: 10` (DEVELOPER_ERROR)

**Cause**: Android app not properly configured for Google Sign-In

**Solutions**:
1. Ensure `google-services.json` is in `android/app/` directory
2. Verify SHA-1 certificate hash matches in Firebase Console
3. Check package name consistency across all configurations
4. Ensure Google Services plugin is properly applied

### Issue: `No Firebase App '[DEFAULT]' has been created`

**Cause**: Firebase not initialized properly

**Solutions**:
1. Ensure `google-services.json` is properly configured
2. Verify Google Services plugin is added to `build.gradle.kts`
3. Check if Firebase project is properly set up

### Issue: `PlatformException(sign_in_failed)`

**Cause**: OAuth client configuration mismatch

**Solutions**:
1. Verify OAuth client ID in `.env.local` matches Google Cloud Console
2. Check if the app is signed with the correct certificate
3. Ensure all OAuth scopes are properly configured

## Testing

1. Test on a physical device (emulator might have issues)
2. Check logs for detailed error messages
3. Verify network connectivity
4. Test both debug and release builds

## Important Notes

- **Never commit** `.env.local` or `google-services.json` to version control
- Use different Firebase projects for development and production
- Test on multiple devices to ensure consistency
- Keep your OAuth client secrets secure

## Support

If you continue to have issues:
1. Check Firebase Console logs
2. Verify all configuration files are in place
3. Test with a clean build
4. Check device date/time settings
5. Ensure Google Play Services is updated on the device 