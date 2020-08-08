# this file should be saved as "UTF-8 with BOM"
$ErrorActionPreference = "Inquire"

# 检查运行环境
if ($Host.Version.Major -lt 5) {
    Write-Output 'powershell 版本过低，无法一键安装'
    exit
}
if ((Get-ChildItem -Path Env:OS).Value -ine 'Windows_NT') {
    Write-Output '当前操作系统不支持一键安装'
    exit
}
if (![Environment]::Is64BitProcess) {
    Write-Output '暂时不支持32位系统'
    exit
}

if (Test-Path .\qqbot) {
    Write-Output '发现重复，是否删除旧文件并重新安装？'
    $reinstall = Read-Host '请输入 y 或 n (y/n)'
    Switch ($reinstall) { 
        Y { Remove-Item .\qqbot -Recurse -Force } 
        N { exit } 
        Default { exit } 
    } 
}

# 用户输入
$loop = $true
while ($loop) {
    $loop = $false
    Write-Output '是否需要安装 python 3.8 ？'
    Write-Output 'y：请帮我安装'
    Write-Output 'n：我已经安装'
    $user_in = Read-Host '请输入 y 或 n (y/n)'
    Switch ($user_in) {
        Y { $install_python = $true }
        N { $install_python = $false }
        Default { $loop = $true }
    }
}

$loop = $true
while ($loop) {
    $loop = $false
    Write-Output '是否需要安装 git ？'
    Write-Output 'y：请帮我安装'
    Write-Output 'n：我已经安装'
    $user_in = Read-Host '请输入 y 或 n (y/n)'
    Switch ($user_in) {
        Y { $install_git = $true }
        N { $install_git = $false }
        Default { $loop = $true }
    }
}

$qqid = Read-Host '请输入作为机器人的QQ号：'
$qqpassword = Read-Host -AsSecureString '请输入作为机器人的QQ密码：'

# 创建运行目录
New-Item -Path .\qqbot -ItemType Directory
Set-Location qqbot
New-Item -ItemType Directory -Path .\mirai, .\mirai\plugins, .\mirai\plugins\CQHTTPMirai

# 下载安装程序
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($install_python) {
    Write-Output "正在安装 python"
    Invoke-WebRequest https://mirrors.huaweicloud.com/python/3.8.5/python-3.8.5-amd64.exe -OutFile .\python-3.8.5.exe
    Start-Process -Wait -FilePath .\python-3.8.5.exe -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"
    Write-Output "python 安装成功"
}
if ($install_git) {
    Write-Output "正在安装 git"
    Invoke-WebRequest https://mirrors.huaweicloud.com/git-for-windows/v2.28.0.windows.1/Git-2.28.0-64-bit.exe -OutFile .\git-2.28.0.exe
    Start-Process -Wait -FilePath .\git-2.28.0.exe -ArgumentList "/SILENT /SP-"
    $env:Path += ";C:\Program Files\Git\bin"  # 添加 git 环境变量
    Write-Output "git 安装成功"
}
Invoke-WebRequest https://get.yobot.win/scyb/miraiOK_win_amd64.exe -OutFile .\mirai\miraiOK.exe
Invoke-WebRequest https://get.yobot.win/scyb/cqhttp-mirai-0.1.9-all.jar -OutFile .\mirai\plugins\cqhttp-mirai-0.1.9-all.jar

# 下载源码
git clone https://github.com/Ice-Cirno/HoshinoBot.git --depth=1
Set-Location HoshinoBot
py -3.8 -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
Copy-Item -Recurse hoshino\config_example hoshino\config
Set-Location ..

# 生成随机 access_token
$token = -join ((65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ })

# 写入 cqmiraihttp 配置文件
New-Item -Path .\mirai\plugins\CQHTTPMirai\setting.yml -ItemType File -Value @"
"${qqid}":
  ws_reverse:
    - enable: true
      postMessageFormat: string
      reverseHost: 127.0.0.1
      reversePort: 8080
      reversePath: /ws/
      accessToken: ${token}
      reconnectInterval: 3000
"@

# 写入 miraiOK 配置文件
New-Item -Path .\mirai\config.txt -ItemType File -Value "----------`nlogin ${qqid} ${qqpassword}`n"

# 写入 HoshinoBot 配置文件
Add-Content .\HoshinoBot\hoshino\config\__bot__.py "`r`nACCESS_TOKEN='${token}'`r`n"

# 启动程序
Start-Process -FilePath py.exe -ArgumentList "-3.8 ${pwd}\HoshinoBot\run.py" -WorkingDirectory .\HoshinoBot
Start-Process -FilePath .\mirai\miraiOK.exe -WorkingDirectory .\mirai
