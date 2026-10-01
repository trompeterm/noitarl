

https://github.com/user-attachments/assets/b5d99449-3ead-447d-965a-2d14676631f5




# 🧙‍♂️ Noita RL — Reinforcement Learning Agent for Noita

[![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/yava-code/noitarl/tests.yml?label=tests)](.github/workflows/tests.yml)

Train an AI agent to play **Noita** — the physics-based roguelike — using reinforcement learning (PPO).

> 🎯 **Goal**: Teach an agent to navigate, fight, and survive in Noita's procedurally generated world using only pixel observations and game state data.

---

## ✨ Features

- **PPO Training** — Proximal Policy Optimization with custom reward shaping
- **Lua-Python Bridge** — Real-time communication between Noita's Lua mod and Python training loop via `pollnet.dll`
- **Custom Environment** — Gym-compatible wrapper with pixel observations, health, mana, and inventory state
- **Episode Tracking** — Automatic logging of rewards, deaths, and progression metrics
- **CI/CD** — Automated tests on every push

---

## 🏗️ Architecture

```
┌─────────────────┐         pollnet.dll         ┌──────────────────┐
│   Noita Game    │ ◄─────────────────────────► │  Python Trainer  │
│   (Lua Mod)     │        TCP / Shared          │  (PPO Agent)     │
│                 │         Memory               │                  │
└─────────────────┘                              └──────────────────┘
       │                                                  │
       ▼                                                  ▼
  Game State                                         Neural Network
  - Pixel buffer                                     - CNN encoder
  - HP / Mana                                        - Policy head
  - Inventory                                        - Value head
  - Position                                         - Reward shaping
```

---

## 🚀 Quick Start

### Prerequisites

- **Python 3.10+** (Windows; Linux needs `pollnet.so` — not bundled yet)
- **Noita installed via Steam** — the game must be on disk (`Noita.exe`); signing into Steam in-game is normal, but **no Steam API keys go in `.env`**
- **Git LFS** — `bin/pollnet.dll` is stored in LFS; without it the mod cannot connect

### 1. Clone and install Python deps

```powershell
git clone https://github.com/yava-code/noitarl.git
cd noitarl
git lfs install
git lfs pull

python -m pip install -r requirements.txt
copy .env.example .env
```

Optional `.env` tweaks for first runs: `CV_ENABLED=false` (default), `TOTAL_TIMESTEPS=10000` for a short smoke test. Telegram, W&B, and Azure can stay empty.

### 2. Install the mod into Noita

The trainer does **not** auto-install the mod. Noita only loads mods from its `mods\` folder.

**Option A — junction (dev):** from repo root, after Noita is installed:

```powershell
.\scripts\install_mod.ps1 -NoitaRoot "C:\Program Files (x86)\Steam\steamapps\common\Noita"
```

Or run `.\scripts\install_mod.ps1` with no args to search Steam libraries.

**Option B — copy:** copy this entire repo (or at least `init.lua`, `mod.xml`, `port.txt`, `lib\`, `bin\`) to:

`Steam\steamapps\common\Noita\mods\noitarl\`

Ensure `port.txt` contains `5001` (must match `NOITA_BASE_PORT` in `.env` / [config.py](config.py)).

### 3. Enable the mod in Noita

1. Main menu → **Mods**.
2. Scroll down → **Enable unsafe mods: On** (required — this mod uses `request_no_api_restrictions` for WebSocket/pollnet).
3. Check **`[x]`** on **RL Agent MVP**.
4. Accept the modding agreement; **restart Noita** if prompted.

### 4. Connect (test before training)

**Order matters:** start Python **first**, then launch the game.

```powershell
python wait_for_noita.py
```

Then start Noita → mod enabled → **New Game** → enter the world (not only the title screen).

Success:

```text
OK: Noita connected and sending state.
```

If it fails, read `Noita\mods\noitarl\logger.txt`. Common issues:

| Symptom | Fix |
|---------|-----|
| `pollnet.dll` / **not a valid Win32 application** | Run `git lfs pull` in the repo (DLL was an LFS pointer stub) |
| `Socket error #1` | Start `wait_for_noita.py` **before** Noita; keep the terminal open |
| Mod list shows privileges warning | Enable **unsafe mods** on the Mods screen |

### 5. Training

```powershell
python train.py --fresh
```

`train.py` waits for the mod to connect (same as step 4) before PPO starts. Checkpoints are `.zip` files under `checkpoints/`.

```powershell
python eval.py checkpoints\your_run_final.zip
```

### 6. Smoke-test the env (before long training)

Use a **short** run in `.env`: `TOTAL_TIMESTEPS=5000`, `N_STEPS=256`, `CV_ENABLED=false`.

1. `python train.py --fresh` → connect Noita → **New Game**, in the world.
2. **Do not play with the keyboard** — the agent drives via velocity, not WASD.
3. Watch the green **RL AGENT** HUD (top-left): action labels **Idle / Left / Right / …**
   - Untrained PPO often picks **Idle** a lot; that looks like “won’t move” but is normal.
   - **Bug** if HUD says **Left** or **Right** for many steps on flat ground and the body still does not slide.

Gravity always pulls down, so vertical motion can look “alive” even when the move head is mostly Idle.

### Configuration

Settings load from environment variables and `.env` ([config.py](config.py)):

| Variable | Default | Description |
|----------|---------|-------------|
| `NOITA_BASE_PORT` | `5001` | WebSocket port (match `port.txt` in mod) |
| `CV_ENABLED` | `false` | `true` = screen capture + CNN (slower; needs visible Noita window) |
| `TOTAL_TIMESTEPS` | `1000000` | PPO training length |
| `LEARNING_RATE` | `1e-4` in code / `.env.example` may override | PPO learning rate |
| `WANDB_ENABLED` | `false` | Optional experiment tracking |

---

## 📊 Training Progress

| Metric | Value |
|--------|-------|
| Episodes logged | See `data/episode_history.csv` |
| Best reward | Tracked in training logs |
| Checkpoints | Saved to `checkpoints/` |

---

## 📁 Project Structure

```
noitarl/
├── train.py              # Main training script
├── eval.py               # Evaluation script
├── config.py             # Configuration parameters
├── callbacks.py          # Training callbacks & logging
├── init.lua              # Noita Lua mod (game-side)
├── bin/
│   └── pollnet.dll       # Lua-Python communication library
├── data/
│   ├── episode_history.csv   # Episode metrics
│   └── schemas/              # Game state XML schemas
├── docs/
│   ├── lua_api_documentation.txt
│   ├── component_documentation.txt
│   └── Noita-ModdingAgreement-v100.rtf
├── .github/workflows/
│   └── tests.yml         # CI pipeline
└── ROADMAP.md            # Development roadmap
```

---

## 🗺️ Roadmap

See [ROADMAP.md](ROADMAP.md) for the full development plan.

**Current priorities:**
- [ ] Improve reward shaping for exploration
- [ ] Add multi-objective training (survival + progression)
- [ ] Implement curriculum learning
- [ ] Add wandb integration for experiment tracking

---

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Noita](https://noitagame.com/) by Nolla Games — incredible game with amazing modding support
- [Stable Baselines3](https://stable-baselines3.readthedocs.io/) — RL framework
- [pollnet](https://github.com/ikarth/pollnet) — Lua-Python communication library

---

<p align="center">Made with ❤️ and a lot of dead agents</p>
