#!/bin/sh

cd godot
rm ../languages.zip
zip -r ../languages.zip languages -x "*.import" -x "*english.csv"