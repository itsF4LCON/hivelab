cd /srv/app
for f in .env deploy_key backup.sql; do
	[ "$(stat -c %U "$f")" = app ] || { echo "$f doesn't belong to app anymore."; exit 1; }
	mode=$(stat -c %a "$f")
	case $mode in 400 | 600) ;; *) echo "$f is still readable by others (mode $mode)."; exit 1 ;; esac
done
su app -s /bin/sh -c 'cat .env deploy_key backup.sql >/dev/null' || { echo "app can't read its own files anymore."; exit 1; }
su app -s /bin/sh -c './start.sh' >/dev/null || { echo "start.sh doesn't run anymore."; exit 1; }
