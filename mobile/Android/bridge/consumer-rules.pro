# UniFFI Kotlin 绑定经 JNA 反射 / 回调访问 libintegratordown_mobile.so：JNA 与生成的绑定类（含 Structure、Callback、
# UniffiHandle 等内部类型）不得被混淆或裁剪。
-keep class com.sun.jna.** { *; }
-keep class * implements com.sun.jna.** { *; }
-keep class com.integratordown.bridge.** { *; }
-dontwarn java.awt.**
