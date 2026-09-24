pkill socat 2>/dev/null || true
port=$((40000 + $(od -An -N2 -tu2 /dev/urandom) % 101))
mkdir -p /var/lib/lab-secret && chmod 700 /var/lib/lab-secret
new_flag >/var/lib/lab-secret/listener
daemon socat TCP-LISTEN:$port,bind=127.0.0.1,fork,reuseaddr EXEC:'cat /var/lib/lab-secret/listener'
sleep 0.3
