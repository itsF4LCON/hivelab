ip netns add office
ip link add lab0 type veth peer name lab-office
ip link set lab-office netns office
ip addr add 10.50.0.1/24 dev lab0
ip link set lab0 up
ip -n office link set lo up
ip -n office link set lab-office up
hosts=""
for i in 1 2 3; do
	h=10.50.0.$(rand 2 254)
	case " $hosts " in *" $h "*) continue ;; esac
	hosts="$hosts $h"
	ip -n office addr add "$h/24" dev lab-office
done
target=$(echo $hosts | tr ' ' '\n' | shuf -n 1)
port=$(rand 1000 2000)
new_flag >"$SECRET/scan"
daemon ip netns exec office socat TCP-LISTEN:$port,bind=$target,fork,reuseaddr EXEC:"cat $SECRET/scan"
daemon ip netns exec office socat TCP-LISTEN:22,fork,reuseaddr EXEC:'echo SSH-2.0-OpenSSH_9.6'
sleep 0.5
