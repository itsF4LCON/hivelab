new_flag >"$SECRET/web"
cp "$LAB_FILES/site.sh" "$SECRET/site.sh"
web 8080 "$SECRET/site.sh"
