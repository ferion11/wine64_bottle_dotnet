#!/bin/bash
WINEBOTTLE="/tmp/teste/bottle"

# Init
mkdir -p "${WINEBOTTLE}"

#echo "======= DEBUG: Starting xvfb ======="
Xvfb :77 -screen 0 1024x768x24 &
Xvfb_PID=$!
sleep 7
export DISPLAY=:77
#==================================
WINEPREFIX="${WINEBOTTLE}" wine wineboot &
echo "Waiting to initialize..."

# Wine Mono ------------
while ! WID=$(xdotool search --name "Wine Mono Installer"); do
	sleep 2
done
echo "Sending installer keystrokes..." >&2
xdotool key --window $WID --delay 500 Tab space
#-----------------------

# Wine Mono ------------
while ! WID=$(xdotool search --name "Wine Gecko Installer"); do
	sleep 2
done
echo "Sending installer keystrokes..." >&2
xdotool key --window $WID --delay 500 Tab space
#-----------------------
#kill -9 "${Xvfb_PID}"
#exit 1

wget -c https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x ./winetricks

#env WINEPREFIX="${WINEBOTTLE}" sh ./winetricks -q dotnet40
env WINEPREFIX="${WINEBOTTLE}" sh ./winetricks -q dotnet48

#echo "Waiting for installer to finish..." >&2
#xwininfo -id $WID -tree
#while pgrep -l setup; do sleep 5; done

#echo "Waiting program to start..." >&2
#while ! WID=$(xdotool search --name "Title - *"); do
#	sleep 2
#done

#echo "Closing application..." >&2
#xdotool key --window $WID --delay 500 Escape Escape Alt+f x
#sleep 1
#wineserver -k
#echo "Installation successful." >&2
#==================================
# End:
#rm -rf "${WINEBOTTLE}"

# kill Xvfb whenever you feel like it
kill -9 "${Xvfb_PID}"
