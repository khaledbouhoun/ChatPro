plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter MUST come before google-services
    id("dev.flutter.flutter-gradle-plugin")
    // google-services MUST be last
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.chat_pro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.chat_pro"

        // Hardcoded to 21 — flutter.minSdkVersion resolves to 16
        // which breaks: permission_handler, record, file_picker, Firebase
        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}
