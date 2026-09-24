# Answers every daily question from the log files alone, like a learner would.
lab daily >/dev/null
cd ~/challenge
top() { sort | uniq -c | sort -rn | head -1 | awk '{print $2}'; }
n=0
lab info | grep -E '^  [0-9]+\. ' | while read -r nr question; do
	n=${nr%.}
	case $question in
	*"IP address had the most"*) a=$(grep 'Failed password' auth.log | grep -o 'from [0-9.]*' | awk '{print $2}' | top) ;;
	*"username did the bots"*) a=$(grep -v '^#' honeypot-capture.txt | awk '{print $3}' | top) ;;
	*"How many different IP"*) a=$(grep 'Failed password' auth.log | grep -o 'from [0-9.]*' | sort -u | wc -l) ;;
	*"which country"*) a=$(grep 'Failed password' auth.log | grep -o 'from [0-9.]*' | awk '{print $2}' | while read -r ip; do grep "^$ip " countries.txt | awk '{print $2}'; done | top) ;;
	*"which password"*) a=$(grep -v '^#' honeypot-capture.txt | awk '{print $4}' | top) ;;
	*"which path"*) a=$(awk '{print $7}' access.log | grep -vx / | sort -u) ;;
	*) echo "unknown question: $question"; exit 1 ;;
	esac
	lab answer "$n" "$a"
done
