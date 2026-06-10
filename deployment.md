# Instabooth deployment

Booth runtime data lives in **instabooth-data** (per event). Event templates and the event registry live in **instabooth-admin** (git-synced). Application code is in **instabooth-server** and **instabooth-frontend**.

## Repositories

| Repo | Role |
|------|------|
| [instabooth-server](https://github.com/vinoduxdata/instabooth-server) | Python backend (`photobooth` CLI) |
| [instabooth-frontend](https://github.com/vinoduxdata/instabooth-frontend) | Vue/Quasar UI (build copied into server) |
| [instabooth-admin](https://github.com/vinoduxdata/instabooth-admin) | Git-synced templates, event registry, booth-global config |
| [instabooth-data](https://github.com/vinoduxdata/instabooth-data) | Runtime data for the default/active event (not git-synced per new event) |
| instabooth-deployment | This guide and `start-booth.sh` |

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
git clone https://github.com/vinoduxdata/instabooth-admin.git
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

Each event folder under `instabooth-data/events/` contains `config/config.json`. On first start the app creates any missing runtime folders (`database/`, `media/`, `cache/`, `log/`, etc.) and links demo assets under `userdata/demoassets/`.

## Run the booth

Recommended: use the launcher (reads `instabooth-admin/active-event.json`):

```bash
chmod +x ~/instabooth/instabooth-deployment/start-booth.sh
~/instabooth/instabooth-deployment/start-booth.sh
```

Or manually with explicit paths:

```bash
source ~/instabooth/instabooth-server/myenv/bin/activate
photobooth --admin-dir ~/instabooth/instabooth-admin --data-dir ~/instabooth/instabooth-data
```

Manage events and templates in the admin UI at `/admin/event` and `/admin/event-template`. Activating an event updates `active-event.json` and restarts the booth into that event's data folder.

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

Edit the active event's `config/config.json` (for example `~/instabooth/instabooth-data/events/default/config/config.json`), or pull from **instabooth-data**:

```bash
cd ~/instabooth/instabooth-data
git pull
```

Restart `photobooth` for config changes to load (or use the admin UI where supported).

Saves from the admin UI write backups next to the config file, e.g. `config/config.json_backup-YYYYMMDD-HHMMSS`.

## Runtime layout (instabooth-data)

```
instabooth-data/
└── events/
    ├── default/                 # default event
    │   ├── config/config.json
    │   ├── cache/
    │   ├── database/
    │   ├── log/
    │   ├── media/
    │   ├── recycle/
    │   ├── tmp/
    │   └── userdata/            # demoassets/ symlinked on first run
    └── {event-id}/              # events created from templates
```

Do not commit `userdata/demoassets/` as a normal directory; the server expects to create a symlink there.

## Multi-event layout

```
instabooth-admin/                 # git-synced
├── booth.json                    # booth-global: cameras, GPIO, admin password
├── events.json                   # event registry
├── active-event.json             # pointer to active event data folder
└── templates/{template-id}/      # reusable templates (config + userdata)

instabooth-data/
└── events/{event-id}/            # all event runtime data lives here
```

New events created in the admin UI are stored under `instabooth-data/events/` and are **not** git-synced.

## Migration from single-event setup

If you already have a working `instabooth-data` folder but no `instabooth-admin` registry yet:

```bash
python3 ~/instabooth/instabooth-server/scripts/migrate_to_multievent.py --root ~/instabooth
```

This creates `instabooth-admin` with a default template, moves legacy runtime folders into `instabooth-data/events/default/`, and registers that folder as the `default` active event.

The older standalone **instabooth-config** backup repo is superseded by **instabooth-admin** for booth-global settings and templates.

## Admin pages

| URL | Purpose |
|-----|---------|
| `/admin/event` | Create and manage events |
| `/admin/event-template` | Create and manage templates |
| `/admin/event/:id/config` | Edit a draft or inactive event config |
| `/admin/event-template/:id/config` | Edit template config |
| `/admin/event/:id/files` | Manage event assets |
| `/admin/event-template/:id/files` | Manage template assets |
