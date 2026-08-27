allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Provide fallback sdk versions for older plugins
extra.set("compileSdkVersion", 35)
extra.set("minSdkVersion", 24)
extra.set("targetSdkVersion", 35)

subprojects {
    plugins.withId("com.android.library") {
        val androidExt = extensions.getByName("android")
        if (androidExt is org.gradle.api.plugins.ExtensionAware) {
            try {
                androidExt.extensions.extraProperties.set("flutter", this@subprojects.project)
            } catch (e: Exception) {}
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory =
        newBuildDir.dir(project.name)

    project.layout.buildDirectory.value(
        newSubprojectBuildDir
    )
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}