f=~/challenge/auth.log
line=$(grep 'Accepted password' $f | head -1)
ip=$(echo "$line" | grep -o 'from [0-9.]*' | awk '{print $2}')
lab answer 1 "$ip"
lab answer 2 "$(echo "$line" | awk '{print $9}')"
lab answer 3 "$(grep "Failed password.*from $ip " $f | wc -l)"
lab answer 4 "$(echo "$line" | awk '{print $3}')"
lab answer 5 "$(grep -o 'new user: name=[a-z]*' $f | cut -d= -f2)"
