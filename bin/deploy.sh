#!/bin/bash

# Run prepare-deploy to prepare deployment env

rm -rv dist/
mkdir dist

rm -rv OpenInftyLoop
cp -rv pak OpenInftyLoop

cp assets-win-linux/* OpenInftyLoop
cp godot-win-linux/* OpenInftyLoop
zip -r dist/OpenInftyLoop-Windows-Linux.zip OpenInftyLoop
rm -rv OpenInftyLoop

# Mac
cp mac/OpenInftyLoop.zip dist/OpenInftyLoop-OSX.zip
