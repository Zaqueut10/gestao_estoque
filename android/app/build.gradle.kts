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

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    throw GradleException("Arquivo key.properties não encontrado na raiz do projeto.")
}

android {
    namespace = "com.zfautomation.gestao_estoque"
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
        applicationId = "com.zfautomation.gestao_estoque"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyAliasProp = keystoreProperties["keyAlias"]?.toString()
            val keyPasswordProp = keystoreProperties["keyPassword"]?.toString()
            val storeFileProp = keystoreProperties["storeFile"]?.toString()
            val storePasswordProp = keystoreProperties["storePassword"]?.toString()

            if (keyAliasProp == null || keyPasswordProp == null || storeFileProp == null || storePasswordProp == null) {
                throw GradleException("Erro ao carregar key.properties. Verifique se o arquivo existe na raiz do projeto e se as chaves estão corretas.")
            }

            keyAlias = keyAliasProp
            keyPassword = keyPasswordProp
            storeFile = file(storeFileProp)
            storePassword = storePasswordProp
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}