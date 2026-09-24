deluser --remove-home deploy 2>/dev/null || true
adduser -D -s /bin/sh deploy
sed -i 's/^deploy:!/deploy:*/' /etc/shadow
rm -rf /home/learner/.ssh
ssh-keygen -A >/dev/null
daemon /usr/sbin/sshd -D -p 2222 -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no -o PermitRootLogin=no
sleep 0.5
