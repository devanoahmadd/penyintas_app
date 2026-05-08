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

// Workaround: isar_flutter_libs 3.1.0+1 belum punya namespace di build.gradle-nya,
// tidak kompatibel dengan AGP 8+. Inject namespace saat plugin diterapkan.
subprojects {
    plugins.withType<com.android.build.gradle.LibraryPlugin> {
        the<com.android.build.gradle.LibraryExtension>().apply {
            if (namespace == null) {
                namespace = group.toString()
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
