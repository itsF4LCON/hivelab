nft flush ruleset 2>/dev/null || true
pkill socat 2>/dev/null || true
ip netns del internet 2>/dev/null || true
ip link del lab0 2>/dev/null || true

pool="203.0.113.14 203.0.113.45 203.0.113.77 203.0.113.102 203.0.113.160 203.0.113.201 192.0.2.66 192.0.2.130 192.0.2.211"
set -- $(for ip in $pool; do echo "$(od -An -N2 -tu2 /dev/urandom) $ip"; done | sort -n | awk '{print $2}')
bad="$1 $2 $3"
low="$4 $5 $6"
admin=198.51.100.7

mkdir -p /var/lib/lab-secret && chmod 700 /var/lib/lab-secret
echo "$bad" >/var/lib/lab-secret/block
echo "$low $admin" >/var/lib/lab-secret/allow

users="root root root admin ubuntu test oracle postgres git user"
{
	for ip in $bad; do
		n=$((12 + $(od -An -N1 -tu1 /dev/urandom) % 30))
		i=0; while [ $i -lt $n ]; do echo "$ip"; i=$((i + 1)); done
	done
	for ip in $low; do
		n=$((1 + $(od -An -N1 -tu1 /dev/urandom) % 8))
		i=0; while [ $i -lt $n ]; do echo "$ip"; i=$((i + 1)); done
	done
	echo "ADMIN"; echo "ADMIN"
} | awk -v users="$users" -v admin=$admin 'BEGIN { srand(); split(users, u, " ") } { print rand() "\t" $0 }' |
	sort -n | cut -f2 | awk -v users="$users" -v admin=$admin 'BEGIN { srand(); split(users, u, " "); t = 8 * 3600 }
	{
		t += int(rand() * 90) + 1
		ts = sprintf("Sep 23 %02d:%02d:%02d", int(t / 3600) % 24, int(t / 60) % 60, t % 60)
		pid = 20000 + int(rand() * 9000); port = 30000 + int(rand() * 30000)
		if ($0 == "ADMIN") {
			printf "%s server sshd[%d]: Accepted publickey for admin from %s port %d ssh2: ED25519 SHA256:q3Rl9vA0cBf2\n", ts, pid, admin, port
		} else {
			name = u[int(rand() * length(u)) + 1]
			inv = (name == "root" || name == "admin") ? "" : "invalid user "
			printf "%s server sshd[%d]: Failed password for %s%s from %s port %d ssh2\n", ts, pid, inv, name, $0, port
		}
	}' >auth.log

ip netns add internet
ip link add lab0 type veth peer name lab1
ip link set lab1 netns internet
ip addr add 10.99.0.1/24 dev lab0
ip link set lab0 up
ip -n internet link set lo up
ip -n internet link set lab1 up
ip -n internet addr add 10.99.0.2/24 dev lab1
for ip in $bad $low $admin; do
	ip -n internet addr add "$ip/32" dev lab1
	ip route add "$ip/32" via 10.99.0.2 dev lab0 2>/dev/null || true
done
ip -n internet route add default via 10.99.0.1
daemon socat TCP-LISTEN:22222,fork,reuseaddr EXEC:'echo SSH-2.0-OpenSSH_9.9'
sleep 0.3
