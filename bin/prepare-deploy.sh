#!/bin/bash

echo "Creating deployment env"

mkdir assets-win
mkdir assets-linux
mkdir osx
mkdir pak

echo "assets-win contains assets + Godot executable for Windows"
echo "assets-linux contains assets + Godot executable for Linux"
echo "osx contains OpenInftyLoop.zip for OSX"
echo "pak contains the exported game content (can be pak/zip/extracted zip)"
