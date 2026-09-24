cidr=$(ip -4 -o addr show lab1 | awk '{print $4}')
ip=${cidr%/*}; len=${cidr#*/}
lab answer 1 "$ip"
lab answer 2 "$len"
IFS=. read -r a b c d <<EOT
$ip
EOT
size=$((1 << (32 - len)))
lab answer 3 "$a.$b.$c.$((d / size * size))"
lab answer 4 "$((size - 2))"
