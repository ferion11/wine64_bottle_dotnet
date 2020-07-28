#!/bin/bash
export WINE64BOTTLE="${PWD}/work/wine64bottle"

#=========================
die() { echo >&2 "$*"; exit 1; };

PRINT_NUM=1
printscreen() {
	xwd -display :77 -root -silent | convert xwd:- png:/tmp/screenshot_${PRINT_NUM}.png
	PRINT_NUM=$((PRINT_NUM+1))
}
#=========================

#Initializing the keyring requires entropy
pacman-key --init

# Enable Multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

# Configure for compilation:
#sed -i '/^BUILDENV/s/\!ccache/ccache/' /etc/makepkg.conf
sed -i '/#MAKEFLAGS=/c MAKEFLAGS="-j2"' /etc/makepkg.conf
#sed -i '/^COMPRESSXZ/s/\xz/xz -T 2/' /etc/makepkg.conf
#sed -i "s/^PKGEXT='.pkg.tar.gz'/PKGEXT='.pkg.tar.xz'/" /etc/makepkg.conf
#sed -i '$a   CFLAGS="$CFLAGS -w"'   /etc/makepkg.conf
#sed -i '$a CXXFLAGS="$CXXFLAGS -w"' /etc/makepkg.conf
sed -i 's/^CFLAGS\s*=.*/CFLAGS="-mtune=nehalem -O2 -pipe -ftree-vectorize -fno-stack-protector"/' /etc/makepkg.conf
sed -i 's/^CXXFLAGS\s*=.*/CXXFLAGS="-mtune=nehalem -O2 -pipe -ftree-vectorize -fno-stack-protector"/' /etc/makepkg.conf
#sed -i 's/^LDFLAGS\s*=.*/LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"/' /etc/makepkg.conf
sed -i 's/^#PACKAGER\s*=.*/PACKAGER="DanielDevBR"/' /etc/makepkg.conf
sed -i 's/^PKGEXT\s*=.*/PKGEXT=".pkg.tar"/' /etc/makepkg.conf
sed -i 's/^SRCEXT\s*=.*/SRCEXT=".src.tar"/' /etc/makepkg.conf

# Add more repo:
echo "" >> /etc/pacman.conf

# https://github.com/archlinuxcn/repo
echo "[archlinuxcn]" >> /etc/pacman.conf
#echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf
echo "SigLevel = Never" >> /etc/pacman.conf
echo "Server = https://repo.archlinuxcn.org/\$arch" >> /etc/pacman.conf
echo "" >> /etc/pacman.conf

# https://lonewolf.pedrohlc.com/chaotic-aur/
echo "[chaotic-aur]" >> /etc/pacman.conf
#echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf
echo "SigLevel = Never" >> /etc/pacman.conf
echo "Server = http://lonewolf-builder.duckdns.org/\$repo/x86_64" >> /etc/pacman.conf
echo "Server = http://chaotic.bangl.de/\$repo/x86_64" >> /etc/pacman.conf
echo "Server = https://repo.kitsuna.net/x86_64" >> /etc/pacman.conf
echo "" >> /etc/pacman.conf
#pacman-key --keyserver keys.mozilla.org -r 3056513887B78AEB
#pacman-key --lsign-key 3056513887B78AEB
#sudo pacman-key --keyserver hkp://p80.pool.sks-keyservers.net:80 -r 3056513887B78AEB
#sudo pacman-key --lsign-key 3056513887B78AEB

# workaround one bug: https://bugzilla.redhat.com/show_bug.cgi?id=1773148
echo "Set disable_coredump false" >> /etc/sudo.conf

echo "DEBUG: updating pacmam keys"
pacman -Syy --noconfirm && pacman --noconfirm -S archlinuxcn-keyring

echo "DEBUG: pacmam sync"
pacman -Syy --noconfirm

echo "DEBUG: pacmam updating system"
pacman -Syu --noconfirm

#Add "base-devel multilib-devel" for compile in the list:
pacman -S --noconfirm wget base-devel multilib-devel pacman-contrib git tar grep sed zstd xz bzip2 procps-ng wine wine-gecko wine-mono wine-nine mpg123 lib32-mpg123 gst-plugins-base-libs lib32-gst-plugins-base-libs xorg-server-xvfb xdotool imagemagick xorg-xwd
#===========================================================================================
echo "======= DEBUG: Starting xvfb ======="
Xvfb :77 -screen 0 1024x768x24 &
Xvfb_PID=$!
sleep 7
echo "* exporting the DISPLAY:"
export DISPLAY=:77
sleep 7
#--------

echo "* exporting wine var and creating bottle"
mkdir -p "${WINE64BOTTLE}"
#export WINEARCH=win32
export WINEARCH=win64
export WINEPREFIX="${WINE64BOTTLE}"
wineboot &
echo "* Waiting to initialize wine..."

# 2 times, one for 32bit and another for 64bit
close_wine_mono_init_windows() {
	while ! WID=$(xdotool search --name "Wine Mono Installer"); do
		sleep 2
	done
	#printscreen
	echo "Sending installer keystrokes..."
	xdotool key --delay 2000 Tab
	sleep 1
	#printscreen
	xdotool key --delay 2000 space
	sleep 2
	#printscreen
	sleep 7
}
close_wine_mono_init_windows

close_wine_gecko_init_windows() {
	while ! WID=$(xdotool search --name "Wine Gecko Installer"); do
		sleep 2
	done
#	printscreen
#	echo "Sending installer keystrokes..."
#	xdotool key --delay 2000 Tab
#	sleep 2
	#printscreen
	xdotool key --delay 2000 space
	sleep 14
	#printscreen
}
close_wine_gecko_init_windows
close_wine_gecko_init_windows

# This will kill all running wine processes in prefix=$WINEPREFIX
#wineserver -k

# This will hang until all wine processes in prefix=$WINEPREFIX
wineserver -w

# Alternative to test only
#sleep 60 && printscreen
ps ux | grep wine


install_dotnet_from_winetricks() {
	wget -c https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
	chmod +x ./winetricks
	./winetricks -q dotnet48
	#./winetricks dotnet48 &
}
install_dotnet_from_winetricks

handle_gui_winetricks_dotnet48() {
	# Wine dotnet40 ------------
	sleep 21
	while ! WID=$(xdotool search --name "Unnamed"); do
		sleep 2
	done
	printscreen
	echo "Sending dotnet keystrokes..."
	xdotool key --delay 2000 Tab Tab Tab
	sleep 2
	printscreen
	xdotool key --delay 2000 space
	sleep 2
	printscreen
	xdotool key --delay 2000 Tab Tab Tab
	sleep 2
	printscreen
	xdotool key --delay 2000 space
	sleep 120
	printscreen
	sleep 120
	printscreen
	echo "* Waiting more 300s to finish"
	sleep 300
	printscreen
	xdotool key --delay 2000 Tab
	sleep 2
	printscreen
	xdotool key --delay 2000 space
	sleep 60
	printscreen
	#-----------------------
	# Wine dotnet48 ------------
	sleep 21
	while ! WID=$(xdotool search --name "Microsoft .NET Framework"); do
		sleep 2
	done
	printscreen
	echo "Sending dotnet keystrokes..."
	xdotool key --delay 2000 Tab Tab Tab Tab
	sleep 2
	printscreen
	xdotool key --delay 2000 space
	sleep 2
	while ! WID=$(xdotool search --name "Unnamed"); do
		sleep 2
	done
	printscreen
	echo "Sending dotnet keystrokes..."
	xdotool key --delay 2000 Tab Tab Tab
	sleep 2
	printscreen
	xdotool key --delay 2000 space
	sleep 2
	printscreen
	xdotool key --delay 2000 Tab Tab
	sleep 2
	printscreen
	xdotool key --delay 2000 space
	sleep 120
	printscreen
	echo "* Waiting more 240s to finish"
	sleep 240
	printscreen
	xdotool key --delay 2000 Tab
	sleep 2
	printscreen
	xdotool key --delay 2000 space
	sleep 2
	while ! WID=$(xdotool search --name "Microsoft .NET Framework"); do
		sleep 2
	done
	printscreen
	xdotool key --delay 2000 space
}
#handle_gui_winetricks_dotnet48
#-----------------------

# This will hang until all wine processes in prefix=$WINEPREFIX
wineserver -w

# kill Xvfb whenever you feel like it
kill -15 "${Xvfb_PID}"
#---------------

#tar cvzf wine64bottle.tar.gz "${WINE64BOTTLE}"
touch wine64bottle.tar.gz
#tar cvzf wine64bottle.tar.gz "${WINE64BOTTLE}" /tmp/screenshot*
#tar cvzf wine64bottle.tar.gz /tmp/screenshot*

tar cvf result.tar wine64bottle.tar.gz
echo "* result.tar size: $(du -hs result.tar)"
