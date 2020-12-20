#!/bin/bash
# Add a feed source
echo -e '\nsrc-git lienol https://github.com/xiaorouji/openwrt-passwall' >> feeds.conf.default

# Swap Lan Wan
cd openwrt
git apply ../patch/r2s_swap_lan_wan.diff