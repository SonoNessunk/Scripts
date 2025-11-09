#!/bin/bash
sudo cpupower frequency-set -g performance
sudo cpupower frequency-set -d 3.4GHz -u 3.4GHz
sudo cpupower frequency-set -g userspace
