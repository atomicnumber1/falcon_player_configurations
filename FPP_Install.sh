#!/bin/bash

#############################################################################
# FPP Install Script (forked from: https://github.com/FalconChristmas/fpp)
# Modified by: atomicnumber1
#
# This is a quick and dirty script to take a stock OS build and install FPP
# onto it for use in building FPP images or setting up a development system.
#
# The script will automatically setup the system for the development
# version of FPP, the system can then be switched to a new version number
# or git branch for release.
#
#############################################################################
# To use this script, download the latest copy from github and run it as
# root on the system where you want to install FPP:
#
# wget -O ./FPP_Install.sh https://raw.githubusercontent.com/atomicnumber1/falcon_player_configurations/master/FPP_Install.sh
# chmod 700 ./FPP_Install.sh
# su
# ./FPP_Install.sh
#
#############################################################################
# NOTE: This script is used to build the SD images for FPP releases.  Its
#       main goal is to prep these release images.  It may be used for othe
#       purposes, but it is not our main priority to keep FPP working on
#       other Linux distributions or distribution versions other than those
#       we base our FPP releases on.  Currently, FPP images are based on the
#       following OS images for the Raspberry Pi:
#
#       Raspberry Pi
#           - URL: https://www.raspberrypi.org/downloads/raspbian/
#           - Image
#             - Raspbian GNU/Linux 9 (strecth)
#           - Login/Password
#             - pi/raspberry
#
#############################################################################
SCRIPTVER="0.1"
FPPBRANCH="master"
FPPIMAGEVER="2.0alpha"
FPPCFGVER="24"
FPPPLATFORM="Raspberry Pi"
OSVER="debian_9"
FPPDIR="/opt/fpp"


#############################################################################
# Some Helper Functions
#############################################################################
# Check local time against U.S. Naval Observatory time, set if too far out.
# This function was copied from /opt/fpp/scripts/functions in FPP source
# since we don't have access to the source until we clone the repo.
checkTimeAgainstUSNO () {
	# www.usno.navy.mil is not pingable, so check github.com instead
	ping -q -c 1 github.com > /dev/null 2>&1

	if [ $? -eq 0 ]
	then
		echo "FPP: Checking local time against U.S. Naval Observatory"

		# allow clocks to differ by 24 hours to handle time zone differences
		THRESHOLD=86400
		USNOSECS=$(wget -q -O - http://www.usno.navy.mil/cgi-bin/time.pl | sed -e "s/.*\">//" -e "s/<\/t.*//" -e "s/...$//")
		LOCALSECS=$(date +%s)
		MINALLOW=$(expr ${USNOSECS} - ${THRESHOLD})
		MAXALLOW=$(expr ${USNOSECS} + ${THRESHOLD})

		#echo "FPP: USNO Secs  : ${USNOSECS}"
		#echo "FPP: Local Secs : ${LOCALSECS}"
		#echo "FPP: Min Valid  : ${MINALLOW}"
		#echo "FPP: Max Valid  : ${MAXALLOW}"

		echo "FPP: USNO Time  : $(date --date=@${USNOSECS})"
		echo "FPP: Local Time : $(date --date=@${LOCALSECS})"

		if [ ${LOCALSECS} -gt ${MAXALLOW} -o ${LOCALSECS} -lt ${MINALLOW} ]
		then
			echo "FPP: Local Time is not within 24 hours of USNO time, setting to USNO time"
			date $(date --date="@${USNOSECS}" +%m%d%H%M%Y.%S)

			LOCALSECS=$(date +%s)
			echo "FPP: New Local Time: $(date --date=@${LOCALSECS})"
		else
			echo "FPP: Local Time is OK"
		fi
	else
		echo "FPP: Not online, unable to check time against U.S. Naval Observatory."
	fi
}


checkTimeAgainstUSNO


#############################################################################
echo "============================================================"
echo "$0 v${SCRIPTVER}"
echo ""
echo "FPP Image Version: v${FPPIMAGEVER}"
echo "FPP Directory    : ${FPPDIR}"
echo "FPP Branch       : ${FPPBRANCH}"
echo "Operating System : ${PRETTY_NAME}"
echo "Platform         : ${FPPPLATFORM}"
echo "OS Version       : ${OSVER}"
echo "============================================================"
#############################################################################

echo ""
echo "Notes:"
echo "- Does this system have internet access to install packages and FPP?"
echo ""
echo "WARNINGS:"
echo "- This install expects to be run on a clean freshly-installed system."
echo "  The script is not currently designed to be re-run multiple times."
echo "- This installer will create a 'fpp' user.  If the system"
echo "  has an empty root password, remote root login will be disabled."
echo ""

echo -n "Do you wish to proceed? [N/y] "
read ANSWER
if [ "x${ANSWER}" != "xY" -a "x${ANSWER}" != "xy" ]
then
	echo
	echo "Install cancelled."
	echo
	exit
fi

STARTTIME=$(date)


#######################################
# Log output and notify user
echo "ALL output will be copied to FPP_Install.log"
exec > >(tee -a FPP_Install.log)
exec 2>&1
echo "========================================================================"
echo "FPP_Install.sh started at ${STARTTIME}"
echo "------------------------------------------------------------------------"


#######################################
# Remove old /etc/fpp if it exists
if [ -e "/etc/fpp" ]
then
	echo "FPP - Removing old /etc/fpp"
	rm -rf /etc/fpp
fi


#######################################
# Create /etc/fpp directory and contents
echo "FPP - Creating /etc/fpp and contents"
mkdir /etc/fpp
echo "${FPPPLATFORM}" > /etc/fpp/platform
echo "v${FPPIMAGEVER}" > /etc/fpp/rfs_version
echo "${FPPCFGVER}" > /etc/fpp/config_version


#######################################
# Setting hostname
echo "FPP - Setting hostname"
echo "FPP" > /etc/hostname
hostname FPP


#######################################
# Add FPP hostname entry
echo "FPP - Adding 'FPP' hostname entry"
# Remove any existing 127.0.1.1 entry first
sed -i -e "/^127.0.1.1[^0-9]/d" /etc/hosts
echo "127.0.1.1       FPP" >> /etc/hosts


#######################################
# Make sure /opt exists
echo "FPP - Checking for existence of /opt"
cd /opt 2> /dev/null || mkdir /opt


#######################################
# Remove old /opt/fpp if it exists
if [ -e "/opt/fpp" ]
then
	echo "FPP - Removing old /opt/fpp"
	rm -rf /opt/fpp
fi


#######################################
# Make sure dependencies are installed
# Set noninteractive install to skip prompt about restarting services
export DEBIAN_FRONTEND=noninteractive

echo "FPP - Updating package list"
apt update

echo "FPP - Upgrading packages"
apt -y upgrade

echo "FPP - Installing required packages"
for package in alsa-base alsa-utils arping avahi-daemon \
				zlib1g-dev libpcre3 libpcre3-dev libbz2-dev libssl-dev \
				avahi-discover avahi-utils bash-completion bc build-essential \
				bzip2 ca-certificates ccache curl device-tree-compiler \
				dh-autoreconf ethtool exfat-fuse fbi fbset file flite gdb \
				gdebi-core git i2c-tools ifplugd imagemagick less \
				libboost-dev libconvert-binary-c-perl \
				libdbus-glib-1-dev libdevice-serialport-perl libjs-jquery \
				libjs-jquery-ui libjson-perl libjsoncpp-dev libnet-bonjour-perl \
				libpam-smbpass libtagc0-dev libtest-nowarnings-perl locales \
				mp3info mpg123 mpg321 mplayer nano node ntp perlmagick \
				php5-cli php5-common php5-curl php5-fpm php5-mcrypt \
				php5-sqlite php-apc python-daemon python-smbus rsync samba \
				samba-common-bin shellinabox sudo sysstat tcpdump usbmount vim \
				vim-common vorbis-tools vsftpd firmware-realtek gcc g++\
				network-manager dhcp-helper hostapd parprouted bridge-utils \
				firmware-atheros firmware-ralink firmware-brcm80211 \
				wireless-tools resolvconf \
				libmicrohttpd-dev libmicrohttpd10 libcurl4-openssl-dev
do
	apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install ${package}
done

echo "FPP - Configuring shellinabox to use /var/tmp"
echo "SHELLINABOX_DATADIR=/var/tmp/" >> /etc/default/shellinabox

echo "FPP - Cleaning up after installing packages"
apt -y clean

echo "FPP - Installing libhttpserver"
(cd /opt/ && git clone https://github.com/etr/libhttpserver && cd libhttpserver && git checkout 0.13.0 && ./bootstrap && mkdir build && cd build && ../configure --prefix=/usr && make && make install && cd /opt/ && rm -rf /opt/libhttpserver)

echo "FPP - Installing non-packaged Perl modules via App::cpanminus"
curl -L https://cpanmin.us | perl - --sudo App::cpanminus
echo "yes" | cpanm -fi Test::Tester File::Map Net::WebSocket::Server Net::PJLink

echo "FPP - Disabling dhcp-helper and hostapd from automatically starting"
update-rc.d -f dhcp-helper remove
update-rc.d -f hostapd remove

echo "FPP - Installing Pi-specific packages"

echo "FPP - Installing ola"
echo "deb   http://apt.openlighting.org/raspbian  wheezy main" >> /etc/apt/sources.list
apt update
apt install ola
apt install ola-python ola-rdm-tests

echo "FPP - Installing wiringpi"
apt install wiringpi

echo "FPP - Installing wiringpi"
apt install omxplayer

echo "FPP - Disabling getty on onboard serial ttyAMA0"
systemctl disable serial-getty@ttyAMA0.service

echo "FPP - Enabling SPI in device tree"
echo >> /boot/config.txt
echo "# Enable SPI in device tree" >> /boot/config.txt
echo "dtparam=spi=on" >> /boot/config.txt
echo >> /boot/config.txt

echo "FPP - Updating SPI buffer size"
sed -i 's/$/ spidev.bufsiz=102400/' /boot/cmdline.txt

echo "# Enable I2C in device tree" >> /boot/config.txt
echo "dtparam=i2c=on" >> /boot/config.txt
echo >> /boot/config.txt

echo "# Setting kernel scaling framebuffer method" >> /boot/config.txt
echo "scaling_kernel=8" >> /boot/config.txt
echo >> /boot/config.txt

echo "# Allow more current through USB" >> /boot/config.txt
echo "max_usb_current=1" >> /boot/config.txt
echo >> /boot/config.txt

echo "FPP - Disabling power management for wireless"
echo -e "# Disable power management\noptions 8192cu rtw_power_mgnt=0 rtw_enusbss=0" > /etc/modprobe.d/8192cu.conf

echo "FPP - Fix ifup/ifdown scripts for manual dns"
sed -i -n 'H;${x;s/^\n//;s/esac\n/&\nif grep -qc "Generated by fpp" \/etc\/resolv.conf\; then\n\texit 0\nfi\n/;p}' /etc/network/if-up.d/000resolvconf
sed -i -n 'H;${x;s/^\n//;s/esac\n/&\nif grep -qc "Generated by fpp" \/etc\/resolv.conf\; then\n\texit 0\nfi\n\n/;p}' /etc/network/if-down.d/resolvconf


#######################################
# Clone git repository
echo "FPP - Cloning git repository into /opt/fpp"
cd /opt
git clone https://github.com/FalconChristmas/fpp fpp


#######################################
# Switch to desired code branch
echo "FPP - Switching git clone to ${FPPBRANCH} branch"
cd /opt/fpp
git checkout ${FPPBRANCH}


#######################################
echo "FPP - Installing PHP composer"
wget https://raw.githubusercontent.com/composer/getcomposer.org/1b137f8bf6db3e79a38a5bc45324414a6b1f9df2/web/installer -O - -q | php -- --quiet


#######################################
echo "FPP - Setting up for UI"
sed -i -e "s/^user =.*/user = fpp/" /etc/php5/fpm/pool.d/www.conf
sed -i -e "s/^group =.*/group = fpp/" /etc/php5/fpm/pool.d/www.conf
sed -i -e "s/.*listen.owner =.*/listen.owner = fpp/" /etc/php5/fpm/pool.d/www.conf
sed -i -e "s/.*listen.group =.*/listen.group = fpp/" /etc/php5/fpm/pool.d/www.conf
sed -i -e "s/.*listen.mode =.*/listen.mode = 0660/" /etc/php5/fpm/pool.d/www.conf


#######################################
echo "FPP - Allowing short tags in PHP"
sed -i -e "s/^short_open_tag.*/short_open_tag = On/" /etc/php5/cli/php.ini
sed -i -e "s/^short_open_tag.*/short_open_tag = On/" /etc/php5/fpm/php.ini


#######################################
# Add the fpp user and group memberships
echo "FPP - Adding fpp user"
addgroup --gid 500 fpp
adduser --uid 500 --home /home/fpp --shell /bin/bash --ingroup fpp --gecos "Falcon Player" --disabled-password fpp
adduser fpp adm
adduser fpp sudo
adduser fpp spi
adduser fpp video
sed -i -e 's/^fpp:\*:/fpp:\$6\$rA953Jvd\$oOoLypAK8pAnRYgQQhcwl0jQs8y0zdx1Mh77f7EgKPFNk\/jGPlOiNQOtE.ZQXTK79Gfg.8e3VwtcCuwz2BOTR.:/' /etc/shadow


#######################################
echo "FPP - Fixing empty root passwd"
sed -i -e 's/root::/root:*:/' /etc/shadow


#######################################
echo "FPP - Populating /home/fpp"
mkdir /home/fpp/.ssh
chown fpp.fpp /home/fpp/.ssh
chmod 700 /home/fpp/.ssh

mkdir /home/fpp/media
chown fpp.fpp /home/fpp/media
chmod 700 /home/fpp/media

echo >> /home/fpp/.bashrc
echo ". /opt/fpp/scripts/common" >> /home/fpp/.bashrc
echo >> /home/fpp/.bashrc


#######################################
# Configure log rotation
echo "FPP - Configuring log rotation"
cp /opt/fpp/etc/logrotate.d/* /etc/logrotate.d/


#######################################
# Configure ccache
echo "FPP - Configuring ccache"
ccache -M 50M


#######################################
echo "FPP - Configuring FTP server"
sed -i -e "s/.*anonymous_enable.*/anonymous_enable=NO/" /etc/vsftpd.conf
sed -i -e "s/.*local_enable.*/local_enable=YES/" /etc/vsftpd.conf
sed -i -e "s/.*write_enable.*/write_enable=YES/" /etc/vsftpd.conf
service vsftpd restart


#######################################
echo "FPP - Configuring Samba"
cat <<-EOF >> /etc/samba/smb.conf

[FPP]
  comment = FPP Home Share
  path = /home/fpp
  writeable = Yes
  only guest = Yes
  create mask = 0777
  directory mask = 0777
  browseable = Yes
  public = yes
  force user = fpp

EOF
systemctl restart smbd.service
systemctl restart nmbd.service


#######################################
# Fix sudoers to not require password
echo "FPP - Giving fpp user sudo"
echo "fpp ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers


#######################################
# Print notice during login regarding console access
cat <<-EOF >> /etc/motd
[0;31m
                   _______  ___
                  / __/ _ \\/ _ \\
                 / _// ___/ ___/ [0m Falcon Player[0;31m
                /_/ /_/  /_/
[1m
This FPP console is for advanced users, debugging, and developers.  If
you aren't one of those, you're probably looking for the web-based GUI.

You can access the UI by typing "http://fpp.local/" into a web browser.[0m
	EOF


#######################################
# Config fstab to mount some filesystems as tmpfs
echo "FPP - Configuring tmpfs filesystems"
echo "#####################################" >> /etc/fstab
echo "tmpfs         /var/log    tmpfs   nodev,nosuid,size=10M 0 0" >> /etc/fstab
echo "tmpfs         /var/tmp    tmpfs   nodev,nosuid,size=10M 0 0" >> /etc/fstab
echo "#####################################" >> /etc/fstab


COMMENTED=""
SDA1=$(lsblk -l | grep sda1 | awk '{print $7}')
if [ -n ${SDA1} ]
then
	COMMENTED="#"
fi
echo "${COMMENTED}/dev/sda1     /home/fpp/media  auto    defaults,noatime,nodiratime,exec,nofail,flush,uid=500,gid=500  0  0" >> /etc/fstab
echo "#####################################" >> /etc/fstab


#######################################
# Disable IPv6
echo "FPP - Disabling IPv6"
cat <<-EOF >> /etc/sysctl.conf

	# FPP - Disable IPv6
	net.ipv6.conf.all.disable_ipv6 = 1
	net.ipv6.conf.default.disable_ipv6 = 1
	net.ipv6.conf.lo.disable_ipv6 = 1
	net.ipv6.conf.eth0.disable_ipv6 = 1
	EOF


#######################################
# Building nginx
echo "FPP - Building nginx webserver"
git clone https://github.com/wandenberg/nginx-push-stream-module.git
wget http://nginx.org/download/nginx-1.8.1.tar.gz
tar xzvf nginx-1.8.1.tar.gz
cd nginx-1.8.1/
./configure --add-module=../nginx-push-stream-module
make
make install


#######################################
echo "FPP - Configuring nginx webserver"
# Comment out the default server section
sed -i.orig '/^\s*location/,/^\s*}/s/^/#/g;/^\s*server/,/^\s*}/s/^/#/g;s/##/#/g' /usr/local/nginx/conf/nginx.conf
# Add an include of our server configuration
sed -i -e '/^\s*http\s*{/a\    push_stream_shared_memory_size 32M;\n    include /etc/fpp_nginx.conf;\n' /usr/local/nginx/conf/nginx.conf
sed -e "s#FPPDIR#${FPPDIR}#g" -e "s#FPPHOME#${FPPHOME}#g" < ${FPPDIR}/etc/nginx.conf > /etc/fpp_nginx.conf
# Set user to fpp
sed -i -e 's/^\s*\#\?\s*user\(\s*\)[^;]*/user\1fpp/' /usr/local/nginx/conf/nginx.conf
# Ensure pid matches our systemd service file
sed -i -e 's/^\s*\#\?\s*pid\(\s*\)[^;]*/pid\1logs\/nginx.pid/' /usr/local/nginx/conf/nginx.conf

cp ${FPPDIR}/scripts/nginx.service /lib/systemd/system/
systemctl enable nginx.service


#######################################
echo "FPP - Configuring FPP startup"
cp /opt/fpp/etc/init.d/fppinit /etc/init.d/
update-rc.d fppinit defaults
cp /opt/fpp/etc/init.d/fppstart /etc/init.d/
update-rc.d fppstart defaults


echo "FPP - Compiling binaries"
cd /opt/fpp/src/
make clean ; make

ENDTIME=$(date)


echo "========================================================="
echo "FPP Install Complete."
echo "Started : ${STARTTIME}"
echo "Finished: ${ENDTIME}"
echo "========================================================="
echo "You can reboot the system by changing to the 'fpp' user with the"
echo "password 'falcon' and running the shutdown command."
echo ""
echo "su - fpp"
echo "sudo shutdown -r now"
echo ""
echo "NOTE: If you are prepping this as an image for release,"
echo "remove the SSH keys before shutting down so they will be"
echo "rebuilt during the next boot."
echo ""
echo "su - fpp"
echo "sudo rm -rf /etc/ssh/ssh_host*key*"
echo "sudo shutdown -r now"
echo "========================================================="
echo ""
