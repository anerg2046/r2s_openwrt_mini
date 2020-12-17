#!/bin/bash

# 初始环境处理
sudo apt-get update
sudo apt-get -y --no-install-recommends install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs gcc-multilib g++-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler jq
curl https://raw.githubusercontent.com/friendlyarm/build-env-on-ubuntu-bionic/master/install.sh | bash
sudo rm -rf /usr/share/dotnet /usr/local/lib/android/sdk
sudo docker image prune -a -f
git clone --depth 1 https://github.com/friendlyarm/repo
sudo cp repo/repo /usr/bin/

# 下载友善官方源码
mkdir friendlywrt-rk3328
pushd friendlywrt-rk3328
repo init -u https://github.com/friendlyarm/friendlywrt_manifests -b master-v19.07.1 -m rk3328.xml --repo-url=https://github.com/friendlyarm/repo --no-clone-bundle --depth=1
repo sync -c --no-tags --no-clone-bundle -j8

# 下载LEDE源码并合并包
git clone --depth 1 https://github.com/coolsnowwolf/lede
cp -r ./lede/package/lean ./friendlywrt/package/

# 修改源
sed -i 's/^src-git packages.*/src-git packages https:\/\/github.com\/coolsnowwolf\/packages/' ./friendlywrt/feeds.conf.default
sed -i 's/^src-git luci.*/src-git luci https:\/\/github.com\/coolsnowwolf\/luci/' ./friendlywrt/feeds.conf.default

# 打补丁
pushd friendlywrt
sed -i '/CONFIG_CGROUPS/a\CONFIG_CGROUP_PERF=y' target/linux/rockchip-rk3328/config-4.14
popd
pushd kernel
wget https://raw.githubusercontent.com/armbian/build/master/patch/kernel/rockchip64-dev/rk3328-enable-1512mhz-opp.patch
git apply rk3328-enable-1512mhz-opp.patch
popd
git clone https://github.com/openwrt/openwrt
pushd openwrt
git checkout a47279154e08d54df05fa8bf45fe935ebf0df5da
cp -a ./target/linux/generic/files/* ../kernel/
./scripts/patch-kernel.sh ../kernel target/linux/generic/backport-5.4
./scripts/patch-kernel.sh ../kernel target/linux/generic/pending-5.4
./scripts/patch-kernel.sh ../kernel target/linux/generic/hack-5.4
popd
echo "CONFIG_NETFILTER_ADVANCED=y" >> kernel/arch/arm64/configs/nanopi-r2_linux_defconfig
echo "CONFIG_NETFILTER_XTABLES=m" >> kernel/arch/arm64/configs/nanopi-r2_linux_defconfig
echo "CONFIG_NETFILTER_XT_TARGET_FLOWOFFLOAD=m" >> kernel/arch/arm64/configs/nanopi-r2_linux_defconfig
rm -rf friendlywrt/package/libs
cp -r openwrt/package/libs friendlywrt/package/
cp -r openwrt/target/linux/octeontx/patches-5.4 friendlywrt/target/linux/rockchip-rk3328/

# 自定义软件
pushd friendlywrt
./scripts/feeds update -a
./scripts/feeds install -a
rm -rf feeds/packages/libs/libcap/
rm -rf feeds/packages/lang/golang/
svn co https://github.com/openwrt/packages/trunk/libs/libcap feeds/packages/libs/libcap
svn co https://github.com/coolsnowwolf/packages/trunk/lang/golang feeds/packages/lang/golang
sed -i '/enable-jsonc/i\\t--disable-cloud \\' feeds/packages/admin/netdata/Makefile
pushd packages/lean
rm -rf luci-app-oled/
rm -rf luci-theme-infinityfreedom/
rm -rf luci-app-chinadns-ng/
rm -rf openwrt-chinadns-ng/
rm -rf v2ray/
git clone --depth 1 https://github.com/NateLol/luci-app-oled
git clone --depth 1 https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom
git clone --depth 1 https://github.com/WuSiYu/luci-app-chinadns-ng
git clone --depth 1 https://github.com/pexcn/openwrt-chinadns-ng
git clone --depth 1 https://github.com/jerrykuku/luci-app-jd-dailybonus
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray
svn co https://github.com/songchenwen/nanopi-r2s/trunk/luci-app-r2sflasher
popd
echo -e '\nsrc-git lienol https://github.com/xiaorouji/openwrt-passwall' >> feeds.conf.default
./scripts/feeds update lienol
rm -rf feeds/lienol/lienol/ipt2socks
rm -rf feeds/lienol/lienol/shadowsocksr-libev
rm -rf feeds/lienol/lienol/pdnsd-alt
rm -rf feeds/lienol/lienol/luci-app-verysync
rm -rf feeds/lienol/package/verysync
rm -rf package/lean/openwrt-chinadns-ng
rm -rf package/lean/luci-app-kodexplorer
rm -rf package/lean/luci-app-pppoe-relay
rm -rf package/lean/luci-app-pptp-server
rm -rf package/lean/luci-app-v2ray-server
./scripts/feeds install -a -p lienol

# 更新Target.mk
pushd include
sed -i 's/dnsmasq /dnsmasq-full default-settings luci /' target.mk
popd
popd

# 编译配置
cat configs/config_rk3328 | grep "TARGET" > ../rk3328.config
cat ../mini_config.seed >> ../rk3328.config
cat ../rk3328.config > configs/config_rk3328

# 清理代码
rm -rf lede
rm -rf openwrt

# 开始编译
pushd friendlywrt
sed -i '/STAMP_BUILT/d' feeds/packages/utils/runc/Makefile feeds/packages/utils/containerd/Makefile
popd
echo -e '\nCONFIG_TCP_CONG_ADVANCED=y' >> kernel/arch/arm/configs/sunxi_defconfig
echo -e '\nCONFIG_TCP_CONG_BBR=m' >> kernel/arch/arm/configs/sunxi_defconfig
sed -i '/feeds/d' scripts/mk-friendlywrt.sh
sed -i 's/set -eu/set -u/' scripts/mk-friendlywrt.sh
sed -i 's/640/1000/' scripts/sd-fuse/mk-sd-image.sh
./build.sh nanopi_r2s.mk

# 修改权限
LOOP_DEVICE=$(sudo losetup -f)
sudo losetup -o 100663296 ${LOOP_DEVICE} out/*.img
sudo rm -rf /mnt/friendlywrt-tmp && sudo mkdir -p /mnt/friendlywrt-tmp
sudo mount ${LOOP_DEVICE} /mnt/friendlywrt-tmp && sudo chown -R root:root /mnt/friendlywrt-tmp && sudo umount /mnt/friendlywrt-tmp
sudo losetup -d ${LOOP_DEVICE}