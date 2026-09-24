ip link add lab1 type veth peer name lab1-peer
ip addr add 172.20.14.37/27 dev lab1
ip link set lab1 up
ip link set lab1-peer up
