# ipsetUtils

## ipset 使用实例

### updater

updater 用于动态更新主机 IP 地址到 ipset 运行时容器中。
这个解决方案适用于主机或域名经常变动的场景，比如主机使用 DDNS 时的 ipset 设置。

- 主机名数据文件: ([host.db](updater/host.db))

  将需要定时监控、更新的主机名、域名逐一加入其中，如下:

  ```db
  DOMAINS="www.yahoo.com"
  ```

  多个域名之间用英文空格分隔。

- ipset 更新脚本: ([update.sh](updater/updater.sh))
  - ipset 中 IPv4 容器名暂定为 host4
  - ipset 中 IPv6 容器名暂定为 host6
  - IP 数据条目超时时间由常量 TTL 定义，单位为秒

- iptables 配置

  - INPUT  链中源地址匹配上则放行。
  - OUTPUT 链中目的地址匹配上则放行。

  ```sh
  # IPv4
  iptables -I INPUT 1 -m set --match-set host4 src -j ACCEPT
  iptables -I OUTPUT 1 -m set --match-set host4 dst -j ACCEPT
  ```
