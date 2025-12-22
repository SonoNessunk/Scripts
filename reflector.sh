#!/bin/bash

sudo reflector \
  --country Italy,Germany,France \
  --latest 10 \
  --protocol https \
  --sort rate \
  --save /etc/pacman.d/mirrorlist
