new_flag >"$SECRET/admin-note"
cp "$LAB_FILES/notes.sh" "$SECRET/notes.sh"
web 8081 "$SECRET/notes.sh"
