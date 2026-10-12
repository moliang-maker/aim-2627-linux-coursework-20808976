#!/bin/bash
# Q8：repair 时识别并停止采集器、修复 HTTP 服务；cleanup 时停止修复后的服务。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-repair}

source "$input/process.env"

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

if [ "$action" = repair ]; then
    user_name=$(ps -p "$TARGET_PID" -o user=)
    state=$(ps -p "$TARGET_PID" -o state=)
    command_line=$(ps -p "$TARGET_PID" -o args=)
    user_name=${user_name//[[:space:]]/}
    state=${state//[[:space:]]/}
    printf 'pid=%s\nuser=%s\nstate=%s\ncommand=%s\n' \
        "$TARGET_PID" "$user_name" "$state" "$command_line" > "$output/process.txt"

    tick_count=0
    for attempt in $(seq 1 50); do
        tick_count=$(awk -v token="$TARGET_TOKEN" \
            '$1 == "TICK" && $2 == token { count++ }
             END { print count + 0 }' "$WORKER_LOG" 2>/dev/null || true)

        if [ "$tick_count" -ge 2 ]; then
            break
        fi
        sleep 0.1
    done

    if [ "$tick_count" -lt 2 ]; then
        printf 'collector produced %s target TICK records; expected 2\n' "$tick_count" >&2
        exit 1
    fi

    cp "$WORKER_LOG" "$output/collector-sample.log"
    kill -TERM "$TARGET_PID"
    wait_for_pid "$TARGET_PID"

    kill -TERM "$SERVICE_PID"
    wait_for_pid "$SERVICE_PID"

    printf 'bind=127.0.0.1\nport=%s\nroute=/status\n' \
        "$TARGET_PORT" > "$output/server.conf"
    bash "$START_TOOL" "$output/server.conf" "$output/service"

    body="$output/http-body.tmp"
    status=
    for attempt in $(seq 1 50); do
        if status=$(curl --silent --show-error --output "$body" \
                --write-out '%{http_code}' \
                "http://127.0.0.1:$TARGET_PORT/status" 2>/dev/null); then
            break
        fi
        sleep 0.1
    done
    if [ -z "$status" ]; then
        printf '%s\n' 'HTTP service did not become ready' >&2
        exit 1
    fi
    mv "$body" "$output/http-body.txt"
    printf '%s\n' "$status" > "$output/http-status.txt"
elif [ "$action" = cleanup ]; then
    if [ -r "$output/service/pid" ]; then
        service_pid=$(<"$output/service/pid")
        if process_running "$service_pid"; then
            kill -TERM "$service_pid"
            wait_for_pid "$service_pid"
        fi
    fi
else
    printf 'unknown action: %s\n' "$action" >&2
    exit 2
fi
