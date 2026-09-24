f=~/challenge/access.log
lab answer 1 "$(wc -l <$f)"
lab answer 2 "$(awk '{print $1}' $f | sort -u | wc -l)"
lab answer 3 "$(awk '$9 == 404' $f | wc -l)"
lab answer 4 "$(awk '$9 == 404 {print $1}' $f | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
