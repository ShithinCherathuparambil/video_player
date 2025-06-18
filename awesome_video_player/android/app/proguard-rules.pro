# Add project specific ProGuard rules here.
# By default, the flags in "proguard-android-optimize.txt" from the Android SDK
# are automatically applied.
# You can also load other ProGuard rules files by adding a visit to the
# build.gradle file. See
# https://developer.android.com/build/building-cmdline#shrink-code

# Rules for media_store_plus plugin (due to internal GSON usage)
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }
-keep class kotlin.jvm.internal.** { *; }
-keep class kotlin.Metadata { *; } 