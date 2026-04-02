#!/usr/bin/env bash

CLASH_PORT=7893
DNS_PORT=1053
LAN_NET=10.10.10.0/24
SSH_PORT=5522

echo "=== Clash旁路由启动 ==="

# 开启IP转发
echo 1 > /proc/sys/net/ipv4/ip_forward

# 清理规则
iptables -t nat -F
iptables -t mangle -F
iptables -F

# 删除旧链
iptables -t mangle -X CLASH 2>/dev/null
iptables -t nat -X CLASH_DNS 2>/dev/null

# 创建链
iptables -t mangle -N CLASH
iptables -t nat -N CLASH_DNS

# -------------------------
# SSH保护
# -------------------------
iptables -I INPUT -p tcp --dport $SSH_PORT -j ACCEPT

# -------------------------
# 本机流量不代理
# -------------------------
for ip in $(hostname -I); do
    iptables -t mangle -A CLASH -s $ip -j RETURN
done

# -------------------------
# 跳过局域网
# -------------------------
for NET in 0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4; do
    iptables -t mangle -A CLASH -d $NET -j RETURN
done

# -------------------------
# 透明代理
# -------------------------
iptables -t mangle -A CLASH -p tcp -j TPROXY --on-port $CLASH_PORT --tproxy-mark 1
iptables -t mangle -A CLASH -p udp -j TPROXY --on-port $CLASH_PORT --tproxy-mark 1

# 应用规则
iptables -t mangle -A PREROUTING -s $LAN_NET -j CLASH

# -------------------------
# DNS劫持
# -------------------------
iptables -t nat -A PREROUTING -s $LAN_NET -p udp --dport 53 -j REDIRECT --to-ports $DNS_PORT
iptables -t nat -A PREROUTING -s $LAN_NET -p tcp --dport 53 -j REDIRECT --to-ports $DNS_PORT

# -------------------------
# routing 幂等性
# -------------------------
ip rule del fwmark 1 table 100 2>/dev/null
ip route del local 0.0.0.0/0 dev lo table 100 2>/dev/null
ip rule add fwmark 1 table 100
ip route add local 0.0.0.0/0 dev lo table 100

echo "iptables 规则完成"
echo "SSH 已保护，不会因 Clash 断开"
