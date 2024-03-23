# x-ui
x-ui is a panel that supports multiple protocols and users for xray.

# Features

- System status monitoring
- Supports multiple users and protocols, with web visualization
- Supported protocols: vmess, vless, trojan, shadowsocks, dokodemo-door, socks, http
- Supports configuring more transmission configurations
- Traffic statistics, traffic limitation, expiration time limitation
- Customizable xray configuration template
- Supports accessing the panel via HTTPS (with own domain + SSL certificate)
- Supports one-click SSL certificate application and automatic renewal
- More advanced configuration options, see the panel for details

# Installation & Upgrade
```
bash <(curl -Ls https://raw.githubusercontent.com/hojat-gazestani/x-ui/master/install.sh)
```

## Manual Installation & Upgrade
1. First, download the latest release from https://github.com/vaxilu/x-ui/releases. Generally, choose the amd64 architecture.
2. Then upload this compressed package to the /root/ directory of your server and log in to the server using the root user.

> If your server's CPU architecture is not amd64, replace amd64 in the command with the appropriate architecture.


```
cd /root/
rm x-ui/ /usr/local/x-ui/ /usr/bin/x-ui -rf
tar zxvf x-ui-linux-amd64.tar.gz
chmod +x x-ui/x-ui x-ui/bin/xray-linux-* x-ui/x-ui.sh
cp x-ui/x-ui.sh /usr/bin/x-ui
cp -f x-ui/x-ui.service /etc/systemd/system/
mv x-ui/ /usr/local/
systemctl daemon-reload
systemctl enable x-ui
systemctl restart x-ui
```

## Installing with Docker

> This Docker tutorial and Docker image are provided by [Chasing66](https://github.com/Chasing66).

1. Install Docker

```shell
curl -fsSL https://get.docker.com | sh
```

2. 
Install x-ui

```shell
mkdir x-ui && cd x-ui
docker run -itd --network=host \
    -v $PWD/db/:/etc/x-ui/ \
    -v $PWD/cert/:/root/cert/ \
    --name x-ui --restart=unless-stopped \
    enwaiax/x-ui:latest
```

> Build your own image

```shell
docker build -t x-ui .
```

## SSL Certificate Application

> This feature and tutorial are provided by [FranzKafkaYu](https://github.com/FranzKafkaYu).

The script includes SSL certificate application functionality. To use this script to apply for a certificate, the following conditions must be met:

- Know the Cloudflare registered email.
- Know the Cloudflare Global API Key.
- The domain name has been resolved to the current server through Cloudflare.

Method to obtain Cloudflare Global API Key:
￼   ![](media/bda84fbc2ede834deaba1c173a932223.png)
    ![](media/d13ffd6a73f938d1037d0708e31433bf.png)
￼

When using it, simply enter the domain name, email, and API KEY. A schematic diagram is as follows:
    ![](media/2022-04-04_141259.png)
￼

Notes:

- This script uses the DNS API for certificate application.
- Let's Encrypt is used as the default CA.
- The certificate installation directory is /root/cert.

Certificates applied for using this script are wildcard certificates.

## Telegram Bot Usage (Under Development, Not Available Yet)

> This feature and tutorial are provided by [FranzKafkaYu](https://github.com/FranzKafkaYu).

X-UI supports features such as daily traffic notifications and panel login reminders through Telegram bots. To use Telegram bots, you need to apply for one yourself. You can refer to the specific application tutorial in this [blog post](https://coderfan.net/how-to-use-telegram-bot-to-alarm-you-when-someone-login-into-your-vps.html)
Instructions for use: Set up the bot-related parameters in the panel backend, including 

- Telegram bot Token
- Telegram bot Chat ID
- Telegram bot periodic runtime, using crontab syntax

Reference syntax:

- 30 * * * * * // Notify at 30 seconds of every minute
- @hourly // Notify every hour
- @daily // Notify every day (midnight)
- @every 8h // Notify every 8 hours

Telegram notification content:

- Node traffic usage
- Panel login reminder
- Node expiration reminder
- Traffic warning notification


- More features are being planned...

## Recommended Systems

- CentOS 7+
- Ubuntu 16+
- Debian 8+

# Common Questions

## Migrating from v2-ui

First, install the latest version of x-ui on the server where v2-ui is installed. Then, use the following command to migrate all inbound account data from v2-ui to x-ui. Note that panel settings and username/password will not be migrated.


> After the migration is successful, please close v2-ui and restart x-ui, otherwise, there will be a port conflict between the inbound of v2-ui and x-ui.

```
x-ui v2-ui
```

## "Close Issue"

Seeing all kinds of newbie questions raises the blood pressure.

## Stargazers over time

[![Stargazers over time](https://starchart.cc/hojat-gazestani/x-ui.svg)](https://starchart.cc/hojat-gazestani/x-ui)
