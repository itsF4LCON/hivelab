k=$(rand 1 24); [ "$k" -ge 13 ] && k=$((k + 1))
a=abcdefghijklmnopqrstuvwxyz
s=$(echo $a | cut -c$((k + 1))-)$(echo $a | cut -c1-$k)
new_flag | tr $a $s >secret.txt
echo >>secret.txt
