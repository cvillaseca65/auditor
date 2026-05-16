allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Desactiva tareas lintVital (bloqueos de archivo en Windows/OneDrive).
// Unifica NDK: plugins nativos (p. ej. `:jni`) pueden pedir otra `ndkVersion` que
// choca con `ndk.dir` en local.properties; forzamos la misma que `:app`.
subprojects {
    afterEvaluate {
        tasks.matching { it.name.startsWith("lintVital") }.configureEach {
            enabled = false
        }
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        try {
            androidExt.javaClass
                .getMethod("setNdkVersion", String::class.java)
                .invoke(androidExt, "29.0.14206865")
        } catch (_: Throwable) {
            // No es proyecto Android o API distinta
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
