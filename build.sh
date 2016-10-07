#!/bin/bash
set -e

if [ -e ./build/ ]; then
	rm -rf ./build/
fi
moonc -l ./src/ || true
cp -r ./src/ ./build/
moonc ./build/
find ./build/ -name "*.moon" -delete
for FILE in patches/*patch; do patch -p0 -u <$FILE; done
