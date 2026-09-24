ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519
doas mkdir -p /home/deploy/.ssh
doas cp ~/.ssh/id_ed25519.pub /home/deploy/.ssh/authorized_keys
doas chown -R deploy:deploy /home/deploy/.ssh
doas chmod 700 /home/deploy/.ssh
doas chmod 600 /home/deploy/.ssh/authorized_keys
lab check
