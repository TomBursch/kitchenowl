import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.tombursch.kitchenowl"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.tombursch.kitchenowl"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        resourceConfigurations += listOf(
            "en", "ar", "be", "bg", "br", "ca", "ca_valencia", "cs", "da", "de", 
            "de_CH", "el", "es", "et", "eu", "fa", "fi", "fr", "he", "hi", "hr", 
            "hu", "id", "it", "ja", "kab", "kk", "ko", "lt", "nb", "nl", "pa", 
            "pl", "pt", "pt_BR", "ro", "ru", "sk", "sl", "sr", "sv", "ta", "te", 
            "tr", "uk", "vi", "zh", "zh_HANT"
        )
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            val storeFileProp = keystoreProperties["storeFile"] as String?
            storeFile = if (storeFileProp != null) file(storeFileProp) else null
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
