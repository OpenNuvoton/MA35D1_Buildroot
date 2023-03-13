#!/bin/sh
#
# Run the chip daemon
#

DAEMON="matter"
PIDFILE="/var/run/$DAEMON.pid"


start() {
	echo -n "Starting $DAEMON... "
	ln -s /mnt/mtdblock3 /matter
	start-stop-daemon -S -b -m -p $PIDFILE -x /opt/chip-lighting-app -- --KVS /matter/chip_kvs --PICS /matter/chip_config.ini
	[ $? -eq 0 ] && echo "OK" || echo "ERROR"
}

stop() {
	echo -n "Stopping $DAEMON... "
	start-stop-daemon -K -p $PIDFILE
	[ $? -eq 0 ] && echo "OK" || echo "ERROR"
}

restart() {
	stop
	start
}

case "$1" in
  start|stop|restart)
	"$1"
	;;
  *)
	echo "Usage: $0 {start|stop|restart}"
	exit 1
esac

exit $?
