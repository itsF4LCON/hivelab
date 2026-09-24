reach() { ip netns exec internet nc -w 1 -s "$1" 10.99.0.1 22222 </dev/null 2>/dev/null | grep -q SSH; }
for ip in $(cat /var/lib/lab-secret/block); do
	if reach "$ip"; then echo "$ip failed 10+ times and can still reach the server."; exit 1; fi
done
if ! reach 198.51.100.7; then echo "You blocked 198.51.100.7, your own admin IP. You just locked yourself out!"; exit 1; fi
for ip in $(cat /var/lib/lab-secret/allow); do
	if ! reach "$ip"; then echo "$ip is blocked, but it failed fewer than 10 times."; exit 1; fi
done
