cp "$LAB_FILES/passwords.txt" .
n=$(wc -l <passwords.txt)
p=$(sed -n "$(rand 1 "$n")p" passwords.txt)
set_flag "flag{$p}" >/dev/null
md5() { printf %s "$1" | md5sum | cut -d' ' -f1; }
{
	echo "admin:$(md5 "$p")"
	for u in alice bob charlie dana; do echo "$u:$(md5 "$(head -c 12 /dev/urandom | base64)")"; done
} >users.db
