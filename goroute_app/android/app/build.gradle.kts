plugins {
    id("com.android.application")
    id("kotlin-android")

    // 🔥 Firebase plugin
    id("com.google.gms.google-services")

    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.goroute_app"
    compileSdk = flutter.compileSdkVersion

    // ✅ FIXED NDK VERSION
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.goroute_app"

        // ✅ FIXED (VERY IMPORTANT)
        minSdk = 23

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ⚠️ change this later for production
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // 🔥 Firebase BOM (manages versions automatically)
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))

    // 🔥 Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}