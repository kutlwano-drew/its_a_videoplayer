[Setup]
AppName=Its A Video Player
AppVersion={%APP_VERSION}
DefaultDirName={autopf}\Its A Video Player
DefaultGroupName=Its A Video Player
OutputDir={%OUT_DIR}
OutputBaseFilename=its_a_videoplayer-{%RELEASE_TAG}-windows-x64-setup
Compression=lzma2
SolidCompression=yes

[Files]
Source: "{%BUILD_DIR}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{autoprograms}\Its A Video Player"; Filename: "{app}\its_a_videoplayer.exe"