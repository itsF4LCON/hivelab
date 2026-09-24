. /opt/lab/web.sh
json() { reply "200 OK" "$1
" application/json; }
if [ "$URL_PATH" != /notes ]; then
	reply "404 Not Found" '{"error": "try /notes?id=17"}
' application/json
	exit
fi
case $(param id) in
1) json "{\"id\": 1, \"owner\": \"admin\", \"note\": \"Keep this safe: $(cat /var/lib/lab-secret/admin-note)\"}" ;;
4) json '{"id": 4, "owner": "sam", "note": "Buy milk"}' ;;
9) json '{"id": 9, "owner": "priya", "note": "Server maintenance on Friday"}' ;;
17) json '{"id": 17, "owner": "learner", "note": "My first note!"}' ;;
*) reply "404 Not Found" '{"error": "no such note"}
' application/json ;;
esac
