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
# 自定义包 & 插件部分（移除easymesh克隆）
# -------------------------------

git clone --depth 1 https://github.com/gdy666/luci-app-lucky.git package/luci-app-lucky
git clone --depth 1 https://github.com/immortalwrt/luci-app-openlist.git package/luci-app-openlist

# 注释/删除easymesh克隆（核心：不再拉取该插件）
# git clone https://github.com/theosoft-git/luci-app-easymesh.git package/luci-app-easymesh

# 添加 passwall2 插件及依赖包
# git clone https://github.com/xiaorouji/openwrt-passwall2.git package/luci-app-passwall2
# git clone https://github.com/xiaorouji/openwrt-passwall-packages.git package/openwrt-passwall-packages

# 添加 主题
# rm -rf feeds/luci/themes/luci-theme-argon
# git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
# git clone https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# -------------------------------
# 系统定制部分
# -------------------------------

# 修改默认主题为 Argon
# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 修改默认 IP（如有需要可取消注释）
sed -i 's/192.168.1.1/192.168.13.1/g' package/base-files/files/bin/config_generate

# 修改主机名
# sed -i 's/LEDE/R3G/g' package/base-files/files/bin/config_generate
# sed -i 's/LEDE/R3G/g' package/base-files/files/etc/init.d/system
# sed -i 's/LEDE/OpenWrt/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
# sed -i 's/LEDE/R3G/g' package/lean/default-settings/files/zzz-default-settings

# 替换 banner
# curl -o package/base-files/files/etc/banner https://raw.githubusercontent.com/istoreos/istoreos/refs/heads/istoreos-24.10/package/base-files/files/etc/banner

# -------------------------------
# 彻底禁用 batman-adv
# -------------------------------
echo "🔧 彻底禁用 batman-adv 组件..."
sed -i '/batman-adv/d' .config
echo "# CONFIG_PACKAGE_batman-adv is not set" >> .config
echo "# CONFIG_PACKAGE_kmod-batman-adv is not set" >> .config
sed -i '/batman-adv/d' feeds/routing/Makefile
rm -rf feeds/routing/batman-adv
rm -rf build_dir/target-*/batman-adv-*
echo "✅ batman-adv 已彻底禁用"

# -------------------------------
# 彻底禁用 easymesh 相关组件（核心新增）
# -------------------------------
echo "🔧 彻底禁用 easymesh 插件..."
# 1. 从配置中删除easymesh所有相关项
sed -i '/easymesh/d' .config
echo "# CONFIG_PACKAGE_luci-app-easymesh is not set" >> .config
echo "# CONFIG_PACKAGE_luci-i18n-easymesh-zh-cn is not set" >> .config
echo "# CONFIG_PACKAGE_luci-proto-batman-adv is not set" >> .config
# 2. 删除已克隆的easymesh源码（若有）
rm -rf package/luci-app-easymesh
# 3. 从feeds中移除easymesh（若存在）
sed -i '/easymesh/d' feeds/luci/Makefile
echo "✅ easymesh 已彻底禁用"

# -------------------------------
# 彻底禁用 erofs-utils
# -------------------------------
echo "🔧 彻底禁用 erofs-utils 工具..."
sed -i '/erofs-utils/d' tools/Makefile
sed -i '/CONFIG_TARGET_ROOTFS_EROFS/c\# CONFIG_TARGET_ROOTFS_EROFS is not set' .config
sed -i '/CONFIG_KERNEL_EROFS_FS/c\# CONFIG_KERNEL_EROFS_FS is not set' .config
rm -rf tools/erofs-utils
rm -f dl/erofs-utils-*
echo "✅ erofs-utils 已彻底禁用"

# -------------------------------
# 重新生成配置
# -------------------------------
make defconfig
echo "✅ 所有禁用操作完成，开始编译固件..."
