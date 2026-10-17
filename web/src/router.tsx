// TanStack Router（history 模式）。
//   壳路由 `shell` —— AppShell：`/` 下载、`/rss`、`/webhooks`、`/settings[/$category]`
// 旧 /login /setup 入口重定向到首页，不再做访问密钥门禁。

import { Outlet, createRootRoute, createRoute, createRouter, redirect } from '@tanstack/react-router'
import { DownloadsPage } from './pages/downloads/DownloadsPage'
import { RssPage } from './pages/rss/RssPage'
import { SettingsCategoryRoute, SettingsIndex, SettingsLayout } from './pages/settings/SettingsLayout'
import { WebhooksPage } from './pages/webhooks/WebhooksPage'
import { AppShell } from './shell'

const rootRoute = createRootRoute({ component: Outlet })

const loginRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/login',
  beforeLoad: () => {
    throw redirect({ to: '/' })
  },
})

const setupRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/setup',
  beforeLoad: () => {
    throw redirect({ to: '/' })
  },
})

const shellRoute = createRoute({
  getParentRoute: () => rootRoute,
  id: 'shell',
  component: AppShell,
})

const downloadsRoute = createRoute({ getParentRoute: () => shellRoute, path: '/', component: DownloadsPage })
const rssRoute = createRoute({ getParentRoute: () => shellRoute, path: '/rss', component: RssPage })
const webhooksRoute = createRoute({ getParentRoute: () => shellRoute, path: '/webhooks', component: WebhooksPage })

const settingsRoute = createRoute({ getParentRoute: () => shellRoute, path: '/settings', component: SettingsLayout })
const settingsIndexRoute = createRoute({ getParentRoute: () => settingsRoute, path: '/', component: SettingsIndex })

const settingsCategoryRoute = createRoute({
  getParentRoute: () => settingsRoute,
  path: '$category',
  component: SettingsCategoryRoute,
})

const routeTree = rootRoute.addChildren([
  loginRoute,
  setupRoute,
  shellRoute.addChildren([
    downloadsRoute,
    rssRoute,
    webhooksRoute,
    settingsRoute.addChildren([settingsIndexRoute, settingsCategoryRoute]),
  ]),
])

export const router = createRouter({ routeTree, defaultPreload: 'intent' })

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
