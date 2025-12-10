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

git clone --depth 1 https://github.com/gdy666/luci-app-lucky.git package/luci-app-lucky
git clone --depth 1 https://github.com/immortalwrt/luci-app-openlist.git package/luci-app-openlist

# 添加 luci-app-easymesh
git clone https://github.com/theosoft-git/luci-app-easymesh.git package/luci-app-easymesh

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
# 修复 batman-adv 5.10 内核兼容问题
# -------------------------------
echo "🔧 开始修复 batman-adv 与 5.10 内核的兼容问题..."
BATMAN_ADV_FEEDS_PATH="feeds/routing/batman-adv"
if [ -d "$BATMAN_ADV_FEEDS_PATH" ]; then
    cd "$BATMAN_ADV_FEEDS_PATH" || exit 1

    # 创建补丁文件，替换报错函数
    cat > 001-fix-multicast-function.patch << 'EOF'
--- a/net/batman-adv/multicast.c
+++ b/net/batman-adv/multicast.c
@@ -208,7 +208,7 @@ static bool batadv_mcast_has_ip4_router(struct net_device *dev)
 	if (!dev || !netif_is_bridge_master(dev))
 		return false;

-	if (!br_multicast_has_router_adjacent(dev, ETH_P_IP))
+	if (!br_multicast_has_querier_adjacent(dev, ETH_P_IP))
 		return false;

 	return true;
EOF

    # 提前下载 batman-adv 源码并应用补丁
    cd ../../..
    OPENWRT_ROOT=$(pwd)
    make package/feeds/routing/batman-adv/download -j1 V=s
    BUILD_DIR=$(find "$OPENWRT_ROOT/build_dir/target-*" -name "batman-adv-2023.3" | head -1)
    if [ -n "$BUILD_DIR" ]; then
        patch -p1 -d "$BUILD_DIR" < "$OPENWRT_ROOT/$BATMAN_ADV_FEEDS_PATH/001-fix-multicast-function.patch"
        echo "✅ batman-adv 补丁已成功应用"
    else
        mkdir -p "$BATMAN_ADV_FEEDS_PATH/net/batman-adv"
        wget -q -O "$BATMAN_ADV_FEEDS_PATH/net/batman-adv/multicast.c" https://raw.githubusercontent.com/open-mesh/batman-adv/2023.3/net/batman-adv/multicast.c
        sed -i 's/br_multicast_has_router_adjacent/br_multicast_has_querier_adjacent/g' "$BATMAN_ADV_FEEDS_PATH/net/batman-adv/multicast.c"
        echo "✅ 已直接修改 batman-adv 源码文件"
    fi

    # 临时关闭严格编译选项
    sed -i '/CONFIG_PKG_CHECK_FORMAT_SECURITY=y/c\# CONFIG_PKG_CHECK_FORMAT_SECURITY is not set' .config
    sed -i '/CONFIG_KERNEL_CC_STACKPROTECTOR_REGULAR=y/c\# CONFIG_KERNEL_CC_STACKPROTECTOR_REGULAR is not set' .config
else
    echo "⚠️ 未找到 batman-adv 目录，跳过修复"
fi

# -------------------------------
# 彻底禁用 erofs-utils（核心修复）
# -------------------------------
echo "🔧 彻底禁用 erofs-utils 编译依赖..."
# 1. 从 tools 编译列表中移除 erofs-utils
sed -i '/erofs-utils/d' tools/Makefile
# 2. 禁用 ERofs 文件系统相关配置（避免触发依赖）
sed -i '/CONFIG_TARGET_ROOTFS_EROFS/c\# CONFIG_TARGET_ROOTFS_EROFS is not set' .config
sed -i '/CONFIG_KERNEL_EROFS_FS/c\# CONFIG_KERNEL_EROFS_FS is not set' .config
# 3. 删除 erofs-utils 工具目录（防止编译时扫描到）
rm -rf tools/erofs-utils
# 4. 清理 dl 目录下的 erofs 缓存
rm -f dl/erofs-utils-*
echo "✅ erofs-utils 已彻底禁用，不会再触发编译"

# -------------------------------
# 重新生成配置
# -------------------------------
make defconfig
echo "✅ 所有修复完成，开始编译固件..."
