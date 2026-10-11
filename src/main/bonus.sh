#!/bin/bash
# Bonus：start 时创建分离的 tmux 会话和采集器；stop 时正常停止采集器并结束会话。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-start}

source "$input/bonus.env"

process_running() {
    local pid=$1
    [ -r "/proc/$pid/stat" ] || return 1
    local state
    state=$(sed -n 's/^.*) \([^ ]\+\) .*$/\1/p' "/proc/$pid/stat")
    [ "$state" != Z ]
}

wait_for_pid() {
    local pid=$1
    local attempt
    for attempt in $(seq 1 50); do
        if ! process_running "$pid"; then
            return 0
        fi
        sleep 0.1
    done
    return 1
}

if [ "$action" = start ]; then
    : > "$output/bonus.log"
    tmux -L "$TMUX_SOCKET" new-session -d -s "$SESSION" \
        python3 "$WORKER_TOOL" --token "$TOKEN" --log "$output/bonus.log"
elif [ "$action" = stop ]; then
    worker_pid=$(awk -v token="$TOKEN" \
        '$1 == "START" && $2 == token { sub(/^pid=/, "", $3); print $3 }' \
        "$output/bonus.log" | tail -n 1)
    if [ -n "$worker_pid" ] && process_running "$worker_pid"; then
        kill -TERM "$worker_pid"
        wait_for_pid "$worker_pid"
    fi
    tmux -L "$TMUX_SOCKET" kill-session -t "$SESSION" 2>/dev/null || true
else
    printf 'unknown action: %s\n' "$action" >&2
    exit 2
fi
