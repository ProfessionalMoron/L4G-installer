#
#Elevate with sudo su -  before running
#
#Meant for Swizzin running Debian 11, should work for Debian 10 but cant test it 
#

#check if running as root
if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi
. /etc/swizzin/sources/globals.sh
. /etc/swizzin/sources/functions/npm
. /etc/swizzin/sources/functions/users
#Get user and pass
user=$(cut -d: -f1 < /root/.master.info)
pass=$(_get_user_password "$user")

function _qbit_install() {
echo "Configuring for Qbittorrent"
mkdir -p /home/$user/scripts
rm -rf /home/$user/scripts/Upload-Assistant/ &> /dev/null
echo_progress_start "Cloning Upload-Assistant to /home/$user/scripts/Upload-Assistant/"
git clone https://github.com/L4GSP1KE/Upload-Assistant.git /home/$user/scripts/Upload-Assistant &> /dev/null
echo_progress_done "Cloning finished"
echo_progress_start "Installing requirements"
pip3 install -q -U -r /home/$user/scripts/Upload-Assistant/requirements.txt
echo_progress_done "Installing requirements done"
mv /home/$user/scripts/Upload-Assistant/data/example-config.py /home/$user/scripts/Upload-Assistant/data/config.py
sudo chown -R ${user}:${user} /home/$user/scripts/Upload-Assistant/


#Get qbit webui port
qbitconfpath="/home/${user}/.config/qBittorrent/qBittorrent.conf"
qbitport=$(grep 'WebUI\\Port' "${qbitconfpath}" | cut -d= -f2)

#Change port,pass and user on qbittorrent part on config
sed -i 's/"qbit_port" : "8080"/"qbit_port" : "'$qbitport'"/g' /home/$user/scripts/Upload-Assistant/data/config.py
sed -i 's/"qbit_pass" : "password"/"qbit_pass" : "'${pass}'"/g' /home/$user/scripts/Upload-Assistant/data/config.py
sed -i 's/"qbit_user" : "username"/"qbit_user" : "'${user}'"/g' /home/$user/scripts/Upload-Assistant/data/config.py
echo ""
echo_progress_done "Upload-Assistant configured for Qbittorrent"
echo ""

#alias
echo "alias upload='python3 /home/${user}/scripts/Upload-Assistant/upload.py 2>/dev/null'" >> /home/${user}/.bashrc
source /home/${user}/.bashrc
}


function _rtorrent_install {
echo "Configuring for rTorrent"
mkdir -p /home/$user/scripts
rm -rf /home/$user/scripts/Upload-Assistant/ &> /dev/null
echo_progress_start "Cloning Upload-Assistant to /home/$user/scripts/Upload-Assistant/"
git clone https://github.com/L4GSP1KE/Upload-Assistant.git /home/$user/scripts/Upload-Assistant &> /dev/null
echo_progress_done "Cloning finished"
echo_progress_start "Installing requirements"
pip3 install -q -U -r /home/$user/scripts/Upload-Assistant/requirements.txt
echo_progress_done "Installing requirements done"
mv /home/$user/scripts/Upload-Assistant/data/example-config.py /home/$user/scripts/Upload-Assistant/data/config.py
sudo chown -R ${user}:${user} /home/$user/scripts/Upload-Assistant/

#
sed -i 's,"https://user:password@server.host.tld:443/username/rutorrent/plugins/httprpc/action.php","https://'$user':'${pass}'@localhost:443/'$user'/rutorrent/plugins/httprpc/action.php",g' /home/$user/scripts/Upload-Assistant/data/config.py

#Change torrent client to rtorrent
sed -i 's/"default_torrent_client" : "Client1"/"default_torrent_client" : "rtorrent_sample"/g' /home/$user/scripts/Upload-Assistant/data/config.py

echo ""
echo_progress_done "Upload-Assistant configured for rTorrent"
echo ""

#alias
echo "alias upload='python3 /home/${user}/scripts/Upload-Assistant/upload.py 2>/dev/null'" >> /home/${user}/.bashrc
source /home/${user}/.bashrc


}

function _deluge_install {
echo "Configuring for Deluge"
mkdir -p /home/$user/scripts
rm -rf /home/$user/scripts/Upload-Assistant/ &> /dev/null
echo_progress_start "Cloning Upload-Assistant to /home/$user/scripts/Upload-Assistant/"
git clone https://github.com/L4GSP1KE/Upload-Assistant.git /home/$user/scripts/Upload-Assistant &> /dev/null
echo_progress_done "Cloning finished"
echo_progress_start "Installing requirements"
pip3 install -q -U -r /home/$user/scripts/Upload-Assistant/requirements.txt
echo_progress_done "Installing requirements done"
mv /home/$user/scripts/Upload-Assistant/data/example-config.py /home/$user/scripts/Upload-Assistant/data/config.py
sudo chown -R ${user}:${user} /home/$user/scripts/Upload-Assistant/

#Change torrent client to deluge
sed -i 's/"default_torrent_client" : "Client1"/"default_torrent_client" : "deluge_sample"/g' /home/$user/scripts/Upload-Assistant/data/config.py

#Get deluge deamon  port
delugeconfpath="/home/${user}/.config/deluge/core.conf"
delugeport=$(grep 'daemon_port' "${delugeconfpath}" | cut -f2 -d"_" | cut -c6-100 | rev | cut -c 3- | rev)

#Change port,pass and user
sed -i 's/"deluge_port" : "8080"/"deluge_port" : "'${delugeport}'"/g' /home/$user/scripts/Upload-Assistant/data/config.py
sed -i 's/"deluge_pass" : "password"/"deluge_pass" : "'${pass}'"/g' /home/$user/scripts/Upload-Assistant/data/config.py
sed -i 's/"deluge_user" : "username"/"deluge_user" : "'${user}'"/g' /home/$user/scripts/Upload-Assistant/data/config.py

echo ""
echo_progress_done "Upload-Assistant configured for Deluge"
echo ""
}



clear
echo "What client are you using?"
echo "qbit = Configures for qbittorrent"
echo "rtorrent = Configures for rtorrent"
echo "deluge = Configures for deluge"
echo ""
while true; do
    read -r -p "Enter client: " choice
    case $choice in
        "qbit")
            _qbit_install
            break
            ;;
        "rtorrent")
            _rtorrent_install
            break
            ;;
        "deluge")
            _deluge_install
            break
            ;;
        *)
            echo "Unknown Option."
            ;;
    esac
done
while true; do
    read -r -p "Would you like to input api keys and announce urls now or add them later manually? yes/no: " choice
    
    case $choice in
        "yes")
            #TMDB API KEY
            echo TMDB api key:
            read TMDB_api_key
            sed -i 's/"tmdb_api key"/"'$TMDB_api_key'"/g' /home/$user/scripts/Upload-Assistant/data/config.py
            #IMGBB API KEY
            echo IMGBB api key:
            read IMGBB_api_key
            sed -i 's/"imgbb api key"/"'$IMGBB_api_key'"/g' /home/$user/scripts/Upload-Assistant/data/config.py
            #PTPIMG API KEY
            echo PTPIMG api key:
            read PTPIMG_api_key
            sed -i 's/"ptpimg api key"/"'$PTPIMG_api_key'"/g' /home/$user/scripts/Upload-Assistant/data/config.py
            #BLU API KEY
            echo Blutopia api key:
            read Blutopia_api_key
            sed -i 's/"BLU api key"/"'$Blutopia_api_key'"/g' /home/$user/scripts/Upload-Assistant/data/config.py
            #Blutopia ANNOUNCE URL 
            echo Blutopia announce url:
            read Blutopia_announce_url
            sed -i 's,"https://blutopia.xyz/announce/customannounceurl","'$Blutopia_announce_url'",g' /home/$user/scripts/Upload-Assistant/data/config.py
            #BHD API KEY
            echo BeyondHD api key:
            read BeyondHD_api_key
            sed -i 's/"BHD api key"/"'$BeyondHD_api_key'"/g' /home/$user/scripts/Upload-Assistant/data/config.py
            #BHD ANNOUNCE URL 
            echo BeyondHD announce url:
            read BeyondHD_announce_url
            sed -i 's,"https://beyond-hd.me/announce/customannounceurl","'$BeyondHD_announce_url'",g' /home/$user/scripts/Upload-Assistant/data/config.py
            
            echo ""
            echo "All added"
            echo "To run the upload script just do 'upload movie.mkv' or 'upload --help' for all the commands"
            echo ""
            break
            ;;
        "no")
            echo "Run nano  /home/$user/scripts/Upload-Assistant/data/config.py  to add them manually"
            echo "Once those have been added run the upload script with 'upload movie.mkv' or 'upload --help' for all the commands"
            break
            ;;
        *)
            echo "Unknown Option."
            ;;
    esac
done



exit
