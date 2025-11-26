# Flutter Voice to Text - IBM Watson

This is a Flutter application that captures voice notes and converts them to text using IBM Watson Speech to Text service.

## Setup

1.  **Flutter Environment**: Ensure Flutter is installed and in your PATH.
    - Run `flutter doctor` to verify.
    - If you haven't created the platform folders yet (android, ios, etc.), run:
      ```bash
      flutter create .
      ```

2.  **Dependencies**:
    - Run `flutter pub get` to install the required packages.

3.  **IBM Watson Configuration**:
    - Open `lib/services/watson_service.dart`.
    - Replace `YOUR_API_KEY` with your IBM Cloud IAM API Key.
    - Replace `YOUR_SERVICE_URL` with your IBM Watson Speech to Text URL (e.g., `https://api.us-south.speech-to-text.watson.cloud.ibm.com/instances/...`).

4.  **Permissions**:
    - **Android**: Open `android/app/src/main/AndroidManifest.xml` and add:
      ```xml
      <uses-permission android:name="android.permission.RECORD_AUDIO" />
      <uses-permission android:name="android.permission.INTERNET" />
      ```
    - **iOS**: Open `ios/Runner/Info.plist` and add:
      ```xml
      <key>NSMicrophoneUsageDescription</key>
      <string>We need access to the microphone to record voice notes.</string>
      ```

## Running the App

Run the following command in your terminal:

```bash
flutter run
```

## Features

- **Record Audio**: Capture voice notes using the device microphone.
- **Transcribe**: Automatically sends audio to IBM Watson for transcription.
- **Save Notes**: Store transcribed notes locally in a list.
