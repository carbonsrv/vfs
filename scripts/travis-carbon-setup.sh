#!/bin/sh
if [ "$1" == "YES" ]; then
	curl $(curl https://apps.wtfits.science/latest-carbon) > lua_install/bin/lua
	chmod +x lua_install/bin/lua
fi
