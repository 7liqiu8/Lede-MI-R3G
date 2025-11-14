#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# -------------------------------
# 自定义包 & 插件部分
# -------------------------------

# 添加 luci-app-easymesh
git clone https://github.com/theosoft-git/luci-app-easymesh.git package/luci-app-easymesh

# 添加 passwall2 插件及依赖包
# git clone https://github.com/xiaorouji/openwrt-passwall2.git package/luci-app-passwall2
# git clone https://github.com/xiaorouji/openwrt-passwall-packages.git package/openwrt-passwall-packages

# 添加 主题
git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon

# -------------------------------
# 系统定制部分
# -------------------------------

# 修改默认主题为 Argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 修改默认 IP（如有需要可取消注释）
sed -i 's/192.168.1.1/192.168.168.1/g' package/base-files/files/bin/config_generate

# 修改主机名
sed -i 's/LEDE/MIR3G-iStoreOS/g' package/base-files/files/bin/config_generate
sed -i 's/LEDE/MIR3G-iStoreOS/g' package/base-files/files/etc/init.d/system
sed -i 's/LEDE/OpenWrt/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
sed -i 's/LEDE/MIR3G-iStoreOS/g' package/lean/default-settings/files/zzz-default-settings

# 替换 banner
curl -o package/base-files/files/etc/banner https://raw.githubusercontent.com/istoreos/istoreos/refs/heads/istoreos-24.10/package/base-files/files/etc/banner
