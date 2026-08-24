plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.viprasetu.app"
    compileSdk = 37 
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.viprasetu.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = project.findProperty("VIPRA_UPLOAD_STORE_FILE")?.toString()
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = file(storeFilePath)
                storePassword = project.findProperty("VIPRA_UPLOAD_STORE_PASSWORD")?.toString()
                keyAlias = project.findProperty("VIPRA_UPLOAD_KEY_ALIAS")?.toString()
                keyPassword = project.findProperty("VIPRA_UPLOAD_KEY_PASSWORD")?.toString()
            }
        }
    }

    buildTypes {
        release {
            val hasReleaseSigning =
                !project.findProperty("VIPRA_UPLOAD_STORE_FILE")?.toString().isNullOrBlank()
            signingConfig = signingConfigs.getByName(if (hasReleaseSigning) "release" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
