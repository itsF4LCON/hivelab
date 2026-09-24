CH=/home/learner/challenge

new_flag() {
	f="flag{$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')}"
	printf %s "$f" | sha256sum | cut -d' ' -f1 >"$STATE/flag.sha256"
	chmod 644 "$STATE/flag.sha256"
	printf %s "$f"
}

daemon() {
	setsid "$@" </dev/null >/dev/null 2>&1 &
}
