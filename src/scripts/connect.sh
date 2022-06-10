#!/bin/bash
connect-linux() {
  ET_phone_home=$(ss -Hnto state established '( sport = :ssh )' | head -n1 | awk '{ split($4, a, ":"); print a[1] }')
  DEFAULT_GW="$(ip route show default|awk '{print $3}')"
  echo "Initial default gateway is $DEFAULT_GW"

  sudo ip route add 169.254.0.0/16 via "$DEFAULT_GW"
  echo "Added route to 169.254.0.0/16 via default gateway"

  if [ -n "$ET_phone_home" ]; then
    sudo ip route add "$ET_phone_home"/32 via "$DEFAULT_GW"
    echo "Added route to $ET_phone_home/32 via default gateway"
  fi

  for IP in $(host runner.circleci.com | awk '{ print $4; }')
    do
      sudo ip route add "$IP"/32 via "$DEFAULT_GW"
      echo "Added route to $IP/32 via default gateway"
  done

  for RESCONF_DNS in $(systemd-resolve --status | grep 'DNS Servers'|awk '{print $3}')
    do
      sudo ip route add "$RESCONF_DNS"/32 via "$DEFAULT_GW"
      echo "Added route to $RESCONF_DNS/32 via default gateway"
  done

  sudo wg-quick up wg0
}

connect-macos() {
  DEFAULT_GW="$(route -n get default|grep gateway| awk '{print $2}')"
  echo "Initial default gateway is $DEFAULT_GW"

  sudo route -n add -net 169.254.0.0/16 "$DEFAULT_GW"
  
  for RESCONF_DNS in $(scutil --dns | grep 'nameserver\[[0-9]*\]'|sort -u|awk '{print$3}')
    do
      sudo route -n add -net "$RESCONF_DNS/32" "$DEFAULT_GW"
  done
  
  ET_phone_home="$(netstat -an | grep '\.2222\s.*ESTABLISHED' | head -n1 | awk '{ split($5, a, "."); print a[1] "." a[2] "." a[3] "." a[4] }')"

  if [ -n "$ET_phone_home" ]; then
    sudo route -n add -net "$ET_phone_home/32" "$DEFAULT_GW"
  fi
  
  for IP in $(host runner.circleci.com | awk '{ print $4; }')
    do
      sudo route -n add -net "$IP/32" "$DEFAULT_GW"
  done
    
cat << EOF | sudo tee /Library/LaunchDaemons/com.wireguard.wg0.plist 1>/dev/null
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.wireguard.wg0</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/local/bin/wg-quick</string>
      <string>up</string>
      <string>wg0</string>
    </array>
  </dict>
</plist>
EOF
  
  printf "\nWireguard daemon configured\n\n"
  
  sudo launchctl load /Library/LaunchDaemons/com.wireguard.wg0.plist
  sudo launchctl start com.wireguard.wg0
  
  until sudo launchctl list | grep wireguard; do
    sleep 1
  done
}

connect-windows() {
  DEFAULT_GW=$(ipconfig|grep "Default" | awk -F ': ' '{print$2}'| grep -v -e '^[[:blank:]]*$')
  echo "Initial default gateway is $DEFAULT_GW"

  route add 169.254.0.0 MASK 255.255.0.0 "$DEFAULT_GW"
  echo "Added route to 169.254.0.0/16 via default gateway"

  ET_phone_home=$(netstat -an | grep ':22 .*ESTABLISHED' | head -n1 | awk '{ split($3, a, ":"); print a[1] }') 
  if [ -n "$ET_phone_home" ]; then
    route add "$ET_phone_home" MASK 255.255.255.255 "$DEFAULT_GW"
    echo "Added route to $ET_phone_home/32 via default gateway"
  fi
  /c/progra~1/wireguard/wireguard.exe //installtunnelservice "C:\tmp\wg0.conf"
}

printf "\nPublic IP before VPN connection is %s\n\n" "$(curl -s http://checkip.amazonaws.com)"
connect-"$WG_CLIENT_EXECUTOR"

case "$WG_CLIENT_EXECUTOR" in
  linux|macos)
    ping_command=(ping -c1 "$WG_SERVER_IP")
    ;;
  windows)
    ping_command=(ping -n 1 "$WG_SERVER_IP")
    ;;
esac

counter=1
  until "${ping_command[@]}" || [ "$counter" -ge $((TIMEOUT)) ]; do
    ((counter++))
    echo "Attempting to connect..."
    sleep 1;
  done

  if (! "${ping_command[@]}" > /dev/null); then
    printf "\nUnable to establish connection within the allocated time ---> Giving up.\n"
  else
    printf "\nConnected to WireGuard server\n"
    printf "\nPublic IP is now %s\n" "$(curl -s http://iconfig.co)"
  fi
