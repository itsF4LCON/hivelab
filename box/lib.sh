CH=/home/learner/challenge
SECRET=/var/lib/lab-secret

set_flag() {
	printf %s "$1" | tr 'A-Z' 'a-z' | sha256sum | cut -d' ' -f1 >"$STATE/flag.sha256"
	chmod 644 "$STATE/flag.sha256"
	printf %s "$1"
}

new_flag() {
	set_flag "flag{$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')}"
}

daemon() {
	setsid "$@" </dev/null >/dev/null 2>&1 &
	echo $! >>/run/lab-daemons
}

web() {
	daemon socat TCP-LISTEN:$1,bind=${3:-127.0.0.1},fork,reuseaddr EXEC:"sh $2"
	sleep 0.3
}

rand() {
	echo $(($1 + $(od -An -N2 -tu2 /dev/urandom) % ($2 - $1 + 1)))
}

mkdir -p "$SECRET" && chmod 700 "$SECRET"
