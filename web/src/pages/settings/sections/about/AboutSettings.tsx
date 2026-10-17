// 关于（GPUI `crates/settings/src/sections/about.rs`）：版本、软件更新、日志导出、浏览器扩展与捐赠链接。
// 桌面专属的「打开日志目录」不在 Web 出现；更新由 agent 驱动（后台检查 / 下载 / 校验），
// 这里按 `snapshot.update` 展示状态，并提供「更新并重启」、取消下载、手动升级入口（Docker / NAS 为页内说明）。

import { useState } from 'react'
import { useT } from '../../../../i18n'
import { exportLogs, rpc, useRpcSelector } from '../../../../lib/rpc'
import { Button, toast } from '../../../../ui'
import { rpcErrorText } from '../../../../lib/rpcErrorText'
import { canCancel, canInstall, manualLine, manualUrl, statusLine, updateLineText, useUpdateStatus } from '../../../../lib/update'
import { DaemonNumberRow, PrefDropdownRow, PrefSwitchRow, SettingsCustomRow, SettingsPage, SettingsRow, SettingsSection, useSettingsReadOnly, usePrefString } from '../../kit'

/** 服务端资产随统一的 `vX.Y.Z` release 发布（更早版本在 `server-v*` release）。 */
const SERVER_RELEASES = ''

function openUrl(url: string) {
  if (!url) return
  window.open(url, '_blank', 'noopener,noreferrer')
}

function LinkButtons({ links }: { links: readonly { label: string; url: string }[] }) {
  const visible = links.filter((link) => link.url)
  if (visible.length === 0) return null
  return (
    <div className="flex flex-wrap gap-2">
      {visible.map((link) => (
        <Button key={link.url} onClick={() => openUrl(link.url)}>
          {link.label}
        </Button>
      ))}
    </div>
  )
}

function UpdateRow() {
  const t = useT()
  const disabled = useSettingsReadOnly()
  const channel = usePrefString('general.update_channel', 'stable')
  const status = useUpdateStatus()
  const [busy, setBusy] = useState<'check' | 'install' | 'cancel' | null>(null)

  const run = async (kind: 'check' | 'install' | 'cancel', action: () => Promise<unknown>) => {
    if (busy) return
    setBusy(kind)
    try {
      // 结果经 `updateChanged` 事件进入快照，这里只负责报错。
      await action()
    } catch (error) {
      toast.error(rpcErrorText(error, t))
    } finally {
      setBusy(null)
    }
  }

  const lines = status ? [statusLine(status), manualLine(status)].flatMap((line) => (line ? [updateLineText(t, line)] : [])) : []
  const url = status ? manualUrl(status) : null
  const checking = busy === 'check' || status?.phase === 'checking'

  return (
    <>
      <SettingsRow title={t('checkUpdate')} description={t('checkUpdateDesc')}>
        <div className="flex flex-col gap-1.5 desktop:items-end">
          {lines.map((line) => (
            <span key={line} className="text-xs text-muted-foreground desktop:text-right">
              {line}
            </span>
          ))}
          <div className="flex flex-wrap items-center gap-2 desktop:justify-end">
            {status && canCancel(status) ? (
              <Button loading={busy === 'cancel'} disabled={disabled || busy !== null} onClick={() => void run('cancel', () => rpc.agent.update.cancel())}>
                {t('cancel')}
              </Button>
            ) : null}
            {status && canInstall(status) ? (
              <Button variant="primary" loading={busy === 'install'} disabled={disabled || busy !== null} onClick={() => void run('install', () => rpc.agent.update.install())}>
                {t('updateRestartNow')}
              </Button>
            ) : null}
            {url ? (
              <Button variant="primary" onClick={() => openUrl(url)}>
                {t('updateFailedOpenSite')}
              </Button>
            ) : null}
            <Button
              loading={checking}
              disabled={disabled || checking}
              onClick={() => void run('check', () => rpc.agent.update.check({ channel: channel === 'frontier' ? 'frontier' : 'stable' }))}
            >
              {t('checkUpdate')}
            </Button>
          </div>
        </div>
      </SettingsRow>
      {status && status.notes.length > 0 ? (
        <SettingsCustomRow className="flex flex-col gap-3">
          {status.notes.slice(0, 10).map((note) => (
            <div key={note.version} className="flex flex-col gap-0.5">
              <div className="text-sm text-foreground">
                v{note.version} {note.publishedAt}
              </div>
              <div className="whitespace-pre-wrap break-words text-xs text-muted-foreground">{note.body}</div>
            </div>
          ))}
        </SettingsCustomRow>
      ) : null}
    </>
  )
}

function ExportRow() {
  const t = useT()
  const disabled = useSettingsReadOnly()
  const [busy, setBusy] = useState(false)
  const exportNow = async () => {
    if (busy) return
    setBusy(true)
    try {
      await exportLogs()
    } catch (error) {
      toast.error(rpcErrorText(error, t), t('logExportFailed'))
    } finally {
      setBusy(false)
    }
  }
  return (
    <SettingsRow title={t('logExportButton')}>
      <div className="flex desktop:justify-end">
        <Button variant="primary" loading={busy} disabled={disabled} onClick={() => void exportNow()}>
          {t('logExportButton')}
        </Button>
      </div>
    </SettingsRow>
  )
}

export function AboutSettings() {
  const t = useT()
  const version = useRpcSelector((state) => state.hello?.serviceVersion ?? '')

  return (
    <SettingsPage title={t('settingsCatAbout')} description={t('settingsCatAboutDesc')}>
      <SettingsSection title="IntegratorDown">
        <SettingsRow title={t('currentVersion')}>
          <span className="text-sm tabular text-foreground">{version ? `v${version}` : '—'}</span>
        </SettingsRow>
      </SettingsSection>
      <SettingsSection title={t('softwareUpdate')}>
        <PrefDropdownRow
          prefKey="general.update_channel"
          fallback="stable"
          titleKey="updateChannel"
          descKey="updateChannelDesc"
          options={[
            { value: 'stable', label: t('updateChannelStable') },
            { value: 'frontier', label: t('updateChannelFrontier') },
          ]}
        />
        <PrefSwitchRow prefKey="general.auto_check_update" fallback titleKey="autoCheckUpdate" descKey="autoCheckUpdateBackgroundDesc" />
        <UpdateRow />
        {SERVER_RELEASES ? (
          <SettingsRow title={t('webServerReleases')}>
            <LinkButtons links={[{ label: 'GitHub', url: SERVER_RELEASES }]} />
          </SettingsRow>
        ) : null}
      </SettingsSection>
      <SettingsSection title={t('logExport')} subtitle={t('logExportDesc')}>
        <DaemonNumberRow configKey="log_max_size_mb" titleKey="logMaxSize" descKey="logMaxSizeDesc" unit="MB" />
        <ExportRow />
      </SettingsSection>
    </SettingsPage>
  )
}
