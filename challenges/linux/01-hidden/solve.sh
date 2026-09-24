lab submit "$(find ~/challenge -name '.*' -type f -exec cat {} + | grep -o 'flag{[^}]*}')"
