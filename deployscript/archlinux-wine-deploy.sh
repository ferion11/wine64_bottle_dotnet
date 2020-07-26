#!/bin/bash
export WINE64BOTTLE="/tmp/wine64bottle"

#=========================
die() { echo >&2 "$*"; exit 1; };
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
pacman -S --noconfirm wget base-devel multilib-devel pacman-contrib git tar grep sed zstd xz bzip2 procps-ng wine-staging mpg123 lib32-mpg123 gst-plugins-base-libs lib32-gst-plugins-base-libs xorg-server-xvfb xdotool
#===========================================================================================
echo "======= DEBUG: Starting xvfb ======="
Xvfb :77 -screen 0 1024x768x24 &
Xvfb_PID=$!
sleep 14
export DISPLAY=:77
#--------

export WINEARCH=win64
export WINEPREFIX="${WINE64BOTTLE}"
mkdir "${WINE64BOTTLE}"
WINEPREFIX="${WINE64BOTTLE}" WINEARCH=win64 wineboot &
echo "Waiting to initialize..."

# 2 times, one for 32bit and another for 64bit
# Wine Mono ------------
while ! WID=$(xdotool search --name "Wine Mono Installer"); do
	sleep 2
done
echo "Sending installer keystrokes..." >&2
xdotool key --window $WID --delay 500 Tab space
#-----------------------

# Wine Gecko ------------
while ! WID=$(xdotool search --name "Wine Gecko Installer"); do
	sleep 2
done
echo "Sending installer keystrokes..." >&2
xdotool key --window $WID --delay 500 Tab space
#-----------------------

# Wine Mono ------------
while ! WID=$(xdotool search --name "Wine Mono Installer"); do
	sleep 2
done
echo "Sending installer keystrokes..." >&2
xdotool key --window $WID --delay 500 Tab space
#-----------------------

## Wine Gecko ------------
#while ! WID=$(xdotool search --name "Wine Gecko Installer"); do
#	sleep 2
#done
#echo "Sending installer keystrokes..." >&2
#xdotool key --window $WID --delay 500 Tab space
#-----------------------

sleep 7
ps ux | grep wine

wget -c https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x ./winetricks

(
## sleep in bash for loop feedback - starting after 2min ##
sleep 120
for i in {1..60}
do
	sleep 60
	echo "------- $i min ------- "
	ps ux | grep wine
done
) &
SLEEP_PID=$!

env WINEPREFIX="${WINE64BOTTLE}" sh ./winetricks -q dotnet48

# kill Xvfb whenever you feel like it
kill -9 "${SLEEP_PID}"
kill -9 "${Xvfb_PID}"
#---------------

tar czf wine64bottle.tar.gz "${WINE64BOTTLE}"

tar cvf result.tar wine64bottle.tar.gz
echo "* result.tar size: $(du -hs result.tar)"
