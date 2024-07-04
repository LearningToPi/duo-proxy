#!/bin/bash
exec() {
    tail -f /opt/duoauthproxy/log/authproxy.log &
    pid="$!"
    trap 'authproxyctl stop' SIGTERM
    wait
}
export -f exec
touch /opt/duoauthproxy/log/authproxy.log

# resolve radius host names to ip addresses (duo auth proxy does not allow dns names for radius hosts)
if [ "$RESOLVER" == "TRUE" ]; then
    /opt/duoauthproxy/usr/local/bin/python3 /scripts/resolver.py /opt/duoauthproxy/conf/authproxy.cfg.resolver /opt/duoauthproxy/conf/authproxy.cfg
fi

/opt/duoauthproxy/bin/authproxyctl start
exec
