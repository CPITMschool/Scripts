# Scripts-2.0 - Project Structure

This repository contains blockchain node management scripts and the cpinodes CLI tool.

## Directory Structure

```
Scripts-2.0/
├── cpinodes-source/       # Go source code for cpinodes binary
│   ├── cmd/               # Main application entry point
│   ├── internal/          # Internal packages
│   ├── build.sh           # Build script
│   └── BUILD.md           # Build instructions
│
├── Arcium/                # Arcium node scripts
│   ├── Install-Arcium.sh
│   ├── Delete-Arcium.sh
│   ├── Update-Arcium.sh
│   ├── Logs-Arcium.sh
│   ├── Status-Arcium.sh
│   └── info.json
│
├── Aztec/                 # Aztec node scripts
│   └── ...
│
├── Other/                 # Utility scripts
│   ├── Install-Docker.sh
│   ├── Uninstall-Docker.sh
│   ├── install_rust.sh
│   ├── install_ufw.sh
│   └── info.json
│
├── nodes.json             # Node configurations
├── system-commands.json   # System diagnostic commands
├── other-scripts.json     # Utility scripts configuration
│
└── cpinodes               # Compiled binary (Linux)
```

## Node Folders

Each node folder contains:
- `Install-{NodeName}.sh` - Installation script (required)
- `Delete-{NodeName}.sh` - Deletion script (required)
- `Update-{NodeName}.sh` - Update script (optional)
- `Logs-{NodeName}.sh` - Logs viewing script (optional)
- `Status-{NodeName}.sh` - Status check script (optional)
- `info.json` - Node metadata

## Configuration Files

### nodes.json
Defines available blockchain nodes with their requirements (CPU, RAM, DISK, OS).

### system-commands.json
Defines system diagnostic commands (ports, disk, processes, memory, etc.).

### other-scripts.json
Defines utility scripts for system setup (Docker, Rust, UFW, etc.).

## Building cpinodes

See [cpinodes-source/BUILD.md](cpinodes-source/BUILD.md) for detailed build instructions.

Quick build:
```bash
cd cpinodes-source
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o ../cpinodes ./cmd/cpinodes
```

## Using cpinodes

```bash
./cpinodes
```

Main menu commands:
- `nodes` - View available nodes
- `system` - System diagnostic commands
- `other` - Utility scripts
- `hardware` - View hardware info
- `help` - Show help
- `<node_name>` - Enter node management context (e.g., `arcium`)

## Local Development

For local testing without GitHub:
```bash
export CPINODES_LOCAL_PATH="/path/to/Scripts-2.0"
./cpinodes
```

## Adding New Nodes

1. Create folder: `{NodeName}/`
2. Add scripts: `Install-{NodeName}.sh`, `Delete-{NodeName}.sh`, etc.
3. Add entry to `nodes.json`
4. Rebuild binary (if needed)

## Adding New Utility Scripts

1. Add script to `Other/` folder
2. Add entry to `other-scripts.json`
3. Rebuild binary (if needed)
