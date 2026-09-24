#!/bin/sh
# Builds the box and runs every challenge's solve.sh in a fresh container.
set -u
cd "$(dirname "$0")/.."
docker build -q -t hivelab -f box/Dockerfile . >/dev/null || exit 1
fail=0
for solve in challenges/*/*/solve.sh; do
	dir=$(dirname "$solve")
	id="$(basename "$(dirname "$dir")")-$(basename "$dir")"
	c=$(docker run -d --cap-add NET_ADMIN --cap-add SYS_ADMIN hivelab)
	docker cp -q "$solve" "$c:/tmp/solve.sh"
	docker cp -q test/in-box.sh "$c:/tmp/in-box.sh"
	docker exec "$c" sh /tmp/in-box.sh "$id" /tmp/solve.sh || fail=1
	docker rm -f "$c" >/dev/null
done
for day in $(ls -d daily/2*/ 2>/dev/null | sort | tail -3); do
	[ -f "$day/meta.json" ] || continue
	c=$(docker run -d -v "$PWD/$day:/opt/lab/daily/$(basename "$day"):ro" hivelab)
	docker cp -q test/solve-daily.sh "$c:/tmp/solve-daily.sh"
	docker exec "$c" su learner -s /bin/sh -c "cd ~ && sh /tmp/solve-daily.sh" >/dev/null
	if docker exec "$c" grep -qx "daily-$(basename "$day")" /var/lib/lab/solved; then echo "ok   daily-$(basename "$day")"; else echo "FAIL daily-$(basename "$day")"; fail=1; fi
	docker rm -f "$c" >/dev/null
done
exit $fail
