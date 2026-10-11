#!/bin/bash
# Q3：复制素材、备份配置、移动草稿、删除 tmp、设定权限并直接运行 hello.sh。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

workspace="$output/sentry_ws"
mkdir -p "$workspace/scripts" "$workspace/config" "$workspace/backup" "$workspace/archive"
cp "$input/hello.sh" "$workspace/scripts/hello.sh"
cp "$input/robot.conf" "$workspace/config/robot.conf"
cp "$input/robot.conf" "$workspace/backup/robot.conf"
cp "$input/draft.conf" "$workspace/archive/draft.conf.old"
rm -f -- "$workspace/config/draft.conf"
rm -rf -- "$workspace/tmp"
chmod 750 "$workspace/scripts/hello.sh"
chmod 640 "$workspace/config/robot.conf"
"$workspace/scripts/hello.sh" > "$output/hello-output.txt"
