#!/usr/bin/env python3
"""Build today's daily challenge from real hive traffic: daily/<date>/{meta.json,setup.sh,files/} + daily/index.json."""
import hashlib
import json
import random
import sys
import urllib.request
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

HIVE = "https://hive.xivlabs.tech"
MIN_EVENTS = 20
SERVER_USERS = {"root"}
DOC_NETS = ["203.0.113", "198.51.100", "192.0.2"]
ADMIN_IP = "198.51.100.7"

PATHS = {
    "/.env": "an `.env` file, where apps keep database passwords and API keys",
    "/.git/config": "a `.git` folder left on a web server, which can leak the site's whole source code",
    "/wp-login.php": "the WordPress login page, to brute-force it",
    "/xmlrpc.php": "WordPress XML-RPC, often abused to guess passwords in bulk",
    "/phpmyadmin/": "phpMyAdmin, a database admin panel that is often left open",
    "/SDK/webLanguage": "Hikvision cameras vulnerable to CVE-2021-36260 (remote command execution)",
    "/doc/page/login.asp": "the login page of Hikvision cameras and DVRs",
    "/cgi-bin/luci/;stok=/locale": "TP-Link routers vulnerable to CVE-2023-1389",
    "/boaform/admin/formLogin": "cheap fiber routers with default passwords",
    "/actuator/env": "Spring Boot apps that expose their settings, secrets included",
    "/server-status": "Apache's status page, which leaks visitors and internal URLs",
    "/owa/auth/logon.aspx": "Microsoft Exchange (Outlook Web Access), a favorite target",
    "/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php": "PHPUnit CVE-2017-9841, which runs any PHP code it's sent",
}


def fetch(path):
    req = urllib.request.Request(HIVE + path, headers={"User-Agent": "hivelab-daily"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def sha(text):
    return hashlib.sha256(text.strip().lower().encode()).hexdigest()


def unique_top(counter):
    top = counter.most_common(2)
    if not top or (len(top) == 2 and top[0][1] == top[1][1]):
        return None
    return top[0]


def remap(events, rng):
    counts = Counter(e["ip_masked"] for e in events)
    pool = [f"{net}.{host}" for net in DOC_NETS for host in range(10, 250) if f"{net}.{host}" != ADMIN_IP]
    rng.shuffle(pool)
    return {masked: pool[i] for i, (masked, _) in enumerate(counts.most_common())}


def build(date, events, stats, out):
    rng = random.Random(date)
    events = sorted(events, key=lambda e: e["ts"])
    ips = remap(events, rng)
    ssh = [e for e in events if e["service"] == "ssh" and e.get("username")]
    http = [e for e in events if e["service"] == "http" and e.get("path")]
    country = {ips[e["ip_masked"]]: e.get("country") or "??" for e in events}

    def stamp(ts, fmt):
        return datetime.fromtimestamp(ts, timezone.utc).strftime(fmt)

    auth, capture = [], []
    for e in ssh:
        user = e["username"]
        who = user if user in SERVER_USERS else f"invalid user {user}"
        pid, port = rng.randint(20000, 29999), rng.randint(32768, 60999)
        auth.append(f"{stamp(e['ts'], '%b %d %H:%M:%S')} server sshd[{pid}]: Failed password for {who} from {ips[e['ip_masked']]} port {port} ssh2")
        capture.append(f"{stamp(e['ts'], '%H:%M:%S')}  {ips[e['ip_masked']]:<16} {user:<16} {e.get('password') or ''}")
    access = []
    for e in http:
        status = 200 if e["path"] == "/" else 404
        ua = (e.get("ua") or "-").replace('"', "'")
        access.append(f'{ips[e["ip_masked"]]} - - [{stamp(e["ts"], "%d/%b/%Y:%H:%M:%S +0000")}] "{e.get("method") or "GET"} {e["path"]} HTTP/1.1" {status} 153 "-" "{ua}"')

    files = out / "files"
    files.mkdir(parents=True, exist_ok=True)
    (files / "auth.log").write_text("\n".join(auth) + "\n")
    (files / "honeypot-capture.txt").write_text(
        "# time      ip               username         password\n"
        "# Only a honeypot sees passwords: a real sshd never logs them.\n" + "\n".join(capture) + "\n")
    (files / "countries.txt").write_text("".join(f"{ip} {c}\n" for ip, c in sorted(country.items())))
    if access:
        (files / "access.log").write_text("\n".join(access) + "\n")

    questions, notes = [], []
    by_ip = Counter(ips[e["ip_masked"]] for e in ssh)
    if top := unique_top(by_ip):
        questions.append(("Which IP address had the most failed SSH logins in auth.log?", [top[0]]))
        notes.append(f"`{top[0]}` alone made {top[1]} of the {len(ssh)} attempts, a typical brute-force bot working through a password list.")
    if top := unique_top(Counter(e["username"] for e in ssh)):
        questions.append(("Which username did the bots try most often?", [top[0]]))
        notes.append(f"`{top[0]}` was the favorite username. Bots go for accounts that exist on almost every server.")
    if len(by_ip) > 1:
        questions.append(("How many different IP addresses tried to log in over SSH?", [str(len(by_ip))]))
    by_country = Counter(country[ips[e["ip_masked"]]] for e in ssh)
    if (top := unique_top(by_country)) and top[0] != "??":
        questions.append(("Use countries.txt: which country (two-letter code) sent the most SSH attempts?", [top[0]]))
    if top := unique_top(Counter(e.get("password") for e in ssh if e.get("password"))):
        questions.append(("Use honeypot-capture.txt: which password was tried most?", [top[0]]))
        notes.append(f"The most tried password was `{top[0]}`. If it's on a bot's list, it's not a password.")
    probes = [p for p in dict.fromkeys(e["path"] for e in http) if p != "/"]
    known = [p for p in probes if p in PATHS]
    if len(probes) == 1:
        questions.append(("Use access.log: which path (other than /) did the web scanner request?", [probes[0]]))
    for p in known[:2]:
        notes.append(f"`{p}`: the scanner was looking for {PATHS[p]}.")
    questions = questions[:5]
    if len(questions) < 3:
        return None

    first, last = stamp(events[0]["ts"], "%H:%M"), stamp(events[-1]["ts"], "%H:%M")
    story = f"""These logs are real. They come from hive, a honeypot on the internet, between {first} and {last} UTC on {date}.
Every line is a bot trying to break in. (IP addresses are replaced with example addresses, but everything else is what really happened.)

Your files in ~/challenge:
- `auth.log`: SSH login attempts, exactly as a real server logs them
- `honeypot-capture.txt`: the passwords the bots tried (only a honeypot can see these)
- `countries.txt`: which country each IP is in""" + ("\n- `access.log`: web requests, in nginx's log format" if access else "")
    learned = " ".join(notes) + f"""

In the last 24 hours hive caught {stats.get('total_24h', 0):,} attempts from {stats.get('unique_sources_24h', 0)} networks.
Come back tomorrow for new logs, or see them live at https://xivlabs.tech/#attacks."""

    meta = {
        "id": f"daily-{date}",
        "track": "daily",
        "title": f"Daily: {date}",
        "difficulty": 2,
        "root": False,
        "type": "questions",
        "story": story,
        "hints": [
            "`grep`, `sort`, `uniq -c` and `sort -rn` answer most questions. Try `grep 'Failed password' ~/challenge/auth.log | head`.",
            "Count per IP: `grep -o 'from [0-9.]*' ~/challenge/auth.log | sort | uniq -c | sort -rn`. Swap the pattern for usernames: `grep -o 'for [a-z ]*from'`.",
            "`awk '{print $3}' ~/challenge/honeypot-capture.txt | sort | uniq -c | sort -rn` counts usernames, `$4` counts passwords. For countries, look each IP up in countries.txt with `grep`.",
        ],
        "learned": learned,
        "questions": [{"prompt": q, "sha256": [sha(a) for a in answers]} for q, answers in questions],
    }
    (out / "meta.json").write_text(json.dumps([meta], indent=1))
    (out / "setup.sh").write_text('cp "$LAB_FILES"/* .\n')
    return meta


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "daily")
    date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    events = fetch("/recent?limit=100")
    stats = fetch("/stats")
    if len([e for e in events if e["service"] == "ssh"]) < MIN_EVENTS:
        sys.exit(f"only {len(events)} events, skipping today")
    meta = build(date, events, stats, root / date)
    if not meta:
        sys.exit("not enough unambiguous questions today, skipping")
    index = root / "index.json"
    days = json.loads(index.read_text()) if index.exists() else []
    days = [d for d in days if d["date"] != date]
    days.insert(0, {"date": date, "id": meta["id"], "questions": len(meta["questions"])})
    index.write_text(json.dumps(days, indent=1))
    print(f"{meta['id']}: {len(meta['questions'])} questions")


if __name__ == "__main__":
    main()
