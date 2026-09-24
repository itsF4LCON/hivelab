deluser --remove-home app 2>/dev/null || true
adduser -D -H -s /sbin/nologin app
rm -rf /srv/app && mkdir -p /srv/app/public
cd /srv/app
printf 'DB_HOST=127.0.0.1\nDB_USER=app\nDB_PASSWORD=%s\n' "$(head -c 12 /dev/urandom | base64)" >.env
ssh-keygen -q -t ed25519 -N '' -C deploy@app -f deploy_key && rm deploy_key.pub
printf -- '-- dump of users table\nINSERT INTO users VALUES (1, %s, %s);\n' "'admin'" "'\$2b\$12\$Qx0v8kq1V0u9'" >backup.sql
printf '#!/bin/sh\nexec echo "app started"\n' >start.sh
echo '<h1>Hello</h1>' >public/index.html
chown -R app:app /srv/app
chmod 755 /srv/app /srv/app/public start.sh
chmod 644 .env deploy_key backup.sql public/index.html
