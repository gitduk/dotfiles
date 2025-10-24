#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage:"
  echo "  $0 backup <backup_dir>       # 安全备份所有 volumes"
  echo "  $0 restore <backup_dir>      # 安全恢复所有 volumes"
  exit 1
}

if [[ $# -ne 2 ]]; then
  usage
fi

ACTION="$1"
BACKUP_DIR="$2"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# 获取所有 volume 名称
VOLUMES=$(podman volume ls --format "{{.Name}}")

# 临时存储已停止的容器及其原始状态
declare -A STOPPED_CONTAINERS

stop_containers_using_volume() {
  local VOL="$1"
  local CONTAINERS=$(podman ps -a --format "{{.ID}}" --filter volume="$VOL")
  for CID in $CONTAINERS; do
    local NAME=$(podman inspect "$CID" --format '{{.Name}}' | sed 's/^\/\(.*\)/\1/')
    local STATE=$(podman inspect "$CID" --format '{{.State.Status}}')
    if [[ "$STATE" == "running" ]]; then
      echo "Stopping container $NAME ($CID), original state: $STATE..."
      podman stop "$CID"
      STOPPED_CONTAINERS["$CID"]="$STATE"
    else
      echo "Container $NAME ($CID) is not running, current state: $STATE, skipping stop."
    fi
  done
}

start_stopped_containers() {
  for CID in "${!STOPPED_CONTAINERS[@]}"; do
    local NAME=$(podman inspect "$CID" --format '{{.Name}}' | sed 's/^\/\(.*\)/\1/')
    echo "Starting container $NAME ($CID)..."
    podman start "$CID"
  done
}

case "$ACTION" in
  backup)
    echo "Starting safe backup of all Podman volumes to '$BACKUP_DIR'..."
    for VOL in $VOLUMES; do
      MOUNTPOINT=$(podman volume inspect "$VOL" --format "{{.Mountpoint}}")
      stop_containers_using_volume "$VOL"
      BACKUP_FILE="$BACKUP_DIR/${VOL}_${DATE}.tar.gz"
      echo "Backing up volume '$VOL' -> '$BACKUP_FILE'..."
      tar -czf "$BACKUP_FILE" -C "$MOUNTPOINT" .
    done
    start_stopped_containers
    echo "Safe backup completed!"
    ;;
  restore)
    echo "Starting safe restore of all Podman volumes from '$BACKUP_DIR'..."
    for BACKUP_FILE in "$BACKUP_DIR"/*.tar.gz; do
      VOL=$(basename "$BACKUP_FILE" | sed -E 's/_(20[0-9]{6}_[0-9]{6})\.tar\.gz$//')
      MOUNTPOINT=$(podman volume inspect "$VOL" --format "{{.Mountpoint}}")
      if [[ -z "$MOUNTPOINT" ]]; then
        echo "Volume '$VOL' does not exist, skipping..."
        continue
      fi
      stop_containers_using_volume "$VOL"
      echo "Restoring volume '$VOL' from '$BACKUP_FILE'..."
      rm -rf "$MOUNTPOINT"/*
      tar -xzf "$BACKUP_FILE" -C "$MOUNTPOINT"
    done
    start_stopped_containers
    echo "Safe restore completed!"
    ;;
  *)
    usage
    ;;
esac
