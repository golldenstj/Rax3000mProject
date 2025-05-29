#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

#屏蔽原有源
#sed -i 's/^[^#]\(.*https:\/\/github\.com\/immortalwrt\/packages.*\)/#\1/' feeds.conf.default
#sed -i 's/^[^#]\(.*https:\/\/github\.com\/immortalwrt\/luci.*\)/#\1/' feeds.conf.default

#添加新软件源
#echo "src-git PSW https://github.com/sbwml/openwrt_helloworld.git;v5" >> "feeds.conf.default"
#echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> "feeds.conf.default"
