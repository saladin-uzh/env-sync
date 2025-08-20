# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

env-sync is a cross-platform environment management tool that keeps working environments consistent and reproducible across machines. It uses native package managers (Homebrew, apt, winget) to bootstrap development environments based on predefined profiles.

**Key Goals:**
- Multi-machine, cross-OS environment consistency
- Profile-based package management
- Machine inventory tracking for reproducibility
- Dry-run capability for safe execution

## Quickstart and Common Commands

### Bootstrap Environment (ALWAYS DRY-RUN FIRST)

**macOS/Linux:**
```bash
./bootstrap.sh --dry-run    # Review what will be installed
./bootstrap.sh              # Apply changes
```

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1 -DryRun
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

### Register a Machine
```bash
./scripts/register.sh --id "laptop-2025" --os "macos" --profile "web-dev"
```

### Profile-Specific Install Commands

**macOS (Homebrew):**
```bash
brew bundle --file=profiles/web-dev/macos/Brewfile
```

**Linux (Debian/Ubuntu):**
```bash
sudo xargs -a profiles/web-dev/linux/apt.txt apt-get install -y
```

**Windows (Winget):**
```powershell
Get-Content profiles\web-dev\windows\winget.txt | ForEach-Object { winget install --id $_ }
```

### Local Linting and Validation
```bash
shellcheck ./scripts/*.sh
./bootstrap.sh --dry-run
```

**Important Notes:**
- Always run bootstrap with `--dry-run` first to preview changes
- Linux support currently limited to Debian/Ubuntu distributions
- Package managers may prompt for privileges or confirmations

## Architecture and Repository Structure

### High-Level Design
- **Cross-platform bootstrap**: Shell/PowerShell scripts with OS detection
- **Profile-based packages**: Organized per OS with native package managers
- **Machine inventory**: JSON documents for reproducibility tracking
- **CI validation**: Shellcheck linting and dry-run testing

### Repository Layout
```
├── bootstrap.sh, bootstrap.ps1     # Main entrypoints with dry-run capability
├── profiles/web-dev/               # Development profile packages
│   ├── macos/Brewfile              # Homebrew packages and casks
│   ├── linux/apt.txt               # Debian/Ubuntu package list  
│   └── windows/winget.txt          # Winget package IDs
├── scripts/register.sh             # Machine registration utility
├── inventory/                      # Machine descriptors with timestamps
│   └── example.json                # JSON format example
└── .github/workflows/ci.yml        # CI: shellcheck + bootstrap dry-run
```

## Key Files and Behaviors

### bootstrap.sh
- **Safety**: `set -euo pipefail`, quoted variables
- **OS Detection**: `uname -s` normalized to lowercase
- **Dry-run Mode**: `--dry-run` flag uses `run()` helper to print vs execute
- **Git Requirement**: Ensures git is present (brew on macOS, apt on Debian/Ubuntu)
- **Profile Application**: Currently hard-coded to `web-dev` profile
  - macOS: `brew bundle --file=profiles/web-dev/macos/Brewfile`
  - Linux: `sudo xargs -a profiles/web-dev/linux/apt.txt apt-get install -y`

### bootstrap.ps1
- **Parameters**: Uses `[switch]$DryRun` for PowerShell conventions
- **Profile**: Installs from `profiles\web-dev\windows\winget.txt`
- **Dry-run**: Displays commands instead of executing them

### scripts/register.sh
- **Required Args**: `--id`, `--os`, `--profile`
- **Output**: Creates `inventory/${ID}.json` with UTC timestamp
- **Format**: JSON with id, os, profile, and registered_at fields

### Profile Files
- **Brewfile**: Standard Homebrew bundle format (brew + cask entries)
  - Contains: git, node, pnpm, Visual Studio Code, Warp
- **apt.txt**: Newline-separated package names for Debian/Ubuntu
  - Contains: git, nodejs, pnpm, build-essential
- **winget.txt**: Winget package IDs for Windows
  - Contains: Git.Git, Microsoft.VisualStudioCode, Warp.Warp

### Constraints
- Linux support assumes Debian/Ubuntu (checks `/etc/debian_version`)
- Bootstrap scripts are hard-coded to `web-dev` profile
- New profiles require extending bootstrap logic

## Development Workflows

### Onboarding a New Machine
1. **Preview**: `./bootstrap.sh --dry-run` (or `.\bootstrap.ps1 -DryRun` on Windows)
2. **Apply**: Run full bootstrap when satisfied with the plan
3. **Register**: 
   ```bash
   ./scripts/register.sh --id "my-host-2025" --os "macos" --profile "web-dev"
   git add inventory/my-host-2025.json
   git commit -m "chore(inventory): register my-host-2025"
   ```
4. **Review**: Open PR for team review

### Updating Platform Packages
1. **Edit**: Modify `profiles/web-dev/{macos/Brewfile|linux/apt.txt|windows/winget.txt}`
2. **Validate locally**:
   - macOS: `brew bundle --file=profiles/web-dev/macos/Brewfile --no-upgrade`
   - Linux: `./bootstrap.sh --dry-run` (or test in container - see Testing)
   - Windows: `.\bootstrap.ps1 -DryRun`
3. **Submit**: Commit and open PR

### Adding New Profile
1. **Scaffold**: Create `profiles/<new-profile>/{macos,linux,windows}/` with appropriate files
2. **Extend Bootstrap**: Modify bootstrap scripts to parameterize profile selection
3. **Document**: Update README and WARP.md with new profile information

## Coding Standards and Patterns

### Shell Script Safety
- **Strict Mode**: `set -euo pipefail` in bash scripts
- **Variable Quoting**: Always quote variables (e.g., `"$var"`)
- **Tool Detection**: Use `command -v` to check tool availability

### Dry-Run Pattern
- Gate side effects through `run()` helper function
- Print intended commands in dry-run mode, execute in apply mode
- Always encourage users to dry-run first

### Cross-Platform Considerations
- **OS Detection**: Use `uname -s` normalized to lowercase
- **Linux Targeting**: Narrow to Debian/Ubuntu via `/etc/debian_version` checks
- **PowerShell**: Use proper parameters (`[switch]$DryRun`), `Test-Path`, `Get-Content`

### Idempotency and Linting
- Design scripts to be re-run safe
- Rely on package managers' built-in idempotency
- Use shellcheck locally and in CI (currently non-blocking)

## Warp-Specific Automation Rules

### npm Script Execution Rule
**CRITICAL**: When instructed to run `npm run <script>`, never run in foreground:
1. Extract script name from command
2. Run in vertically split pane (preferred)
3. Fallback to new tab if pane splitting unavailable  
4. Final fallback: background with `nohup npm run <script> &`
5. Immediately report: script name, status, log location, PID

### Long-Running Operations
- For `brew`/`apt`/`winget` operations, prefer split pane or new tab
- Keep logs visible without blocking primary shell
- Expect `sudo` prompts on Linux; ensure interactive capability

## Testing and Validation

### Dry-Run Everything First
```bash
./bootstrap.sh --dry-run
.\bootstrap.ps1 -DryRun      # Windows
```

### Local Linting
```bash
shellcheck ./scripts/*.sh
```

### Container Testing (Linux)
Test bootstrap safely without modifying host:
```bash
docker run --rm -it ubuntu:22.04 bash -lc '
apt-get update &&
apt-get install -y ca-certificates git && 
git clone <repo-url> &&
cd env-sync &&
./bootstrap.sh --dry-run
'
```

### Package Manager Simulation
```bash
# macOS - preview without upgrading
brew bundle --file=profiles/web-dev/macos/Brewfile --no-upgrade

# Windows - view commands only
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1 -DryRun
```

## CI Pipeline and Local Equivalents

### GitHub Actions CI
- **Triggers**: Push and pull request
- **Steps**: 
  1. Install shellcheck
  2. Run `shellcheck ./scripts/*.sh` (non-blocking with `|| true`)
  3. Execute `./bootstrap.sh --dry-run`

### Local CI Equivalent
```bash
# Install shellcheck (Linux example)
sudo apt-get update && sudo apt-get install -y shellcheck

# Run the same checks as CI
shellcheck ./scripts/*.sh || true
./bootstrap.sh --dry-run
```

**Note**: Shellcheck is currently non-blocking in CI. For stricter enforcement, remove `|| true` in future updates.

## FAQs and Troubleshooting

**Q: What if I'm not on Debian/Ubuntu Linux?**
A: bootstrap.sh won't auto-apply packages. Install git manually and adapt the profile application for your distribution's package manager.

**Q: brew/apt/winget command not found?**
A: Install the appropriate package manager first:
- macOS: Install Homebrew
- Linux: Use built-in apt (Debian/Ubuntu) 
- Windows: Ensure winget is available (Windows 10/11)

**Q: What's the inventory JSON format?**
A: See `inventory/example.json`. Required: id, os, profile. Optional: tags array. The `registered_at` timestamp is auto-generated.

**Q: Dry-run only shows intended commands?**
A: Correct. Dry-run mode previews actions without executing them. Always review dry-run output before applying.

**Q: How do I add a new development profile?**
A: Create the profile directory structure, add package files for each OS, then extend the bootstrap scripts to handle profile selection via flags or environment variables.
