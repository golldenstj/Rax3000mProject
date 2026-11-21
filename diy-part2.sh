#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 移除 openwrt feeds 自带的核心包
rm -rf feeds/packages/net/{xray-core,xray-plugin,v2ray-core,v2ray-plugin,v2ray-geodata,sing-box,hysteria,naiveproxy,shadowsocks-rust,tuic-client,microsocks,chinadns-ng,alist,dns2socks,dns2tcp,ipt2socks}
rm -rf feeds/luci/applications/{luci-app-passwall,luci-app-ssr-plus}
git clone https://github.com/sbwml/openwrt_helloworld package/helloworld

# 修复 SSR Plus+ 在旧版 OpenWrt 上的 socket 依赖误报
SSR_INIT="package/helloworld/luci-app-ssr-plus/root/etc/init.d/shadowsocksr"

if [ -f "$SSR_INIT" ]; then
python3 - "$SSR_INIT" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

old = '''\
\t\tfor pkg in $dep_list; do
\t\t\tif [ ! -s "${file_path}/${pkg}${file_ext}" ]; then
'''

new = '''\
\t\tfor pkg in $dep_list; do
\t\t\tif [ "$USE_TABLES" = "iptables" ] && \\
\t\t\t   [ "$pkg" = "iptables-mod-socket" ] && \\
\t\t\t   [ -s "${file_path}/iptables-mod-tproxy${file_ext}" ] && \\
\t\t\t   iptables -m socket -h >/dev/null 2>&1; then
\t\t\t\tcontinue
\t\t\tfi
\t\t\tif [ ! -s "${file_path}/${pkg}${file_ext}" ]; then
'''

if old not in s:
    raise SystemExit("SSR Plus+ 检测代码已变化，请重新适配")

p.write_text(s.replace(old, new, 1))
PY
fi

# 更新 golang 1.27 版本
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 27.x feeds/packages/lang/golang

# 补充 Rust package support
rm -rf feeds/packages/lang/rust
git clone -b openwrt-23.05 --depth=1 https://github.com/openwrt/packages.git openwrt-packages-rust
cp -r openwrt-packages-rust/lang/rust feeds/packages/lang
rm -rf openwrt-packages-rust

# 添加luci-app-alist源码
git clone https://github.com/sbwml/luci-app-alist package/alist

# 替换最新版brook
rm -rf feeds/packages/net/brook
git clone -b main https://github.com/xiaorouji/openwrt-passwall-packages.git
cp -r openwrt-passwall-packages/brook feeds/packages/net
rm -rf openwrt-passwall-packages

# 克隆 coolsnowwolf 的 luci 和 packages 仓库
git clone https://github.com/coolsnowwolf/luci.git coolsnowwolf-luci
git clone https://github.com/coolsnowwolf/packages.git coolsnowwolf-packages

# 替换luci-app-zerotier和luci-app-frpc
rm -rf feeds/luci/applications/{luci-app-zerotier,luci-app-frpc}
cp -r coolsnowwolf-luci/applications/{luci-app-zerotier,luci-app-frpc} feeds/luci/applications
cp coolsnowwolf-luci/luci.mk package/
sed -i 's|include ../../luci\.mk|include ../../../../package/luci.mk|' feeds/luci/applications/luci-app-zerotier/Makefile
sed -i 's|include ../../luci\.mk|include ../../../../package/luci.mk|' feeds/luci/applications/luci-app-frpc/Makefile

# 替换zerotier、frp 和kcptun
rm -rf feeds/packages/net/{zerotier,frp,kcptun,haproxy}
cp -r coolsnowwolf-packages/net/{zerotier,frp,kcptun,haproxy} feeds/packages/net

# =====================================================================
# 自动更新 FRP 到官方最新稳定版
# =====================================================================
FRP_DIR="feeds/packages/net/frp"
FRP_MAKEFILE="$FRP_DIR/Makefile"

FRP_VERSION="$(
    git ls-remote --tags --refs https://github.com/fatedier/frp.git \
    | sed -n 's#.*refs/tags/v\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)$#\1#p' \
    | sort -V \
    | tail -1
)"

curl -fL "https://codeload.github.com/fatedier/frp/tar.gz/v${FRP_VERSION}" \
    -o /tmp/frp.tar.gz

FRP_HASH="$(sha256sum /tmp/frp.tar.gz | cut -d' ' -f1)"

sed -i -E "s/^PKG_VERSION:=.*/PKG_VERSION:=${FRP_VERSION}/" "$FRP_MAKEFILE"
sed -i -E "s/^PKG_HASH:=.*/PKG_HASH:=${FRP_HASH}/" "$FRP_MAKEFILE"

# FRP 0.68.0+ 官方支持 noweb
if grep -q '^GO_PKG_TAGS:=' "$FRP_MAKEFILE"; then
    sed -i -E 's/^GO_PKG_TAGS:=.*/GO_PKG_TAGS:=noweb/' "$FRP_MAKEFILE"
else
    sed -i '/^GO_PKG_BUILD_PKG:=/a GO_PKG_TAGS:=noweb' "$FRP_MAKEFILE"
fi

# 当前旧版 OpenWrt recipe 会强制执行 npm/Web 编译，
# noweb 模式下改为只执行 Go 编译
sed -i '/^define Build\/Compile$/,/^endef$/c\
define Build/Compile\
	$(call GoPackage/Build/Compile)\
endef' "$FRP_MAKEFILE"

rm -f /tmp/frp.tar.gz

# 删除克隆的 coolsnowwolf-luci 和 coolsnowwolf-packages 仓库
rm -rf coolsnowwolf-luci
rm -rf coolsnowwolf-packages

git clone https://github.com/coolsnowwolf/lede.git coolsnowwolf-lede
cp -r coolsnowwolf-lede/package/lean/upx package/
rm -rf coolsnowwolf-lede
