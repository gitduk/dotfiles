{% if request.target == "clash" or request.target == "clashr" %}

mixed-port: {{ default(global.clash.mixed-port, "7890") }}
redir-port: {{ default(global.clash.redir_port, "7891") }}
allow-lan: {{ default(global.clash.allow_lan, "true") }}
mode: Rule
log-level: {{ default(global.clash.log_level, "info") }}
secret: {{ default(global.clash.secret, "clash") }}
external-controller: :9090

tun:
  enable: true
  stack: system   # or gvisor
  dns-hijack:
    - 8.8.8.8:53
    - tcp://8.8.8.8:53
    - any:53
    - tcp://any:53
  auto-route: true
  auto-detect-interface: true

dns:
  enable: {{ default(request.clash.dns, "true") }}
  listen: :{{ default(local.clash.dns.port, "7853") }}
  enhanced-mode: {{ default(local.clash.dns.enhanced-mode, "fake-ip") }}
  fake-ip-range: 198.18.0.1/16
  use-hosts: true

  # 对于下面的域名，fake-ip 模式会返回真实 ip
  fake-ip-filter:
    - "*.lan"
    - "*.biliapi.com"
    - "*.bilibili.com"
    - "*.bilivideo.com"
    - "*.bilivideo.cn"
    - "*.foxmail.com"
    - "*.gtimg.com"
    - "*.idqqimg.com"
    - "*.igamecj.com"
    - "*.myapp.com"
    - "*.myqcloud.com"
    - "*.qq.com"
    - "*.qqmail.com"
    - "*.qqurl.com"
    - "*.smtcdns.com"
    - "*.smtcdns.net"
    - "*.soso.com"
    - "*.tencent-cloud.net"
    - "*.tencent.com"
    - "*.tencentmind.com"
    - "*.tenpay.com"
    - "*.wechat.com"
    - "*.weixin.com"
    - "*.weiyun.com"

  # 对于所有 DNS 请求，fallback 和 nameserver 内的服务器都会同时查找
  # 如果 DNS 结果为非国内 IP(GEOIP country is not `CN`)，会使用 fallback 内的服务器的结果
  # 因为 nameserver 内为国内服务器，对国外域名可能有 DNS 污染。fallback 内是国外服务器，能防止国外域名被 DNS 污染
  nameserver:
    - 127.0.0.1:53
  fallback:
    - https://doh.pub/dns-query
    - https://cloudflare-dns.com/dns-query

  fallback-filter:
    # If geoip is true, when geoip matches geoip-code, clash will use nameserver results. Otherwise, Clash will only use fallback results.
    geoip: true
    geoip-code: CN
    # IPs in these subnets will be considered polluted, when nameserver results match these ip, clash will use fallback results.
    ipcidr:
      - 0.0.0.0/8
      - 10.0.0.0/8
      - 100.64.0.0/10
      - 127.0.0.0/8
      - 169.254.0.0/16
      - 172.16.0.0/12
      - 192.0.0.0/24
      - 192.0.2.0/24
      - 192.88.99.0/24
      - 192.168.0.0/16
      - 198.18.0.0/15
      - 198.51.100.0/24
      - 203.0.113.0/24
      - 224.0.0.0/4
      - 240.0.0.0/4
      - 255.255.255.255/32

    # Domains in these list will be considered polluted, when lookup these domains, clash will use fallback results.
    domain:
      - +.claude.ai
      - +.github.com
      - +.google.com
      - +.youtube.com
      - +.facebook.com
      - +.githubusercontent.com

script:
  shortcuts:
    quic: network == 'udp' and dst_port == 443

{% if local.clash.new_field_name == "true" %}
proxies: ~
proxy-groups: ~
rules: ~
{% else %}
Proxy: ~
Proxy Group: ~
Rule: ~
{% endif %}

{% endif %}
