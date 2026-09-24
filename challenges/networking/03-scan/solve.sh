hosts=$(nmap -sn -n 10.50.0.0/24 -oG - | awk '/Up$/ {print $2}' | grep -vx 10.50.0.1)
for h in $hosts; do
	port=$(nmap -n -p 1000-2000 "$h" -oG - | grep -o '[0-9]*/open' | cut -d/ -f1 | head -1)
	[ -n "$port" ] && { lab submit "$(nc -w 2 "$h" "$port" </dev/null)"; exit; }
done
