# untrusted.py — Chai aur Docker lab scaffolding (Chapter 39).
#
# Pretend TutorAI just generated this file from a student's request and we
# have to execute it. It has ONE legitimate job (compute an answer, write it
# to /tmp, print it) — and three pieces of mischief hidden inside. Every
# attempt reports honestly what happened, so the jail's effect is visible:
#   [network]/[filesystem]/[fork-bomb]  →  "BLOCKED (...)" or "ESCAPED (...)"
#
# Run it unprotected and you'll see ESCAPED lines. Run it in the jail and
# the legitimate work still succeeds while every attack fails.

import os
import socket
import sys
import time


def report(line):
    print(line, flush=True)


def legitimate_work():
    answer = 6 * 7
    report(f"RESULT: {answer}")
    try:
        with open("/tmp/result.txt", "w") as f:
            f.write(f"RESULT: {answer}\n")
        report("[tmp] wrote /tmp/result.txt")
    except OSError as e:
        report(f"[tmp] FAILED to write /tmp/result.txt ({e}) — the sandbox is too tight; legit work must still succeed")
        sys.exit(1)


def attempt_network():
    try:
        s = socket.create_connection(("1.1.1.1", 443), timeout=3)
        s.close()
        report("[network] ESCAPED (opened a connection to 1.1.1.1:443 — data could have been exfiltrated)")
    except OSError as e:
        report(f"[network] BLOCKED ({e})")


def attempt_filesystem():
    try:
        with open("/etc/pwned.txt", "w") as f:
            f.write("owned\n")
        report("[filesystem] ESCAPED (wrote /etc/pwned.txt — the rootfs is writable)")
    except OSError as e:
        report(f"[filesystem] BLOCKED ({e})")


def attempt_forkbomb():
    children = []
    error = None
    try:
        for _ in range(200):
            sys.stdout.flush()
            pid = os.fork()
            if pid == 0:
                time.sleep(3)   # child: stay alive so the process count climbs
                os._exit(0)
            children.append(pid)
    except OSError as e:
        error = e
    for pid in children:        # reap what we sowed
        try:
            os.waitpid(pid, 0)
        except OSError:
            pass
    if error is not None:
        report(f"[fork-bomb] BLOCKED after {len(children)} forks ({error})")
    else:
        report(f"[fork-bomb] ESCAPED (spawned {len(children)} processes unchallenged)")


uid = os.getuid()
report("TUTORAI SANDBOX REPORT")
report(f"uid={uid} (running as {'non-root' if uid != 0 else 'ROOT — bad'})")
legitimate_work()
attempt_network()
attempt_filesystem()
attempt_forkbomb()
report("done.")
