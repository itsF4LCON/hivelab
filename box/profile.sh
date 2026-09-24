if [ "$(id -un)" = learner ] && [ -t 0 ]; then
	PS1='\[\033[1m\]learner@server\[\033[0m\]:\w\$ '
	cd ~
	cat /etc/motd
fi
