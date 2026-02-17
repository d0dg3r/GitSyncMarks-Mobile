pluginManagement {
    val gradlePath =
        System.getenv("FLUTTER_GRADLE_PATH")
            ?: System.getProperty("user.home") + "/.local/flutter-gradle/gradle"
    includeBuild(file(gradlePath).toString())

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
