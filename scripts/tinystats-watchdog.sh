#!/bin/bash
# tinystats-watchdog.sh — dk3 only.
#
# dk3 runs the tinystats client under cron, not systemd (the login user has no
# passwordless sudo), so it cannot use the MemoryMax + RuntimeMaxSec drop-in the
# rest of the fleet got. This reproduces both guards in userspace and also keeps
# the original respawn-if-dead behaviour it replaces in the crontab.
#
# Recycles the client if RSS exceeds MAX_RSS_KB (leak guard) or it has been up
# longer than MAX_AGE_S (24h backstop), and starts it if it is not running.

BIN="$HOME/.local/bin/tinystats"
SERVER="http://188.245.71.48:9095"
LOG=/tmp/tinystats-client.log
MAX_RSS_KB=65536   # 64 MB; steady-state is ~3.7 MB
MAX_AGE_S=86400    # 24h

# Anchor on the full command line. An unanchored "tinystats client.*dk3" also
# matches any shell or SSH command that merely mentions that string, which would
# make the watchdog kill an innocent process (it killed a test session that way).
PATTERN="^$BIN client --name dk3 "
pid=$(pgrep -f "$PATTERN" | head -1)

if [ -n "$pid" ]; then
	rss=$(awk '/VmRSS/{print $2}' "/proc/$pid/status" 2>/dev/null)
	age=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')
	recycle=""
	[ -n "$rss" ] && [ "$rss" -gt "$MAX_RSS_KB" ] && recycle="rss=${rss}KB"
	[ -n "$age" ] && [ "$age" -gt "$MAX_AGE_S" ] && recycle="${recycle:+$recycle }age=${age}s"
	if [ -n "$recycle" ]; then
		echo "$(date -Is) watchdog: recycling pid $pid ($recycle)" >> "$LOG"
		kill "$pid" 2>/dev/null
		sleep 2
		kill -9 "$pid" 2>/dev/null
		pid=""
	fi
fi

if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
	setsid nohup "$BIN" client --name dk3 --server "$SERVER" >> "$LOG" 2>&1 < /dev/null &
fi
