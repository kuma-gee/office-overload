#!/bin/sh

# wav is s*** from microsoft that causes only problems (with the bitrate, probably, likely...)
find . -name "*.wav" -exec sh -c 'ffmpeg -y -i "$1" -b:a 192k "${1%.*}.mp3"' sh {} \;