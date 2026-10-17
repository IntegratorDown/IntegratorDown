package com.integratordown.app.feature.settings

import androidx.compose.runtime.Composable
import com.integratordown.app.feature.settings.account.AccountPage
import com.integratordown.app.feature.settings.bt.BtPage
import com.integratordown.app.feature.settings.bt.Ed2kPage
import com.integratordown.app.feature.settings.diagnostics.DiagnosticsPage
import com.integratordown.app.feature.settings.extensions.ExtensionsPage
import com.integratordown.app.feature.settings.extensions.PluginDetailPage
import com.integratordown.app.feature.settings.extensions.PluginMarketPage
import com.integratordown.app.feature.settings.general.GeneralPage
import com.integratordown.app.feature.settings.general.NotifyPage
import com.integratordown.app.feature.settings.network.NetworkPage
import com.integratordown.app.feature.settings.service.ApiServicePage
import com.integratordown.app.feature.settings.service.WebhookPage
import com.integratordown.app.nav.SettingsPage

/** 设置推入页分发（S2–S14）。 */
@Composable
fun SettingsPageScreen(page: SettingsPage, arg: String) {
    when (page) {
        SettingsPage.Account -> AccountPage()
        SettingsPage.General -> GeneralPage()
        SettingsPage.Appearance -> AppearancePage()
        SettingsPage.Notify -> NotifyPage()
        SettingsPage.Download -> DownloadPage()
        SettingsPage.Bt -> BtPage()
        SettingsPage.Ed2k -> Ed2kPage()
        SettingsPage.Network -> NetworkPage()
        SettingsPage.Extensions -> ExtensionsPage()
        SettingsPage.PluginMarket -> PluginMarketPage()
        SettingsPage.PluginDetail -> PluginDetailPage(pluginId = arg)
        SettingsPage.Webhook -> WebhookPage()
        SettingsPage.Api -> ApiServicePage()
        SettingsPage.Diagnostics -> DiagnosticsPage()
        SettingsPage.About -> AboutPage()
    }
}
