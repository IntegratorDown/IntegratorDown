; IntegratorDown Windows Installer Script (Inno Setup) — GPUI desktop client
; This script is used by GitHub Actions to build the installer.
;
; Layout: integratordown-desktop.exe (UI) + integratordown-agent.exe (resident gateway / tray)
; + integratordownd.exe (download daemon) + integratordown_nmh.exe (browser relay) + MSVC CRT,
; all in {app}. AppId / install dir / output name are unchanged from the Flutter
; client, so the Flutter auto-updater (`setup.exe /SILENT`) upgrades in place.
; The GPUI in-app updater (native/agent/src/update/install) runs this installer with
; `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-` after the agent and daemon have exited;
; the silent [Run] entry then relaunches the desktop with `--after-update`.

#define MyAppName "IntegratorDown"
#define MyAppPublisher "IntegratorDown"
#define MyAppURL ""
#define MyAppExeName "integratordown-desktop.exe"
#define MyAgentExeName "integratordown-agent.exe"
; Former Flutter executable, removed on upgrade
#define LegacyExeName "integrator_down.exe"

; Version is passed from CI via /DMyAppVersion=x.y.z
#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

; Architecture is passed from CI via /DMyAppArch=x64 or /DMyAppArch=arm64
#ifndef MyAppArch
  #define MyAppArch "x64"
#endif

; Staged GPUI binaries, passed from CI via /DMySourceDir=<abs path>
#ifndef MySourceDir
  #define MySourceDir "..\..\build\gpui\windows-" + MyAppArch
#endif

[Setup]
AppId={{B7E3F2A1-5C4D-4E8F-9A6B-1D2E3F4A5B6C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\build\installer
OutputBaseFilename=IntegratorDown-{#MyAppVersion}-windows-{#MyAppArch}-setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
#if MyAppArch == "arm64"
ArchitecturesAllowed=arm64
ArchitecturesInstallIn64BitMode=arm64
#else
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
#endif
; 强制管理员安装：{autopf} → Program Files\IntegratorDown。
; Inno Setup 7 的 loader 默认 asInvoker，编译后再把 setup.exe 清单改成 requireAdministrator。
; 主程序 PE 清单同样是 requireAdministrator，安装后以管理员权限运行。
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=commandline
CloseApplications=force
SetupIconFile=..\..\assets\logo\windows\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
ShowLanguageDialog=no
LanguageDetectionMethod=none

[Languages]
Name: "chinesetraditional"; MessagesFile: "ChineseTraditional.isl"

[CustomMessages]
chinesetraditional.OtherTasks=其他：
chinesetraditional.FileAssociations=檔案關聯：
chinesetraditional.LaunchOnStartup=開機時自動啟動
chinesetraditional.TorrentAssoc=將 .torrent 檔案關聯到 IntegratorDown
chinesetraditional.LegacyAllUsersFound=偵測到為所有使用者安裝的舊版 IntegratorDown：%n%1%n%n安裝程式會先解除安裝舊版本，再完成本次系統管理員安裝。下載工作與設定會保留。
chinesetraditional.LegacyAllUsersRemoveFailed=未能移除 %1 中為所有使用者安裝的舊版 IntegratorDown。請在 Windows 設定 > 應用程式中解除安裝它（需要系統管理員權限），然後重新執行本安裝程式。

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "launchonstartup"; Description: "{cm:LaunchOnStartup}"; GroupDescription: "{cm:OtherTasks}"; Flags: unchecked
Name: "torrentassoc"; Description: "{cm:TorrentAssoc}"; GroupDescription: "{cm:FileAssociations}"; Flags: unchecked

[InstallDelete]
; Upgrading from the Flutter client: drop its executable, engine DLL, plugin DLLs and
; asset bundle. A stale integrator_down.exe would otherwise be relaunchable and fight
; integratordownd for engine.lock. Runs before [Files], so the CRT DLLs are reinstalled.
Type: files; Name: "{app}\{#LegacyExeName}"
Type: files; Name: "{app}\integratordown_updater.exe"
Type: files; Name: "{app}\*.dll"
Type: filesandordirs; Name: "{app}\data"

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
; First install: create desktop icon only if user checks the task
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
; Overlay/update install: always refresh the shortcut if it already exists on desktop
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Check: DesktopIconAlreadyExists

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent runascurrentuser
; Silent (auto-)update: relaunch the UI. `--after-update` makes the desktop wait for the
; previous instance to finish exiting instead of forwarding activation to it.
Filename: "{app}\{#MyAppExeName}"; Parameters: "--after-update"; Flags: nowait skipifdoesntexist skipifnotsilent runascurrentuser

[Registry]
; Autostart launches the resident agent (tray), same value the agent writes itself
; (native/agent/src/platform/autostart.rs).
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#MyAppName}"; ValueData: """{app}\{#MyAgentExeName}"" --autostart"; Flags: uninsdeletevalue; Tasks: launchonstartup

; .torrent file association
Root: HKCU; Subkey: "Software\Classes\.torrent"; ValueType: string; ValueData: "IntegratorDown.TorrentFile"; Flags: uninsdeletekey; Tasks: torrentassoc
Root: HKCU; Subkey: "Software\Classes\IntegratorDown.TorrentFile"; ValueType: string; ValueData: "BitTorrent File"; Flags: uninsdeletekey; Tasks: torrentassoc
Root: HKCU; Subkey: "Software\Classes\IntegratorDown.TorrentFile\DefaultIcon"; ValueType: string; ValueData: """{app}\{#MyAppExeName}"",0"; Flags: uninsdeletekey; Tasks: torrentassoc
Root: HKCU; Subkey: "Software\Classes\IntegratorDown.TorrentFile\shell\open\command"; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; Flags: uninsdeletekey; Tasks: torrentassoc

[UninstallDelete]
; 删除 Flutter 客户端时代的 KvStore 落盘文件（升级自 Flutter 的安装里可能仍存在）。
; 语义：卸载后重装 = 生成新设备 ID = 统计为新安装；升级/覆盖安装不触发本节，ID 保留。
; 路径 = shared_preferences_windows：%APPDATA%\<CompanyName>\<ProductName>。
Type: files; Name: "{userappdata}\IntegratorDown\IntegratorDown\shared_preferences.json"
Type: dirifempty; Name: "{userappdata}\IntegratorDown\IntegratorDown"
Type: dirifempty; Name: "{userappdata}\IntegratorDown"

; NMH manifest JSON files written at runtime by the agent (native/agent/src/nmh.rs)
; into the per-user data dir (never installed via [Files], so the standard
; uninstall never learns about them and leaves them on disk). The {app}
; entries cover manifests left behind by older releases that wrote them next
; to the exe.
Type: files; Name: "{localappdata}\IntegratorDown\nmh\com.integratordown.nmh.json"
Type: files; Name: "{localappdata}\IntegratorDown\nmh\com.integratordown.nmh.firefox.json"
Type: dirifempty; Name: "{localappdata}\IntegratorDown\nmh"
Type: files; Name: "{app}\com.integratordown.nmh.json"
Type: files; Name: "{app}\com.integratordown.nmh.firefox.json"

[Code]
const
  RunKey = 'Software\Microsoft\Windows\CurrentVersion\Run';
  { Uninstall key of an all-users (administrative mode) install; the GUID must
    match [Setup] AppId, Inno appends "_is1". }
  LegacyUninstallKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{B7E3F2A1-5C4D-4E8F-9A6B-1D2E3F4A5B6C}_is1';

var
  { Per-user integrations owned by a removed all-users install; recreated
    against the new install dir once its files are in place (RemoveLegacyAllUsersInstall). }
  LegacyAutostart, LegacyTorrentAssoc, LegacyDesktopIcon: Boolean;
  LegacyIntegratordownScheme, LegacyEd2kScheme, LegacyMagnetScheme: Boolean;

function DesktopIconAlreadyExists: Boolean;
begin
  Result := LegacyDesktopIcon or FileExists(ExpandConstant('{autodesktop}\{#MyAppName}.lnk'));
end;

{ Upgrading from the Flutter client: an enabled autostart Run value still points
  at the removed integrator_down.exe. Keep the user's choice by retargeting it to the
  agent (the form the agent itself writes). }
procedure MigrateLegacyAutostart;
var
  Command: String;
begin
  if not RegQueryStringValue(HKCU, RunKey, '{#MyAppName}', Command) then
    Exit;
  if Pos(Lowercase(ExpandConstant('{app}\{#LegacyExeName}')), Lowercase(Command)) > 0 then
    RegWriteStringValue(HKCU, RunKey, '{#MyAppName}',
      '"' + ExpandConstant('{app}\{#MyAgentExeName}') + '" --autostart');
end;

{ Extract the quoted executable path from a `"<exe>" "%1"`-style
  shell\open\command value (the format written by the agent,
  native/agent/src/platform/protocol_registry.rs and file_association.rs). }
function ExtractQuotedExe(const Command: String): String;
var
  FirstQuote, SecondQuote: Integer;
begin
  Result := '';
  FirstQuote := Pos('"', Command);
  if FirstQuote = 0 then Exit;
  SecondQuote := Pos('"', Copy(Command, FirstQuote + 1, MaxInt));
  if SecondQuote = 0 then Exit;
  Result := Copy(Command, FirstQuote + 1, SecondQuote - 1);
end;

{ Whether a `"<exe>" ...` command value launches Exe. }
function CommandTargets(const Command, Exe: String): Boolean;
var
  RegisteredExe: String;
begin
  RegisteredExe := ExtractQuotedExe(Command);
  Result := (RegisteredExe <> '') and (CompareText(RegisteredExe, Exe) = 0);
end;

{ integratordown:// / ed2k:// / magnet: handler registered at runtime by
  native/agent/src/platform/protocol_registry.rs and pointing at Exe. A handler
  since reclaimed by another app (e.g. eMule re-registering ed2k://) is not ours. }
function ProtocolHandlerTargets(const Scheme, Exe: String): Boolean;
var
  Command: String;
begin
  Result := False;
  if RegQueryStringValue(HKCU, 'Software\Classes\' + Scheme + '\shell\open\command', '', Command) then
    Result := CommandTargets(Command, Exe);
end;

{ IntegratorDown.TorrentFile ProgID (torrentassoc task or
  native/agent/src/platform/file_association.rs) pointing at Exe. }
function TorrentAssociationTargets(const Exe: String): Boolean;
var
  Command: String;
begin
  Result := False;
  if RegQueryStringValue(HKCU, 'Software\Classes\IntegratorDown.TorrentFile\shell\open\command', '', Command) then
    Result := CommandTargets(Command, Exe);
end;

{ Autostart Run value (launchonstartup task or
  native/agent/src/platform/autostart.rs, `"<integratordown-agent.exe>" --autostart`)
  pointing at Agent. }
function AutostartTargets(const Agent: String): Boolean;
var
  Command, RegisteredExe: String;
begin
  Result := False;
  if not RegQueryStringValue(HKCU, RunKey, '{#MyAppName}', Command) then
    Exit;
  RegisteredExe := ExtractQuotedExe(Command);
  { Legacy entries may store the path unquoted; fall back to the raw value
    with any trailing arguments stripped. }
  if RegisteredExe = '' then
  begin
    RegisteredExe := Trim(Command);
    if Pos(' --', RegisteredExe) > 0 then
      RegisteredExe := Trim(Copy(RegisteredExe, 1, Pos(' --', RegisteredExe) - 1));
  end;
  Result := (RegisteredExe <> '') and (CompareText(RegisteredExe, Agent) = 0);
end;

{ Same values as native/agent/src/platform/protocol_registry.rs::register. }
procedure WriteProtocolHandler(const Scheme, Description, Exe: String);
var
  Key: String;
begin
  Key := 'Software\Classes\' + Scheme;
  RegWriteStringValue(HKCU, Key, '', Description);
  RegWriteStringValue(HKCU, Key, 'URL Protocol', '');
  RegWriteStringValue(HKCU, Key + '\DefaultIcon', '', '"' + Exe + '",0');
  RegWriteStringValue(HKCU, Key + '\shell\open\command', '', '"' + Exe + '" "%1"');
end;

{ Same values as the torrentassoc [Registry] entries and
  native/agent/src/platform/file_association.rs::associate. }
procedure WriteTorrentAssociation(const Exe: String);
begin
  RegWriteStringValue(HKCU, 'Software\Classes\.torrent', '', 'IntegratorDown.TorrentFile');
  RegWriteStringValue(HKCU, 'Software\Classes\IntegratorDown.TorrentFile', '', 'BitTorrent File');
  RegWriteStringValue(HKCU, 'Software\Classes\IntegratorDown.TorrentFile\DefaultIcon', '', '"' + Exe + '",0');
  RegWriteStringValue(HKCU, 'Software\Classes\IntegratorDown.TorrentFile\shell\open\command', '', '"' + Exe + '" "%1"');
end;

{ Earlier all-users copies (Program Files + HKLM uninstall key) may still exist.
  Leaving that copy behind would keep an older
  integratordown-agent/integratordownd reachable through its shortcuts,
  competing for the same %LOCALAPPDATA%\IntegratorDown data dir, and keep the browser
  NMH registration pinned to its relay (auto_register in native/agent/src/nmh.rs
  never takes over from another healthy install). Remove it through its own
  uninstaller after snapshotting the per-user integrations that uninstaller
  deletes, so RestoreLegacyIntegrations can recreate them against the new
  install dir. NMH needs no snapshot: its keys go missing and the new agent
  re-registers on first launch. }
function RemoveLegacyAllUsersInstall: String;
var
  UninstallString, UninstallExe, LegacyDir, LegacyDesktop: String;
  ErrorCode, Waited: Integer;
begin
  Result := '';
  if not RegQueryStringValue(HKLM, LegacyUninstallKey, 'UninstallString', UninstallString) then
    Exit;
  UninstallExe := RemoveQuotes(UninstallString);
  LegacyDir := ExtractFileDir(UninstallExe);
  LegacyDesktop := LegacyDir + '\{#MyAppExeName}';
  LegacyAutostart := AutostartTargets(LegacyDir + '\{#MyAgentExeName}');
  LegacyTorrentAssoc := TorrentAssociationTargets(LegacyDesktop);
  LegacyIntegratordownScheme := ProtocolHandlerTargets('integratordown', LegacyDesktop);
  LegacyEd2kScheme := ProtocolHandlerTargets('ed2k', LegacyDesktop);
  LegacyMagnetScheme := ProtocolHandlerTargets('magnet', LegacyDesktop);
  LegacyDesktopIcon := FileExists(ExpandConstant('{commondesktop}\{#MyAppName}.lnk'));
  { Files already removed by hand: only a stale HKLM entry is left, nothing can
    still run from there. }
  if not FileExists(UninstallExe) then
    Exit;

  if SuppressibleMsgBox(FmtMessage(CustomMessage('LegacyAllUsersFound'), [LegacyDir]),
    mbInformation, MB_OKCANCEL, IDOK) <> IDOK then
  begin
    Result := FmtMessage(CustomMessage('LegacyAllUsersRemoveFailed'), [LegacyDir]);
    Exit;
  end;
  { UAC is shown even for /VERYSILENT; declining it makes ShellExec fail. }
  if not ShellExec('runas', UninstallExe, '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART', '',
    SW_HIDE, ewWaitUntilTerminated, ErrorCode) then
  begin
    Result := FmtMessage(CustomMessage('LegacyAllUsersRemoveFailed'), [LegacyDir]);
    Exit;
  end;
  { The uninstaller's first phase waits for its second phase; the bounded wait
    only guards against the uninstall key being deleted last. }
  Waited := 0;
  while RegKeyExists(HKLM, LegacyUninstallKey) and (Waited < 10000) do
  begin
    Sleep(250);
    Waited := Waited + 250;
  end;
  if RegKeyExists(HKLM, LegacyUninstallKey) then
    Result := FmtMessage(CustomMessage('LegacyAllUsersRemoveFailed'), [LegacyDir]);
end;

procedure RestoreLegacyIntegrations;
var
  Desktop: String;
begin
  Desktop := ExpandConstant('{app}\{#MyAppExeName}');
  { Only the Run value is rewritten; StartupApproved (system-level disable) is
    left as the user set it, like autostart::retarget. }
  if LegacyAutostart then
    RegWriteStringValue(HKCU, RunKey, '{#MyAppName}',
      '"' + ExpandConstant('{app}\{#MyAgentExeName}') + '" --autostart');
  if LegacyTorrentAssoc then
    WriteTorrentAssociation(Desktop);
  if LegacyIntegratordownScheme then
    WriteProtocolHandler('integratordown', 'URL:IntegratorDown Protocol', Desktop);
  if LegacyEd2kScheme then
    WriteProtocolHandler('ed2k', 'URL:ed2k Protocol', Desktop);
  if LegacyMagnetScheme then
    WriteProtocolHandler('magnet', 'URL:Magnet Link', Desktop);
end;

{ Upgrading from the Flutter client: .torrent association and URL protocol handlers
  still point at the removed integrator_down.exe. Retarget only entries that name this
  install's old exe, so other programs' registrations stay untouched. }
procedure MigrateLegacyIntegrations;
var
  OldExe, NewExe: String;
begin
  OldExe := ExpandConstant('{app}\{#LegacyExeName}');
  NewExe := ExpandConstant('{app}\{#MyAppExeName}');
  if TorrentAssociationTargets(OldExe) then
    WriteTorrentAssociation(NewExe);
  if ProtocolHandlerTargets('integratordown', OldExe) then
    WriteProtocolHandler('integratordown', 'URL:IntegratorDown Protocol', NewExe);
  if ProtocolHandlerTargets('ed2k', OldExe) then
    WriteProtocolHandler('ed2k', 'URL:ed2k Protocol', NewExe);
  if ProtocolHandlerTargets('magnet', OldExe) then
    WriteProtocolHandler('magnet', 'URL:Magnet Link', NewExe);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  { Force-kill every IntegratorDown process as a fallback in case Restart Manager
    fails: the resident agent/daemon/relay keep their exes locked otherwise.
    Matches by image name, so a legacy all-users copy is stopped too. }
  Exec('taskkill', '/f /im {#MyAppExeName} /im {#MyAgentExeName} /im integratordownd.exe /im integratordown_nmh.exe /im {#LegacyExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  { Upgrade installs must overwrite the previous uninstaller; a stray
    read-only attribute on it makes CreateFile fail with access denied.
    Clear the attribute up-front (no-op when the files do not exist). }
  Exec('attrib', '-r "' + ExpandConstant('{app}\unins000.exe') + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('attrib', '-r "' + ExpandConstant('{app}\unins000.dat') + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  { Small delay to ensure file locks are released }
  Sleep(500);
  Result := RemoveLegacyAllUsersInstall;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    MigrateLegacyAutostart;
    MigrateLegacyIntegrations;
    RestoreLegacyIntegrations;
  end;
end;

{ Remove a URL scheme handler registered at runtime. These keys live under
  HKCU\Software\Classes\<scheme> and are never declared in [Registry] — the
  standard uninstall never removes them, and Windows tries to relaunch the
  deleted exe whenever a matching link is opened. }
procedure RemoveProtocolHandler(const Scheme: String);
begin
  if ProtocolHandlerTargets(Scheme, ExpandConstant('{app}\{#MyAppExeName}')) then
    RegDeleteKeyIncludingSubkeys(HKCU, 'Software\Classes\' + Scheme);
end;

{ Remove the `.torrent` file association registered at runtime (toggled from the
  app's settings page, 独立于 install-time 的 torrentassoc task — that task's registry
  entries carry uninsdeletekey, but a runtime-written association is
  invisible to the uninstall log). Only removes the `.torrent` extension key if
  it still maps to our ProgID (mirrors the conservative ownership check in
  file_association.rs::disassociate). }
procedure RemoveTorrentAssociation;
var
  ProgId: String;
begin
  if not TorrentAssociationTargets(ExpandConstant('{app}\{#MyAppExeName}')) then
    Exit;
  if RegQueryStringValue(HKCU, 'Software\Classes\.torrent', '', ProgId)
    and (CompareText(ProgId, 'IntegratorDown.TorrentFile') = 0) then
    RegDeleteKeyIncludingSubkeys(HKCU, 'Software\Classes\.torrent');
  RegDeleteKeyIncludingSubkeys(HKCU, 'Software\Classes\IntegratorDown.TorrentFile');
end;

{ Remove the autostart Run value written at runtime by the agent. A
  runtime-written value is invisible to the uninstall log, so uninsdeletevalue
  alone cannot be relied on. }
procedure RemoveAutostartRunValue;
begin
  if AutostartTargets(ExpandConstant('{app}\{#MyAgentExeName}')) then
    RegDeleteValue(HKCU, RunKey, '{#MyAppName}');
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    { Chrome/Edge/Firefox Native Messaging Host registrations written at
      runtime by the agent (native/agent/src/nmh.rs). Never declared in the
      Registry section (the app writes them directly via winreg on every startup),
      so the standard uninstall never removes them. `com.integratordown.nmh` is
      IntegratorDown-specific, safe to remove unconditionally. }
    RegDeleteKeyIncludingSubkeys(HKCU, 'Software\Google\Chrome\NativeMessagingHosts\com.integratordown.nmh');
    RegDeleteKeyIncludingSubkeys(HKCU, 'Software\Microsoft\Edge\NativeMessagingHosts\com.integratordown.nmh');
    RegDeleteKeyIncludingSubkeys(HKCU, 'Software\Mozilla\NativeMessagingHosts\com.integratordown.nmh');

    { integratordown:// / ed2k:// / magnet: URL protocol handlers — same gap as above. }
    RemoveProtocolHandler('integratordown');
    RemoveProtocolHandler('ed2k');
    RemoveProtocolHandler('magnet');

    { Completion notifications target the agent, not the desktop executable.
      Leave a handler installed by another copy (including portable) untouched. }
    if ProtocolHandlerTargets('integratordown-notification', ExpandConstant('{app}\{#MyAgentExeName}')) then
      RegDeleteKeyIncludingSubkeys(HKCU, 'Software\Classes\integratordown-notification');

    { .torrent association + autostart Run value — runtime-written variants
      of the [Registry] task entries, invisible to the uninstall log. }
    RemoveTorrentAssociation;
    RemoveAutostartRunValue;
  end;
end;
