#!/bin/bash
rm -rf package/lean/luci-app-oled/
rm -rf package/lean/luci-theme-infinityfreedom/

git clone --depth 1 https://github.com/NateLol/luci-app-oled package/lean/luci-app-oled
git clone --depth 1 https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom package/lean/luci-theme-infinityfreedom
git clone --depth 1 https://github.com/jerrykuku/luci-app-jd-dailybonus package/lean/luci-app-jd-dailybonus
svn co https://github.com/songchenwen/nanopi-r2s/trunk/luci-app-r2sflasher package/lean/luci-app-r2sflasher

sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate