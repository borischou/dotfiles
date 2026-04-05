# OpenSpec Spec Format Reference

This document provides detailed formatting rules for OpenSpec specification files.

## Table of Contents
1. [Delta Operations](#delta-operations)
2. [Requirement Format](#requirement-format)
3. [Scenario Format](#scenario-format)
4. [Common Errors](#common-errors)
5. [Best Practices](#best-practices)

## Delta Operations

Delta files show how specs change using four operations:

### ADDED Requirements
Use for new capabilities that can stand alone:
```markdown
## ADDED Requirements

### Requirement: Two-Factor Authentication
Users MUST provide a second factor during login.

#### Scenario: OTP required
- **WHEN** valid credentials are provided
- **THEN** an OTP challenge is required
```

### MODIFIED Requirements
Use when changing behavior of existing requirements. **Critical**: Always paste the **complete** updated requirement from `openspec/specs/<capability>/spec.md`:

```markdown
## MODIFIED Requirements

### Requirement: User Authentication
The system SHALL issue a JWT on successful login and MUST require two-factor authentication.

#### Scenario: Valid credentials with 2FA
- **WHEN** a user submits valid credentials and OTP
- **THEN** a JWT is returned

#### Scenario: Valid credentials without 2FA
- **WHEN** a user submits valid credentials without OTP
- **THEN** an OTP challenge is required
```

**Common pitfall**: Using MODIFIED to add a new concern without including previous text causes loss of detail at archive time. If not changing the existing requirement, use ADDED instead.

### REMOVED Requirements
Use when deprecating features:
```markdown
## REMOVED Requirements

### Requirement: Legacy Password Reset
**Reason**: Replaced by secure email-based reset flow
**Migration**: Users should use the new "Forgot Password" link
```

### RENAMED Requirements
Use when only the name changes:
```markdown
## RENAMED Requirements
- FROM: `### Requirement: Login`
- TO: `### Requirement: User Authentication`
```

If changing both name and behavior, use RENAMED (for name) + MODIFIED (for content, referencing the new name).

## Requirement Format

### Requirement Headers
- Use exactly 3 hashtags: `### Requirement: [Name]`
- Name should be descriptive and unique within the capability

### Requirement Text
- Use normative language: **SHALL**, **MUST**, **SHOULD**
- Be specific and testable
- Focus on behavior, not implementation

**Good examples:**
```markdown
### Requirement: Authentication Token
The system SHALL issue a JWT token valid for 24 hours.
```

```markdown
### Requirement: Rate Limiting
The API MUST reject requests exceeding 100 requests per minute per user.
```

**Bad examples:**
```markdown
### Requirement: Make it fast
The system should be performant. ❌ (Not specific or testable)
```

```markdown
### Requirement: Login
Users can login. ❌ (No normative language)
```

## Scenario Format

### Critical Rules
1. Use **exactly 4 hashtags**: `#### Scenario: [Name]`
2. Every requirement **MUST** have at least one scenario
3. Use GIVEN-WHEN-THEN or WHEN-THEN format

### GIVEN-WHEN-THEN Format
Best for scenarios with important preconditions:
```markdown
#### Scenario: Successful login
- **GIVEN** a registered user with valid credentials
- **WHEN** the user submits login form
- **THEN** a JWT token is returned
- **AND** the user is redirected to dashboard
```

### WHEN-THEN Format
Best for simple scenarios:
```markdown
#### Scenario: Invalid credentials
- **WHEN** user submits incorrect password
- **THEN** return 401 Unauthorized error
- **AND** increment failed login counter
```

### Scenario Naming
- Use descriptive names: "Successful login", "Rate limit exceeded", "Missing required field"
- Avoid vague names: "Test 1", "Happy path", "Basic case"

## Common Errors

### Error: "Requirement must have at least one scenario"
**Wrong:**
```markdown
### Requirement: User Login
The system SHALL authenticate users.

No scenario here! ❌
```

**Right:**
```markdown
### Requirement: User Login
The system SHALL authenticate users.

#### Scenario: Valid credentials
- **WHEN** valid credentials provided
- **THEN** return JWT token
```

### Error: "Scenario not recognized"
**Wrong:**
```markdown
- **Scenario: Login** ❌ (bullet point)
**Scenario**: Login ❌ (bold text)
### Scenario: Login ❌ (3 hashtags)
```

**Right:**
```markdown
#### Scenario: Login ✓ (exactly 4 hashtags)
```

### Error: "Change must have at least one delta"
Ensure your spec file has at least one of:
- `## ADDED Requirements`
- `## MODIFIED Requirements`
- `## REMOVED Requirements`
- `## RENAMED Requirements`

### Error: "Missing normative language"
**Wrong:**
```markdown
### Requirement: File Upload
The system allows file uploads. ❌
```

**Right:**
```markdown
### Requirement: File Upload
The system SHALL support file uploads up to 10MB. ✓
```

## Best Practices

### 1. One Concern Per Requirement
**Wrong:**
```markdown
### Requirement: User Management
The system SHALL support login, registration, password reset, and profile editing.
```

**Right:**
```markdown
### Requirement: User Login
The system SHALL authenticate users with email and password.

### Requirement: User Registration
The system SHALL allow new users to create accounts.
```

### 2. Testable Scenarios
Write scenarios that can be automated or manually verified:
```markdown
#### Scenario: File size validation
- **GIVEN** a 15MB file
- **WHEN** user attempts upload
- **THEN** return 400 Bad Request
- **AND** display error message "File exceeds 10MB limit"
```

### 3. Cover Edge Cases
Don't just write happy path scenarios:
```markdown
#### Scenario: Success case
- **WHEN** valid input
- **THEN** success

#### Scenario: Missing required field
- **WHEN** field is empty
- **THEN** return validation error

#### Scenario: Invalid format
- **WHEN** field has wrong format
- **THEN** return format error

#### Scenario: Duplicate entry
- **WHEN** entry already exists
- **THEN** return conflict error
```

### 4. Use Specific Values
**Vague:**
```markdown
#### Scenario: Rate limit
- **WHEN** too many requests
- **THEN** reject request
```

**Specific:**
```markdown
#### Scenario: Rate limit exceeded
- **WHEN** user exceeds 100 requests per minute
- **THEN** return 429 Too Many Requests
- **AND** include Retry-After header
```

### 5. Multi-Capability Changes
When a change affects multiple capabilities, create separate delta files:
```
openspec/changes/add-2fa/
├── proposal.md
├── tasks.md
└── specs/
    ├── auth/spec.md       # Delta for auth capability
    └── notifications/spec.md  # Delta for notifications capability
```

### 6. MODIFIED Requirements - Complete Text
When modifying a requirement:
1. Locate existing requirement in `openspec/specs/<capability>/spec.md`
2. Copy the entire requirement block
3. Paste under `## MODIFIED Requirements`
4. Make your changes to the pasted text

This ensures no information is lost when the change is archived.
