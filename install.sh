### Background service installation ###

serviceName="gadget-server-oled"
serviceRepo="https://github.com/kccarbone/gadget-server-oled.git"
serviceHome="/etc/$serviceName"
serviceFile="/lib/systemd/system/$serviceName.service"

printf "\033[0;97;104m[ Installing $serviceName ]\033[0m\n\n"
sudo rm -rf $serviceHome
sudo mkdir -p $serviceHome
sudo rm -f $serviceFile
sudo touch $serviceFile

# Setup NPM
printf '\033[0;36mChecking Node.js\033[0m\n'
if ! type node > /dev/null 2>&1; 
then
  curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
  sudo apt install -y nodejs
fi
printf "Node $(node -v) installed\n"
printf "NPM $(npm -v) installed\n\n"

# Setup git
printf '\033[0;36mChecking git\033[0m\n'
if ! type git > /dev/null 2>&1; 
then
  printf '\033[0;36m\nInstalling Git...\033[0m\n'
  sudo apt install -y git-all
fi
printf "$(git --version) installed\n\n"

# Enable i2c
printf '\033[0;36mSetting up hardware\033[0m\n'
if grep -q 'i2c-bcm2708' /etc/modules; 
then
  printf 'i2c-bcm2708 is enabled\n'
else
  printf 'Enabling i2c-bcm2708\n'
  echo 'i2c-bcm2708' | sudo tee -a /etc/modules > /dev/null
fi
if grep -q 'i2c-dev' /etc/modules; 
then
  printf 'i2c-dev is enabled\n'
else
  printf 'Enabling i2c-dev\n'
  echo 'i2c-dev' | sudo tee -a /etc/modules > /dev/null
fi
if grep -q 'dtparam=i2c1=on' /boot/config.txt; 
then
  printf 'i2c1 parameter is set\n'
else
  printf 'Setting i2c1 parameter\n'
  echo 'dtparam=i2c1=on' | sudo tee -a /boot/config.txt > /dev/null
fi
if grep -q 'dtparam=i2c_arm=on' /boot/config.txt; 
then
  printf 'i2c_arm parameter is set\n'
else
  printf 'Setting i2c_arm parameter\n'
  echo 'dtparam=i2c_arm=on' | sudo tee -a /boot/config.txt > /dev/null
fi
if [ -f /etc/modprobe.d/raspi-blacklist.conf ]; 
then
  printf 'Removing blacklist entries\n'
  sudo sed -i 's/^blacklist spi-bcm2708/#blacklist spi-bcm2708/' /etc/modprobe.d/raspi-blacklist.conf
  sudo sed -i 's/^blacklist i2c-bcm2708/#blacklist i2c-bcm2708/' /etc/modprobe.d/raspi-blacklist.conf
fi
printf '\n'

# Download app
printf '\033[0;36mDownloading service\033[0m\n'
sudo git clone $serviceRepo $serviceHome
printf "\n"

# Install dependencies
printf '\033[0;36mInstalling dependencies\033[0m\n'
sudo npm config set user 0
sudo npm --prefix $serviceHome install
sudo npm config set user $UID
printf "\n"

# Create local service
printf '\033[0;36mEnabling background service\033[0m\n'
echo '[Unit]' | sudo tee -a $serviceFile > /dev/null
echo 'Description=Local server for controlling a pi oled display' | sudo tee -a $serviceFile > /dev/null
echo 'After=network-online.target' | sudo tee -a $serviceFile > /dev/null
echo '' | sudo tee -a $serviceFile > /dev/null
echo '[Service]' | sudo tee -a $serviceFile > /dev/null
echo 'User=root' | sudo tee -a $serviceFile > /dev/null
echo 'Type=simple' | sudo tee -a $serviceFile > /dev/null
echo "WorkingDirectory=$serviceHome" | sudo tee -a $serviceFile > /dev/null
echo 'Environment="PORT=33301"' | sudo tee -a $serviceFile > /dev/null
echo 'ExecStart=npm start' | sudo tee -a $serviceFile > /dev/null
echo 'Restart=on-failure' | sudo tee -a $serviceFile > /dev/null
echo 'RestartSec=10' | sudo tee -a $serviceFile > /dev/null
echo 'StandardOutput=syslog' | sudo tee -a $serviceFile > /dev/null
echo 'StandardError=syslog' | sudo tee -a $serviceFile > /dev/null
echo "SyslogIdentifier=$serviceName" | sudo tee -a $serviceFile > /dev/null
echo '' | sudo tee -a $serviceFile > /dev/null
echo '[Install]' | sudo tee -a $serviceFile > /dev/null
echo 'WantedBy=multi-user.target' | sudo tee -a $serviceFile > /dev/null

sudo rm -f "$rootDir/etc/systemd/system/multi-user.target.wants/$serviceName.service"
sudo ln -s "$serviceFile" "$rootDir/etc/systemd/system/multi-user.target.wants/$serviceName.service"
sudo systemctl daemon-reload
printf 'Service enabled\n'
sudo systemctl start $serviceName
printf 'Service started\n\n'

printf '\033[0;32mDone!\033[0m\n'