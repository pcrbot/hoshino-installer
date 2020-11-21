# HoshinoBot 一键安装脚本

## Windows

在合适的位置打开 `powershell` 中执行：

```powershell
iwr https://raw.fastgit.org/pcrbot/hoshino-installer/master/hoshino_installer.ps1 -O .\hinstall.ps1 ; ./hinstall.ps1 ; rm hinstall.ps1
```

## Linux

在终端执行：

```bash
wget https://raw.fastgit.org/pcrbot/hoshino-installer/master/hoshino_installer.sh -O hinstall.sh && sudo bash hinstall.sh && rm hinstall.sh
```
