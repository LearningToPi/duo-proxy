#!/bin/bash
exec() {
    tail -f /opt/duoauthproxy/log/authproxy.log &
    pid="$!"
    trap 'authproxyctl stop' SIGTERM
    wait
}
export -f exec
authproxyctl start
exec
