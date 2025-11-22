plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin should be applied after Android and Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.waygo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        this.sourceCompatibility = JavaVersion.VERSION_11
        this.targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.waygo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        minSdk = flutter.minSdkVersion  // Stripe requires at least 21
        
    }

    buildTypes {
        getByName("release") {
            // TODO: Add your own signing config for release
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = file("../..")
}
