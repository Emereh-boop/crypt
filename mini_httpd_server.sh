#!/bin/sh

DESC="mini-httpd"
set -e

mh_pro=/usr/bin/mini_httpd
mh_conf=/tmp/wc_mini_httpd.conf

do_start() {
cat >$mh_conf <<EOF
port=8080
user=root
dir=/wwwcrypt
cgipat=cgi-bin/*
pidfile=/tmp/wc_mini_httpd.pid
logfile=/tmp/wc_mini_httpd.log
charset=UTF-8
EOF

$mh_pro -C $mh_conf 2>/dev/null &
}

do_stop() {
        killall mini_httpd 1>/dev/null 2>/dev/null
}

case "$1" in
  start)
        echo "Starting $DESC"
        do_start
        ;;
  stop)
        echo "Stopping $DESC"
        do_stop
        ;;
  restart|force-reload)
        echo "Restarting $DESC"
        do_stop
        sleep 1
        do_start
        ;;
  *)
        echo "Usage: $0 {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0