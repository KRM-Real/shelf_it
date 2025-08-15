# 🔐 Firebase Security Setup Guide

## ⚠️ IMPORTANT SECURITY NOTICE

**NEVER commit sensitive Firebase configuration files to version control!**

The following files contain sensitive API keys and should be kept private:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- Any `.env` files with API keys

## 🛠️ Setup Instructions

### 1. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing project
3. Enable the following services:
   - Authentication
   - Firestore Database
   - Analytics (optional)

### 2. Android Configuration

1. In Firebase Console, add an Android app
2. Use package name: `com.example.shelf_it` (or update to your package name)
3. Download the `google-services.json` file
4. Place it in: `android/app/google-services.json`
5. **DO NOT commit this file to git!**

### 3. iOS Configuration (if needed)

1. In Firebase Console, add an iOS app
2. Use bundle ID: `com.example.shelfIt` (or update to your bundle ID)
3. Download the `GoogleService-Info.plist` file
4. Place it in: `ios/Runner/GoogleService-Info.plist`
5. **DO NOT commit this file to git!**

### 4. Environment Variables (Recommended)

For production apps, consider using environment variables:

1. Create a `.env` file in the project root:
```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
FIREBASE_AUTH_DOMAIN=your-project-id.firebaseapp.com
FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com
```

2. Add `.env` to your `.gitignore` file (already done)

3. Use packages like `flutter_dotenv` to load environment variables

### 5. Security Best Practices

1. **Rotate API Keys**: If keys are accidentally exposed, rotate them immediately
2. **Restrict API Keys**: In Google Cloud Console, restrict your API keys to specific services
3. **Use Firebase Security Rules**: Implement proper security rules for Firestore
4. **Monitor Usage**: Set up alerts for unusual API usage

### 6. Team Development

For team development:
1. Share configuration files securely (encrypted, not in git)
2. Use different Firebase projects for dev/staging/production
3. Document the setup process for new team members

## 🚨 If API Keys Are Exposed

If you accidentally commit sensitive keys:

1. **Immediately rotate the keys** in Firebase Console
2. **Remove from git history** using `git filter-branch` or BFG Repo-Cleaner
3. **Update your application** with new keys
4. **Monitor for unauthorized usage**

## 📝 Example Configuration Files

Sample configuration files are provided:
- `android/app/google-services.json.example`

Copy these to the actual file names and replace with your real values.
