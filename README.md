# Scripts-2.0

Blockchain node management scripts and cpinodes CLI tool.

## 📁 Project Structure

See [STRUCTURE.md](STRUCTURE.md) for detailed project organization.

```
Scripts-2.0/
├── cpinodes-source/       # Go source code (separate private repo)
├── Arcium/                # Arcium node scripts
├── Aztec/                 # Aztec node scripts
├── Stable/                # Stable node scripts
├── Tashi/                 # Tashi node scripts
├── Other/                 # Utility scripts
├── system-commands.json   # System diagnostic commands
└── cpinodes               # Compiled binary
```

## 🚀 Quick Start

### Download and Run

```bash
# Download binary
wget https://github.com/CPITMschool/Scripts/releases/latest/download/cpinodes
chmod +x cpinodes

# Run
./cpinodes
```

### Main Menu

- `nodes` - View and manage blockchain nodes
- `system` - System diagnostic commands (ports, disk, processes, memory, etc.)
- `other` - Utility scripts (Docker, Rust, UFW, Grafana, server status)
- `<node_name>` - Enter node context (e.g., `arcium`, `aztec`)
- `help` - Show help
- `exit` - Exit program

### Node Management

```bash
./cpinodes
>>> arcium          # Enter Arcium context
arcium >>> install  # Install Arcium node
arcium >>> logs     # View logs
arcium >>> status   # Check status
arcium >>> back     # Return to main menu
```

## 📦 Configuration

All configurations are stored in node folders and loaded from GitHub:

- **Node configs**: Each node folder has `info.json` with requirements
- **System commands**: `system-commands.json` in root
- **Other scripts**: `Other/info.json` with script list

## 🔧 Adding New Nodes

1. Create folder: `NewNode/`
2. Add `info.json`:
```json
{
  "name": "NewNode",
  "cpu": "4 CPU",
  "ram": "8 GB RAM",
  "disk": "500 GB Storage",
  "os": "Ubuntu 22.04"
}
```
3. Add scripts: `Install-NewNode.sh`, `Delete-NewNode.sh`, etc.
4. Push to GitHub - cpinodes will auto-detect it!

## 🛠️ Adding Utility Scripts

1. Add script to `Other/` folder
2. Update `Other/info.json`:
```json
{
  "name": "script-name",
  "description": "Script description",
  "file": "script_file.sh"
}
```
3. Push to GitHub

## 🔒 Security

- All scripts fetched via HTTPS from GitHub
- Script validation (shebang check, dangerous command detection)
- Automatic line ending conversion (CRLF → LF)
- Size limits (1MB per script)
- Temp file cleanup

## 📝 Logging

Logs stored in `~/.cpinodes/logs/`:
- Command execution history
- Script output
- Errors and warnings

## 🌐 GitHub Repository

Scripts are loaded from: `https://github.com/CPITMschool/Scripts`

### For Public Repository
No additional configuration needed - just run the binary.

### For Private Repository
Set GitHub token as environment variable:

```bash
# Create GitHub Personal Access Token:
# 1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
# 2. Generate new token with 'repo' scope
# 3. Copy the token

# Set token
export GITHUB_TOKEN="your_github_token_here"

# Run cpinodes
./cpinodes
```

**Permanent setup (add to ~/.bashrc or ~/.zshrc):**
```bash
echo 'export GITHUB_TOKEN="your_github_token_here"' >> ~/.bashrc
source ~/.bashrc
```

### For Local Development
```bash
export CPINODES_LOCAL_PATH="/path/to/Scripts-2.0"
./cpinodes
```

## 📖 Documentation

- [STRUCTURE.md](STRUCTURE.md) - Project structure details
- [cpinodes-source/BUILD.md](cpinodes-source/BUILD.md) - Build instructions (separate repo)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Add/modify scripts in appropriate folders
4. Update `info.json` files
5. Submit a pull request

## 📄 License

Private repository - all rights reserved.
```

### Використання build скрипту

```bash
# Збірка з обфускацією та компресією
./scripts/build.sh
```

## Використання

Запустіть `cpinodes` для відображення інтерактивного меню:

```bash
cpinodes
```

### Доступні команди

- `help` - Показати довідку
- `install <node>` - Встановити ноду
- `delete <node>` - Видалити ноду
- `update <node>` - Оновити ноду
- `logs <node>` - Показати логи ноди
- `nodes` - Показати список доступних нод
- `hardware` - Показати характеристики сервера
- `clear` - Очистити екран
- `about` - Інформація про програму
- `exit` - Вийти з програми

### Приклади

```bash
# Встановити Arcium ноду
>>> install Arcium

# Переглянути логи Aztec ноди
>>> logs Aztec

# Показати всі доступні ноди
>>> nodes
```

## Структура проекту

```
cpinodes/
├── cmd/cpinodes/          # Entry point
├── internal/
│   ├── cli/               # CLI interface layer
│   ├── config/            # Configuration layer
│   ├── executor/          # Execution layer
│   ├── logger/            # Logging layer
│   └── commands/          # Command handlers
├── pkg/version/           # Version info
├── testdata/              # Test data
└── scripts/               # Build scripts
```

## Розробка

### Запуск тестів

```bash
# Всі тести
go test ./...

# З покриттям
go test -cover ./...

# Property-based тести
go test -v ./... -run Property
```

### Додавання нової ноди

1. Додайте ноду в `nodes.json` на GitHub
2. Створіть відповідні скрипти: `Install-NodeName.sh`, `Delete-NodeName.sh`, `Update-NodeName.sh`, `Logs-NodeName.sh`
3. Нода автоматично з'явиться в меню після перезапуску

## Вимоги

- Go 1.21+
- Linux (Ubuntu 22.04 LTS рекомендовано)
- curl, bash, chmod (стандартні утиліти)

## Ліцензія

MIT License

## Автор

cpinodes team
