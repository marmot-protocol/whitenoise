import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val hasGoogleServicesConfig =
    file("google-services.json").exists() ||
        file("src/main/google-services.json").exists() ||
        file("src/staging/google-services.json").exists() ||
        file("src/production/google-services.json").exists()

if (hasGoogleServicesConfig) {
    apply(plugin = "com.google.gms.google-services")
}

fun loadKeystoreProperties(fileName: String): Properties? {
    val propertiesFile = rootProject.file(fileName)
    if (!propertiesFile.exists()) {
        return null
    }

    return Properties().apply {
        propertiesFile.inputStream().use { load(it) }
    }
}

fun requireKeystoreProperty(properties: Properties, fileName: String, propertyName: String): String {
    val value = properties.getProperty(propertyName)
    require(!value.isNullOrBlank()) {
        "Missing android/$fileName property: $propertyName"
    }
    return value
}

fun requireKeystoreProperties(properties: Properties?, fileName: String): Properties {
    requireNotNull(properties) {
        "Missing android/$fileName for release signing"
    }
    return properties
}

val productionKeystorePropertiesFileName = "key.properties"
val productionKeystoreProperties = loadKeystoreProperties(productionKeystorePropertiesFileName)
val stagingKeystorePropertiesFileName = "key-staging.properties"
val stagingKeystoreProperties = loadKeystoreProperties(stagingKeystorePropertiesFileName)

val requestedTaskNames = gradle.startParameter.taskNames
val buildsStagingRelease = requestedTaskNames.any {
    it.contains("StagingRelease", ignoreCase = true)
}
val buildsProductionRelease = requestedTaskNames.any {
    it.contains("ProductionRelease", ignoreCase = true)
}

android {
    namespace = "org.parres.whitenoise"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "org.parres.whitenoise"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("staging") {
            if (buildsStagingRelease) {
                val properties = requireKeystoreProperties(
                    stagingKeystoreProperties,
                    stagingKeystorePropertiesFileName,
                )
                storeFile = rootProject.file(
                    requireKeystoreProperty(
                        properties,
                        stagingKeystorePropertiesFileName,
                        "storeFile",
                    ),
                )
                storePassword = requireKeystoreProperty(
                    properties,
                    stagingKeystorePropertiesFileName,
                    "storePassword",
                )
                keyAlias = requireKeystoreProperty(
                    properties,
                    stagingKeystorePropertiesFileName,
                    "keyAlias",
                )
                keyPassword = requireKeystoreProperty(
                    properties,
                    stagingKeystorePropertiesFileName,
                    "keyPassword",
                )
            }
        }

        create("production") {
            if (buildsProductionRelease) {
                val properties = requireKeystoreProperties(
                    productionKeystoreProperties,
                    productionKeystorePropertiesFileName,
                )
                storeFile = rootProject.file(
                    requireKeystoreProperty(
                        properties,
                        productionKeystorePropertiesFileName,
                        "storeFile",
                    ),
                )
                storePassword = requireKeystoreProperty(
                    properties,
                    productionKeystorePropertiesFileName,
                    "storePassword",
                )
                keyAlias = requireKeystoreProperty(
                    properties,
                    productionKeystorePropertiesFileName,
                    "keyAlias",
                )
                keyPassword = requireKeystoreProperty(
                    properties,
                    productionKeystorePropertiesFileName,
                    "keyPassword",
                )
            }
        }
    }

    flavorDimensions += "environment"

    productFlavors {
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            manifestPlaceholders["deepLinkScheme"] = "whitenoise-staging"
            resValue("string", "app_name", "WN Staging")
        }
        create("production") {
            dimension = "environment"
            manifestPlaceholders["deepLinkScheme"] = "whitenoise"
            resValue("string", "app_name", "White Noise")
        }
    }

    buildTypes {
        release {
        }
    }

    productFlavors {
        getByName("staging") {
            signingConfig = signingConfigs.getByName("staging")
        }
        getByName("production") {
            signingConfig = signingConfigs.getByName("production")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.gms:play-services-base:18.10.0")
    implementation(platform("com.google.firebase:firebase-bom:34.13.0"))
    implementation("com.google.firebase:firebase-messaging")
}

flutter {
    source = "../.."
}
