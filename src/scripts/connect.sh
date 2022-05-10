#!/bin/bash
case "$(uname)" in
  [Ll]inux*)
    if [ -f /.dockerenv ]; then
      EXECUTOR=docker
      printf "The WireGuard orb doesn not support the 'docker' executor.\n"
      printf "Please use the Linux 'machine' executor instead."
      exit 1
    else
      EXECUTOR=linux
    fi
    PLATFORM=Linux
    ping_command=(ping -c1 "$WG_SRV_IP")
    check_install=(wg --version)
    ;;
  [Dd]arwin*)
    PLATFORM=macOS
    EXECUTOR=macos
    ping_command=(ping -c1 "$WG_SRV_IP")
    check_install=(wg --version)
    ;;
  msys*|MSYS*|nt|win*)
    PLATFORM=Windows
    EXECUTOR=windows
    ping_command=(ping -n 1 "$WG_SRV_IP")
    check_install=(/c/progra~1/wireguard/wg.exe --version)
    ;;
esac

install-Linux() {
  printf "Installing WireGuard for Linux\n\n"
  sudo apt-get update
  sudo apt-get install -y wireguard-tools resolvconf
  printf "\nWireGuard for %s installed\n\n" "$PLATFORM"
}

install-macOS() {
  printf "Installing WireGuard for macOS\n\n"
  HOMEBREW_NO_AUTO_UPDATE=1 brew install wireguard-tools
  sudo sed -i '' 's/\/usr\/bin\/env[[:space:]]bash/\/usr\/local\/bin\/bash/' /usr/local/Cellar/wireguard-tools/1.0.20210914/bin/wg-quick
  printf "\nWireGuard for %s installed\n\n" "$PLATFORM"
}

install-Windows() {
  printf "Installing WireGuard for Windows\n\n"
  choco install wireguard
  printf "\nWireGuard for %s installed\n" "$PLATFORM"
}

configure-Linux() {
  echo "${!CONFIG}" | sudo bash -c 'base64 --decode > /etc/wireguard/wg0.conf'
}

configure-macOS() {
  echo "${!CONFIG}" | base64 --decode > /tmp/wg0.conf
}

configure-Windows() {
  echo "${!CONFIG}" | base64 --decode > "C:\tmp\wg0.conf"
}

if "${check_install[@]}" 2>/dev/null; then
  printf "WireGuard is already installed\n"
else
  install-$PLATFORM
fi

configure-$PLATFORM
printf "\nWireGuard for %s configured\n" "$PLATFORM"

printf "\nPublic IP before VPN connection is %s\n\n" "$(curl -s http://checkip.amazonaws.com)"

connect-linux() {
  ET_phone_home=$(ss -Hnto state established '( sport = :ssh )' | head -n1 | awk '{ split($4, a, ":"); print a[1] }')
  DEFAULT_GW="$(ip route show default|awk '{print $3}')"
  echo "Default gateway is $DEFAULT_GW"

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
      <string>/tmp/wg0.conf</string>
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
  ET_phone_home=$(netstat -an | grep ':22 .*ESTABLISHED' | head -n1 | awk '{ split($3, a, ":"); print a[1] }') 
  DEFAULT_GW=$(ipconfig|grep "Default" | awk -F ': ' '{print$2}'| grep -v -e '^[[:blank:]]*$')
  route add 169.254.0.0 MASK 255.255.0.0 "$DEFAULT_GW"
  route add "$ET_phone_home" MASK 255.255.255.255 "$DEFAULT_GW"

  /c/progra~1/wireguard/wireguard.exe //installtunnelservice "C:\tmp\wg0.conf"
}

connect-"$EXECUTOR"

counter=1
  until "${ping_command[@]}" || [ "$counter" -ge $((TIMEOUT)) ]; do
    ((counter++))
    echo "Attempting to connect..."
    sleep 1;
  done

  if (! "${ping_command[@]}" > /dev/null); then
    printf "\nUnable to establish connection within the allocated time ---> Giving up.\n"
  else
    printf "\nConnected to WireGuard\n"
    printf "\nPublic IP is now %s\n" "$(curl -s http://checkip.amazonaws.com)"
  fi

echo "export PLATFORM=$PLATFORM" >> "$BASH_ENV"
echo "export EXECUTOR=$EXECUTOR" >> "$BASH_ENV"