#!/bin/bash
# Q5：运行 launch.env 给定的启动前检查，保存 stdout/stderr、真实退出码和诊断报告。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

source "$input/launch.env"
mkdir -p "$output"

set +e
"$LAUNCH_TOOL" "$MODEL_PATH" "$CAMERA_PATH" \
    > "$output/stdout.log" 2> "$output/stderr.log"
status=$?
set -e

printf '%s\n' "$status" > "$output/exit-code.txt"
if [ "$status" -eq 0 ]; then
    result=SUCCESS
    reason=NONE
elif [ "$status" -eq 10 ]; then
    result=FAILED
    reason=MODEL_MISSING
elif [ "$status" -eq 20 ]; then
    result=FAILED
    reason=CAMERA_DENIED
else
    result=FAILED
    reason=UNKNOWN
fi
printf 'result=%s\nexit_code=%s\nreason=%s\n' \
    "$result" "$status" "$reason" > "$output/report.txt"
