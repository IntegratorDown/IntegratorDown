// 移动端底部标签栏（<=820px）：替代活动栏。44px 触摸目标、图标 + caption 文字标签，
// 底部避开 Home 指示条（safe-area-inset-bottom）。条目与桌面活动栏同源（activity.ts）。

import { Link, useLocation } from '@tanstack/react-router'
import type { ReactNode } from 'react'
import { useT } from '../i18n'
import { cn } from '../lib/cn'
import { Icon } from '../ui'
import { isActivityActive } from './activity'
import type { ActivityEntry } from './activity'
import { useVisibleActivityEntries } from './useVisibleActivityEntries'

/** 标签栏内容高度（不含安全区）。与 index.css 的 `--fx-bottom-bar` 保持一致。 */
export const BOTTOM_BAR_HEIGHT = 56

const TAB = 'flex min-h-touch min-w-touch flex-1 flex-col items-center justify-center gap-0.5 px-1 active:bg-nav-hover'

export function BottomTabBar() {
  const t = useT()
  const location = useLocation()
  const entries = useVisibleActivityEntries()

  const renderEntry = (entry: ActivityEntry) => {
    const active = isActivityActive(entry, location.pathname)
    const content = (glyph: ReactNode, label: string, highlighted: boolean) => (
      <>
        {glyph}
        <span className={cn('max-w-full truncate text-caption', highlighted ? 'font-medium text-foreground' : 'text-muted-foreground')}>
          {label}
        </span>
      </>
    )
    return (
      <Link key={entry.id} to={entry.to ?? '/'} aria-current={active ? 'page' : undefined} className={TAB}>
        {content(<Icon icon={entry.icon} size="xl" className={cn(active && 'text-nav-selected-icon')} />, t(entry.labelKey), active)}
      </Link>
    )
  }

  return (
    <nav
      aria-label="Activity"
      className="flex shrink-0 items-stretch border-t border-hairline bg-chrome pb-safe pl-safe pr-safe desktop:hidden"
      style={{ minHeight: BOTTOM_BAR_HEIGHT }}
    >
      {entries.map(renderEntry)}
    </nav>
  )
}
