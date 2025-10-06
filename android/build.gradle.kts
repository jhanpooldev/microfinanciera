// build.gradle.kts (raíz del proyecto)
plugins {
    // Plugins Android y Kotlin (apply false, se aplican solo en módulos)
    id("com.android.application") apply false
    id("kotlin-android") apply false
    id("dev.flutter.flutter-gradle-plugin") apply false

    // Google Services para Firebase
    id("com.google.gms.google-services") version "4.4.3" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Opcional: cambiar carpeta build para Flutter
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
