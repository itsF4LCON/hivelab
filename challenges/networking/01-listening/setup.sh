port=$((40000 + $(od -An -N2 -tu2 /dev/urandom) % 101))
new_flag >/var/lib/lab-secret/listener
daemon socat TCP-LISTEN:$port,bind=127.0.0.1,fork,reuseaddr EXEC:'cat /var/lib/lab-secret/listener'
sleep 0.3
