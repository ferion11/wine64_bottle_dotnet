#!/bin/bash
# user mod with sudo acess: $HOME is /home/travis
# travis use DISPLAY=:99.0 to xvfb
export DISPLAY=:99.0
# the wine 5.11 is the last that work to install dotnet48 on the 32bits, so trying it here (thw WoW64 installation):
WINE_URL="https://www.playonlinux.com/wine/binaries/phoenicis/staging-linux-x86/PlayOnLinux-wine-5.11-staging-linux-x86.tar.gz"
WINE_FILENAME=$(echo ${WINE_URL} | cut -d/ -f8)

#=========================
die() { echo >&2 "$*"; exit 1; };

PRINT_NUM=1
printscreen() {
	xwd -display :99 -root -silent | convert xwd:- png:./screenshot_${PRINT_NUM}.png
	PRINT_NUM=$((PRINT_NUM+1))
}

wine_playonlinux() {
	echo "* Download and install wine from another source:"
	wget -q "${WINE_URL}" || die "Can't download the: ${WINE_URL}"

	export WINEINSTALLATION="$HOME/wine_installation"
	mkdir "${WINEINSTALLATION}"
	tar xf "${WINE_FILENAME}" -C "${WINEINSTALLATION}"/ || die "Can't extract the: ${WINE_FILENAME}"

	#-------
	# the installation replace:
	export PATH="${WINEINSTALLATION}/bin:${PATH}"
	export LD_LIBRARY_PATH="${WINEINSTALLATION}/lib":"${WINEINSTALLATION}/lib64":"${LD_LIBRARY_PATH}"

	export WINELOADER="${WINEINSTALLATION}/bin/wine"
	export WINEPATH="${WINEINSTALLATION}/bin":"${WINEINSTALLATION}/lib/wine":"${WINEINSTALLATION}/lib64/wine":"$WINEPATH"
	export WINEDLLPATH="${WINEINSTALLATION}/lib/wine/fakedlls":"${WINEINSTALLATION}/lib64/wine/fakedlls":"$WINEDLLPATH"

#	export WINE="${WINEINSTALLATION}/bin/wine64"
#	export WINESERVER="${WINEINSTALLATION}/bin/wineserver"
}

close_wine_mono_init_windows() {
	while ! WID=$(xdotool search --name "Wine Mono Installer"); do
		sleep 3
	done
	printscreen
	echo "Sending installer keystrokes..."
	xdotool key --window $WID --delay 1000 Tab
	sleep 1
	xdotool key --window $WID --delay 1000 space
	sleep 2
}

close_wine_gecko_init_windows() {
	while ! WID=$(xdotool search --name "Wine Gecko Installer"); do
		sleep 3
	done
	printscreen
	echo "Sending installer keystrokes..."
	xdotool key --window $WID --delay 1000 Tab
	sleep 1
	xdotool key --window $WID --delay 1000 space
	sleep 2
}

install_dotnet_from_winetricks() {
	wget -c https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
	chmod +x ./winetricks
	./winetricks -q dotnet48 || die " !!!!!!! winetricks fail to install dotnet48 !!!!!!!"
}

#===========================================================================================
#echo "using the wine from playonlinux: "
#wine_playonlinux

export WINE64BOTTLE="${HOME}/wine64bottle"

#export WINEARCH=win32
export WINEARCH=win64
export WINEPREFIX="${WINE64BOTTLE}"

#--------------

echo "* wine64 --version:"
wine64 --version

echo "* creating bottle ..."
wine64 wineboot &
echo "* Waiting to initialize wine..."

# 2 times, one for 32bit and another for 64bit:
echo "* wine mono cancel"
close_wine_mono_init_windows

echo "* wine gecko cancel"
close_wine_gecko_init_windows

#echo "* wine mono cancel part2:"
#close_wine_mono_init_windows

echo "* wine gecko cancel part2:"
close_wine_gecko_init_windows

echo "* ... waiting wineboot to finish ..."
wineserver -w


install_dotnet_from_winetricks


echo "* ... waiting winetricks to finish ..."
wineserver -w
#-----------------------


echo "* Compressing and copying the results: ..."

tar czf wine64bottle.tar.gz "${WINEPREFIX}"
mv wine64bottle.tar.gz ./result/

tar cvzf screenshots.tar.gz ./screenshot*
mv screenshots.tar.gz ./result/
