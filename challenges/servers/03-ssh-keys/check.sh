su learner -s /bin/sh -c 'ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -p 2222 deploy@127.0.0.1 true' 2>/dev/null
