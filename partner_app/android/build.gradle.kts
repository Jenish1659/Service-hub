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

subprojects {
    val configureAndroid = Action<Project> {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val compileSdkVersionMethod = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                compileSdkVersionMethod.invoke(android, 36)
            } catch (e: Exception) {
                // Ignored fallback
            }
            try {
                val buildToolsVersionMethod = android.javaClass.getMethod("buildToolsVersion", String::class.java)
                buildToolsVersionMethod.invoke(android, "36.0.0")
            } catch (e: Exception) {
                // Ignored fallback
            }
        }
    }
    if (state.executed) {
        configureAndroid.execute(this)
    } else {
        afterEvaluate(configureAndroid)
    }
}

subprojects {
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.addAll(listOf("-Xlint:-options", "-Xlint:-deprecation", "-nowarn"))
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
