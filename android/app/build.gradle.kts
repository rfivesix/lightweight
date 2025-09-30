// android/app/build.gradle.kts
import java.util.Properties

val localProps = Properties().apply {
    load(rootProject.file("local.properties").inputStream())
}
val flutterVersionName = localProps.getProperty("flutter.versionName") ?: "0.0.0"
val flutterVersionCode = (localProps.getProperty("flutter.versionCode") ?: "1").toInt()

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.lightweight"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.lightweight"
        versionName = flutterVersionName
        versionCode = flutterVersionCode

        minSdk = flutter.minSdkVersion            // ← add this
        targetSdk = 36      // optional; you can set it or let Flutter handle it
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") { }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions { jvmTarget = "1.8" }
}

flutter { source = "../.." }
