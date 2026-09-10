allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Integration fix: sentry_flutter 8.x pins Kotlin `languageVersion = "1.6"` in its
// android/build.gradle, which the project's Kotlin 2.3 toolchain rejects
// ("Language version 1.6 is no longer supported"). Raise the language/api version
// for any subproject that still requests a retired one so the module compiles.
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            if (languageVersion.orNull != null &&
                languageVersion.get() < org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0
            ) {
                languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
            }
            if (apiVersion.orNull != null &&
                apiVersion.get() < org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0
            ) {
                apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
            }
        }
    }

    // Integration fix: sentry_flutter 8.x hardcodes `compileSdkVersion 34`, but other
    // plugins (e.g. package_info_plus) require compiling against SDK 36. Align every
    // Android subproject with the app's compileSdk (36) after it configures its own
    // android block. Guard for subprojects already evaluated via evaluationDependsOn.
    val alignCompileSdk: Project.() -> Unit = {
        extensions.findByName("android")?.withGroovyBuilder {
            "compileSdkVersion"(36)
        }
    }
    if (state.executed) alignCompileSdk() else afterEvaluate { alignCompileSdk() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
