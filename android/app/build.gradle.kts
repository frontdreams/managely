import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.managely.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.managely.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Firebase Auth requires minSdk 23.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug key when key.properties isn't present
            // (e.g. a fresh clone without the release keystore), so
            // `flutter run --release` still works out of the box.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

// Flutter's own Gradle plugin always copies the built artifacts to
// app-release.apk / app-release.aab (see FlutterPlugin.kt), ignoring any
// AGP-level outputFileName customization — so renaming has to happen as a
// step *after* that copy, not via signingConfigs/AGP output settings.
//
// This copies rather than renames/deletes app-release.{apk,aab}: the
// `flutter build` command checks for that exact original filename once
// Gradle finishes, and reports a false "failed to produce an .apk" error if
// it's gone — even though the build (and the managely.apk copy) succeeded.
tasks.register("renameReleaseArtifacts") {
    doLast {
        val apk = layout.buildDirectory.file("outputs/flutter-apk/app-release.apk").get().asFile
        if (apk.exists()) {
            apk.copyTo(File(apk.parentFile, "managely.apk"), overwrite = true)
        }
        val aab = layout.buildDirectory.file("outputs/bundle/release/app-release.aab").get().asFile
        if (aab.exists()) {
            aab.copyTo(File(aab.parentFile, "managely.aab"), overwrite = true)
        }
    }
}

afterEvaluate {
    tasks.findByName("assembleRelease")?.finalizedBy("renameReleaseArtifacts")
    tasks.findByName("bundleRelease")?.finalizedBy("renameReleaseArtifacts")
}
