#!/bin/bash

function setTitle() {
	echo -ne "\e]0;$@\a"
}

function status() {
	setTitle "$@"
	echo $@
	sleep 0.5
}

function get_my_windowid() {
	local TEMP_TITLE="TEMP_TITLE.$$.$RANDOM.$RANDOM.$RANDOM.$RANDOM.$SECONDS."
	setTitle "$TEMP_TITLE"
	sleep 0.5
	MY_WID=$( xdotool search --all --name "$TEMP_TITLE" )
	if [ "$MY_WID" == "" ]; then
		MY_WID=""
		echo "Failed to find my own window.  Aborting." >&2
		exit 1
	fi
	TEMP_TITLE="TEMP_TITLE.$$.$RANDOM.$RANDOM.$RANDOM.$RANDOM.$SECONDS."
	setTitle "$TEMP_TITLE"
	sleep 0.5
	local MY_WID2=$( xdotool search --all --name "$TEMP_TITLE" | head -n1 )
	if [ "$MY_WID2" == "" ]; then
		MY_WID=""
		echo "Failed to refind my own window.  Aborting." >&2
		exit 1
	fi
	if [ "$MY_WID" != "$MY_WID2" ]; then
		MY_WID=""
		echo "Failed to verify my own window.  Aborting." >&2
		exit 1
	fi
}

function find_chrome_pids() {
	ps ax | grep 'google/chrome' | awk '{ print $1 }'
}

MY_WID=""
get_my_windowid
if [ $? != 0 -o "$MY_WID" == "" ]; then
	echo "Aborting."
	exit 1
elif ! [ $(( MY_WID +0 )) -gt 0 ]; then
	echo "Aborting2."
	exit 1
fi

find_chrome_pids | while read PID ; do
	status "===== PID: $PID ====="
	# find chrome windows for this PID
	xdotool search --all --pid $PID --name ' - Google Chrome' | while read WID ; do
		# keep track of first tab title
		INITIAL_TITLE=""
		INITIAL_TITLE2="x"
		while [ "$INITIAL_TITLE" != "$INITIAL_TITLE2" ]; do
			sleep 1
			INITIAL_TITLE=$( xdotool getwindowname "$WID" )
			sleep 0.2
			INITIAL_TITLE2=$( xdotool getwindowname "$WID" )
		done
		
		# loop until all tabs are handled in this window:
		TITLE=""
		while [ "$TITLE" != "$INITIAL_TITLE" ]; do
			if [ "$TITLE" == "" ]; then
				TITLE=$INITIAL_TITLE
			fi
			# update INITIAL_TITLE if it was for Great Suspender
			if [[ $INITIAL_TITLE =~ ^$|^chrome-extension://klbibkeccnjlkjkiokjodocebajanakg ]]; then
				if [ "$TITLE" != "" ]; then
					echo "Resetting INITIAL_TITLE: $TITLE"
					INITIAL_TITLE="$TITLE"
				fi
			fi
			status "Processing Tab: $TITLE"
			# switch to chrome window and send keys: alt+d, home, ctrl+shift+right x 3
			xdotool windowactivate --sync "$WID" key --clearmodifiers --window "$WID" alt+d Home ctrl+shift+Right ctrl+shift+Right ctrl+shift+Right || exit 1
			sleep 0.1
			# compare clipboard to: chrome-extension://klbibkeccnjlkjkiokjodocebajanakg
			CLIP=$( xclip -o -r )
			if [ "$CLIP" == "chrome-extension://klbibkeccnjlkjkiokjodocebajanakg" ]; then
				# send keys: chrome-extension://noogafoofpebimajpfpamcfhoaifemoa
				xdotool windowactivate --sync "$WID" type --clearmodifiers --window "$WID" 'chrome-extension://noogafoofpebimajpfpamcfhoaifemoa' || exit 1
				# send keys: ENTER
				xdotool windowactivate --sync "$WID" key --clearmodifiers --window "$WID" Return || exit 1
				sleep 0.1
				# check INITIAL_TITLE
				if [ "$TITLE" == "$INITIAL_TITLE" ]; then
					INITIAL_TITLE=""
				fi
			fi
			# send keys: ctrl+pgdn
			xdotool windowactivate --sync "$WID" key --clearmodifiers --window "$WID" ctrl+Next || exit 1
			sleep 0.3
			# update title
			TITLE=$( xdotool getwindowname "$WID" )
			sleep 0.1
			TITLE2=$( xdotool getwindowname "$WID" )
			while [ "$TITLE" != "$TITLE2" -o "$TITLE" == "... - Google Chrome" ]; do
				sleep 1
				TITLE=$( xdotool getwindowname "$WID" )
				sleep 0.2
				TITLE2=$( xdotool getwindowname "$WID" )
			done
		done
		xdotool windowactivate --sync "$MY_WID"
		sleep 3
	done
done

echo "complete." >&2
exit 0

Available commands:
	Windows:
		search --all --sync --onlyvisible --pid PID --name title
		selectwindow (manual user-involved window selection)
		getwindowname [window]
		getwindowpid [window]
		getwindowgeometry [window]
		behave window blur windowactivate window
		set_window
	Desktop/WM:
		getactivewindow
		windowactivate --sync [window]
	Keys:
		key --clearmodifiers --window window
		type --clearmodifiers --window window
		keydown
		keyup
	Utilities:
		exec
		sleep
