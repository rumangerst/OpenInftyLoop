#!/bin/bash

# Download Godot if needed
if [ ! -e ./bin/godot ]; then

    mkdir bin
    cd bin
    wget -O godot.zip https://downloads.tuxfamily.org/godotengine/3.0/beta2/Godot_v3.0-beta2_x11.64.zip
    unzip godot.zip
    
    ln -s Godot_v3.0-beta2_x11.64 godot
    rm godot.zip
    
    cd ..

fi

# Remove the old deployment 
rm -rv deploy-bin
mkdir deploy-bin

# Deploy for Linux+Windows as zip
rm -rv deploy-tmp
mkdir deploy-tmp
./bin/godot --export "Linux/X11" deploy-tmp/OpenInftyLoop.x86_64
./bin/godot --export "Linux/X11 (x32)" deploy-tmp/OpenInftyLoop.x86
./bin/godot --export "Windows Desktop" deploy-tmp/OpenInftyLoop.exe

cp README.md deploy-tmp
cp LICENSE deploy-tmp
cp icon.ico deploy-tmp
cp icon.png deploy-tmp
cp icon.svg deploy-tmp

cd deploy-tmp
zip -r ../deploy-bin/OpenInftyLoop-Windows-Linux.zip .
cd ..

rm -rv deploy-tmp

# Deploy for Windows as installer
mkdir deploy-tmp
mkdir deploy-tmp/app

./bin/godot --export "Windows Desktop" deploy-tmp/app/OpenInftyLoop.exe
cp README.md deploy-tmp/app/README.txt
cp LICENSE deploy-tmp/app/LICENSE.txt
cp icon.ico deploy-tmp/app/icon.ico

cp deploy-assets/OpenInftyLoopInstaller.iss deploy-tmp
cd deploy-tmp
wine ~/.wine/drive_c/Program\ Files\ \(x86\)/Inno\ Setup\ 5/ISCC.exe OpenInftyLoopInstaller.iss
cd ..
cp deploy-tmp/Output/Install-OpenInftyLoop.exe deploy-bin
rm -rv deploy-tmp

# Deploy for OSX
./bin/godot --export "Mac OSX" deploy-bin/OpenInftyLoop-OSX.zip

# Deploy for Android
./bin/godot --export "Android" deploy-bin/OpenInftyLoop.apk
