# Worktree Script Setup

This directory contains a `worktree` script that creates git worktrees for both server and enterprise repositories in a new base directory structure, and copies all the base files (except server and enterprise directories) to the new location.

## Configuration

Put the script in the parent of your mattermost server and enterprise directories. E.g.:

monorepo/
│ ── worktree
│ ── worktree-completion.bash
│ ── README.md (this file)
├── mattermost/
└── enterprise/


The script is configurable for different directory naming conventions. At the top of the `worktree` script, you can modify:

```bash
# Configuration - change these if your directories have different names
SERVER_DIR_NAME="server"
ENTERPRISE_DIR_NAME="enterprise"
```

For example, if your directories are named differently:
```bash
SERVER_DIR_NAME="mattermost"
ENTERPRISE_DIR_NAME="mattermost-enterprise"
```

The script automatically uses the current directory name as the base name for creating new worktree directories. If you're in a directory called "my-project", it will create "my-project-shortname" directories.

You can also add any files you need copied over to the `server_files` and `enterprise_files` lists.


## Usage

```bash
./worktree <command> [arguments]
```

### Commands

- **create** - Create worktrees for NEW branches only (prevents accidental overwrites)
- **remove** - Remove worktrees and base directory (with confirmation)
- **list** - List existing worktree directories

### Examples

```bash
# Create worktrees with short directory name
# Note: Only creates worktrees for NEW branches that don't exist yet
./worktree create MM-63556-compliance-export-download compliance-export

# List existing worktrees (shows both short name and branch)
./worktree list

# Remove worktrees by branch name (with confirmation prompt)
./worktree remove MM-63556-compliance-export-download

# Remove worktrees without confirmation (for scripts)
./worktree remove MM-63556-compliance-export-download --force
```

### Create Command Workflow

When you run the create command, the script will:

1. **Check if branch exists** - If the branch already exists in either server or enterprise repos, it will exit with an error
2. **Prompt for base branch** - You'll be asked to select which branch to use as the base for the new branch
3. **Show available branches** - All local and remote branches will be displayed
4. **Default to master** - The script defaults to `master` branch (press Enter to accept)
5. **Create new worktrees** - Creates the new branch from your selected base branch

### Create Command Result
```
monorepo-compliance-export/
├── CLAUDE.md                                         (copied from current base dir)
├── CLAUDE.local.md                                   (copied from current base dir)
├── mise.toml                                         (copied from current base dir)
├── ... (all other files/dirs except server/enterprise)
├── server/                                           (git worktree for MM-63556-compliance-export-download)
└── enterprise/                                       (git worktree for MM-63556-compliance-export-download)
```

## Shell Completion Setup

To enable tab completion for branch names:

### Option 1: Source the completion script for current session
```bash
source ./worktree-completion.bash
```

### Option 2: Add to your shell profile for permanent setup
Add this line to your `~/.bashrc`, `~/.bash_profile`, or `~/.zshrc`:

```bash
source /wherever/worktree-completion.bash
```


After setup, you can use tab completion:
```bash
worktree <TAB>                    # Shows: create, remove, list
worktree create MM-<TAB>          # Shows available branches starting with MM- (excludes existing branches)
worktree create MM-123 <TAB>      # Short name - no completion (type freely)
worktree remove <TAB>             # Shows existing branch names for removal
```

The completion script is smart enough to:
- Only suggest non-existing branches for the `create` command
- Only suggest existing worktree branches for the `remove` command
- Support both bash and zsh shells

### Interactive Base Branch Selection

When creating a new branch, you'll get an interactive prompt with tab completion:
```bash
$ ./worktree create my-new-feature feature
[INFO] Branch my-new-feature does not exist. What branch should be used as base?
Available branches:
  master
  release-10.9
  MM-64569-LDAP-wizard-load-test
  MM-64699-ldap-wizard-e2e-tests
  ...

Enter base branch (default: master): <TAB to complete>
```

## Cleanup Worktrees

### Easy Way (Recommended)
```bash
# Interactive removal with confirmation (use branch name, not short name)
./worktree remove <branch-name>

# Force removal without confirmation (for scripts)
./worktree remove <branch-name> --force
```

### Manual Way
```bash
cd server && git worktree remove ../BASE-NAME-SHORT-NAME/server
cd enterprise && git worktree remove ../BASE-NAME-SHORT-NAME/enterprise
rm -rf ../BASE-NAME-SHORT-NAME
```

The `remove` command automatically handles all cleanup including git worktree removal and directory deletion. It finds worktrees by branch name and shows what will be removed, asking for confirmation to prevent accidental deletions.
