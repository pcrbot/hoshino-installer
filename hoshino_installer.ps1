# this file should be saved as "UTF-8 with BOM"
$ErrorActionPreference = "Stop"

function Expand-ZIPFile($file, $destination) {
    $file = (Resolve-Path -Path $file).Path
    $destination = (Resolve-Path -Path $destination).Path
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    foreach ($item in $zip.items()) {
        $shell.Namespace($destination).copyhere($item)
    }
}

# 检查运行环境
if ($Host.Version.Major -lt 3) {
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

try {
    py -3.8 --version
    if ($LASTEXITCODE = '0') {
        Write-Output 'python 3.8 已发现，跳过安装'
        $install_git = $false
    }
    else {
        $install_python = $true
        Write-Output 'python 3.8 未发现，将自动安装'
    }
}
catch [System.Management.Automation.CommandNotFoundException] {
    $install_python = $true
    Write-Output 'python 3.8 未发现，将自动安装'
}

try {
    git --version
    $install_git = $false
    Write-Output 'git 已发现，跳过安装'
}
catch [System.Management.Automation.CommandNotFoundException] {
    $install_git = $true
    Write-Output 'git 未发现，将自动安装'
}

$qqid = Read-Host '请输入作为机器人的QQ号：'
$qqpassword = Read-Host -AsSecureString '请输入作为机器人的QQ密码：'

$loop = $true
while ($loop) {
    $loop = $false
    Write-Output '请选择下载源'
    Write-Output '1、中国大陆'
    Write-Output '2、港澳台或国外'
    $user_in = Read-Host '请输入 1 或 2'
    Switch ($user_in) {
        1 { $source_cn = $true }
        2 { $source_cn = $false }
        Default { $loop = $true }
    }
}

if ($source_cn) {
    # 中国大陆下载源
    $python38 = 'https://mirrors.huaweicloud.com/python/3.8.6/python-3.8.6-amd64.exe'
    $git = 'https://mirrors.huaweicloud.com/git-for-windows/v2.29.2.windows.1/Git-2.29.2-64-bit.exe'
    $gocqhttp = 'https://download.fastgit.org/Mrs4s/go-cqhttp/releases/download/v0.9.29-fix2/go-cqhttp-v0.9.29-fix2-windows-amd64.zip'
    $hoshinobotgit = 'https://hub.fastgit.org/Ice-Cirno/HoshinoBot.git'
    $pypi = 'http://mirrors.aliyun.com/pypi/simple/'
}
else {
    # 国际下载源
    $python38 = 'https://www.python.org/ftp/python/3.8.6/python-3.8.6-amd64.exe'
    $git = 'https://github.com/git-for-windows/git/releases/download/v2.29.2.windows.1/Git-2.29.2-64-bit.exe'
    $gocqhttp = 'https://github.com/Mrs4s/go-cqhttp/releases/download/v0.9.29-fix2/go-cqhttp-v0.9.29-fix2-windows-amd64.zip'
    $hoshinobotgit = 'https://github.com/Ice-Cirno/HoshinoBot.git'
    $pypi = 'https://pypi.org/simple/'
}

# 创建运行目录
New-Item -Path .\qqbot -ItemType Directory
Set-Location qqbot
New-Item -ItemType Directory -Path .\mirai

# 下载安装程序
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($install_python) {
    Write-Output "正在安装 python"
    Invoke-WebRequest $python38 -OutFile .\python-3.8.6.exe
    Start-Process -Wait -FilePath .\python-3.8.6.exe -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"
    Write-Output "python 安装成功"
    Remove-Item python-3.8.6.exe
}
if ($install_git) {
    Write-Output "正在安装 git"
    Invoke-WebRequest $git -OutFile .\git-2.29.2.exe
    Start-Process -Wait -FilePath .\git-2.29.2.exe -ArgumentList "/SILENT /SP-"
    $env:Path += ";C:\Program Files\Git\bin"  # 添加 git 环境变量
    Write-Output "git 安装成功"
    Remove-Item git-2.29.2.exe
}
Invoke-WebRequest $gocqhttp -O .\go-cqhttp-latest-windows-amd64.zip
Expand-ZIPFile go-cqhttp-latest-windows-amd64.zip -Destination .\mirai\
Remove-Item go-cqhttp-latest-windows-amd64.zip

# 下载源码
git clone $hoshinobotgit --depth=1
Set-Location HoshinoBot
py -3.8 -m pip install "matplotlib~=3.2.0" -i $pypi
py -3.8 -m pip install -r requirements.txt -i $pypi
Copy-Item -Recurse hoshino\config_example hoshino\config
Set-Location ..

# 生成随机 access_token
$token = -join ((65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ })

# 写入 gocqhttp 配置文件
$realpassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($qqpassword))
New-Item -Path .\mirai\config.json -ItemType File -Value @"
{
    "uin": ${qqid},
    "password": "${realpassword}",
    "encrypt_password": false,
    "enable_db": false,
    "access_token": "${token}",
    "relogin": {
        "enabled": false
    },
    "_rate_limit": {
        "enabled": false
    },
    "ignore_invalid_cqcode": false,
    "force_fragmented": false,
    "heartbeat_interval": 0,
    "http_config": {
        "enabled": false
    },
    "ws_config": {
        "enabled": false
    },
    "ws_reverse_servers": [
        {
            "enabled": true,
            "reverse_url": "ws://127.0.0.1:8080/ws",
            "reverse_reconnect_interval": 3000
        }
    ],
    "post_message_format": "string",
    "debug": false,
    "log_level": "",
    "web_ui": {
        "enabled": false
    }
}
"@

# 写入 HoshinoBot 配置文件
Add-Content .\HoshinoBot\hoshino\config\__bot__.py "`r`nACCESS_TOKEN='${token}'`r`n"

# 启动程序
Start-Process -FilePath py.exe -ArgumentList "-3.8 ${pwd}\HoshinoBot\run.py" -WorkingDirectory .\HoshinoBot
Start-Process -FilePath .\mirai\go-cqhttp.exe -WorkingDirectory .\mirai
