. /opt/lab/web.sh
case $URL_PATH in
/) reply "200 OK" "<h1>Welcome to Staffnet</h1><p>Nothing to see here.</p>" text/html ;;
/robots.txt) reply "200 OK" "User-agent: *
Disallow: /staff-only/
" ;;
/staff-only | /staff-only/)
	if [ "$USER_AGENT" = "staffnet-browser" ]; then
		reply "200 OK" "Welcome back. Today's flag: $(cat /var/lib/lab-secret/web)
"
	else
		reply "403 Forbidden" "403: this page only works in the staff browser (User-Agent: staffnet-browser).
"
	fi ;;
*) reply "404 Not Found" "404: not found
" ;;
esac
