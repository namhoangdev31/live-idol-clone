; Live Idol Clone Installer Script
; Created with Inno Setup 6+
; Build command: iscc setup.iss

#define MyAppName "Live Idol Clone"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Live Idol Clone Team"
#define MyAppURL "https://github.com/yourusername/live-idol-clone"
#define MyAppExeName "live_idol_clone.exe"
#define MyAppGUID "{{A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D}"

[Setup]
; Unique app ID
AppId={#MyAppGUID}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; Installation directories
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
DisableProgramGroupPage=yes

; Output
OutputDir=output
OutputBaseFilename=LiveIdolCloneInstaller_{#MyAppVersion}
; SetupIconFile=icon.ico

; Compression
Compression=lzma2/max
SolidCompression=yes
LZMAUseSeparateProcess=yes
LZMANumBlockThreads=2

; Architecture
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x64

; Privileges
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

; UI
WizardStyle=modern
; WizardImageFile=installer_banner.bmp
; WizardSmallImageFile=installer_small.bmp
DisableWelcomePage=no

; Uninstall
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation"
Name: "compact"; Description: "Compact installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "app"; Description: "Live Idol Clone Application"; Types: full compact custom; Flags: fixed
Name: "backend"; Description: "Backend (TTS Engine)"; Types: full compact custom; Flags: fixed
Name: "unity"; Description: "Unity VRM Renderer"; Types: full custom
Name: "samples"; Description: "Sample VRM Avatar and Voice Profiles"; Types: full

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Flutter App (Main Application)
Source: "files\flutter\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: app

; Django Backend
Source: "files\backend\LiveIdolBackend.exe"; DestDir: "{app}\backend"; Flags: ignoreversion; Components: backend


; Bundled Unity Runtime (Pre-built)
Source: "..\unity_vrm_scripts\build\*"; DestDir: "{app}\backend\renderer"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: unity

; OBS Studio Portable
Source: "..\backend\obs-studio-portable\*"; DestDir: "{app}\backend\obs-studio-portable"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: app

; Assets and Samples
Source: "files\assets\*"; DestDir: "{app}\assets"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: samples

; Documentation
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme
Source: "..\BUILD.md"; DestDir: "{app}"; Flags: ignoreversion

; Voice Profiles directory
Source: "..\backend\voice_profiles\default\README.md"; DestDir: "{app}\backend\voice_profiles\default"; Flags: ignoreversion; Components: samples

[Dirs]
; Create output directories
Name: "{app}\backend\output"; Permissions: users-full
Name: "{app}\backend\voice_profiles"; Permissions: users-full
Name: "{app}\logs"; Permissions: users-full
Name: "{app}\backend\renderer"; Permissions: users-full

[Icons]
; Start Menu
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{group}\Voice Profiles Folder"; Filename: "{app}\backend\voice_profiles"
Name: "{group}\README"; Filename: "{app}\README.md"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

; Desktop
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

; Quick Launch
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
; Launch app after installation
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
end;

// No VB-CABLE checks needed anymore for All-in-One version
procedure InitializeWizard();
begin
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  // No post-install checks needed
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
end;

[UninstallDelete]
; Clean up generated files
Type: filesandordirs; Name: "{app}\backend\output\*"
Type: filesandordirs; Name: "{app}\logs\*"

[Messages]
; Custom messages
WelcomeLabel2=This will install [name/ver] on your computer.%n%nLive Idol Clone is a voice cloning and VRM avatar system for livestreaming.%n%nIt is recommended that you close all other applications before continuing.
FinishedLabel=Live Idol Clone has been installed successfully!

