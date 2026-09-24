#!/bin/sh
# Usage (as root inside the box): in-box.sh <challenge-id> <solve.sh>
set -u
id=$1 solve=$2
as_learner() { su learner -s /bin/sh -c "cd ~ && $1"; }

as_learner "lab start $id" >/dev/null || { echo "FAIL $id: start"; exit 1; }
if [ "$(jq -r --arg id "$id" '.[] | select(.id == $id) | .type' /opt/lab/challenges.json)" = check ]; then
	as_learner "lab check" >/dev/null 2>&1 && { echo "FAIL $id: solved before doing anything"; exit 1; }
fi
as_learner "lab submit flag{wrong}" >/dev/null 2>&1 && { echo "FAIL $id: accepted a wrong flag"; exit 1; }
out=$(as_learner "sh $solve" 2>&1)
if grep -qx "$id" /var/lib/lab/solved 2>/dev/null; then
	echo "ok   $id"
else
	echo "FAIL $id: solve.sh didn't solve it"
	echo "$out" | sed 's/^/     /'
	exit 1
fi
