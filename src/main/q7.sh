#!/bin/bash
# Q7：读取 input/remote.env，生成 ssh_config，用 SSH 和 SCP 获取远程数据。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

source "$input/remote.env"
config="$output/ssh_config"
mkdir -p "$output/received"
printf '%s\n' \
    'Host aim-sentry' \
    "    HostName $HOST" \
    "    Port $PORT" \
    "    User $REMOTE_USER" \
    "    IdentityFile \"$KEY_PATH\"" \
    '    IdentitiesOnly yes' \
    '    StrictHostKeyChecking yes' \
    "    UserKnownHostsFile \"$KNOWN_HOSTS\"" > "$config"
chmod 600 "$config"

ssh -F "$config" -o BatchMode=yes -o ConnectTimeout=5 \
    aim-sentry whoami > "$output/remote-user.txt"

remote_path=${REMOTE_LOG// /\\ }
if scp -F "$config" -o BatchMode=yes -o ConnectTimeout=5 \
        "aim-sentry:${remote_path}" "$output/received/errors.log"; then
    :
else
    scp -O -F "$config" -o BatchMode=yes -o ConnectTimeout=5 \
        "aim-sentry:${remote_path}" "$output/received/errors.log"
fi
