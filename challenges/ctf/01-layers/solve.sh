lab submit "$(base64 -d ~/challenge/message.txt | xxd -r -p | tr 'a-zA-Z' 'n-za-mN-ZA-M')"
