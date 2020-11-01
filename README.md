# HoshinoBot 一键安装脚本

## Windows

在合适的位置打开 `powershell` 中执行：

```powershell
Invoke-WebRequest https://github.com/pcrbot/hoshino-installer/raw/master/hoshino_installer.ps1 -OutFile .\install.ps1 ; ./install.ps1
```

国内服务器如果无法连接 github 可改用：

```powershell
Invoke-WebRequest https://raw.fastgit.org/pcrbot/hoshino-installer/master/hoshino_installer.ps1 -OutFile .\install.ps1 ; ./install.ps1
```

## Linux

编写中……
