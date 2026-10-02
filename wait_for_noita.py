"""
Wait for the Noita mod WebSocket — no training, no PPO.

Usage:
    python wait_for_noita.py
    python wait_for_noita.py --port 5001 --timeout 120

Start this (or train.py) BEFORE launching Noita. When you see
"Noita connected", enable the mod in-game if you have not already.
"""

from __future__ import annotations

import argparse
import sys

from rich.console import Console

from config import Config
from noita_env import NoitaEnv

console = Console()


def main() -> None:
    p = argparse.ArgumentParser(description="Block until Noita mod connects")
    p.add_argument("--port", type=int, default=None, help="WebSocket port (default: from Config)")
    p.add_argument("--timeout", type=float, default=300.0, help="Max wait seconds")
    args = p.parse_args()

    cfg = Config()
    port = args.port if args.port is not None else cfg.noita_base_port

    console.print(f"[cyan]Listening on port {port}[/] — launch Noita with mod [bold]noitarl[/] enabled.")
    env = NoitaEnv(host=cfg.noita_host, port=port)
    try:
        ok, reason = env.wait_for_noita(connect_timeout=args.timeout, state_timeout=120.0)
        if ok:
            console.print("[green]OK:[/] Noita connected and sending state.")
            sys.exit(0)
        if reason == "state_timeout":
            console.print(
                "[red]WebSocket OK but no game state[/] — start [bold]New Game[/] "
                "and enter the world (not the main menu), then retry."
            )
            sys.exit(1)
        console.print(
            "[red]Timed out[/] — no connection.\n"
            "  • Start [cyan]wait_for_noita.py[/] *before* launching Noita.\n"
            "  • Enable unsafe mods + RL Agent MVP, then New Game.\n"
            "  • If logger.txt says pollnet.dll / [bold]not a valid Win32 application[/]: "
            "run [cyan]git lfs pull[/] in the repo (DLL was an LFS stub).\n"
            "  Log: Steam\\\\...\\\\Noita\\\\mods\\\\noitarl\\\\logger.txt"
        )
        sys.exit(1)
    finally:
        env.close()


if __name__ == "__main__":
    main()
