[ -f /etc/ssh/sshd_config.lab ] || cp /etc/ssh/sshd_config /etc/ssh/sshd_config.lab
cp /etc/ssh/sshd_config.lab /etc/ssh/sshd_config
ssh-keygen -A >/dev/null
sed -i -e '/^#\?PermitRootLogin/d' -e '/^#\?PasswordAuthentication/d' /etc/ssh/sshd_config
printf '\n#PermitRootLogin prohibit-password\nPermitRootLogin yes\nPasswordAuthentication yes\n' >>/etc/ssh/sshd_config
