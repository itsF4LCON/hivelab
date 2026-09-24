ips=$(grep 'Failed password' ~/challenge/auth.log | grep -o 'from [0-9.]*' | sort | uniq -c | awk '$1 >= 10 {print $3}' | paste -sd, -)
doas nft add table inet filter
doas nft add chain inet filter input '{ type filter hook input priority 0; }'
doas nft add rule inet filter input ip saddr "{ $ips }" drop
lab check
