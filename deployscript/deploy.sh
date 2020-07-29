#!/bin/bash
# user mod with sudo acess: $HOME is /home/travis

#=========================
die() { echo >&2 "$*"; exit 1; };

PRINT_NUM=1
printscreen() {
	#xwd -display :77 -root -silent | convert xwd:- png:/tmp/screenshot_${PRINT_NUM}.png
	xwd -root -silent | convert xwd:- png:./screenshot_${PRINT_NUM}.png
	PRINT_NUM=$((PRINT_NUM+1))
}

close_wine_mono_init_windows() {
	while ! WID=$(xdotool search --name "Wine Mono Installer"); do
		sleep 3
	done
	printscreen
	echo "Sending installer keystrokes..."
	xdotool key --window $WID --delay 1000 Tab
	sleep 1
	printscreen
	xdotool key --window $WID --delay 1000 space
	sleep 2
	printscreen
}

close_wine_gecko_init_windows() {
	while ! WID=$(xdotool search --name "Wine Gecko Installer"); do
		sleep 3
	done
	printscreen
	echo "Sending installer keystrokes..."
	xdotool key --window $WID --delay 1000 Tab
	sleep 1
	printscreen
	xdotool key --window $WID --delay 1000 space
	sleep 2
	printscreen
}

install_dotnet_from_winetricks() {
	wget -c https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
	chmod +x ./winetricks
	./winetricks -q dotnet48
	#./winetricks dotnet48 &
}

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
#===========================================================================================
export WINE64BOTTLE="${HOME}/wine64bottle"

#--------------
echo "* Download and install wine from another source:"
# the wine 5.11 is the last that work to install dotnet48 on the 32bits, so trying it here (thw WoW64 installation):
wget -nv -c "https://github.com/Kron4ek/Wine-Builds/releases/download/5.11/wine-5.11-staging-amd64.tar.xz"
tar xf "wine-5.11-staging-amd64.tar.xz" -C "/tmp/wine"
export WINEINSTALLATION="$HOME/wine-5.11-staging-amd64"

#-------
# the installation replace:
export PATH="${WINEINSTALLATION}/bin:${PATH}"
export LD_LIBRARY_PATH="${WINEINSTALLATION}/lib":"${WINEINSTALLATION}/lib64":"${LD_LIBRARY_PATH}"

export WINELOADER="${WINEINSTALLATION}/bin/wine"
export WINEPATH="${WINEINSTALLATION}/bin":"${WINEINSTALLATION}/lib/wine":"${WINEINSTALLATION}/lib64/wine":"$WINEPATH"
export WINEDLLPATH="${WINEINSTALLATION}/lib/wine/fakedlls":"${WINEINSTALLATION}/lib64/wine/fakedlls":"$WINEDLLPATH"

export WINE="${WINEINSTALLATION}/bin/wine"
export WINESERVER="${WINEINSTALLATION}/bin/wineserver"

#export WINEARCH=win32
export WINEARCH=win64
export WINEPREFIX="${WINE64BOTTLE}"
#--------------

echo "* creating bottle ..."
wineboot &
echo "* Waiting to initialize wine..."
sleep 7
printscreen
sleep 7
printscreen

# 2 times, one for 32bit and another for 64bit:
#echo "* wine mono cancel part1"
#close_wine_mono_init_windows

#echo "* wine gecko cancel part1:"
#close_wine_gecko_init_windows

#echo "* wine mono cancel part2:"
#close_wine_mono_init_windows

#echo "* wine gecko cancel part2:"
#close_wine_gecko_init_windows

echo "* ... waiting wineboot to finish ..."
# This will kill all running wine processes in prefix=$WINEPREFIX
wineserver -k

# This will hang until all wine processes in prefix=$WINEPREFIX
#wineserver -w

# Alternative to test only
#sleep 60 && printscreen
ps ux | grep wine

#install_dotnet_from_winetricks

# dont need it now, using -q
#handle_gui_winetricks_dotnet48


## This will hang until all wine processes in prefix=$WINEPREFIX
#wineserver -w
#-----------------------


echo "* copying the results: ..."

#tar cvzf wine64bottle.tar.gz "wine64bottle"
#mv wine64bottle.tar.gz ./result/

tar cvzf screenshots.tar.gz ./screenshot*
mv screenshots.tar.gz ./result/