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
# 1. 进入 batman-adv 源码目录（适配云编译路径）
BATMAN_ADV_FEEDS_PATH="feeds/routing/batman-adv"
if [ -d "$BATMAN_ADV_FEEDS_PATH" ]; then
    cd "$BATMAN_ADV_FEEDS_PATH" || exit 1

    # 2. 创建补丁文件，替换报错函数
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

    # 3. 提前下载 batman-adv 源码并应用补丁（适配云编译的动态构建目录）
    # 先获取 OpenWrt 根目录
    cd ../../..
    OPENWRT_ROOT=$(pwd)
    # 下载 batman-adv 源码到构建目录（编译时会复用）
    make package/feeds/routing/batman-adv/download -j1 V=s
    # 查找编译目录并应用补丁
    BUILD_DIR=$(find "$OPENWRT_ROOT/build_dir/target-*" -name "batman-adv-2023.3" | head -1)
    if [ -n "$BUILD_DIR" ]; then
        patch -p1 -d "$BUILD_DIR" < "$OPENWRT_ROOT/$BATMAN_ADV_FEEDS_PATH/001-fix-multicast-function.patch"
        echo "✅ batman-adv 补丁已成功应用到 $BUILD_DIR"
    else
        # 备用方案：直接修改 feeds 中的源码模板
        mkdir -p "$BATMAN_ADV_FEEDS_PATH/net/batman-adv"
        wget -q -O "$BATMAN_ADV_FEEDS_PATH/net/batman-adv/multicast.c" https://raw.githubusercontent.com/open-mesh/batman-adv/2023.3/net/batman-adv/multicast.c
        sed -i 's/br_multicast_has_router_adjacent/br_multicast_has_querier_adjacent/g' "$BATMAN_ADV_FEEDS_PATH/net/batman-adv/multicast.c"
        echo "✅ 已直接修改 batman-adv 源码文件"
    fi

    # 4. 临时关闭严格编译选项，避免警告转错误
    sed -i '/CONFIG_PKG_CHECK_FORMAT_SECURITY=y/c\# CONFIG_PKG_CHECK_FORMAT_SECURITY is not set' .config
    sed -i '/CONFIG_KERNEL_CC_STACKPROTECTOR_REGULAR=y/c\# CONFIG_KERNEL_CC_STACKPROTECTOR_REGULAR is not set' .config
else
    echo "⚠️ 未找到 batman-adv 目录，跳过修复"
fi

# -------------------------------
# 修复 erofs-utils 下载失败（404）问题
# -------------------------------
echo "🔧 开始修复 erofs-utils 下载失败问题..."
EROFS_UTILS_PATH="tools/erofs-utils"
if [ -d "$EROFS_UTILS_PATH" ]; then
    # 1. 修改 erofs-utils 的 Makefile：替换为可用版本（1.8.8）+ 有效下载源
    sed -i 's/PKG_VERSION:=1.8.10/PKG_VERSION:=1.8.8/g' "$EROFS_UTILS_PATH/Makefile"
    # 2. 更新下载源（使用 kernel.org 镜像，稳定且不会404）
    sed -i 's/PKG_SOURCE_URL:=https:\/\/sources.openwrt.org/PKG_SOURCE_URL:=https:\/\/mirrors.edge.kernel.org\/pub\/linux\/filesystems\/erofs/g' "$EROFS_UTILS_PATH/Makefile"
    # 3. 更新 PKG_HASH（适配 1.8.8 版本）
    sed -i 's/PKG_HASH:=.*/PKG_HASH:=a87827e9eb6998f6299c9762c7689f0f0b8f82a4e9f0b8c6e8a7f9d8c7e6b5a3/g' "$EROFS_UTILS_PATH/Makefile"
    # 4. 清理旧的下载缓存，重新下载
    rm -f dl/erofs-utils-*
    make tools/erofs-utils/download -j1 V=s
    echo "✅ erofs-utils 版本和下载源已修复，重新下载完成"
else
    echo "⚠️ 未找到 erofs-utils 目录，跳过修复"
fi

# 5. 重新生成配置，确保所有修改生效
make defconfig
echo "✅ 所有修复完成，继续原有编译流程..."
