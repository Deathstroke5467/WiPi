#!/bin/bash

#  This file is part of WiPi
#  Copyright (C) 2017 Marcello Barbieri

#  WiPi is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

#  WiPi is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with WiPi.  If not, see <http://www.gnu.org/licenses/>.


##COLOR LIB##
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
NORMAL=$(tput sgr0)

DIR=/opt/WiPi

printf '%s\n' "Building Directories" "may ask for sudo password"
#create directories
sudo install -d -m 755 $DIR/lib
sudo install -d -m 755 $DIR/conf
sudo install -d -m 777 $DIR/logs
#install files to directories
sudo install -m 644 lib/* $DIR/lib/
sudo install -m 644 conf/* $DIR/conf/
sudo install -m 755 WiPi.sh $DIR/

#install dependencies
printf '%s\n' "Installing Dependencies"
[ ! -f "lib/DEAL-Lib.cfg" ] && printf '%s\n' "${RED}!!! lib is missing${NORMAL}" && exit 1
. lib/DEAL-Lib.cfg
packlist="iptables iproute hostapd dnsmasq"
pack_install

#disables services at boot
printf '%s\n' "Disabling hostapd and dnsmasq services at boot" "${BLUE}Enable WiPi at boot to start your AP at boot${NORMAL}"
if sudo systemctl disable hostapd.service &> /dev/null ; then
  printf '%s\n' "hostapd disabled at boot"
else
  printf '%s\n' "unable to disable hostapd at boot"
fi
if sudo systemctl disable dnsmasq.service &> /dev/null ; then
  printf '%s\n' "dnsmasq disabled at boot"
else
  printf '%s\n' "unable to disable dnsmasq at boot"
fi

#create systemd file
printf '%s\n' "Adding systemd file"
sudo cat <<'EOF'> /tmp/WiPi.service
[Unit]
Description=manages WiPi AP

[Service]
Type=oneshot
ExecStart=$DIR/WiPi.sh start
ExecStop=$DIR/WiPi.sh stop
ExecReload=$DIR/WiPi.sh stop ; sleep 5 ; $DIR/WiPi.sh start

[Install]
WantedBy=multi-user.target
EOF
chmod 755 /tmp/WiPi.service
sudo mv /tmp/WiPi.service /etc/systemd/system/

#create alias
printf '%s\n' "Creating Alias"
cd $HOME
[ ! -f .bash_aliases ] && touch .bash_aliases
if ! grep "WiPi=\"$DIR/WiPi.sh\"" .bash_aliases; then
 sudo -- bash -c 'echo alias WiPi=\"'$DIR'/WiPi.sh\" >> .bash_aliases'
fi
. ~/.bash_aliases

printf '%s\n' "You can run WiPi by typing '${GREEN}WiPi${NORMAL}'"
