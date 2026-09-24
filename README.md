# hivelab

Learn cybersecurity by doing it, on a real Linux machine. The challenges cover Linux, networking, servers and CTF
puzzles, and a new challenge every day is built from real attacks caught by [hive](https://github.com/itsF4LCON/hive),
my honeypot.

Two ways to play:

- **In your browser** at [learn.xivlabs.tech](https://learn.xivlabs.tech). A small Alpine Linux machine runs inside
  the page ([v86](https://github.com/copy/v86)), so there's nothing to install and no account.
- **On your own machine** with Docker:

  ```sh
  git clone https://github.com/itsF4LCON/hivelab
  cd hivelab && ./lab
  ```

  `./lab` builds the box and opens a shell in it. `./lab reset` throws the box away and starts a clean one.

Inside the box:

```
lab list              all challenges
lab start <id|nr>     start one
lab daily             today's challenge, made from real attacks
lab hint              a hint (3 per challenge)
lab submit <flag>     for flag challenges
lab answer <nr> <x>   for question challenges
lab check             for task challenges
```

## Challenges

| Track | |
|---|---|
| Linux | hidden files, permissions, grep, processes, pipes, a setuid privilege escalation |
| Networking | listening ports, addresses and subnets, nmap, sniffing with tcpdump, HTTP with curl |
| Servers | secret file permissions, hardening sshd, SSH keys, firewalling attackers with nftables, investigating a break-in |
| CTF | forensics, encodings, Caesar brute force, an IDOR web bug, cracking hashes with real hive passwords |

Flags are random every time you start a challenge, so you can't look them up. Task challenges check the real
state of the machine: the firewall challenge, for example, builds a small fake internet with network
namespaces and tries to connect from each attacker's address.

## The daily challenge

Every morning a GitHub Action (`.github/workflows/daily.yml`) runs `gen/daily.py`. It reads hive's public
`/stats` and `/recent` endpoints and writes `daily/<date>/`:

- `auth.log` in real sshd format, with no passwords, because a real sshd never logs them
- `honeypot-capture.txt` with the passwords the bots tried (only a honeypot sees those)
- `countries.txt` and, if there were web probes, an nginx-style `access.log`
- 3 to 5 questions, each answered from those files. A question whose answer is a tie is skipped.

hive only publishes masked networks (`1.2.3.x`). Each one is mapped to an address in the documentation ranges
(`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`), so the logs work with grep and firewalls without
naming anyone's real IP. On a quiet day with too little data, no challenge is made.

The website loads the newest day straight from this repo on GitHub, so a new daily needs no redeploy.

## How it's built

```
challenges/<track>/<nr-name>/   challenge.toml, setup.sh, check.sh (task challenges), solve.sh (tests only)
box/                            the lab CLI, its root helper, and the install script shared by Docker and the VM
gen/build.py                    compiles challenges/ into challenges.json + scripts for the box
gen/daily.py                    the daily generator
image/                          builds the 32-bit Alpine image for v86 (root filesystem over 9p)
site/                           the website: plain HTML, CSS and one ES module, no build step
test/                           runs every challenge's solve.sh in a fresh box
```

`challenge.toml` has a title, difficulty (1–3), `type` (`flag`, `check` or `questions`), whether the learner
gets `doas` (`root = true`), a story, exactly 3 hints and a "what you learned" note. `setup.sh` runs as root in
`~/challenge` and can call `new_flag`, `daemon` and `web` from `box/lib.sh`. Everything a challenge starts is
cleaned up before the next one starts.

### Add a challenge

1. Make a folder in `challenges/<track>/` with `challenge.toml`, `setup.sh` and a `solve.sh` that solves it
   the way a learner would, running as the unprivileged `learner` user.
2. `sh test/docker.sh` checks that every challenge starts unsolved, rejects a wrong flag, and gets solved by
   its `solve.sh`. CI runs the same test on every push.

### Build and deploy the website

```sh
unshare --map-auto --map-root-user sh build-site.sh   # or run as root
npx wrangler deploy
```

`build-site.sh` builds the VM image into `site/vm/`: about 1,300 zstd-compressed files (46 MB), of which the
browser only downloads the ones it uses. A first visit transfers about 17 MB (8 MB of that is the Linux kernel),
and after that it's all cached. The page runs entirely in the visitor's browser: there's no
server code, and progress is kept in `localStorage`.

## Credits

[v86](https://github.com/copy/v86) (BSD-2-Clause; `image/tools` comes from it), SeaBIOS and VGABIOS in `image/bios` (LGPL),
[Alpine Linux](https://alpinelinux.org) and [xterm.js](https://xtermjs.org).
