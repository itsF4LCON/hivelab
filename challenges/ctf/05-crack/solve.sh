h=$(grep admin ~/challenge/users.db | cut -d: -f2)
while read -r p; do
	[ "$(printf %s "$p" | md5sum | cut -d' ' -f1)" = "$h" ] && { lab submit "flag{$p}"; exit; }
done <~/challenge/passwords.txt
