import { Terminal } from "https://cdn.jsdelivr.net/npm/@xterm/xterm@6.0.0/lib/xterm.mjs";
import { FitAddon } from "https://cdn.jsdelivr.net/npm/@xterm/addon-fit@0.11.0/lib/addon-fit.mjs";
import { V86 } from "https://cdn.jsdelivr.net/npm/v86@0.5.462/build/libv86.mjs";

const V86_WASM = "https://cdn.jsdelivr.net/npm/v86@0.5.462/build/v86.wasm";
const LOCAL = ["localhost", "127.0.0.1"].includes(location.hostname);
const DAILY_SOURCES = LOCAL
  ? ["daily/", "https://raw.githubusercontent.com/itsF4LCON/hivelab/main/daily/"]
  : ["https://raw.githubusercontent.com/itsF4LCON/hivelab/main/daily/", "daily/"];

const TRACKS = {
  linux: ["Linux basics", "Find your way around a Linux machine: files, permissions, users and processes."],
  networking: ["Networking", "Ports, addresses and traffic. See what's talking to what."],
  servers: ["Servers", "Run and defend a real server: SSH, logs and firewalls."],
  ctf: ["CTF", "Puzzles like the ones in capture-the-flag contests: encodings, forensics and more."],
};
const LEVEL = { 1: "Easy", 2: "Medium", 3: "Hard" };

const $ = (id) => document.getElementById(id);
let challenges = [];
let daily = null;

const store = {
  solved() {
    try { return new Set(JSON.parse(localStorage.getItem("hivelab-solved") || "[]")); } catch { return new Set(); }
  },
  add(id) {
    const s = store.solved();
    s.add(id);
    try { localStorage.setItem("hivelab-solved", JSON.stringify([...s])); } catch {}
  },
};

function esc(text) {
  return text.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
}

function inline(text) {
  return esc(text)
    .replace(/`([^`]+)`/g, "<code>$1</code>")
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/(https:\/\/[^\s<)]+[^\s<).,])/g, '<a href="$1">$1</a>');
}

function markdown(text) {
  return text.trim().split(/\n\s*\n/).map((block) => {
    const lines = block.split("\n");
    if (lines.every((l) => l.startsWith("- "))) {
      return "<ul>" + lines.map((l) => `<li>${inline(l.slice(2))}</li>`).join("") + "</ul>";
    }
    const items = lines.filter((l) => l.startsWith("- "));
    if (items.length && lines[0] && !lines[0].startsWith("- ")) {
      const head = lines.filter((l) => !l.startsWith("- ")).join(" ");
      return `<p>${inline(head)}</p><ul>` + items.map((l) => `<li>${inline(l.slice(2))}</li>`).join("") + "</ul>";
    }
    return `<p>${inline(lines.join(" "))}</p>`;
  }).join("");
}

async function fetchDaily(path, as = "json") {
  for (const base of DAILY_SOURCES) {
    try {
      const r = await fetch(base + path, { cache: "no-cache" });
      if (r.ok) return as === "json" ? r.json() : r.text();
    } catch {}
  }
  throw new Error("daily not available");
}

async function loadDaily() {
  const index = await fetchDaily("index.json");
  const day = index[0];
  const [meta] = await fetchDaily(`${day.date}/meta.json`);
  const files = {};
  await Promise.all(meta.files.map(async (f) => { files[f] = await fetchDaily(`${day.date}/files/${f}`, "text"); }));
  return { date: day.date, meta, files };
}

function renderHome() {
  const solved = store.solved();
  $("tracks").innerHTML = Object.entries(TRACKS).map(([track, [name, about]]) => {
    const list = challenges.filter((c) => c.track === track);
    return `<div class="track"><h2>${name}</h2><p>${about}</p><ol>` + list.map((c, i) => {
      const done = solved.has(c.id);
      return `<li class="${done ? "done" : ""}"><a href="#/c/${c.id}">
        <span class="n" aria-label="${done ? "Solved" : `Challenge ${i + 1}`}">${done ? "✓" : i + 1}</span>
        <span class="t">${esc(c.title)}</span><span class="d">${LEVEL[c.difficulty]}</span></a></li>`;
    }).join("") + "</ol></div>";
  }).join("");

  if (!daily) return;
  const auth = daily.files["auth.log"].trim().split("\n");
  const ips = new Set(auth.map((l) => (l.match(/from (\S+)/) || [])[1]));
  const time = (l) => l.split(" ").filter(Boolean)[2].slice(0, 5);
  const done = solved.has(daily.meta.id) ? " You solved this one." : "";
  $("daily-summary").textContent =
    `${auth.length} failed SSH logins from ${ips.size} addresses, caught by a real honeypot between ` +
    `${time(auth[0])} and ${time(auth[auth.length - 1])} UTC. Find out who attacked and what they tried.${done}`;
  $("daily-log").innerHTML = auth.slice(0, 9).map((l) => {
    const m = l.match(/^(\S+ +\S+ \S+) (server sshd\[\d+\]:) (.*from )(\S+)( port .*)$/);
    return m ? `<span class="dim">${esc(m[1])}</span> ${esc(m[3])}<span class="ip">${esc(m[4])}</span><span class="dim">${esc(m[5])}</span>` : esc(l);
  }).join("\n");
  $("daily-start").href = "#/daily";
  $("daily").hidden = false;
}

let vm = null;

function stopVM() {
  if (!vm) return;
  vm.alive = false;
  vm.emulator.destroy();
  vm.term.dispose();
  window.removeEventListener("resize", vm.onResize);
  vm = null;
}

function startVM(challenge) {
  stopVM();
  $("boot").hidden = false;
  $("boot-text").textContent = "Booting Linux";
  $("vm-status").textContent = "Starting the machine";

  const term = new Terminal({
    fontFamily: '"JetBrains Mono", ui-monospace, monospace',
    fontSize: window.innerWidth < 600 ? 12 : 14,
    cursorBlink: true,
    theme: { background: "#000000", foreground: "#edeae2", cursor: "#edeae2", selectionBackground: "#5d574e" },
  });
  const fit = new FitAddon();
  term.loadAddon(fit);
  term.open($("terminal"));
  fit.fit();

  const emulator = new V86({
    wasm_path: V86_WASM,
    memory_size: 256 * 1024 * 1024,
    bios: { url: "vm/seabios.bin" },
    vga_bios: { url: "vm/vgabios.bin" },
    bzimage: { url: "vm/bzImage" },
    initrd: { url: "vm/initrd.img" },
    cmdline: "console=ttyS0 quiet",
    filesystem: { basefs: "vm/fs.json", baseurl: "vm/fs/" },
    autostart: true,
    screen_dummy: true,
    disable_keyboard: true,
    disable_mouse: true,
    disable_speaker: true,
  });

  const self = { emulator, term, alive: true, onResize: () => fit.fit() };
  vm = self;
  window.addEventListener("resize", self.onResize);

  term.parser.registerOscHandler(7337, (data) => {
    const [kind, id] = data.split(";");
    if (kind === "solved" && id === challenge.id) solved(challenge);
    return true;
  });
  term.onData((d) => emulator.serial0_send(d));

  emulator.add_listener("emulator-ready", async () => {
    if (challenge.track === "daily" && daily) {
      const inbox = JSON.stringify({ date: daily.date, meta: daily.meta, files: daily.files });
      await emulator.create_file("/opt/lab/inbox/daily.json", new TextEncoder().encode(inbox));
    }
  });

  let pending = [];
  let seen = "";
  emulator.add_listener("serial0-output-byte", (byte) => {
    if (!self.alive) return;
    if (pending.length === 0) requestAnimationFrame(() => { if (self.alive) term.write(new Uint8Array(pending)); pending = []; });
    pending.push(byte);
    if (self.ready) return;
    seen = (seen + String.fromCharCode(byte)).slice(-40);
    if (seen.includes("learner@server")) {
      self.ready = true;
      $("boot").hidden = true;
      $("vm-status").textContent = "learner@server";
      const cmd = challenge.track === "daily" ? "lab daily" : `lab start ${challenge.id}`;
      document.fonts.ready.then(() => {
        fit.fit();
        emulator.serial0_send(`stty cols ${term.cols} rows ${term.rows} 2>/dev/null; clear; ${cmd}\n`);
        term.focus();
      });
    }
  });

  let dots = 0;
  const tick = setInterval(() => {
    if (!self.alive || self.ready) return clearInterval(tick);
    dots = (dots + 1) % 4;
    $("boot-text").textContent = "Booting Linux" + ".".repeat(dots);
  }, 600);
}

function solved(challenge) {
  store.add(challenge.id);
  $("c-learned-text").innerHTML = markdown(challenge.learned);
  const solvedSet = store.solved();
  const next = challenges.find((c) => !solvedSet.has(c.id));
  $("next").href = next ? `#/c/${next.id}` : "#/";
  $("next").textContent = next ? `Next: ${next.title}` : "Back to all challenges";
  $("c-learned").hidden = false;
  $("c-learned").scrollIntoView({ behavior: "smooth", block: "nearest" });
}

function renderPlay(challenge) {
  document.title = `${challenge.title} · hivelab`;
  $("c-title").textContent = challenge.title;
  const track = challenge.track === "daily" ? "Daily challenge" : TRACKS[challenge.track][0];
  $("c-meta").textContent = `${track}, ${LEVEL[challenge.difficulty].toLowerCase()}`;
  $("c-story").innerHTML = markdown(challenge.story);
  const qs = $("c-questions");
  qs.hidden = challenge.type !== "questions";
  qs.innerHTML = challenge.questions.map((q) => `<li>${inline(q.prompt)}</li>`).join("");
  $("c-how").innerHTML = {
    flag: "Find the flag, then type <code>lab submit flag{...}</code> in the terminal.",
    check: "When you're done, type <code>lab check</code> in the terminal.",
    questions: "Answer each question in the terminal with <code>lab answer 1 your-answer</code>.",
  }[challenge.type] + (challenge.root ? " You can use <code>doas</code> (like sudo) here." : "");
  $("hint-list").innerHTML = "";
  $("hint").hidden = false;
  $("hint").onclick = () => {
    const list = $("hint-list");
    const n = list.children.length;
    list.insertAdjacentHTML("beforeend", `<li>${inline(challenge.hints[n])}</li>`);
    if (n + 1 >= challenge.hints.length) $("hint").hidden = true;
    else $("hint").textContent = "Show another hint";
  };
  $("hint").textContent = "Show a hint";
  $("c-learned").hidden = true;
  $("restart").onclick = () => startVM(challenge);
  startVM(challenge);
}

async function route() {
  const hash = location.hash.replace(/^#\/?/, "");
  const [page, id] = hash.split("/");
  let challenge = null;
  if (page === "c") challenge = challenges.find((c) => c.id === id);
  if (page === "daily") {
    if (!daily) { location.hash = "#/"; return; }
    challenge = daily.meta;
  }
  $("home").hidden = !!challenge;
  $("play").hidden = !challenge;
  document.body.classList.toggle("playing", !!challenge);
  if (challenge) {
    renderPlay(challenge);
  } else {
    stopVM();
    document.title = "hivelab";
    renderHome();
  }
  window.scrollTo(0, 0);
}

challenges = await (await fetch("challenges.json")).json();
try { daily = await loadDaily(); } catch {}
window.addEventListener("hashchange", route);
route();
