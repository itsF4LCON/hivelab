new_flag | tr 'a-zA-Z' 'n-za-mN-ZA-M' | od -An -tx1 | tr -d ' \n' | base64 -w 0 >message.txt
echo >>message.txt
