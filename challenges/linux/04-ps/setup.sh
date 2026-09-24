printf '#!/bin/sh\nwhile :; do sleep 30; done\n' >/usr/local/bin/backup-job
chmod 755 /usr/local/bin/backup-job
daemon /usr/local/bin/backup-job --target s3://backups/prod --upload-token "$(new_flag)"
