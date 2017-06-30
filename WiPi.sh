#!/bin/bash

#  WiPi - an AP configurator and manager
#  Copyright (C) 2017 Marcello Barbieri

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

DIR=/opt/WiPi

#Config
inint="wlan0"
outint="intwifi0"
apconf="$DIR/conf/hostapd.conf"   #hostapd config
dnsconf="$DIR/conf/dnsmasq.conf"  #dnsmasq config

#if [ !  . $apconf] || [ ! . $dnsconf ] ; then

#fi

start_all() {
#  case $2 in
#    s)
#    ip link set dev $intin down
#    macchanger -r $intin ;;
#  esac

  #add rfkill unblock??
  sudo ip link set dev $inint up

  #start hostapd
  sed -i "/interface=/c \interface=$inint" $apconf
  sudo hostapd -B $apconf
  sleep 2

address="10.0.0"
  #configure routing for interface
  [ -z $mask] && mask="24" #if netmask is not defined set to 255.255.255.0
echo "mask is $mask"
  sudo ip addr add "$address.1"/$mask dev $inint
  sudo ip ro add  "$address.0"/$mask via "$address.1"

  #start DNS server
  sudo dnsmasq -z -C $dnsconf -i $inint -I lo

  #forward ipv4
  sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

  #setup iptable rules
  #sudo iptables -t nat -A POSTROUTING -o $outint -j MASQUERADE
  #sudo iptables -A FORWARD -i $intin -o $outint -j ACCEPT
  sudo iptables -t nat -A POSTROUTING -o $outint -j MASQUERADE
  sudo iptables -A FORWARD -i $outint -o $inint -m state --state RELATED,ESTABLISHED -j ACCEPT
  sudo iptables -A FORWARD -i $inint -o $outint -j ACCEPT

  #check if dnsmasq and hostapd are running properly
  printf '%s\n' "AP is now started"
}

stop_all() {
  #$stop="$(pkill hostapd) $(pkill dnsmasq) $(iptables -t nat F)"
  sudo pkill hostapd
  sudo pkill dnsmasq
  #iptables -t nat -F
}

case $1 in
  [sS][tT][aA][rR][tT]|i)
    start_all ;;
  [sS][tT][oO][pP]|k)
    stop_all ;;
  [rR][eE][lL][oO][aA][dD]|r)
    stop_all
    start_all ;;
  *)
    printf '%s\n' "Options:" "start  | i" "stop   | k" "reload | r" "Usage: $0 start" ;;
esac
