//! Embed Windows PE version information into `integratordown_nmh.exe`.
//!
//! A binary with a fully populated `VS_VERSION_INFO` resource (company,
//! product, description, version) looks far less suspicious to antivirus
//! heuristic engines than one with a blank version block. Everything here is
//! a no-op on non-Windows targets.

fn main() {
    println!("cargo:rerun-if-env-changed=INTEGRATORDOWN_APP_VERSION");
    #[cfg(windows)]
    embed_version_info();
}

/// Populate the standard `StringFileInfo` fields consumed by Explorer's
/// "Details" tab and by AV reputation heuristics.
#[cfg(windows)]
fn embed_version_info() {
    let mut res = winresource::WindowsResource::new();
    // Icon shared with the main application (path relative to this crate).
    res.set_icon("../../assets/logo/windows/app_icon.ico");
    res.set("CompanyName", "IntegratorDown");
    res.set("ProductName", "IntegratorDown");
    res.set(
        "FileDescription",
        "IntegratorDown Native Messaging Host (browser bridge)",
    );
    res.set("InternalName", "integratordown_nmh");
    res.set("OriginalFilename", "integratordown_nmh.exe");
    res.set(
        "LegalCopyright",
        "Copyright (C) 2026 IntegratorDown. All rights reserved.",
    );
    let version = std::env::var("INTEGRATORDOWN_APP_VERSION")
        .ok()
        .filter(|version| !version.is_empty())
        .unwrap_or_else(|| env!("CARGO_PKG_VERSION").to_owned());
    res.set("FileVersion", &version);
    res.set("ProductVersion", &version);
    if let Err(e) = res.compile() {
        // Don't fail the build on resource-compiler issues; just warn so the
        // binary still links (only the version block is missing).
        println!("cargo:warning=integratordown_nmh version resource failed: {e}");
    }
}
