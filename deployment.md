# Instabooth deployment

Booth runtime lives in **instabooth-data** (working directory). Application code is in **instabooth-server** and **instabooth-frontend**.

## Repositories

| Repo | Role |
|------|------|
| [instabooth-server](https://github.com/vinoduxdata/instabooth-server) | Python backend (`photobooth` CLI) |
| [instabooth-frontend](https://github.com/vinoduxdata/instabooth-frontend) | Vue/Quasar UI (build copied into server) |
| [instabooth-data](https://github.com/vinoduxdata/instabooth-data) | Runtime data: `config/config.json`, media, DB, logs |
| instabooth-deployment | This guide |

## Prerequisites

- Linux (Raspberry Pi or desktop)
- Python 3.11+ with venv support, e.g. `sudo apt install python3.14-venv`
- Node.js 22+ and npm (for frontend build)
- Git

## Initial setup

```bash
mkdir -p ~/instabooth
cd ~/instabooth

git clone https://github.com/vinoduxdata/instabooth-server.git
git clone https://github.com/vinoduxdata/instabooth-frontend.git
git clone https://github.com/vinoduxdata/instabooth-data.git
```

### Frontend

Build output must land in the server package. In `instabooth-frontend/quasar.config.ts`, set:

```ts
distDir: '../instabooth-server/src/web/frontend/',
```

Then build:

```bash
cd ~/instabooth/instabooth-frontend
npm install
npm run build
```

### Backend

```bash
cd ~/instabooth/instabooth-server
python3 -m venv --system-site-packages myenv
source myenv/bin/activate
python -m pip install --upgrade pip
python -m pip install -e .
python -m pip install pydot
```

`instabooth-data` should already contain `config/config.json`. On first start the app creates any missing runtime folders (`database/`, `media/`, `cache/`, `log/`, etc.) and links demo assets under `userdata/demoassets/`.

## Run the booth

Always start from **instabooth-data** (current working directory = data root):

```bash
cd ~/instabooth/instabooth-data
source ../instabooth-server/myenv/bin/activate
photobooth
```

Open the UI at http://localhost:8000 (default).

## Update workflows

### Frontend only

```bash
cd ~/instabooth/instabooth-frontend
git pull
npm install   # if package-lock changed
npm run build
```

Restart the booth if it is already running.

### Backend only

```bash
cd ~/instabooth/instabooth-server
git pull
source myenv/bin/activate
python -m pip install -e .

cd ~/instabooth/instabooth-data
photobooth
```

### Config only

Edit `~/instabooth/instabooth-data/config/config.json`, or pull from **instabooth-data**:

```bash
cd ~/instabooth/instabooth-data
git pull
```

Restart `photobooth` for config changes to load (or use the admin UI where supported).

Saves from the admin UI write backups next to the config file, e.g. `config/config.json_backup-YYYYMMDD-HHMMSS`.

## Runtime layout (instabooth-data)

```
instabooth-data/
├── config/
│   └── config.json          # required; tracked in git
├── cache/                   # created on first run if missing
├── database/
├── log/
├── media/
│   ├── camera_original/
│   ├── unprocessed_original/
│   └── processed_full/
├── recycle/
├── tmp/
└── userdata/                # demoassets/ symlinked on first run
```

Do not commit `userdata/demoassets/` as a normal directory; the server expects to create a symlink there.
