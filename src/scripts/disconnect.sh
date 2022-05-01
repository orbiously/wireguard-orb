#!/bin/bash
case "$EXECUTOR" in
  linux)
    sudo wg-quick down wg0
    ;;
  macos)
    sudo wg-quick down /tmp/wg0.conf
    ;;
  windows)
    /c/progra~1/wireguard/wireguard.exe //uninstalltunnelservice wg0
    ;;
esac