// 全局提供者与连接控制器。
//   ConnectionController 是 /rpc 连接的唯一所有者：启动后直接连网关，不再走登录门禁。

import { useEffect } from 'react'
import type { ReactNode } from 'react'
import { I18nProvider } from './i18n'
import { getToken } from './lib/access'
import { startConnection } from './lib/rpc/client'
import { ThemeProvider } from './theme'
import { ConfirmHost, ToastHost, TooltipProvider } from './ui'

function ConnectionController() {
  useEffect(() => {
    startConnection(getToken())
  }, [])

  return null
}

/** 必须位于 RouterProvider 内部（ConnectionController 用到 navigate）。 */
export function AppProviders({ children }: { children: ReactNode }) {
  return (
    <I18nProvider>
      <ThemeProvider>
        <TooltipProvider>
          <ConnectionController />
          {children}
          <ConfirmHost />
          <ToastHost />
        </TooltipProvider>
      </ThemeProvider>
    </I18nProvider>
  )
}
