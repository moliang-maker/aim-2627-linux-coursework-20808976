#!/bin/bash
# Q4：合并日志，按级别提取，保存首尾片段并统计错误行数。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

mkdir -p "$output"
cat "$input/boot.log" "$input/run.log" > "$output/all.log"
awk '/^ERROR /' "$output/all.log" > "$output/errors.log"
awk '/^(WARN |ERROR )/' "$output/all.log" > "$output/attention.log"
tail -n 5 "$output/all.log" > "$output/recent.log"
awk '/^ERROR / { if (++count <= 3) print }' "$output/all.log" > "$output/first-errors.log"
awk '/^ERROR / { count++ } END { print count + 0 }' "$output/all.log" > "$output/error-count.txt"
