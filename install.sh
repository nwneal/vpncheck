#!/usr/bin/env bash

# check if being run by root
if [ $(whoami) != root ]; then
	echo "you must be root to install..."	
	exit
fi

# setup vars
VPNC_INSTALL_DIR=/opt/vpncheck
VPNC_USER=vpncheck
VPNC_GROUP=vpncheck

# create dir
if [ ! -e $VPNC_INSTALL_DIR ]; then
	mkdir $VPNC_INSTALL_DIR
fi

# create user
groupadd $VPNC_GROUP
useradd -d $VPNC_INSTALL_DIR -s /bin/sh -g $VPNC_GROUP $VPNC_USER 

# copy files over to dir
cp ./vpncheck.rb ./firewall-block ./firewall-open $VPNC_INSTALL_DIR/

# set up systemd
touch ./vpncheck.service
echo "[Unit]" >> ./vpncheck.service
echo "Description=shutdown all connections if vpn is not connected." >> ./vpncheck.service
echo "After=network.target" >> ./vpncheck.service
echo "" >> ./vpncheck.service
echo "[Service]" >> ./vpncheck.service
echo "Type=simple" >> ./vpncheck.service
echo "ExecStart=$VPNC_INSTALL_DIR/vpncheck.rb $VPNC_INSTALL_DIR" >> ./vpncheck.service
echo 'ExecStop=/bin/kill -s QUIT $MAINPID' >> ./vpncheck.service
echo "User=$VPNC_USER" >> ./vpncheck.service
echo "Group=$VPNC_GROUP" >> ./vpncheck.service
echo '' >> ./vpncheck.service
echo '[Install]' >> ./vpncheck.service
echo 'WantedBy=multi-user.target' >> ./vpncheck.service

chown root:root ./vpncheck.service
chmod 664 ./vpncheck.service

cp -p ./vpncheck.service /etc/systemd/system/
rm -f ./vpncheck.service

# add to sudoers file
touch ./vpncheck-perm
echo "# give $VPNC_USER permission to run iptables-restore without a sudo password." >> ./vpncheck-perm
echo "$VPNC_USER ALL=(ALL) NOPASSWD: /sbin/iptables-restore" >> ./vpncheck-perm

chown root:root ./vpncheck-perm
chmod 440 ./vpncheck-perm

cp -p ./vpncheck-perm /etc/sudoers.d/
rm -f ./vpncheck-perm

# create uninstall.sh file
touch ./uninstall.sh
echo '#!/usr/bin/env bash' >> ./uninstall.sh
echo '' >> ./uninstall.sh
echo 'if [ $(whoami) != root ]; then' >> ./uninstall.sh
echo 'echo "script must be run as root. exiting..."' >> ./uninstall.sh
echo 'exit' >> ./uninstall.sh
echo 'fi' >> ./uninstall.sh
echo '' >> ./uninstall.sh
echo "VPNC_INSTALL_DIR=$VPNC_INSTALL_DIR" >> ./uninstall.sh
echo "VPNC_USER=$VPNC_USER" >> ./uninstall.sh
echo "VPNC_GROUP=$VPNC_GROUP" >> ./uninstall.sh
echo '' >> ./uninstall.sh
echo 'systemctl stop vpncheck' >> ./uninstall.sh
echo 'systemctl disable vpncheck' >> ./uninstall.sh
echo '' >> ./uninstall.sh
echo 'rm -f /etc/systemd/system/vpncheck.service' >> ./uninstall.sh
echo 'rm -f /etc/sudoers.d/vpncheck-perm' >> ./uninstall.sh
echo '' >> ./uninstall.sh
echo 'rm -rf $VPNC_INSTALL_DIR' >> ./uninstall.sh
echo 'userdel $VPNC_USER' >> ./uninstall.sh
echo 'groupdel $VPNC_GROUP' >> ./uninstall.sh
echo '' >> ./uninstall.sh
echo 'echo "vpncheck sucessfully uninstalled."' >> ./uninstall.sh

cp ./uninstall.sh $VPNC_INSTALL_DIR/
rm -f ./uninstall.sh

# fix permissions
chown -R $VPNC_USER:$VPNC_GROUP $VPNC_INSTALL_DIR
chmod -R 750 $VPNC_INSTALL_DIR

# echo instructions for enabling and disabling service
echo "vpncheck is installed."
echo 
echo "you will want to build your own firewall rules for when your VPN is disconnected."
echo "the best way to do this is to build your iptables firewall while testing your VPN."
echo "once you have set up your rules, run:"
echo "    sudo iptables-save > $VPNC_INSTALL_DIR/firewall-block"
echo "if you need to restore your rules to new, run:"
echo "    sudo iptables-restore < $VPNC_INSTALL_DIR/firewall-open"
echo
echo "to enable the service on start-up, run 'sudo systemctl enable vpncheck'".
echo
echo "if connections aren't working after the vpn is connected, run 'sudo $VPNC_INSTALL_DIR/vpncheck.rb --fix'"
echo
echo "to uninstall vpncheck, run 'sudo $VPNC_INSTALL_DIR/uninstall.sh'"
echo


