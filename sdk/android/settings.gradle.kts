pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        maven("https://raw.githubusercontent.com/iProov/android/master/maven/")
        google()
        mavenCentral()
    }
}

rootProject.name = "Iproov_firebase"
include(":iproov_firebase")
include(":example-app")
