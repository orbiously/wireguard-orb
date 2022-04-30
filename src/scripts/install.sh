#!/bin/bash
install() {
  case $1 in
    [Ll]inux*)
      if [ -f /.dockerenv ]; then
        EXECUTOR=docker
        exit 1
      else
        EXECUTOR=linux
      fi
      printf "Installing WireGuard for Linux\n\n"
      sudo apt-get update
      sudo apt-get install -y wireguard-tools resolvconf
      PLATFORM=Linux
      ;;
    [Dd]arwin*)
      printf "Installing WireGuard for macOS\n\n"
      HOMEBREW_NO_AUTO_UPDATE=1 brew install wireguard-tools
      sudo sed -i '' 's/\/usr\/bin\/env[[:space:]]bash/\/usr\/local\/bin\/bash/' /usr/local/Cellar/wireguard-tools/1.0.20210914/bin/wg-quick
      PLATFORM=macOS
      EXECUTOR=macos
      ;;
    msys*|MSYS*|nt|win*)
      printf "Installing WireGuard for Windows\n\n"
      choco install wireguard
      PLATFORM=Windows
      EXECUTOR=windows
      ;;
  esac
}

install "$(uname)"

printf "\nWireGuard for %s installed\n\n" "$PLATFORM"
printf "\nPublic IP before VPN connection is %s\n" "$(curl http://checkip.amazonaws.com)"
echo "export PLATFORM=$PLATFORM" >> "$BASH_ENV"
echo "export EXECUTOR=$EXECUTOR" >> "$BASH_ENV"