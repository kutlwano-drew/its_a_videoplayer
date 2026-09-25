#ifndef BuildDir
  #define BuildDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutDir
  #define OutDir "..\..\dist\windows"
#endif
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef ReleaseTag
  #define ReleaseTag "v1.0.0"
#endif

[Setup]
AppName=Its A Video Player
AppVersion={#AppVersion}
DefaultDirName={autopf}\Its A Video Player
DefaultGroupName=Its A Video Player
OutputDir={#OutDir}
OutputBaseFilename=its_a_videoplayer-{#ReleaseTag}-windows-x64-setup
Compression=lzma2
SolidCompression=yes

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{autoprograms}\Its A Video Player"; Filename: "{app}\its_a_videoplayer.exe"