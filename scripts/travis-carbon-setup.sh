#!/bin/sh
set -e 
if [ "$1" == "YES" ]; then
	echo "Downloading carbon..."
	curl $(curl https://apps.wtfits.science/latest-carbon) > lua_install/bin/lua
	chmod +x lua_install/bin/lua
	echo "Done."
fi
