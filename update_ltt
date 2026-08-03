#!/bin/bash

set -e

yt-dlp \
--flat-playlist \
--playlist-reverse \
--print "#EXTINF:-1,%(title)s\n%(url)s" \
"https://www.youtube.com/playlist?list=UUXuqSBlHAE6Xw-yeJA0Tunw" \
> /home/sononessunk/Videos/ltt.m3u
