lab submit "$(ps -o args | grep backup-job | grep -o 'flag{[^}]*}' | head -1)"
