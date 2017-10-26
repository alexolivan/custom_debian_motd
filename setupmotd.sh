#!/bin/bash
# +---------------------------------------------------------------------+
# |    ____       _     _                               _      _ _      |
# |   |  _ \  ___| |__ (_) __ _ _ __    _ __ ___   ___ | |_ __| | |     |
# |   | | | |/ _ \ '_ \| |/ _` | '_ \  | '_ ` _ \ / _ \| __/ _` | |     |
# |   | |_| |  __/ |_) | | (_| | | | | | | | | | | (_) | || (_| |_|     |
# |   |____/ \___|_.__/|_|\__,_|_| |_| |_| |_| |_|\___/ \__\__,_(_)     |
# |                                                                     |
# |                                                                     |
# | Copyright Alejandro Olivan 2017                 alex@alexolivan.com |
# +---------------------------------------------------------------------+
# | A Script that enables a custom motd with system like on Ubuntu.     |
# | The script needs to install stuff and modify some sys files.        |
# | Use at absolutelly your own risk!                                   |
# +---------------------------------------------------------------------+
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, 
# MA  02110-1301, USA.

# A IPv4 validation function
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# check and install figlet to enable ASCII art
if ! hash figlet 2>/dev/null; then
	echo "figlet command was not found in system, but we need it..."
	while true; do
    	read -p "Can I install it now?" yn
    	case $yn in
        	[Yy]* ) apt-get -y install figlet; break;;
        	[Nn]* ) echo "OK, leaving now!"; exit;;
        	* ) echo "Please answer yes or no.";;
    	esac
	done
fi

if [ -d "/etc/update-motd.d" ]; then
	echo "Found some previous motd stuff here...."
	while true; do
    	read -p "May I proceed and overwrite it?" yn
    	case $yn in
        	[Yy]* ) rm -rf /etc/update-motd.d; break;;
        	[Nn]* ) echo "OK, leaving now!"; exit;;
        	* ) echo "Please answer yes or no.";;
    	esac
	done
fi

echo "OK... enter a cool word you want to appear as banner title"
read MYBANNER

# create directory
mkdir /etc/update-motd.d/
# change to new directory
cd /etc/update-motd.d/
# create dynamic files
touch 00-header && touch 10-sysinfo && touch 90-footer
# make files executable
chmod +x /etc/update-motd.d/*
# remove MOTD file
rm /etc/motd
# symlink dynamic MOTD file
ln -s /var/run/motd /etc/motd

cat > 00-header << EOF
#!/bin/sh
#
#    00-header - create the header of the MOTD
#    Copyright (c) 2013 Nick Charlton
#    Copyright (c) 2009-2010 Canonical Ltd.
#
#    Authors: Nick Charlton <hello@nickcharlton.net>
#             Dustin Kirkland <kirkland@canonical.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

[ -r /etc/lsb-release ] && . /etc/lsb-release

if [ -z "\$DISTRIB_DESCRIPTION" ] && [ -x /usr/bin/lsb_release ]; then
        # Fall back to using the very slow lsb_release utility
        DISTRIB_DESCRIPTION=\$(lsb_release -s -d)
fi

figlet ${MYBANNER}
printf "%s\n" "\$(hostname -f)"
printf "\n"

printf "Welcome to %s (%s).\n" "$DISTRIB_DESCRIPTION" "\$(uname -r)"
printf "\n"
EOF

cat > 10-sysinfo << EOF
#!/bin/bash
#
#    10-sysinfo - generate the system information
#    Copyright (c) 2013 Nick Charlton
#
#    Authors: Nick Charlton <hello@nickcharlton.net>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

date=\`date\`
load=\`cat /proc/loadavg | awk '{print \$1}'\`
root_usage=\`df -h / | awk '/\// {print \$(NF-1)}'\`
memory_usage=\`free -m | awk '/Mem:/ { total=\$2 } /buffers\/cache/ { used=\$3 } END { printf("%3.1f%%", used/total*100)}'\`
swap_usage=\`free -m | awk '/Swap/ { printf("%3.1f%%", "exit !\$2;$3/\$2*100") }'\`
users=\`users | wc -w\`
time=\`uptime | grep -ohe 'up .*' | sed 's/,/\ hours/g' | awk '{ printf \$2" "\$3 }'\`
processes=\`ps aux | wc -l\`


ip=\`ip -4 addr show \$(route | grep default | awk '{ print \$8 }') | grep "inet" | head -1 | awk '{print \$2}' | cut -f1 -d"/"\`
if [ ! valid_ip $ip ]; then
	ip=\`ifconfig \$(route | grep default | awk '{ print \$8 }') | grep "netmask" | awk '{print \$2}'\`
	if [ ! valid_ip $ip ]; then
		ip=\`ifconfig \$(route | grep default | awk '{ print \$8 }') | grep "inet addr" | awk -F: '{print \$2}' | awk '{print \$1}'\`
		if [ ! valid_ip $ip ]; then
			ip="unknown IP"
		fi
	fi
fi



echo "System information as of: \$date"
echo
printf "System load:\t%s\tIP Address:\t%s\n" \$load \$ip
printf "Memory usage:\t%s\tSystem uptime:\t%s\n" \$memory_usage "\$time"
printf "Usage on /:\t%s\tSwap usage:\t%s\n" \$root_usage \$swap_usage
printf "Local Users:\t%s\tProcesses:\t%s\n" \$users \$processes
echo
EOF

cat > 90-footer << EOF
#!/bin/sh
#
#    90-footer - write the admin's footer to the MOTD
#    Copyright (c) 2013 Nick Charlton
#    Copyright (c) 2009-2010 Canonical Ltd.
#
#    Authors: Nick Charlton <hello@nickcharlton.net>
#             Dustin Kirkland <kirkland@canonical.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

[ -f /etc/motd.tail ] && cat /etc/motd.tail || true
EOF
