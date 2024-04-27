# XRayR
A Xray backend framework that can easily support many panels.

一个基于Xray的后端框架，支持V2ay,Trojan,Shadowsocks协议，极易扩展，支持多面板对接

Find the source code here: [XrayR-project/XrayR](https://github.com/XrayR-project/XrayR)

# 详细使用教程

[教程](https://xrayr-project.github.io/XrayR-doc/)

# 一键安装

```
bash <(curl -Ls https://raw.githubusercontent.com/rebecca554owen/XrayR-release/master/install.sh)
```
# Docker 一键启动
```
docker run -d   --name xrayr   --network host   --restart always  \
  -e ApiHost=your_api_host  \
  -e ApiKey=your_api_key  \
  -e NodeID=1  \
  -e NodeType=Vless  \
  -e EnableREALITY=true  \
  ghcr.io/rebecca554owen/xrayr:latest

```


