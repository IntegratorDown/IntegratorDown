package com.integratordown.app.shell

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.integratordown.app.AppContainer
import com.integratordown.app.data.AppearanceState
import com.integratordown.app.data.ThemeMode
import com.integratordown.app.nav.AppNavigator
import com.integratordown.app.nav.LocalNavigator
import com.integratordown.fluxui.theme.FluxTheme

/** 各 Activity 的组合根：外观偏好 → [FluxTheme]，并注入进程级容器与该窗口自己的导航状态。 */
@Composable
fun FluxAppRoot(container: AppContainer, navigator: AppNavigator, content: @Composable () -> Unit) {
    val appearance by container.appearance.state.collectAsStateWithLifecycle(AppearanceState())
    val dark = when (appearance.mode) {
        ThemeMode.System -> isSystemInDarkTheme()
        ThemeMode.Dark -> true
        ThemeMode.Light -> false
    }
    FluxTheme(dark = dark, accent = appearance.accent) {
        CompositionLocalProvider(
            LocalAppContainer provides container,
            LocalNavigator provides navigator,
            content = content,
        )
    }
}
