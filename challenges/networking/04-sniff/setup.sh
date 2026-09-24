ip netns add office
ip link add lab0 type veth peer name lab-office
ip link set lab-office netns office
ip addr add 10.60.0.1/24 dev lab0
ip link set lab0 up
ip -n office link set lo up
ip -n office link set lab-office up
ip -n office addr add 10.60.0.21/24 dev lab-office
flag=$(new_flag)
printf 'USER backup\r\nPASS %s\r\nRETR nightly.tar.gz\r\nQUIT\r\n' "$flag" >"$SECRET/ftp"
daemon socat TCP-LISTEN:21,bind=10.60.0.1,fork,reuseaddr SYSTEM:'cat >/dev/null'
daemon ip netns exec office sh -c "while :; do nc -w 1 10.60.0.1 21 <$SECRET/ftp; sleep 2; done"
sleep 0.3
