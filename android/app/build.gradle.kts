// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.lightweight"        // <- BEHALTE DEINEN WERT
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.lightweight" // <- BEHALTE DEINEN WERT
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 3                   // 0.0.3
        versionName = "0.0.3"
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            // TEMP: Release mit Debug-Keys signieren (installierbar, nicht Play-Store-tauglich)
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") { /* default */ }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
}

flutter {
    source = "../.."
}
