#!/usr/bin/env zsh

# 获取默认网关 IP 地址
GATEWAY_IP=$(ip route show default | head -n 1 | awk '/default/ {print $3}')

# 获取网关接口的 IP 地址和子网掩码
INTERFACE=$(ip route show default | head -n 1 | awk '/default/ {print $5}')
INTERFACE_IP=$(ip addr show dev $INTERFACE | awk '/inet / {print $2}' | cut -d'/' -f1)
SUBNET_MASK=$(ip addr show dev $INTERFACE | awk '/inet / {print $2}' | cut -d'/' -f2)

# 计算网段地址范围
calc_network_address() {
    local ip=$1
    local mask=$2

    IFS=. read -r i1 i2 i3 i4 <<< "$ip"
    if [[ $mask =~ ^[0-9]+$ ]]; then
        # CIDR 表示法，例如 24
        local mbits=$mask
        local mask_value=$((0xFFFFFFFF << (32 - mbits)))
        local m1=$((mask_value >> 24 & 0xFF))
        local m2=$((mask_value >> 16 & 0xFF))
        local m3=$((mask_value >> 8 & 0xFF))
        local m4=$((mask_value & 0xFF))

    else
        # 完整的子网掩码，例如 255.255.255.0
        IFS=. read -r m1 m2 m3 m4 <<< "$mask"
    fi

    printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))"
}
NETWORK_ADDRESS=$(calc_network_address $INTERFACE_IP $SUBNET_MASK)

# 扫描间隔时间(秒)
SCAN_INTERVAL=60

while true; do
    # 使用 nmap 扫描活跃主机
    nmap -sn -n $NETWORK_ADDRESS/24 | awk '/report/ {print $5}' | tee /tmp/live_hosts
    sleep $SCAN_INTERVAL
done

