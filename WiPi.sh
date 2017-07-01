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
apconf="$DIR/conf/AP.cfg" #user AP config
hostapdconf="$DIR/conf/hostapd.conf"   #hostapd config
dnsconf="$DIR/conf/dnsmasq.conf"  #dnsmasq config

if [ ! -f  $hostapdconf ] || [ ! -f $dnsconf ] || [ ! -f $apconf ] ; then
 "one or more config files in '$DIR/conf' are missing"
else
  . $apconf
fi

ap_load() {
  sudo ip link set dev $inint up > /dev/null && printf '%s\n' "$inint up"

  #start hostapd
  sudo sed -i "/interface=/c \interface=$inint" $hostapdconf
  if ! sudo hostapd -B $hostapdconf ; then
    printf '%s\n' "hostapd failed to start"
  fi
  sleep 2

  #configure routing for interface
  [ -z $mask] && mask="24" #if netmask is not defined set to 255.255.255.0
  sudo ip addr add "$address.1"/$mask dev $inint
  sudo ip ro add  "$address.0"/$mask via "$address.1"

  #start DNS server
  if ! sudo dnsmasq -z -C $dnsconf -i $inint -I lo ; then
    printf '%s\n' "dnsmasq failed to start"
  fi

  #forward ipv4
  sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

  #setup iptable rules
  sudo iptables -t nat -A POSTROUTING -o $outint -j MASQUERADE
  sudo iptables -A FORWARD -i $outint -o $inint -m state --state RELATED,ESTABLISHED -j ACCEPT
  sudo iptables -A FORWARD -i $inint -o $outint -j ACCEPT
}

start() {
  if ap_load ; then
    printf '%s\n' "AP is now started"
  else
    reload
  fi
}

stop() {
  sudo pkill hostapd
  sudo pkill dnsmasq
  sudo iptables -t nat -F
  #"WiPi successfully stopped"
}

reload() {
  if printf '%s\n' "stopping AP" stop && ap_load ; then
    printf '%s\n' "AP is now started"
  else
    printf '%s\n' "failed to reload" && exit 1
  fi
}

case $1 in
  [sS][tT][aA][rR][tT]|i)
    start ;;
  [sS][tT][oO][pP]|k)
    stop ;;
  [rR][eE][lL][oO][aA][dD]|r)
    reload;;
  *)
    printf '%s\n' "Options:" "start  | i" "stop   | k" "reload | r" "Usage: $0 start" ;;
esac
