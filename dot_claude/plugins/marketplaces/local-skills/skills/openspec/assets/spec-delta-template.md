# Delta for [Capability Name]

## ADDED Requirements

### Requirement: [New Feature Name]
The system SHALL [description of what the system must do].

#### Scenario: [Success case name]
- **GIVEN** [initial state or preconditions]
- **WHEN** [user action or trigger]
- **THEN** [expected outcome]

#### Scenario: [Error case name]
- **GIVEN** [initial state]
- **WHEN** [invalid action]
- **THEN** [expected error handling]

## MODIFIED Requirements

### Requirement: [Existing Feature Name]
[Complete updated requirement text - paste the full requirement from openspec/specs/<capability>/spec.md and modify it]

The system SHALL [updated behavior description].

#### Scenario: [Updated scenario name]
- **GIVEN** [preconditions]
- **WHEN** [action]
- **THEN** [new expected outcome]

#### Scenario: [New additional scenario if needed]
- **GIVEN** [preconditions]
- **WHEN** [action]
- **THEN** [expected outcome]

## REMOVED Requirements

### Requirement: [Feature Being Removed]
**Reason**: [Why this requirement is being removed]
**Migration**: [How existing users should handle this removal]

## RENAMED Requirements

- FROM: `### Requirement: [Old Name]`
- TO: `### Requirement: [New Name]`

---

## Formatting Notes:
- Use exactly 4 hashtags (####) for scenarios
- Every requirement MUST have at least one scenario
- Use SHALL/MUST for normative requirements
- For MODIFIED, include the complete updated requirement text
- Headers are matched with whitespace trimming
