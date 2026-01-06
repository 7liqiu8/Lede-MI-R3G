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
git clone --depth 1 https://github.com/sbwml/luci-app-openlist2 package/luci-app-openlist2
git clone https://github.com/7liqiu8/nf_deaf-openwrt package/kernel/nf_deaf
git clone https://github.com/EasyTier/luci-app-easytier package/luci-app-easytier

# ==============================================
# 新增：nf_deaf 编译报错修复（核心修正，保留原有脚本不变，仅追加此处）
# ==============================================
echo "开始修正 nf_deaf Makefile 配置，解决404和编译报错..."
# 1. 定义Makefile路径
NF_DEAF_MAKEFILE="package/kernel/nf_deaf/Makefile"
# 2. 检查Makefile是否存在
if [ -f "$NF_DEAF_MAKEFILE" ]; then
    # 2.1 修正下载地址：指向kob仓库的正确标签tar包路径（带v前缀，适配GitHub规范）
    sed -i 's|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/kob/nf_deaf-openwrt/archive/refs/tags/|g' "$NF_DEAF_MAKEFILE"
    sed -i 's|PKG_SOURCE:=.*|PKG_SOURCE:=v1.1.tar.xz|g' "$NF_DEAF_MAKEFILE"
    # 2.2 强制指定使用tar包下载，屏蔽无效Git克隆（避免兜底失败）
    sed -i '/PKG_SOURCE_PROTO/d' "$NF_DEAF_MAKEFILE"  # 删除原有PROTO配置
    sed -i '/PKG_SOURCE_VERSION/a PKG_SOURCE_PROTO:=tar' "$NF_DEAF_MAKEFILE"  # 新增tar配置
    # 2.3 添加SHA256校验和（先计算真实值，再替换下面的<你的SHA256值>）
    sed -i '/PKG_LICENSE/d' "$NF_DEAF_MAKEFILE"  # 先删除原有LICENSE行后插入，确保位置正确
    cat >> "$NF_DEAF_MAKEFILE" << EOF
PKG_SHA256SUM:=<你的SHA256值>
PKG_LICENSE:=GPL-2.0
EOF
    # 2.4 修正版本对应（可选，确保和标签一致）
    sed -i 's|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=v1.1|g' "$NF_DEAF_MAKEFILE"
    echo "✅ nf_deaf Makefile 配置修正完成！"
else
    echo "⚠️  警告：未找到 nf_deaf Makefile，跳过修正！"
fi

# 3. 清理无效缓存（避免云编译残留旧文件干扰）
echo "开始清理 nf_deaf 无效缓存..."
rm -rf openwrt/dl/nf_deaf-1.1.tar.xz  # 删除旧的404下载包
rm -rf package/kernel/nf_deaf/nf_deaf-1.1  # 删除无效Git克隆目录
echo "✅ nf_deaf 缓存清理完成！"
# ==============================================
# nf_deaf 修复结束
# ==============================================

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

# 修复 batman-adv 编译错误（用于支持 EasyMesh）
echo "应用 batman-adv 内核兼容性补丁..."
TARGET_FILE="package/feeds/routing/batman-adv/src/compat-hacks.h"
if [ -f "$TARGET_FILE" ]; then
    echo "备份原文件: $TARGET_FILE -> ${TARGET_FILE}.bak"
    cp "$TARGET_FILE" "${TARGET_FILE}.bak"
fi
echo "从 GitHub 下载修复补丁..."
curl -fSLo "$TARGET_FILE" \
    "https://raw.githubusercontent.com/No06/routing/main/batman-adv/src/compat-hacks.h"
if [ $? -eq 0 ]; then
    echo "✅ batman-adv 补丁应用成功。"
else
    echo "⚠️  警告：下载补丁失败，可能影响编译。尝试使用备份文件。"
    [ -f "${TARGET_FILE}.bak" ] && cp "${TARGET_FILE}.bak" "$TARGET_FILE"
fi

# 修改主机名
# sed -i 's/LEDE/R3G/g' package/base-files/files/bin/config_generate
# sed -i 's/LEDE/R3G/g' package/base-files/files/etc/init.d/system
# sed -i 's/LEDE/OpenWrt/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
# sed -i 's/LEDE/R3G/g' package/lean/default-settings/files/zzz-default-settings

# 替换 banner
# curl -o package/base-files/files/etc/banner https://raw.githubusercontent.com/istoreos/istoreos/refs/heads/istoreos-24.10/package/base-files/files/etc/banner
