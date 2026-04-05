---
name: openspec
description: Spec-driven development workflow for AI coding assistants. Use when user asks to create/plan/help with OpenSpec proposals, spec changes, change implementation, or archiving. Supports creating change proposals with proposal.md/tasks.md/spec deltas, validating specs, implementing changes, and archiving completed work. Trigger phrases include "openspec", "create proposal", "spec change", "implement change", "archive change".
---

# OpenSpec Workflow

OpenSpec enables spec-driven development by separating current specifications (`openspec/specs/`) from proposed changes (`openspec/changes/`). This skill guides you through creating proposals, implementing changes, and archiving completed work.

## When to Use This Skill

Use when user requests:
- Creating OpenSpec change proposals or specs
- Implementing OpenSpec changes
- Archiving completed changes
- Validating spec format
- Understanding OpenSpec workflow

## Three-Stage Workflow

### Stage 1: Create Proposal

**When to create proposals:**
- New features or capabilities
- Breaking changes (API, schema)
- Architecture or pattern changes
- Performance optimizations
- Security updates

**Skip proposals for:**
- Bug fixes (restoring intended behavior)
- Typos, formatting, comments
- Non-breaking dependency updates

**Steps:**

1. **Understand context**
   ```bash
   openspec list               # Active changes
   openspec list --specs       # Existing specs
   ```

2. **Choose unique change-id**
   - Use kebab-case: `add-two-factor-auth`, `update-rate-limiting`
   - Verb-led prefixes: `add-`, `update-`, `remove-`, `refactor-`

3. **Scaffold change directory**
   ```
   openspec/changes/<change-id>/
   ├── proposal.md        # Why and what changes
   ├── tasks.md          # Implementation checklist
   ├── design.md         # Technical decisions (optional)
   └── specs/            # Delta changes
       └── <capability>/
           └── spec.md
   ```

4. **Use templates from assets/**
   - `assets/proposal-template.md` → `proposal.md`
   - `assets/tasks-template.md` → `tasks.md`
   - `assets/spec-delta-template.md` → `specs/<capability>/spec.md`
   - `assets/design-template.md` → `design.md` (only if needed)

5. **Write spec deltas**

   **Critical formatting rules:**
   - Use exactly `#### Scenario:` (4 hashtags)
   - Every requirement MUST have at least one scenario
   - Use SHALL/MUST for normative requirements
   - Delta operations: `## ADDED Requirements`, `## MODIFIED Requirements`, `## REMOVED Requirements`

   **Example:**
   ```markdown
   ## ADDED Requirements

   ### Requirement: Two-Factor Authentication
   The system MUST require a second factor during login.

   #### Scenario: OTP required
   - **WHEN** valid credentials are provided
   - **THEN** an OTP challenge is required
   ```

6. **Validate before sharing**
   ```bash
   openspec validate <change-id> --strict
   ```
   Or use validation script:
   ```bash
   python scripts/validate_spec.py openspec/changes/<change-id>/
   ```

**For detailed format rules, see:** `references/spec-format-guide.md`

**For real-world examples, see:** `references/workflow-examples.md`

### Stage 2: Implement Change

**Approval gate**: Do not implement until proposal is approved.

**Steps:**

1. **Read proposal context**
   - Read `proposal.md` - understand why and what
   - Read `design.md` (if exists) - technical decisions
   - Read `tasks.md` - implementation checklist

2. **Implement tasks sequentially**
   - Complete tasks one by one
   - Mark completed: `- [x]` in tasks.md
   - Ensure implementation matches spec deltas

3. **Update checklist**
   - After all tasks done, set every item to `- [x]`
   - This reflects reality for archiving stage

### Stage 3: Archive Change

**After deployment**, archive to merge deltas into source specs.

```bash
openspec archive <change-id> --yes
```

**What happens:**
1. Change moves to `changes/archive/YYYY-MM-DD-<change-id>/`
2. Deltas merge into `openspec/specs/`
3. Specs reflect current deployed state

**Validation:**
```bash
openspec validate --strict
```

## CLI Commands Quick Reference

```bash
openspec list                        # Active changes
openspec list --specs                # Existing specs
openspec show <item>                 # View details
openspec validate <change-id> --strict  # Validate formatting
openspec archive <change-id> --yes   # Archive completed change
```

**Full CLI reference:** `references/cli-commands.md`

## Common Patterns

### Single-Capability Change
```
changes/add-password-reset/
├── proposal.md
├── tasks.md
└── specs/
    └── auth/spec.md
```

### Multi-Capability Change
```
changes/add-2fa/
├── proposal.md
├── tasks.md
└── specs/
    ├── auth/spec.md
    └── notifications/spec.md
```

### Complex Change with Design
```
changes/add-caching-layer/
├── proposal.md
├── tasks.md
├── design.md
└── specs/
    ├── caching/spec.md
    └── data-access/spec.md
```

## Delta Operations

### ADDED Requirements
For new capabilities:
```markdown
## ADDED Requirements

### Requirement: New Feature
System SHALL provide new capability.

#### Scenario: Success case
- **WHEN** action occurs
- **THEN** expected result
```

### MODIFIED Requirements
For changed behavior. **CRITICAL**: Include complete updated requirement text from `openspec/specs/<capability>/spec.md`:

```markdown
## MODIFIED Requirements

### Requirement: Existing Feature
[Complete updated requirement text with all scenarios]
```

**Common mistake**: Adding new concerns without including previous text causes information loss.

### REMOVED Requirements
```markdown
## REMOVED Requirements

### Requirement: Old Feature
**Reason**: Why removing
**Migration**: How to handle removal
```

### RENAMED Requirements
```markdown
## RENAMED Requirements
- FROM: `### Requirement: Old Name`
- TO: `### Requirement: New Name`
```

## Validation Script

Quick validation without full CLI:

```bash
python scripts/validate_spec.py openspec/changes/<change-id>/
```

Checks:
- Delta operations present
- Requirements have scenarios
- Scenarios use `#### Scenario:` format
- Normative language used

**Always run full validation before committing:**
```bash
openspec validate <change-id> --strict
```

## Resources

### scripts/
- `validate_spec.py` - Lightweight spec validation script for quick checks

### assets/
- `proposal-template.md` - Change proposal structure
- `tasks-template.md` - Implementation checklist
- `spec-delta-template.md` - Spec delta format
- `design-template.md` - Technical design doc

### references/
- `spec-format-guide.md` - Detailed formatting rules and common errors
- `cli-commands.md` - Complete CLI command reference
- `workflow-examples.md` - Real-world examples of changes

## Best Practices

1. **Check existing work first**
   - Run `openspec list --specs` before creating specs
   - Prefer modifying existing specs over creating duplicates

2. **Validate early and often**
   - Validate after writing deltas
   - Validate before requesting approval
   - Use `--strict` flag for comprehensive checks

3. **One concern per requirement**
   - Keep requirements focused
   - Split complex requirements into multiple

4. **Write testable scenarios**
   - Use specific values, not vague descriptions
   - Cover both success and error cases
   - Include edge cases

5. **MODIFIED requirements must be complete**
   - Copy entire requirement from source spec
   - Include all existing scenarios
   - Make changes to the copied text

6. **Use design.md when needed**
   - Cross-cutting changes
   - New dependencies
   - Security/performance complexity
   - Architectural decisions

## Troubleshooting

### "Change must have at least one delta"
Ensure spec files have `## ADDED|MODIFIED|REMOVED Requirements` headers.

### "Requirement must have at least one scenario"
Add at least one `#### Scenario:` (4 hashtags) per requirement.

### "Scenario not recognized"
Use exactly `#### Scenario: Name` format (not bullets, not 3 hashtags).

### "Missing normative language"
Use SHALL/MUST/SHOULD in requirement descriptions.

**For more errors and solutions, see:** `references/spec-format-guide.md` → Common Errors section

## Prerequisites

- **Node.js >= 20.19.0**
- OpenSpec CLI installed: `npm install -g @fission-ai/openspec@latest`
- Initialized project: `openspec init`

## Workflow Summary

1. **Create**: Draft proposal with deltas → Validate → Request approval
2. **Implement**: Follow tasks.md → Mark tasks complete
3. **Archive**: Merge deltas into specs → Validate

Remember: Specs are truth. Changes are proposals. Keep them in sync.
