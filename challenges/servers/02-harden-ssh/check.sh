sshd -t
eff=$(sshd -T -C user=root,host=x,addr=203.0.113.1)
echo "$eff" | grep -qx 'permitrootlogin no'
echo "$eff" | grep -qx 'passwordauthentication no'
