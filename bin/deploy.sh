#!/bin/bash

# Run prepare-deploy to prepare deployment env

rm -rv dist/
mkdir dist

# Windows + Linux zip deployment
rm -rv OpenInftyLoop
cp -rv pak OpenInftyLoop

cp assets-win/* OpenInftyLoop
cp assets-linux/* OpenInftyLoop
zip -r dist/OpenInftyLoop-Windows-Linux.zip OpenInftyLoop
rm -rv OpenInftyLoop

# Mac deployment
cp osx/OpenInftyLoop.zip dist/OpenInftyLoop-OSX.zip

# Windows setup deployment
rm -rv installer-windows/app
cp -rv pak installer-windows/app
cp assets-win/* installer-windows/app

echo "Run InnoSetup to generate the exe installer!"
echo "Don't forget to change the directory InnoSetup is using as base dir!"
