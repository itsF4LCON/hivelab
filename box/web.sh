read -r METHOD TARGET _
TARGET=$(printf %s "$TARGET" | tr -d '\r')
URL_PATH=${TARGET%%\?*}
QUERY=""
case $TARGET in *\?*) QUERY=${TARGET#*\?} ;; esac
USER_AGENT=""
while IFS= read -r line; do
	line=$(printf %s "$line" | tr -d '\r')
	[ -z "$line" ] && break
	case $line in [Uu]ser-[Aa]gent:*) USER_AGENT=$(printf %s "${line#*:}" | sed 's/^ *//') ;; esac
done

param() { printf %s "$QUERY" | tr '&' '\n' | sed -n "s/^$1=//p" | head -1; }

reply() {
	body=$2
	printf 'HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nConnection: close\r\nServer: hivelab\r\n\r\n%s' \
		"$1" "${3:-text/plain}" "$(printf %s "$body" | wc -c)" "$body"
}
