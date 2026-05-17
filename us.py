

from __future__ import annotations

import argparse
import json
import threading
import time
import webbrowser
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from random import choice, uniform
from string import ascii_letters, digits

import requests
from rich import box
from rich.align import Align
from rich.console import Console
from rich.layout import Layout
from rich.live import Live
from rich.panel import Panel
from rich.progress import (
    BarColumn,
    MofNCompleteColumn,
    Progress,
    SpinnerColumn,
    TaskProgressColumn,
    TextColumn,
    TimeElapsedColumn,
    TimeRemainingColumn,
)
from rich.rule import Rule
from rich.table import Table
from rich.text import Text

CHARSET = ascii_letters + digits + "."

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Safari/605.1.15",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.0.0",
]

console = Console()

_lock        = threading.Lock()
_sse_clients: list[list] = []

def broadcast(event: str, data: dict):
    msg = f"event: {event}\ndata: {json.dumps(data)}\n\n"
    with _lock:
        for q in _sse_clients:
            q.append(msg)

DASHBOARD_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>usersrch</title>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700;800&family=Syne+Mono&display=swap" rel="stylesheet">
<style>
:root {
  --bg:
  --surf:
  --border:
  --red:
  --cyan:
  --green:
  --text:
  --muted:
  --mono:    'JetBrains Mono', monospace;
  --display: 'Syne Mono', monospace;
}
*{margin:0;padding:0;box-sizing:border-box}
html,body{height:100%;overflow:hidden}
body{
  background:var(--bg);
  color:var(--text);
  font-family:var(--mono);
  font-size:13px;
}
body::after{
  content:'';position:fixed;inset:0;z-index:0;pointer-events:none;
  background:
    radial-gradient(ellipse 55% 45% at 85% 5%,  rgba(254,44,85,.10) 0%,transparent 65%),
    radial-gradient(ellipse 45% 40% at 5%  95%,  rgba(37,244,238,.07) 0%,transparent 65%);
}
.root{
  position:relative;z-index:1;
  display:grid;
  grid-template-rows: 70px 1fr;
  grid-template-columns: 1fr 320px;
  gap:10px;
  padding:10px;
  height:100vh;
}

/* Header */
header{
  grid-column:1/-1;
  display:flex;align-items:center;justify-content:space-between;
  padding:0 20px;
  background:var(--surf);
  border:1px solid var(--border);
  border-radius:8px;
}
.logo{ font-family:var(--display); font-size:1.3rem; letter-spacing:2px; }
.logo .r{color:var(--red)} .logo .c{color:var(--cyan)}

.stats{display:flex;gap:32px}
.stat{text-align:center;line-height:1}
.stat-n{ font-family:var(--display); font-size:1.55rem; font-weight:800; }
.stat-n.t{color:var(--cyan)} .stat-n.x{color:var(--red)}
.stat-n.v{color:var(--green)} .stat-n.e{color:var(--muted)}
.stat-l{font-size:.6rem;color:var(--muted);letter-spacing:2px;text-transform:uppercase;margin-top:3px}

.live-dot{ display:flex;align-items:center;gap:8px; font-size:.7rem;letter-spacing:1px;text-transform:uppercase; color:var(--cyan); }
.dot{ width:8px;height:8px;border-radius:50%; background:var(--green); box-shadow:0 0 8px var(--green); animation:blink 1.1s infinite; }
.dot.off{background:var(--muted);box-shadow:none;animation:none}
@keyframes blink{0%,100%{opacity:1}50%{opacity:.2}}

/* Feed panel */
.feed-panel{
  background:var(--surf); border:1px solid var(--border); border-radius:8px;
  display:flex;flex-direction:column; overflow:hidden;
}
.panel-head{
  padding:8px 16px; font-size:.6rem;letter-spacing:3px;text-transform:uppercase;
  color:var(--muted); border-bottom:1px solid var(--border);
  display:flex;justify-content:space-between;align-items:center; flex-shrink:0;
}
.panel-head span{color:var(--cyan)}

/* progress */
.prog-wrap{ padding:8px 16px 12px; border-top:1px solid var(--border); flex-shrink:0; }
.prog-track{height:3px;background:var(--border);border-radius:2px;overflow:hidden}
.prog-fill{ height:100%; background:linear-gradient(90deg,var(--red),var(--cyan)); border-radius:2px; transition:width .3s ease; box-shadow:0 0 8px rgba(254,44,85,.4); }
.prog-meta{ display:flex;justify-content:space-between; font-size:.6rem;color:var(--muted);margin-top:5px; }

/* Rows */
.row{
  display:grid;
  grid-template-columns: 28px 76px 1fr 40px 58px;
  align-items:center; gap:10px;
  padding:6px 8px; border-radius:5px;
  animation:fadeSlide .18s ease;
  border-left:2px solid transparent;
  transition:background .12s;
}
.row:hover{background:rgba(255,255,255,.03)}
.row.taken{ border-left-color:var(--red)  }
.row.avail{ border-left-color:var(--green)}
.row.error{ border-left-color:var(--muted)}
@keyframes fadeSlide{from{opacity:0;transform:translateX(-6px)}to{opacity:1;transform:none}}

.row-n   {color:var(--muted);font-size:.65rem;text-align:right}
.row-tag {font-size:.65rem;font-weight:700;letter-spacing:.5px;text-transform:uppercase}
.row.taken .row-tag{color:var(--red)}
.row.avail .row-tag{color:var(--green)}
.row.error .row-tag{color:var(--muted)}
/* USERNAME: grande y legible */
.row-user{font-size:1rem;font-weight:700;letter-spacing:1px;color:#ffffff}
.row-code{font-size:.65rem;color:var(--muted);text-align:right}
.row-time{font-size:.6rem;color:var(--muted);text-align:right}

/* Panel disponibles */
.avail-panel{
  background:var(--surf); border:1px solid rgba(37,244,238,.2); border-radius:8px;
  display:flex;flex-direction:column; overflow:hidden;
}
.panel-head.green{color:var(--green)}
.panel-head.green span{color:var(--green)}

.avail-card{
  background:rgba(0,242,169,.06); border:1px solid rgba(0,242,169,.15); border-radius:6px;
  padding:10px 14px; cursor:pointer;
  transition:background .15s,border-color .15s,transform .1s;
  animation:popIn .28s cubic-bezier(.175,.885,.32,1.275);
}
.avail-card:hover{ background:rgba(0,242,169,.13); border-color:rgba(0,242,169,.4); transform:translateX(2px); }
@keyframes popIn{from{opacity:0;transform:scale(.85)}to{opacity:1;transform:none}}
/* nombre disponible: muy legible */
.avail-name{ font-family:var(--display); font-size:1.15rem; font-weight:800; color:var(--green); letter-spacing:1.5px; }
.avail-hint{font-size:.6rem;color:var(--muted);margin-top:3px;letter-spacing:1px}
.avail-card:hover .avail-hint{color:var(--green)}

.empty{ flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center; color:var(--muted);gap:8px;font-size:.75rem; }
.empty-ico{font-size:1.8rem}

/* toast */

  position:fixed;bottom:20px;right:20px;
  background:rgba(0,242,169,.12); border:1px solid rgba(0,242,169,.35); color:var(--green);
  padding:10px 18px; border-radius:6px; font-size:.8rem;font-weight:700;
  transform:translateY(60px);opacity:0; transition:all .25s ease;z-index:999; pointer-events:none;
}

</style>
</head>
<body>
<div class="root">

  <header>
    <div class="logo">usersrch</div>
    <div class="stats">
      <div class="stat"><div class="stat-n t" id="s-tot">0</div><div class="stat-l">Total</div></div>
      <div class="stat"><div class="stat-n x" id="s-tak">0</div><div class="stat-l">Taken</div></div>
      <div class="stat"><div class="stat-n v" id="s-avl">0</div><div class="stat-l">Free</div></div>
      <div class="stat"><div class="stat-n e" id="s-err">0</div><div class="stat-l">Errors</div></div>
    </div>
    <div class="live-dot"><div class="dot off" id="dot"></div><span id="status">done.</span></div>
  </header>

  <div class="feed-panel">
    <div class="panel-head">results &nbsp;·&nbsp; <span id="feed-count">0 / 0</span></div>
    <div id="feed"></div>
    <div class="prog-wrap">
      <div class="prog-track"><div class="prog-fill" id="prog" style="width:0"></div></div>
      <div class="prog-meta"><span id="p-done">0 / 0</span><span id="p-pct">0%</span></div>
    </div>
  </div>

  <div class="avail-panel">
    <div class="panel-head green">✦ Available &nbsp;·&nbsp; <span id="avail-count">0</span></div>
    <div id="avail-list">
      <div class="empty"><div class="empty-ico">🔍</div><span>nothing yet</span></div>
    </div>
  </div>

</div>
<div id="toast"></div>
<script>
let TOTAL=0, taken=0, avail=0, errs=0, done=0;
let firstAvail=true;
const feed      = document.getElementById('feed');
const availList = document.getElementById('avail-list');
const dot       = document.getElementById('dot');
const toast     = document.getElementById('toast');

function scrollFeed(){
  // Scroll instantáneo al último elemento — sin preguntar
  feed.scrollTop = feed.scrollHeight;
}

function toast_(msg){
  toast.textContent=msg;
  toast.classList.add('show');
  clearTimeout(toast._t);
  toast._t=setTimeout(()=>toast.classList.remove('show'),2000);
}

function updateStats(){
  document.getElementById('s-tot').textContent=done;
  document.getElementById('s-tak').textContent=taken;
  document.getElementById('s-avl').textContent=avail;
  document.getElementById('s-err').textContent=errs;
  document.getElementById('avail-count').textContent=avail;
  if(TOTAL>0){
    const pct=Math.round(done/TOTAL*100);
    document.getElementById('prog').style.width=pct+'%';
    document.getElementById('feed-count').textContent=done+' / '+TOTAL;
    document.getElementById('p-done').textContent=done+' / '+TOTAL;
    document.getElementById('p-pct').textContent=pct+'%';
  }
}

function addRow(d){
  const now=new Date().toLocaleTimeString('en',{hour:'2-digit',minute:'2-digit',second:'2-digit'});
  let cls,tag;
  if(d.available===true)       {cls='avail';tag='FREE'}
  else if(d.available===false) {cls='taken';tag='TAKEN'}
  else                          {cls='error';tag='ERROR'}

  const row=document.createElement('div');
  row.className='row '+cls;
  row.innerHTML=
    '<span class="row-n">'+done+'</span>'+
    '<span class="row-tag">'+tag+'</span>'+
    '<span class="row-user">@'+d.username+'</span>'+
    '<span class="row-code">'+(d.code||'—')+'</span>'+
    '<span class="row-time">'+now+'</span>';
  feed.appendChild(row);
  scrollFeed();  // siempre scroll al nuevo
}

function addAvailCard(username){
  if(firstAvail){availList.innerHTML='';firstAvail=false;}
  const card=document.createElement('div');
  card.className='avail-card';
  card.innerHTML=
    '<div class="avail-name">@'+username+'</div>'+
    '<div class="avail-hint">click to copy</div>';
  card.onclick=()=>{
    navigator.clipboard?.writeText('@'+username);
    toast_('✓  @'+username+' copiado');
  };
  availList.prepend(card);
}

const es=new EventSource('/events');
es.addEventListener('start',e=>{
  const d=JSON.parse(e.data);
  TOTAL=d.total;
  dot.classList.remove('off');
  document.getElementById('status').textContent='running...';
  updateStats();
});
es.addEventListener('result',e=>{
  const d=JSON.parse(e.data);
  done++;
  if(d.available===true)      {avail++;addAvailCard(d.username);toast_('🎉  @'+d.username+' libre!');}
  else if(d.available===false){taken++;}
  else                         errs++;
  addRow(d);
  updateStats();
});
es.addEventListener('done',e=>{
  dot.classList.add('off');
  document.getElementById('status').textContent='done.';
});
</script>
</body>
</html>"""

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_): pass

    def do_GET(self):
        if self.path == '/':
            body = DASHBOARD_HTML.encode()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path == '/events':
            self.send_response(200)
            self.send_header('Content-Type', 'text/event-stream')
            self.send_header('Cache-Control', 'no-cache')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            q: list[str] = []
            with _lock:
                _sse_clients.append(q)
            try:
                while True:
                    if q:
                        self.wfile.write(q.pop(0).encode())
                        self.wfile.flush()
                    else:
                        time.sleep(0.04)
            except Exception:
                pass
            finally:
                with _lock:
                    if q in _sse_clients:
                        _sse_clients.remove(q)
        else:
            self.send_response(404); self.end_headers()

def start_server(port: int):
    srv = HTTPServer(('localhost', port), Handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()

def random_username(length: int) -> str:
    while True:
        name = "".join(choice(CHARSET) for _ in range(length))
        if not name.startswith('.') and not name.endswith('.') and '..' not in name:
            return name

def check_username(username: str, retries: int = 3) -> dict:
    url = f"https://www.tiktok.com/@{username}"
    for attempt in range(retries + 1):
        try:
            headers = {
                "User-Agent": choice(USER_AGENTS),
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Accept-Language": choice(["en-US,en;q=0.9", "es-ES,es;q=0.9", "en-GB,en;q=0.8"]),
                "Accept-Encoding": "gzip, deflate, br",
                "Connection": "keep-alive",
                "Upgrade-Insecure-Requests": "1",
                "Sec-Fetch-Dest": "document",
                "Sec-Fetch-Mode": "navigate",
                "Sec-Fetch-Site": "none",
            }

            time.sleep(uniform(0.4, 1.2))
            r = requests.get(url, headers=headers, timeout=12, allow_redirects=True)
            if r.status_code == 404:
                return {"username": username, "available": True,  "code": 404}
            elif r.status_code == 200:
                return {"username": username, "available": False, "code": 200}
            else:
                if attempt < retries:
                    time.sleep(uniform(2.0, 4.0))
                    continue
                return {"username": username, "available": None, "code": r.status_code}
        except Exception:
            if attempt < retries:
                time.sleep(uniform(1.0, 2.5))
            else:
                return {"username": username, "available": None, "code": None}
    return {"username": username, "available": None, "code": None}

def make_banner() -> Panel:
    t = Text(justify="center")
    t.append("\n")
    t.append("  ██╗   ██╗███████╗███████╗██████╗ ███████╗██████╗  ██████╗██╗  ██╗\n", "bold #fe2c55")
    t.append("  ██║   ██║██╔════╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██║  ██║\n", "bold #fe2c55")
    t.append("  ██║   ██║███████╗█████╗  ██████╔╝███████╗██████╔╝██║     ███████║\n", "bold #25f4ee")
    t.append("  ██║   ██║╚════██║██╔══╝  ██╔══██╗╚════██║██╔══██╗██║     ██╔══██║\n", "bold #25f4ee")
    t.append("  ╚██████╔╝███████║███████╗██║  ██║███████║██║  ██║╚██████╗██║  ██║\n", "bold white")
    t.append("   ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝\n", "bold white")
    t.append("                          usersrch\n", "dim #25f4ee")
    t.append("\n")
    return Panel(Align.center(t), border_style="#fe2c55", box=box.DOUBLE_EDGE, padding=(0, 4))

def make_progress() -> Progress:
    return Progress(
        SpinnerColumn(spinner_name="dots12", style="bold #fe2c55"),
        TextColumn("[bold white]{task.description}"),
        BarColumn(bar_width=36, style="#1a1a2e", complete_style="#fe2c55", finished_style="#25f4ee"),
        MofNCompleteColumn(),
        TaskProgressColumn(),
        TimeElapsedColumn(),
        TimeRemainingColumn(),
        expand=True,
    )

def make_log_table(rows: list[dict], total: int) -> Panel:
    t = Table(
        box=box.SIMPLE_HEAD, show_header=True,
        header_style="bold #4a4a68",
        expand=True, min_width=55, padding=(0, 1),
    )
    t.add_column("#",       style="dim",         width=5,  justify="right")
    t.add_column("ESTADO",                        width=13)
    t.add_column("USUARIO", style="bold white",  width=18, justify="left")
    t.add_column("HTTP",    style="dim",          width=6,  justify="center")

    for r in rows[-55:]:
        if r["available"] is True:
            st = Text("✅  FREE",    style="bold #00f2a9")
        elif r["available"] is False:
            st = Text("❌  TAKEN",  style="bold #fe2c55")
        else:
            st = Text(f"⚠  {r.get('code','—')}", style="dim")
        
        uname = Text(f"@{r['username']}", style="bold bright_white")
        t.add_row(str(r["n"]), st, uname, str(r.get("code") or "—"))

    return Panel(
        t,
        title=f"[bold]results[/]  [dim]({len(rows)}/{total})[/]",
        border_style="#1a1a2e",
        box=box.ROUNDED,
    )

def make_avail_panel(available: list[str]) -> Panel:
    if not available:
        body = Align.center(Text("none yet", style="dim italic"))
    else:
        t = Table(box=box.SIMPLE, show_header=False, padding=(0, 2), expand=True)
        t.add_column(style="bold bright_cyan", no_wrap=True)
        t.add_column(style="dim")
        for u in reversed(available[-30:]):
            t.add_row(f"@{u}", "✓")
        body = t
    return Panel(
        body,
        title="[bold #25f4ee]✦ free[/]",
        border_style="#25f4ee",
        box=box.ROUNDED,
    )

def run(total_n: int, length: int, workers: int, save: bool, no_browser: bool, port: int):
    console.print(make_banner())
    console.print()

    start_server(port)
    url = f"http://localhost:{port}"
    console.print(Panel(
        f"[bold]Dashboard → [link={url}][#25f4ee]{url}[/][/link]  "
        f"[dim](opens browser)[/]",
        border_style="dim", box=box.SIMPLE,
    ))
    if not no_browser:
        threading.Timer(1.2, lambda: webbrowser.open(url)).start()
    console.print()

    usernames = [random_username(length) for _ in range(total_n)]
    broadcast("start", {"total": total_n})

    rows: list[dict]     = []
    available: list[str] = []
    taken_n = errs_n = 0
    n = 0

    progress = make_progress()
    tid = progress.add_task("running", total=total_n)

    layout = Layout()
    layout.split_column(
        Layout(name="prog", size=3),
        Layout(name="main"),
    )
    layout["main"].split_row(
        Layout(name="log",   ratio=3),
        Layout(name="avail", ratio=1),
    )
    layout["prog"].update(Panel(progress, border_style="dim", box=box.SIMPLE))
    layout["log"].update(make_log_table(rows, total_n))
    layout["avail"].update(make_avail_panel(available))

    with Live(layout, console=console, refresh_per_second=12):
        with ThreadPoolExecutor(max_workers=workers) as ex:
            futures = {ex.submit(check_username, u): u for u in usernames}
            for future in as_completed(futures):
                res = future.result()
                n += 1
                res["n"] = n
                rows.append(res)

                if res["available"] is True:
                    available.append(res["username"])
                elif res["available"] is False:
                    taken_n += 1
                else:
                    errs_n += 1

                broadcast("result", {
                    "username":  res["username"],
                    "available": res["available"],
                    "code":      res.get("code"),
                })

                progress.update(tid, advance=1)
                layout["prog"].update(Panel(progress, border_style="dim", box=box.SIMPLE))
                layout["log"].update(make_log_table(rows, total_n))
                layout["avail"].update(make_avail_panel(available))

    broadcast("done", {})
    elapsed = progress.tasks[tid].elapsed or 0

    
    console.print()
    console.print(Rule("[bold #fe2c55]summary[/]", style="#fe2c55"))
    console.print()

    summary = Table.grid(expand=True, padding=(0, 6))
    summary.add_column(justify="center")
    summary.add_column(justify="center")
    summary.add_column(justify="center")
    summary.add_column(justify="center")
    summary.add_row(
        Text(f"❌  {taken_n}",       style="bold #fe2c55"),
        Text(f"✅  {len(available)}", style="bold #00f2a9"),
        Text(f"⚠   {errs_n}",        style="dim"),
        Text(f"⏱   {elapsed:.1f}s",  style="bold white"),
    )
    summary.add_row(
        Text("Taken",    style="dim"),
        Text("Available", style="dim"),
        Text("Errors",     style="dim"),
        Text("Time",      style="dim"),
    )
    console.print(Panel(
        Align.center(summary),
        box=box.DOUBLE, border_style="#25f4ee", padding=(1, 4),
    ))

    if available:
        console.print()
        console.print(make_avail_panel(available))

    if save and available:
        fname = f"disponibles_{datetime.now():%Y%m%d_%H%M%S}.txt"
        Path(fname).write_text("\n".join(available))
        console.print(f"\n  [bold #25f4ee]💾 saved to[/] [white]{fname}[/]\n")

    console.print(
        f"\n  [dim]running at[/] [#25f4ee]{url}[/]  "
        f"[dim](Ctrl+C to stop)[/]\n"
    )
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        pass

def main():
    p = argparse.ArgumentParser(description="usersrch")
    p.add_argument("-n", "--total",   type=int,   default=1000, help="total to check (default: 1000)")
    p.add_argument("-l", "--length",  type=int,   default=4,    help="length (default: 4)")
    p.add_argument("-w", "--workers", type=int,   default=8,    help="workers (default: 8)")
    p.add_argument("-p", "--port",    type=int,   default=7331, help="port (default: 7331)")
    p.add_argument("-s", "--save",    action="store_true",      help="save free usernames to .txt")
    p.add_argument("--no-browser",    action="store_true",      help="do not open browser")
    args = p.parse_args()

    run(
        total_n    = args.total,
        length     = args.length,
        workers    = args.workers,
        save       = args.save,
        no_browser = args.no_browser,
        port       = args.port,
    )

if __name__ == "__main__":
    main()
