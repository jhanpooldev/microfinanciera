// build.gradle.kts (módulo app)
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")

    // Aplicar Google services para Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.microfinanciera"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.microfinanciera"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
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
    // Firebase BoM (gestiona versiones)
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // Firebase Core
    implementation("com.google.firebase:firebase-analytics")
    
    // Agregar otros SDKs de Firebase si los necesitaras
    // ejemplo: Firestore, Auth, Storage
}
