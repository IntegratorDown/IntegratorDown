//! 为 GPUI 桌面客户端嵌入 Windows 程序资源。

const WINDOWS_APP_ICON: &str = "../../assets/logo/windows/app_icon.ico";

fn main() -> std::io::Result<()> {
    println!("cargo:rerun-if-changed={WINDOWS_APP_ICON}");

    #[cfg(windows)]
    embed_windows_resources()?;

    Ok(())
}

/// 资源 ID 1 是 Windows Explorer 与 GPUI Windows 后端共同读取的默认图标。
///
/// 后续运行时图标切换应覆盖窗口、任务栏和快捷方式引用；这里的默认资源始终
/// 保留，供未选择动态图标、重置图标及进程未运行时回退使用。
#[cfg(windows)]
fn embed_windows_resources() -> std::io::Result<()> {
    let mut resources = winresource::WindowsResource::new();
    resources.set_icon(WINDOWS_APP_ICON);
    resources.set("CompanyName", "IntegratorDown");
    resources.set("ProductName", "IntegratorDown");
    resources.set("FileDescription", "IntegratorDown");
    resources.set("InternalName", "com.integratordown.app");
    resources.set("OriginalFilename", "integratordown-desktop.exe");
    resources.set(
        "LegalCopyright",
        "Copyright (C) 2026 IntegratorDown. All rights reserved.",
    );
    // 必须保留 GPUI 的 Common-Controls 6.0 / DPI / SegmentHeap；只把执行级别改成管理员。
    resources.set_manifest(
        r#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <assemblyIdentity
    version="1.0.0.0"
    processorArchitecture="*"
    name="IntegratorDown.Desktop"
    type="win32"/>
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
    <security>
      <requestedPrivileges>
        <requestedExecutionLevel level="requireAdministrator" uiAccess="false"/>
      </requestedPrivileges>
    </security>
  </trustInfo>
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>
      <supportedOS Id="{1f676c76-80e1-4239-95bb-83d0f6d0da78}"/>
      <supportedOS Id="{4a2f28e3-53b9-4441-ba9c-d69d4a4a6e38}"/>
      <supportedOS Id="{35138b9a-5d96-4fbd-8e2d-a2440225f93a}"/>
    </application>
  </compatibility>
  <application xmlns="urn:schemas-microsoft-com:asm.v3">
    <windowsSettings>
      <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true/pm</dpiAware>
      <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
      <heapType xmlns="http://schemas.microsoft.com/SMI/2020/WindowsSettings">SegmentHeap</heapType>
    </windowsSettings>
  </application>
  <dependency>
    <dependentAssembly>
      <assemblyIdentity
        type="win32"
        name="Microsoft.Windows.Common-Controls"
        version="6.0.0.0"
        processorArchitecture="*"
        publicKeyToken="6595b64144ccf1df"/>
    </dependentAssembly>
  </dependency>
</assembly>
"#,
    );
    resources.compile()
}
