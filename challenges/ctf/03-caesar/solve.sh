a=abcdefghijklmnopqrstuvwxyz
for k in $(seq 1 25); do
	s=$(echo $a | cut -c$((k + 1))-)$(echo $a | cut -c1-$k)
	out=$(tr $s $a <~/challenge/secret.txt)
	case $out in flag\{*) lab submit "$out"; exit ;; esac
done
