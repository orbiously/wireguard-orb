#!/bin/bash
case "$EXECUTOR" in
  linux)
    sudo wg-quick down wg0
    sudo rm -f /etc/wireguard/wg0.conf
    ;;
  macos)
    sudo wg-quick down /tmp/wg0.conf
    rm -f /tmp/wg0.conf
    ;;
  windows)
    /c/progra~1/wireguard/wireguard.exe //uninstalltunnelservice wg0
    rm -f "C:\tmp\wg0.conf"
    ;;
esac