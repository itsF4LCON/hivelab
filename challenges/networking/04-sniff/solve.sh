lab submit "$(doas timeout 10 tcpdump -n -i lab0 -A -l 2>/dev/null | grep -o 'flag{[^}]*}' | head -1)"
