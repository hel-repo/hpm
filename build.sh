#!/bin/bash
set -e

if [[ -e ./build/ ]]; then
	rm -rf ./build/
fi
moonc -l ./src/ || true
cp -r ./src/ ./build/
moonc ./build/
find ./build/ -name "*.moon" -delete
for FILE in patches/*patch; do patch -p0 -u <$FILE; done
if [[ $BUILD = 'release' ]]; then
	cd ./luaminify
	./LuaMinify.sh ../build/bin/hpm.lua ../build/bin/hpm.min.lua
	cd ..
	mv ./build/bin/hpm.min.lua ./build/bin/hpm.lua
fi
