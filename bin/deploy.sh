#!/bin/bash

# Run prepare-deploy to prepare deployment env

rm -rv dist/
mkdir dist

# Cleanup
rm assets-win/*.import
rm assets-linux/*.import

# Fetch license and README
cd assets-win
rm LICENSE.txt
wget -O LICENSE.txt https://github.com/rumangerst/OpenInftyLoop/raw/master/LICENSE
rm README.txt
wget -O README.txt https://github.com/rumangerst/OpenInftyLoop/raw/master/README.md
cd ..

cd assets-linux
rm LICENSE
wget https://github.com/rumangerst/OpenInftyLoop/raw/master/LICENSE
rm README.md
wget https://github.com/rumangerst/OpenInftyLoop/raw/master/README.md
cd ..

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
