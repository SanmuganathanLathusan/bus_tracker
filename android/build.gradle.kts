buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.1")
        classpath("com.google.gms:google-services:4.4.3")
        classpath(kotlin("gradle-plugin", version = "1.9.10"))
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
