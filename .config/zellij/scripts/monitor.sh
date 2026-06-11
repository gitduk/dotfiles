#!/usr/bin/env bash
# Thresholds
MEM_THRESH=${MEM_THRESH:-80}
CPU_THRESH=${CPU_THRESH:-80}
TEMP_THRESH=${TEMP_THRESH:-80}
DISK_THRESH=${DISK_THRESH:-80}

# Timing: fast metrics every INTERVAL seconds, disk every DISK_EVERY loops
INTERVAL=${INTERVAL:-5}
DISK_EVERY=${DISK_EVERY:-12}

notify() {
  zellij pipe "zjstatus::notify::$1" 2>/dev/null
}

loop_count=0

while true; do
  # Memory
  mem=$(free | awk '/Mem/{printf "%d", $3/$2*100}')
  if [ "$mem" -ge "$MEM_THRESH" ]; then
    notify "MEM ${mem}%"
  fi

  # CPU
  read _ u n s i io irq si st g gn < /proc/stat
  sleep 0.1
  read _ u2 n2 s2 i2 io2 irq2 si2 st2 g2 gn2 < /proc/stat
  tot=$(( u2+n2+s2+i2+io2+irq2+si2+st2+g2+gn2 - u-n-s-i-io-irq-si-st-g-gn ))
  idl=$(( i2+io2 - i-io ))
  [ "$tot" -eq 0 ] && cpu=0 || cpu=$(( (tot - idl) * 100 / tot ))
  if [ "$cpu" -ge "$CPU_THRESH" ]; then
    notify "CPU ${cpu}%"
  fi

  # Temperature (max across thermal zones)
  temp=0
  for f in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$f" ] || continue
    v=$(( $(cat "$f") / 1000 ))
    [ "$v" -gt "$temp" ] && temp=$v
  done
  if [ "$temp" -ge "$TEMP_THRESH" ] 2>/dev/null; then
    notify "TEMP ${temp}°C"
  fi

  # Disk (root filesystem) — checked every DISK_EVERY loops
  loop_count=$(( loop_count + 1 ))
  if [ $(( loop_count % DISK_EVERY )) -eq 0 ]; then
    disk=$(df --output=pcent / | tail -1 | tr -d ' %')
    if [ "$disk" -ge "$DISK_THRESH" ]; then
      notify "DISK ${disk}%"
    fi
  fi

  sleep "$INTERVAL"
done
