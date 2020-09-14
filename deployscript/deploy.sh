#!/bin/bash
# user mod with sudo acess: $HOME is /home/travis
# travis use DISPLAY=:99.0 to xvfb
export DISPLAY=:99.0
# the wine 5.11 is the last that work to install dotnet48 on the 32bits, so trying it here:
WINE_APPIMAGE_URL="https://github.com/ferion11/Wine_Appimage/releases/download/continuous-logos/wine-staging-linux-x86-v5.11-f11-x86_64.AppImage"
WINE_APPIMAGE_FILENAME="$(echo "${WINE_APPIMAGE_URL}" | cut -d/ -f9)"

export WORKDIR="${PWD}"
export WINE32_BOTTLE_NAME="wine32_bottle"
export WINE32_BOTTLE="${WORKDIR}/${WINE32_BOTTLE_NAME}"

#=========================
die() { echo >&2 "$*"; exit 1; };

PRINT_NUM=1
printscreen() {
	xwd -display :99 -root -silent | convert xwd:- png:./screenshot_${PRINT_NUM}.png
	PRINT_NUM=$((PRINT_NUM+1))
}

wine_AppImage() {
	export WINEINSTALLATION="${WORKDIR}/bin"
	mkdir -p "${WINEINSTALLATION}"

	echo "* Download and install wine AppImage from another source:"
	wget -q "${WINE_APPIMAGE_URL}" || die "Can't download the: ${WINE_APPIMAGE_URL}"

	chmod +x "${WINE_APPIMAGE_FILENAME}"
	mv "${WINE_APPIMAGE_FILENAME}" "${WINEINSTALLATION}"/

	ln -s "${WINE_APPIMAGE_FILENAME}" wine
	ln -s "${WINE_APPIMAGE_FILENAME}" wineserver

	mv wine "${WINEINSTALLATION}"/
	mv wineserver "${WINEINSTALLATION}"/

	#-------
	# the installation replace:
	export PATH="${WINEINSTALLATION}:${PATH}"
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

dotnet48_install_window(){
	#-------
	while ! WID=$(xdotool search --name "Extracting*"); do
		sleep "1"
	done
	printscreen
	sleep 7
	while true; do
		sleep "3"
		xwd -display $DISPLAY -root -silent | convert xwd:- png:./current32.png
		PIXELS_DIFF=$(compare -metric AE ./current32.png ./img/dotnet4_start.png null: 2>&1)
		rm current32.png
		#using 20000 or more (because the diff is larger, like 145699, and we avoid font issues, that is around 5000 in 2-3 lines +3buttons changes)
		[ "${PIXELS_DIFF}" -gt "20000" ] || break
	done
	# printscreen to update the dotnet4_end.png
	printscreen
	echo "* Sending installer keystrokes..."
	#-------
	xdotool key --delay 500 Tab
	sleep "0.5"
	xdotool key --delay 500 Tab
	sleep "0.5"
	xdotool key --delay 500 Tab
	sleep "0.5"
	#select checkbox
	xdotool key --delay 500 space
	sleep "0.5"
	xdotool key --delay 500 Tab
	sleep "0.5"
	xdotool key --delay 500 Tab
	sleep "0.5"
	xdotool key --delay 500 Tab
	sleep "0.5"
	printscreen
	xdotool key --delay 500 space
	#-------
	sleep 120
	while true; do
		sleep "3"
		xwd -display $DISPLAY -root -silent | convert xwd:- png:./current32.png
		PIXELS_DIFF=$(compare -metric AE ./current32.png ./img/dotnet4_end.png null: 2>&1)
		rm current32.png
		#using 20000 or more (because the diff is larger, like 145699, and we avoid font issues, that is around 5000 in 2-3 lines +3buttons changes)
		[ "${PIXELS_DIFF}" -gt "20000" ] || break
	done
	# printscreen to update the dotnet4_end.png
	printscreen
	xdotool key --delay 500 Tab
	sleep "0.5"
	printscreen
	xdotool key --delay 500 space
	#-------
	while ! WID=$(xdotool search --name "Extracting*"); do
		sleep "1"
	done
	printscreen
	sleep 7
	while ! WID=$(xdotool search --name "Microsoft*"); do
		sleep "1"
	done
	sleep 3
	xdotool key --delay 500 Tab
	sleep "0.5"
	xdotool key --delay 500 Tab
	sleep "0.5"
	xdotool key --delay 500 Tab
	sleep "0.5"
	xdotool key --delay 500 Tab
	sleep "0.5"
	printscreen
	xdotool key --delay 500 space
	#-------
	sleep 3
	xdotool key --delay 500 Tab
	sleep "0.5"
	xdotool key --delay 500 Tab
	sleep "0.5"
	xdotool key --delay 500 Tab
	sleep "0.5"
	# select checkbox
	xdotool key --delay 500 space
	sleep "0.5"
	xdotool key --delay 500 Tab
	sleep "0.5"
	xdotool key --delay 500 Tab
	sleep "0.5"
	printscreen
	xdotool key --delay 500 space
	#-------
	sleep 120
	while true; do
		sleep "3"
		xwd -display $DISPLAY -root -silent | convert xwd:- png:./current32.png
		PIXELS_DIFF=$(compare -metric AE ./current32.png ./img/dotnet48_end.png null: 2>&1)
		rm current32.png
		#using 20000 or more (because the diff is larger, like 145699, and we avoid font issues, that is around 5000 in 2-3 lines +3buttons changes)
		[ "${PIXELS_DIFF}" -gt "20000" ] || break
	done
	# printscreen to update the dotnet48_end.png
	printscreen
	xdotool key --delay 500 Tab
	sleep "0.5"
	printscreen
	xdotool key --delay 500 space
	#-------
	while ! WID=$(xdotool search --name "Microsoft*"); do
		sleep "1"
	done
	sleep 3
	xdotool key --delay 500 Tab
	sleep "0.5"
	printscreen
	xdotool key --delay 500 space
	#-------
}

set_wine_regedit_keys() {
	cat > disable-winemenubuilder.reg << EOF
REGEDIT4
[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
"winemenubuilder.exe"=""
EOF

	cat > renderer_gdi.reg << EOF
REGEDIT4
[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"DirectDrawRenderer"="gdi"
"renderer"="gdi"
EOF
	#-------

	echo "* Running: wine regedit.exe disable-winemenubuilder.reg"
	wine regedit.exe disable-winemenubuilder.reg

	echo "* ... wine regedit.exe to finish ..."
	wineserver -w
	#-------

	echo "* Running: wine regedit.exe renderer_gdi.reg"
	wine regedit.exe renderer_gdi.reg

	echo "* ... wine regedit.exe to finish ..."
	wineserver -w
	#-------
}

# wait to all process that is using the ${1} directory to finish
wait_process_using_dir() {
	VERIFICATION_DIR="${1}"
	VERIFICATION_TIME=7
	VERIFICATION_NUM=3

	echo "* Starting wait_process_using_dir..."
	i=0 ; while true; do
		i=$((i+1))
		echo "-------"
		echo "wait_process_using_dir: loop with i=${i}"

		echo "wait_process_using_dir: sleep ${VERIFICATION_TIME}"
		sleep "${VERIFICATION_TIME}"

		FIST_PID="$(lsof -t "${VERIFICATION_DIR}" | head -n 1)"
		echo "wait_process_using_dir FIST_PID: ${FIST_PID}"
		if [ -n "${FIST_PID}" ]; then
			i=0
			echo "wait_process_using_dir: tail --pid=${FIST_PID} -f /dev/null"
			tail --pid="${FIST_PID}" -f /dev/null
			continue
		fi

		echo "-------"
		[ "${i}" -lt "${VERIFICATION_NUM}" ] || break
	done
	echo "* End of wait_process_using_dir."
}

install_dotnet48_from_winetricks() {
	echo "* starting winetricks -q dotnet48 ..."
	./winetricks dotnet48 || die " !!!!!!! winetricks fail to install dotnet48 !!!!!!!"

	echo "* ... waiting winetricks to finish ..."
	wineserver -w
}

install_packages_from_winetricks() {
	#wget -c https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
	wget -c https://github.com/ferion11/libsutil/releases/download/winetricks/winetricks
	chmod +x ./winetricks
	#-------

	echo "* starting winetricks -q corefonts ..."
	./winetricks corefonts || die " !!!!!!! winetricks fail to install corefonts !!!!!!!"

	echo "* ... waiting winetricks to finish ..."
	wineserver -w
	#-------

	echo "* starting winetricks -q settings fontsmooth=rgb ..."
	./winetricks settings fontsmooth=rgb || die " !!!!!!! winetricks fail to install: settings fontsmooth=rgb !!!!!!!"

	echo "* ... waiting winetricks to finish ..."
	wineserver -w
	#-------

	install_dotnet48_from_winetricks &
	dotnet48_install_window
	#-------
}

#===========================================================================================
echo "* using the wine from wine_AppImage: "
wine_AppImage

export WINEARCH=win32
#export WINEARCH=win64
export WINEPREFIX="${WINE32_BOTTLE}"
#--------------

echo "* wine --version:"
wine --version

echo "* creating bottle ..."
wine wineboot &
echo "* Waiting to initialize wine..."

# 2 times, one for 32bit and another for 64bit:
echo "* wine mono cancel"
close_wine_mono_init_windows

echo "* wine gecko cancel"
close_wine_gecko_init_windows

#sleep 7
#echo "* wine mono cancel part2:"
#close_wine_mono_init_windows

#echo "* wine gecko cancel part2:"
#close_wine_gecko_init_windows

echo "* ... waiting wineboot to finish ..."
wineserver -w

set_wine_regedit_keys
install_packages_from_winetricks

echo "* ... waiting wineboot to finish ..."
# dotnet40
wait_process_using_dir "${WINE32_BOTTLE}"
# dotnet48
wait_process_using_dir "${WINE32_BOTTLE}"
# dotnet leftover
wait_process_using_dir "${WINE32_BOTTLE}"
wineserver -w
#-----------------------

echo "* Compressing and copying the results: ..."

tar czf wine32_bottle.tar.gz "${WINE32_BOTTLE_NAME}"
mv wine32_bottle.tar.gz ./result/

#tar cvzf screenshots.tar.gz ./screenshot*
#mv screenshots.tar.gz ./result/
