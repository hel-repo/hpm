#!/bin/bash
set -e

if [ -e ./build/ ]; then
	rm -rf ./build/
fi
moonc -l ./src/
cp -r ./src/ ./build/
moonc ./build/
find ./build/ -name "*.moon" -delete
