# OpenSpec CLI Command Reference

Complete reference for OpenSpec CLI commands.

## Core Commands

### openspec list
List active changes in `openspec/changes/`.

```bash
openspec list                    # Show active changes
openspec list --specs            # Show existing specifications
openspec change list --json      # Machine-readable output (deprecated)
```

**Output:**
```
Active Changes:
  • add-two-factor-auth
  • update-rate-limiting

Use 'openspec show <change-id>' for details
```

### openspec show
Display details of a change or spec.

```bash
openspec show <item>                      # Auto-detect type
openspec show <item> --type change        # Explicit type
openspec show <item> --type spec          # Show spec details
openspec show <spec-id> --json            # Machine-readable
openspec show <change> --json --deltas-only  # Debug delta parsing
```

**Examples:**
```bash
openspec show add-2fa              # Show proposal, tasks, and deltas
openspec show auth --type spec     # Show auth specification
```

### openspec validate
Validate change structure and spec formatting.

```bash
openspec validate                  # Interactive bulk validation
openspec validate <change-id>      # Validate specific change
openspec validate <change-id> --strict  # Comprehensive checks
openspec validate --no-interactive # Non-interactive mode
```

**What it checks:**
- Required files exist (proposal.md, tasks.md)
- Spec deltas have proper operations (ADDED/MODIFIED/REMOVED)
- Requirements have at least one scenario
- Scenarios use correct format (`#### Scenario:`)
- Normative language used (SHALL/MUST/SHOULD)

**Always use `--strict` before committing changes.**

### openspec archive
Move completed change to archive and update specs.

```bash
openspec archive <change-id>           # Interactive mode (prompts for confirmation)
openspec archive <change-id> --yes     # Non-interactive (skip confirmation)
openspec archive <change-id> -y        # Short form
openspec archive <change-id> --skip-specs  # Archive without updating specs
```

**What it does:**
1. Validates the change
2. Moves `changes/<change-id>/` → `changes/archive/YYYY-MM-DD-<change-id>/`
3. Merges deltas into `openspec/specs/` (unless `--skip-specs`)

**Important:** Always pass the change ID explicitly. Use `--yes` for non-interactive scripts.

### openspec spec list
List all specifications.

```bash
openspec spec list                 # List all specs
openspec spec list --long          # Show with descriptions
openspec spec list --json          # Machine-readable format
```

## Project Management

### openspec init
Initialize OpenSpec in a project.

```bash
openspec init                      # Initialize in current directory
openspec init [path]               # Initialize in specific directory
```

**Creates:**
```
openspec/
├── project.md              # Project conventions
├── AGENTS.md              # AI agent instructions
├── specs/                 # Current specifications
└── changes/               # Change proposals
    └── archive/           # Completed changes
```

**Interactive prompts:**
- Select AI tools to configure (Claude Code, Cursor, etc.)
- Generates slash commands for selected tools
- Creates managed AGENTS.md instruction file

### openspec update
Update instruction files and slash commands.

```bash
openspec update                    # Update in current directory
openspec update [path]             # Update specific directory
```

**Use when:**
- Upgrading OpenSpec version
- Switching AI tools
- Refreshing agent instructions

## Command Flags

### Global Flags
- `--json` - Machine-readable JSON output
- `--no-interactive` - Disable prompts
- `--help` / `-h` - Show help

### Command-Specific Flags

#### list
- `--specs` - Show specifications instead of changes

#### show
- `--type <change|spec>` - Disambiguate item type
- `--json` - JSON output
- `--deltas-only` - Show only delta operations (with --json)

#### validate
- `--strict` - Comprehensive validation (recommended)
- `--no-interactive` - Non-interactive mode

#### archive
- `--yes` / `-y` - Skip confirmation prompt
- `--skip-specs` - Don't update specs (tooling-only changes)

## Usage Patterns

### Creating a Change
```bash
# Ask AI to create proposal
# AI creates: openspec/changes/add-feature/

# Verify structure
openspec list
openspec show add-feature

# Validate formatting
openspec validate add-feature --strict
```

### Implementing a Change
```bash
# Ask AI to implement
# AI follows: openspec/changes/add-feature/tasks.md

# AI marks tasks as complete
# Verify implementation matches specs
```

### Archiving a Change
```bash
# Validate one more time
openspec validate add-feature --strict

# Archive (interactive)
openspec archive add-feature

# Or archive (non-interactive)
openspec archive add-feature --yes

# Verify specs updated
openspec list --specs
openspec show feature-name --type spec
```

### Debugging Issues
```bash
# Check delta parsing
openspec show add-feature --json --deltas-only

# Verbose validation
openspec validate add-feature --strict

# List all specs
openspec spec list --long

# Check specific requirement
openspec show auth --json -r 1
```

## Exit Codes
- `0` - Success
- `1` - Error (validation failed, file not found, etc.)

## Environment
- **Node.js >= 20.19.0** required
- No API keys needed
- Works with any AI tool

## Getting Help
```bash
openspec --help              # General help
openspec <command> --help    # Command-specific help
```
