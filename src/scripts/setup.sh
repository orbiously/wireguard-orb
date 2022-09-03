#!/bin/bash
case "$(uname)" in
  [Ll]inux*)
    if [ -f /.dockerenv ]; then
      WG_CLIENT_EXECUTOR=docker
      printf "The WireGuard orb does not support the 'docker' executor.\n"
      printf "Please use the Linux 'machine' executor instead."
      exit 1
    else
      WG_CLIENT_EXECUTOR=linux
    fi
    WG_CLIENT_PLATFORM=Linux
    check_install=(wg --version)
    ;;
  [Dd]arwin*)
    WG_CLIENT_PLATFORM=macOS
    WG_CLIENT_EXECUTOR=macos
    check_install=(wg --version)
    ;;
  msys*|MSYS*|nt|win*)
    WG_CLIENT_PLATFORM=Windows
    WG_CLIENT_EXECUTOR=windows
    check_install=(/c/progra~1/wireguard/wg.exe --version)
    ;;
esac

install-Linux() {
  printf "Installing WireGuard for Linux\n\n"
  sudo apt-get update
  sudo apt-get install -y wireguard-tools resolvconf
}

install-macOS() {
  printf "Installing WireGuard for macOS\n\n"
  HOMEBREW_NO_AUTO_UPDATE=1 brew install wireguard-tools
  sudo sed -i '' 's/\/usr\/bin\/env[[:space:]]bash/\/usr\/local\/bin\/bash/' /usr/local/Cellar/wireguard-tools/1.0.20210914/bin/wg-quick
}

install-Windows() {
  printf "Installing WireGuard for Windows\n\n"
  choco install wireguard
}

configure-Linux() {
  echo "${!CLIENT_CONFIG}" | sudo bash -c 'base64 --decode > /etc/wireguard/wg0.conf'
}

configure-macOS() {
  sudo mkdir /etc/wireguard
  echo "${!CLIENT_CONFIG}" |  sudo bash -c 'base64 --decode > /etc/wireguard/wg0.conf'
}

configure-Windows() {
  echo "${!CLIENT_CONFIG}" | base64 --decode > "C:\tmp\wg0.conf"
}

if "${check_install[@]}" 2>/dev/null; then
  printf "WireGuard is already installed\n"
else
  install-$WG_CLIENT_PLATFORM
  printf "\nWireGuard for %s installed\n" "$WG_CLIENT_PLATFORM"
fi

configure-$WG_CLIENT_PLATFORM
printf "\nWireGuard for %s configured\n" "$WG_CLIENT_PLATFORM"

echo "export WG_CLIENT_PLATFORM=$WG_CLIENT_PLATFORM" >> "$BASH_ENV"
echo "export WG_CLIENT_EXECUTOR=$WG_CLIENT_EXECUTOR" >> "$BASH_ENV"
