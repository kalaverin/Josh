#!/bin/zsh

cd "$(dirname "$0")"

if [ "$?" -eq 0 ]; then

    # check if supervisord is already running

    if [ -f "run/supervisord.pid" ]; then
        pid="$(pgrep -F "run/supervisord.pid")"
        if [ -n "$pid" ] && [ "$pid" -gt 0 ] && [ -S "run/supervisord.sock" ]; then
            echo " ++ warn ($0): supervisord($pid) is already running (from $PWD/run/supervisord.pid)" >&2
            return 0
        fi
    fi

    # evaluate local .env when exists before supervisord

    if [ -x $commands[direnv] ]; then
        eval "$(direnv export zsh)"
    fi

    # start supervisord and check if it is started successfully

    supervisord --silent --configuration $PWD/supervisord.conf

    if [ "$?" -eq 0 ] && [ -f "run/supervisord.pid" ]; then
        pid="$(pgrep -F "run/supervisord.pid")"
        if [ -n "$pid" ] && [ "$pid" -gt 0 ] && [ -S "run/supervisord.sock" ]; then
            echo " -- info ($0): supervisord($pid) started (from $PWD/run/supervisord.pid)" >&2
            return 0
        fi
    fi

    echo " == fail ($0): supervisord start failed" >&2
    return 1
fi
