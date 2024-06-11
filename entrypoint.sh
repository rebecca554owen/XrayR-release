#!/bin/sh

if [ -z "$NodeID" ]; then
  exit 1
fi

Level=${Level:-none}
DnsConfigPath=${DnsConfigPath:-}
RouteConfigPath=${RouteConfigPath:-}
InboundConfigPath=${InboundConfigPath:-}
OutboundConfigPath=${OutboundConfigPath:-}
BufferSize=${BufferSize:-64}

PanelType=${PanelType:-NewV2board}
ApiHost=${ApiHost:-http://127.0.0.1:7001}
ApiKey=${ApiKey:-xboardisbest}
NodeID=${NodeID:-1}
NodeType=${NodeType:-V2ray}
EnableVless=${EnableVless:-false}

RuleListPath=${RuleListPath:-}
ListenIP=${ListenIP:-0.0.0.0} 
SendIP=${SendIP:-0.0.0.0} 
EnableDNS=${EnableDNS:-false}
DNSType=${EnableDNS:-UseIP}
EnableREALITY=${EnableREALITY:-false}
DisableLocalREALITYConfig=${DisableLocalREALITYConfig:-true}

CertMode=${CertMode:-none}
CertDomain=${CertDomain:-xboard.com}
Provider=${Provider:-cloudflare}
ALICLOUD_ACCESS_KEY=${ALICLOUD_ACCESS_KEY:-}
ALICLOUD_SECRET_KEY=${ALICLOUD_SECRET_KEY:-}
CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL:-}
CLOUDFLARE_API_KEY=${CLOUDFLARE_API_KEY:-}

cat > /etc/XrayR/xrayr.yml <<EOF
Log:
  Level: $Level # Log level: none, error, warning, info, debug 
  AccessPath: # /etc/XrayR/access.Log
  ErrorPath: # /etc/XrayR/error.log
DnsConfigPath: $DnsConfigPath # /etc/XrayR/dns.json # Path to dns config, check https://xtls.github.io/config/dns.html for help
RouteConfigPath: $RouteConfigPath # /etc/XrayR/route.json # Path to route config, check https://xtls.github.io/config/routing.html for help
InboundConfigPath: $InboundConfigPath # /etc/XrayR/custom_inbound.json # Path to custom inbound config, check https://xtls.github.io/config/inbound.html for help
OutboundConfigPath: $OutboundConfigPath # /etc/XrayR/custom_outbound.json # Path to custom outbound config, check https://xtls.github.io/config/outbound.html for help
ConnectionConfig:
  Handshake: 4 # Handshake time limit, Second
  ConnIdle: 30 # Connection idle time limit, Second
  UplinkOnly: 0 # Time limit when the connection downstream is closed, Second
  DownlinkOnly: 0 # Time limit when the connection is closed after the uplink is closed, Second
  BufferSize: $BufferSize # The internal cache size of each connection, kB
Nodes:
  - PanelType: $PanelType # Panel type: SSpanel, NewV2board, PMpanel, Proxypanel, V2RaySocks, GoV2Panel
    ApiConfig:
      ApiHost: $ApiHost
      ApiKey: $ApiKey
      NodeID: $NodeID
      NodeType: $NodeType # Node type: V2ray, Shadowsocks, Trojan, Shadowsocks-Plugin
      Timeout: 30 # Timeout for the api request
      EnableVless: $EnableVless # Enable Vless for V2ray Type
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings, 0 means disable
      DeviceLimit: 0 # Local settings will replace remote settings, 0 means disable
      RuleListPath: $RuleListPath # /etc/XrayR/rulelist Path to local rulelist file
      DisableCustomConfig: false # disable custom config for sspanel
    ControllerConfig:
      ListenIP: 0.0.0.0 # IP address you want to listen
      SendIP: 0.0.0.0 # IP address you want to send pacakage
      UpdatePeriodic: 60 # Time to update the nodeinfo, how many sec.
      DeviceOnlineMinTraffic: 100 # V2board面板设备数限制统计阈值，大于此流量时上报设备数在线，单位kB，不填则默认上报
      EnableDNS: $EnableDNS # Use custom DNS config, Please ensure that you set the dns.json well
      DNSType: $DNSType # AsIs, UseIP, UseIPv4, UseIPv6, DNS strategy
      EnableProxyProtocol: false # Only works for WebSocket and TCP
      AutoSpeedLimitConfig:
        Limit: 0 # Warned speed. Set to 0 to disable AutoSpeedLimit (mbps)
        WarnTimes: 0 # After (WarnTimes) consecutive warnings, the user will be limited. Set to 0 to punish overspeed user immediately.
        LimitSpeed: 0 # The speedlimit of a limited user (unit: mbps)
        LimitDuration: 0 # How many minutes will the limiting last (unit: minute)
      GlobalDeviceLimitConfig:
        Enable: false # Enable the global device limit of a user
        RedisAddr: 127.0.0.1:6379 # The redis server address
        RedisPassword: YOUR PASSWORD # Redis password
        RedisDB: 0 # Redis DB
        Timeout: 5 # Timeout for redis request
        Expiry: 60 # Expiry time (second)
      EnableFallback: false # Only support for Trojan and Vless
      FallBackConfigs:  # Support multiple fallbacks
        - SNI: # TLS SNI(Server Name Indication), Empty for any
          Alpn: # Alpn, Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 80 # Required, Destination of fallback, check https://xtls.github.io/config/features/fallback.html for details.
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for disable
      EnableREALITY: $EnableREALITY # 是否开启 REALITY
      DisableLocalREALITYConfig: $DisableLocalREALITYConfig  # 是否忽略本地 REALITY 配置
      REALITYConfigs: # 本地 REALITY 配置
        Show: false # Show REALITY debug
        Dest: m.media-amazon.com:443 # REALITY 目标地址
        ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for disable
        ServerNames: # Required, list of available serverNames for the client, * wildcard is not supported at the moment.
          - m.media-amazon.com
        PrivateKey: # 可不填
        MinClientVer: # Optional, minimum version of Xray client, format is x.y.z.
        MaxClientVer: # Optional, maximum version of Xray client, format is x.y.z.
        MaxTimeDiff: 0 # Optional, maximum allowed time difference, unit is in milliseconds.
        ShortIds: # 可不填
          - ""
      CertConfig:
        CertMode: $CertMode # Option about how to get certificate: none, file, http, tls, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: $CertDomain # Domain to cert
        CertFile: /etc/XrayR/cert/$CertDomain.cert # Provided if the CertMode is file
        KeyFile: /etc/XrayR/cert/$CertDomain.key
        Provider: $Provider # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
        Email: admin@gmail.com
        DNSEnv: # DNS ENV option used by DNS provider
          CLOUDFLARE_EMAIL: $CLOUDFLARE_EMAIL 
          CLOUDFLARE_API_KEY: $CLOUDFLARE_API_KEY 

EOF

  echo "xrayr.yml 配置文件已创建成功，开始启动xrayr"

while true; do XrayR --config /etc/XrayR/xrayr.yml; sleep 5; done
