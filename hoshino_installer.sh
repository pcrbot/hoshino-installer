#!/bin/bash
set -e

# ensure amd64
if [ $(uname -m) != "x86_64" ]; then
    echo "Sorry, the architecture of your device is not supported yet."
    exit
fi

# ensure run as root
if [ $EUID -ne 0 ]; then
    echo "Please run as root"
    exit
fi

if [ -z "$(command -v wget)" ]; then
    echo "wget not found, install wget first"
    exit 1
fi

echo "
yobot-gocqhttp installer script
What will it do:
1. install docker
2. run hoshinobot in docker
3. run yobot in docker
4. run go-cqhttp in docker
After script finished, you need to press 'ctrl-P, ctrl-Q' to detach the container.
此脚本执行结束并登录后，你需要按下【ctrl-P，ctrl-Q】连续组合键以挂起容器
"

read -p "请输入作为机器人的QQ号：" qqid
read -p "请输入作为机器人的QQ密码：" qqpassword
export qqid
export qqpassword

echo "开始安装，请等待"

if [ -x "$(command -v docker)" ]; then
    echo "docker found, skip installation"
else
    echo "installing docker"
    wget "https://get.docker.com" -O docker-installer.sh
    sh docker-installer.sh --mirror Aliyun
    rm docker-installer.sh
fi

access_token="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)"

wget https://down.yobot.club/images/hyg.tar.gz
gzip -d hyg.tar.gz
docker load -i hyg.tar
rm hyg.tar

docker network create qqbot

mkdir yobot_data gocqhttp_data

docker run --rm -v ${PWD}:/tmp/Hoshino hoshinobot mv /HoshinoBot/ /tmp/Hoshino/Hoshino
echo "HOST = '0.0.0.0'">>Hoshino/hoshino/config/__bot__.py
echo "ACCESS_TOKEN = '${access_token}'">>Hoshino/hoshino/config/__bot__.py


echo "
{
  \"uin\": ${qqid},
  \"password\": \"${qqpassword}\",
  \"encrypt_password\": false,
  \"password_encrypted\": \"\",
  \"enable_db\": false,
  \"access_token\": \"${access_token}\",
  \"relogin\": {
    \"enabled\": true,
    \"relogin_delay\": 3,
    \"max_relogin_times\": 0
  },
  \"_rate_limit\": {
    \"enabled\": false,
    \"frequency\": 1,
    \"bucket_size\": 1
  },
  \"post_message_format\": \"string\",
  \"ignore_invalid_cqcode\": false,
  \"force_fragmented\": true,
  \"heartbeat_interval\": 5,
  \"use_sso_address\": false,
  \"http_config\": {
    \"enabled\": false
  },
  \"ws_config\": {
    \"enabled\": false
  },
  \"ws_reverse_servers\": [
    {
      \"enabled\": true,
      \"reverse_url\": \"ws://hoshino:8080/ws/\",
      \"reverse_reconnect_interval\": 3000
    },
    {
      \"enabled\": true,
      \"reverse_url\": \"ws://yobot:9222/ws/\",
      \"reverse_reconnect_interval\": 3000
    }
  ],
  \"web_ui\": {
    \"enabled\": false
  }
}
">gocqhttp_data/config.json

echo "starting hoshinobot"
docker run -d \
           -v ${PWD}/Hoshino:/HoshinoBot \
           --name hoshino \
           --network qqbot \
           hoshinobot

echo "starting yobot"
docker run -d \
           -v ${PWD}/yobot_data:/yobot/yobot_data \
           -e YOBOT_ACCESS_TOKEN="${access_token}" \
           -p 9222:9222 \
           --name yobot \
           --network qqbot \
           yobot/yobot:pypy

echo "starting gocqhttp"
docker run -it \
           -v ${PWD}/gocqhttp_data:/data \
           -v ${PWD}/Hoshino:/HoshinoBot \
           --name gocqhttp \
           --network qqbot \
           gocqhttp:0.9.31-fix2
