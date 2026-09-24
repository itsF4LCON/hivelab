flag=$(new_flag)
at=$(rand 5000 19000)
awk -v at="$at" -v flag="$flag" 'BEGIN {
	srand()
	split("INFO INFO INFO INFO WARN ERROR DEBUG", lvl, " ")
	split("user logged in|cache refreshed|request served in 12ms|disk usage at 71%|retrying job|connection reset by peer|config reloaded|token expired for session", msg, "|")
	for (i = 1; i <= 20000; i++) {
		t = sprintf("2026-09-23T%02d:%02d:%02d", int(i / 834) % 24, int(i / 14) % 60, i % 60)
		if (i == at) print t " ERROR payment-worker: leaked debug value " flag
		else print t " " lvl[int(rand() * 7) + 1] " " msg[int(rand() * 8) + 1]
	}
}' >app.log
