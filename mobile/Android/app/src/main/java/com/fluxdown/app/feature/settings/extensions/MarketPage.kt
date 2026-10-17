package com.integratordown.app.feature.settings.extensions

import androidx.annotation.StringRes
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.integratordown.app.R
import com.integratordown.app.feature.settings.SettingsPageFrame
import com.integratordown.app.feature.settings.flowItem
import com.integratordown.app.feature.settings.rememberLastNonNull
import com.integratordown.app.i18n.str
import com.integratordown.app.nav.LocalNavigator
import com.integratordown.app.shell.hostState
import com.integratordown.core.protocol.MarketAction
import com.integratordown.core.protocol.MarketEntry
import com.integratordown.core.protocol.PluginDetail
import com.integratordown.core.protocol.PluginDto
import com.integratordown.core.protocol.PluginMarket
import com.integratordown.fluxui.controls.ButtonVariant
import com.integratordown.fluxui.controls.FluxActionRow
import com.integratordown.fluxui.controls.FluxButton
import com.integratordown.fluxui.controls.FluxField
import com.integratordown.fluxui.controls.FluxFieldAction
import com.integratordown.fluxui.controls.GlassSection
import com.integratordown.fluxui.controls.Tone
import com.integratordown.fluxui.feedback.FluxEmpty
import com.integratordown.fluxui.feedback.FluxGlyph
import com.integratordown.fluxui.feedback.FluxSpinner
import com.integratordown.fluxui.icons.FluxIcon
import com.integratordown.fluxui.icons.FluxIcons
import com.integratordown.fluxui.material.rememberFlowInGate
import com.integratordown.fluxui.overlay.FluxBannerKind
import com.integratordown.fluxui.overlay.FluxBanner
import com.integratordown.fluxui.overlay.FluxPortal
import com.integratordown.fluxui.overlay.FluxSheet
import com.integratordown.fluxui.overlay.FluxSheetDetent
import com.integratordown.fluxui.overlay.FluxSheetFooter
import com.integratordown.fluxui.overlay.FluxSheetHeader
import com.integratordown.fluxui.theme.FluxText
import com.integratordown.fluxui.theme.FluxTheme
import com.integratordown.fluxui.theme.fluxPressable

/**
 * S11.2 · 插件市场：`daemon.plugin.marketList` 拉取索引，本地关键字过滤 + 分页展开，`marketInstall` 安装
 * （安装前确认权限，撤回版本不可安装）。点条目打开详情 Sheet（撤回条目顶部红色横幅），安装 / 更新在其底部。
 */
@Composable
internal fun PluginMarketPage() {
    val nav = LocalNavigator.current
    val model = rememberExtensionsModel()
    val env = rememberExtensionsEnv()
    val hostState = hostState()
    val readOnly by remember { derivedStateOf { hostState.value.isReadOnly } }
    val plugins by rememberPlugins()
    val gate = rememberFlowInGate()
    val focusManager = LocalFocusManager.current
    var query by remember { mutableStateOf("") }
    var limit by remember(query) { mutableIntStateOf(PluginMarket.PAGE_SIZE) }
    var detail by remember { mutableStateOf<MarketEntry?>(null) }

    LaunchedEffect(readOnly) { model.ensureMarketLoaded(env) }
    PluginAutoDisabledEffect(env)

    val latest = model.marketLatest
    val filtered = remember(latest, query) { PluginMarket.filter(latest, query) }
    val installedById = remember(plugins) { plugins.associateBy { it.identity } }
    val phase = model.marketPhase

    Box(Modifier.fillMaxSize()) {
        SettingsPageFrame(title = str(R.string.marketSectionTitle), onBack = { nav.pop() }) {
            var index = 0
            if (readOnly) {
                flowItem(index++, gate, "banner") {
                    FluxBanner(str(R.string.localServiceDisconnected), kind = FluxBannerKind.Warn, slim = true)
                }
            }
            flowItem(index++, gate, "search") {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    FluxField(
                        value = query,
                        onValueChange = { query = it },
                        placeholder = str(R.string.marketSearchPlaceholder),
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                        keyboardActions = KeyboardActions(onSearch = { focusManager.clearFocus() }),
                        trailing = {
                            if (query.isNotEmpty()) {
                                FluxFieldAction(FluxIcons.X, str(R.string.close), { query = "" })
                            }
                        },
                    )
                    GlassSection {
                        row(hasIcon = true) {
                            FluxActionRow(
                                title = str(R.string.marketRefreshTooltip),
                                icon = FluxIcons.RefreshCw,
                                loading = phase == ExtensionsModel.MarketPhase.Loading,
                                enabled = !readOnly && phase != ExtensionsModel.MarketPhase.Loading,
                                onClick = { model.loadMarket(env) },
                            )
                        }
                    }
                }
            }
            when {
                latest.isEmpty() && phase == ExtensionsModel.MarketPhase.Loading -> flowItem(index++, gate, "loading") {
                    Row(
                        Modifier.fillMaxWidth().padding(vertical = 32.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterHorizontally),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        FluxSpinner(size = 20.dp, label = str(R.string.pluginCommonLoading))
                        FluxText(str(R.string.pluginCommonLoading), style = FluxTheme.type.sm, color = FluxTheme.colors.inkMuted)
                    }
                }
                latest.isEmpty() && phase is ExtensionsModel.MarketPhase.Failed -> flowItem(index++, gate, "failed") {
                    FluxEmpty(
                        glyph = FluxGlyph.Plug,
                        title = str(R.string.marketLoadFailed, "message" to phase.message),
                        action = {
                            FluxButton(
                                str(R.string.mobileRetry),
                                onClick = { model.loadMarket(env) },
                                variant = ButtonVariant.Primary,
                                enabled = !readOnly,
                            )
                        },
                    )
                }
                latest.isEmpty() && phase == ExtensionsModel.MarketPhase.Loaded -> flowItem(index++, gate, "empty") {
                    FluxEmpty(glyph = FluxGlyph.Inbox, title = str(R.string.marketEmpty))
                }
                latest.isNotEmpty() && filtered.isEmpty() -> flowItem(index++, gate, "noResult") {
                    FluxEmpty(glyph = FluxGlyph.Search, title = str(R.string.marketSearchNoResult))
                }
            }
            if (filtered.isNotEmpty()) {
                flowItem(index++, gate, "list") {
                    GlassSection {
                        for (entry in filtered.take(limit)) {
                            val current = installedById[entry.pluginId]
                            row {
                                MarketRow(
                                    entry = entry,
                                    installed = current,
                                    installedYanked = current?.let { PluginMarket.installedVersionYanked(model.marketEntries, it) },
                                    pending = entry.pluginId in model.marketPending,
                                    onClick = { detail = entry },
                                )
                            }
                        }
                        if (filtered.size > limit) {
                            row {
                                FluxActionRow(
                                    title = str(R.string.marketShowMore, "count" to (filtered.size - limit)),
                                    onClick = { limit += PluginMarket.PAGE_SIZE },
                                )
                            }
                        }
                    }
                }
            }
        }
        MarketDetailSheet(entry = detail, model = model, env = env, readOnly = readOnly, plugins = plugins, onDismiss = { detail = null })
        ExtensionsOverlays(model, env)
    }
}

@StringRes
private fun actionTitle(action: MarketAction, pending: Boolean): Int {
    if (pending) return if (action == MarketAction.Update) R.string.marketUpdatingButton else R.string.marketInstallingButton
    return when (action) {
        MarketAction.Install -> R.string.marketInstallButton
        MarketAction.Update -> R.string.marketUpdateButton
        MarketAction.Installed -> R.string.marketInstalledButton
        MarketAction.Unavailable -> R.string.marketUnavailableButton
    }
}

@Composable
private fun MarketRow(
    entry: MarketEntry,
    installed: PluginDto?,
    installedYanked: String?,
    pending: Boolean,
    onClick: () -> Unit,
) {
    val c = FluxTheme.colors
    val t = FluxTheme.type
    val action = PluginMarket.action(entry, installed)
    val badges = ArrayList<Badge>()
    yankedLabelRes(entry.yanked)?.let { badges += Badge(str(it), Tone.Coral, FluxIcons.ShieldAlert) }
    installedYanked?.let { y ->
        yankedLabelRes(y)?.let {
            badges += Badge(str(R.string.pluginInstalledVersionYanked, "label" to str(it)), Tone.Coral, FluxIcons.ShieldAlert)
        }
    }
    Column(
        Modifier
            .fillMaxWidth()
            .fluxPressable(onClick = onClick, scale = 0.99f)
            .heightIn(min = 56.dp)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            FluxText(entry.displayName, Modifier.weight(1f, fill = false), style = t.weight(t.body, 500), color = c.ink, maxLines = 2)
            FluxText("v${entry.version}", style = t.monoS, color = c.inkMuted, maxLines = 1)
            if (entry.author.isNotEmpty()) {
                FluxText(entry.author, Modifier.weight(1f, fill = false), style = t.sm, color = c.inkMuted, maxLines = 1)
            }
            Box(Modifier.weight(1f))
            if (pending) {
                FluxSpinner(size = 16.dp, label = str(actionTitle(action, true)))
            } else if (action != MarketAction.Install) {
                BadgeFlow(listOf(Badge(str(actionTitle(action, false)), if (action == MarketAction.Update) Tone.Accent else Tone.Neutral)))
            }
        }
        if (entry.homepage.isNotEmpty()) FluxText(entry.homepage, style = t.sm, color = c.inkMuted, maxLines = 1)
        if (entry.description.isNotEmpty()) FluxText(entry.description, style = t.sm, color = c.inkMuted, maxLines = 2)
        BadgeFlow(badges)
    }
}

/** 市场条目详情（撤回条目顶部红色横幅）；安装 / 更新在底部。 */
@Composable
private fun MarketDetailSheet(
    entry: MarketEntry?,
    model: ExtensionsModel,
    env: ExtensionsEnv,
    readOnly: Boolean,
    plugins: List<PluginDto>,
    onDismiss: () -> Unit,
) {
    val shown = rememberLastNonNull(entry)
    FluxPortal {
        FluxSheet(
            visible = entry != null,
            onDismissRequest = onDismiss,
            detent = FluxSheetDetent.Full,
            title = shown?.displayName,
            header = {
                if (shown != null) FluxSheetHeader(title = shown.displayName, subtitle = "v${shown.version}", onClose = onDismiss)
            },
            footer = {
                if (shown != null) {
                    val installed = plugins.firstOrNull { it.identity == shown.pluginId }
                    val action = PluginMarket.action(shown, installed)
                    val pending = shown.pluginId in model.marketPending
                    FluxSheetFooter {
                        FluxButton(str(R.string.close), onClick = onDismiss, modifier = Modifier.weight(1f))
                        if (action == MarketAction.Install || action == MarketAction.Update || pending) {
                            FluxButton(
                                str(actionTitle(action, pending)),
                                onClick = { model.requestInstall(env, shown, installed) },
                                modifier = Modifier.weight(1f),
                                variant = ButtonVariant.Primary,
                                loading = pending,
                                enabled = !readOnly,
                            )
                        }
                    }
                }
            },
        ) {
            if (shown != null) PluginInfoBlock(PluginDetail.of(shown), env)
        }
    }
}
