#!/bin/bash

if systemctl is-active --quiet smb; then
    echo "Samba Services active. Stopping..."
    sudo systemctl stop smb nmb
else
    echo "Samba Services inactive. Starting..."
    sudo systemctl start smb nmb
fi
