port=$(ss -tln | awk '{print $4}' | grep -o '40[01][0-9][0-9]$' | head -1)
lab submit "$(nc -w 2 127.0.0.1 "$port" </dev/null)"
