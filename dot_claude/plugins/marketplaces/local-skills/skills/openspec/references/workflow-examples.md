# OpenSpec Workflow Examples

Real-world examples of creating and implementing OpenSpec changes.

## Table of Contents
1. [Simple Feature Addition](#simple-feature-addition)
2. [Multi-Capability Change](#multi-capability-change)
3. [Breaking Change with Migration](#breaking-change-with-migration)
4. [Modifying Existing Behavior](#modifying-existing-behavior)
5. [Architectural Change](#architectural-change)

## Simple Feature Addition

### Scenario
Add password reset functionality to an authentication system.

### Change Structure
```
openspec/changes/add-password-reset/
├── proposal.md
├── tasks.md
└── specs/
    └── auth/
        └── spec.md
```

### proposal.md
```markdown
# Change: Add Password Reset

## Why
Users currently cannot reset forgotten passwords, requiring manual admin intervention.

## What Changes
- Add password reset request endpoint
- Add password reset confirmation endpoint
- Add email notification for reset requests

## Impact
- Affected specs: auth
- Affected code: auth-service, email-service
- Migration needed: No
```

### tasks.md
```markdown
## 1. Backend Implementation
- [ ] 1.1 Add reset token generation logic
- [ ] 1.2 Create POST /auth/password-reset-request endpoint
- [ ] 1.3 Create POST /auth/password-reset-confirm endpoint
- [ ] 1.4 Add reset token validation

## 2. Email Integration
- [ ] 2.1 Create password reset email template
- [ ] 2.2 Integrate with email service

## 3. Testing
- [ ] 3.1 Unit tests for token generation/validation
- [ ] 3.2 Integration tests for endpoints
- [ ] 3.3 Manual testing of email delivery
```

### specs/auth/spec.md
```markdown
# Delta for Auth

## ADDED Requirements

### Requirement: Password Reset Request
The system SHALL allow users to request a password reset via email.

#### Scenario: Valid email
- **GIVEN** a registered user email
- **WHEN** user requests password reset
- **THEN** send email with reset link valid for 1 hour
- **AND** return 200 OK

#### Scenario: Unregistered email
- **WHEN** user requests reset for non-existent email
- **THEN** return 200 OK (prevent email enumeration)
- **AND** do not send email

### Requirement: Password Reset Confirmation
The system SHALL allow users to set a new password using a valid reset token.

#### Scenario: Valid token
- **GIVEN** a valid unexpired reset token
- **WHEN** user submits new password
- **THEN** update user password
- **AND** invalidate reset token
- **AND** return 200 OK

#### Scenario: Expired token
- **GIVEN** an expired reset token
- **WHEN** user submits new password
- **THEN** return 401 Unauthorized
- **AND** require new reset request
```

## Multi-Capability Change

### Scenario
Add two-factor authentication that affects both authentication and notifications.

### Change Structure
```
openspec/changes/add-2fa/
├── proposal.md
├── tasks.md
└── specs/
    ├── auth/
    │   └── spec.md
    └── notifications/
        └── spec.md
```

### proposal.md
```markdown
# Change: Add Two-Factor Authentication

## Why
Enhance security by requiring a second factor during login.

## What Changes
- Add OTP generation and validation to auth flow
- Add SMS/email notifications for OTP delivery
- Add user settings for enabling/disabling 2FA

## Impact
- Affected specs: auth, notifications
- Affected code: auth-service, notification-service, user-settings-ui
- Migration needed: No (opt-in feature)
```

### specs/auth/spec.md
```markdown
# Delta for Auth

## ADDED Requirements

### Requirement: Two-Factor Authentication
The system MUST require a second factor during login when 2FA is enabled.

#### Scenario: 2FA enabled user login
- **GIVEN** user has 2FA enabled
- **WHEN** user submits valid credentials
- **THEN** generate and send OTP
- **AND** require OTP verification before issuing JWT

#### Scenario: 2FA disabled user login
- **GIVEN** user has 2FA disabled
- **WHEN** user submits valid credentials
- **THEN** issue JWT without OTP challenge
```

### specs/notifications/spec.md
```markdown
# Delta for Notifications

## ADDED Requirements

### Requirement: OTP Delivery
The system SHALL deliver OTP codes via SMS or email based on user preference.

#### Scenario: SMS delivery
- **GIVEN** user prefers SMS
- **WHEN** OTP is generated
- **THEN** send 6-digit code via SMS
- **AND** code expires in 5 minutes

#### Scenario: Email delivery
- **GIVEN** user prefers email
- **WHEN** OTP is generated
- **THEN** send 6-digit code via email
- **AND** code expires in 5 minutes
```

## Breaking Change with Migration

### Scenario
Update API authentication from API keys to JWT tokens (breaking change).

### Change Structure
```
openspec/changes/update-auth-to-jwt/
├── proposal.md
├── tasks.md
├── design.md
└── specs/
    └── auth/
        └── spec.md
```

### proposal.md
```markdown
# Change: Migrate to JWT Authentication

## Why
Current API key system lacks expiration and fine-grained permissions.

## What Changes
- **BREAKING**: Replace API key auth with JWT tokens
- Add token refresh mechanism
- Deprecate API key endpoints

## Impact
- Affected specs: auth
- Affected code: auth-service, all API endpoints
- Migration needed: Yes - clients must obtain JWT tokens
```

### design.md
```markdown
# Design: JWT Migration

## Context
Current API key system has no expiration, making key rotation difficult and security incidents harder to contain.

## Goals / Non-Goals

**Goals:**
- Replace API keys with short-lived JWT tokens
- Provide seamless migration path for existing clients

**Non-Goals:**
- Changing authorization/permissions system
- Modifying client authentication UI

## Decisions

### Decision 1: Dual authentication support during migration
**Choice**: Support both API keys and JWT for 3 months
**Rationale**: Allow gradual client migration
**Alternatives considered**:
- Immediate cutover - Rejected due to client coordination complexity

### Decision 2: Token expiration
**Choice**: 1-hour access tokens, 30-day refresh tokens
**Rationale**: Balance security with user experience

## Migration Plan
1. Month 1: Deploy JWT support, announce deprecation
2. Month 2: Notify remaining API key users
3. Month 3: Disable API key authentication
4. Rollback: Re-enable API key endpoints if >50% users not migrated
```

### specs/auth/spec.md
```markdown
# Delta for Auth

## MODIFIED Requirements

### Requirement: API Authentication
The system SHALL authenticate API requests using JWT tokens with Bearer scheme.

#### Scenario: Valid JWT token
- **WHEN** request includes valid JWT in Authorization header
- **THEN** authenticate request
- **AND** proceed to authorization check

#### Scenario: Expired JWT token
- **WHEN** request includes expired JWT
- **THEN** return 401 Unauthorized
- **AND** require token refresh

#### Scenario: Missing token
- **WHEN** request has no Authorization header
- **THEN** return 401 Unauthorized

## ADDED Requirements

### Requirement: Token Refresh
The system SHALL allow clients to refresh access tokens using refresh tokens.

#### Scenario: Valid refresh token
- **GIVEN** a valid unexpired refresh token
- **WHEN** client requests token refresh
- **THEN** issue new access token
- **AND** issue new refresh token
- **AND** invalidate old refresh token

## REMOVED Requirements

### Requirement: API Key Authentication
**Reason**: Replaced by JWT token authentication for better security
**Migration**: Clients must obtain JWT tokens via POST /auth/login
```

## Modifying Existing Behavior

### Scenario
Update rate limiting from 100 to 1000 requests per minute.

### specs/rate-limiting/spec.md
```markdown
# Delta for Rate Limiting

## MODIFIED Requirements

### Requirement: API Rate Limiting
The API MUST reject requests exceeding 1000 requests per minute per user.

#### Scenario: Within rate limit
- **GIVEN** user has made 500 requests in current minute
- **WHEN** user makes another request
- **THEN** process request normally

#### Scenario: Rate limit exceeded
- **GIVEN** user has made 1000 requests in current minute
- **WHEN** user makes another request
- **THEN** return 429 Too Many Requests
- **AND** include Retry-After header
- **AND** include X-RateLimit-Reset header

#### Scenario: Rate limit reset
- **WHEN** new minute begins
- **THEN** reset user's request counter to 0
```

**Important**: This shows the complete updated requirement text, not just the changed parts.

## Architectural Change

### Scenario
Introduce caching layer for frequently accessed data.

### Change Structure
```
openspec/changes/add-caching-layer/
├── proposal.md
├── tasks.md
├── design.md
└── specs/
    ├── caching/
    │   └── spec.md
    └── data-access/
        └── spec.md
```

### design.md
```markdown
# Design: Caching Layer

## Context
Database queries for product catalog are causing slow page loads (>2s average).

## Goals / Non-Goals

**Goals:**
- Reduce product catalog query latency to <200ms
- Cache frequently accessed product data

**Non-Goals:**
- Caching user-specific data
- Distributed caching (single instance sufficient for current scale)

## Decisions

### Decision 1: Cache technology
**Choice**: Redis for in-memory caching
**Rationale**: Fast, simple, mature
**Alternatives considered**:
- Memcached: No data persistence
- Application memory: Doesn't survive restarts

### Decision 2: Cache invalidation
**Choice**: TTL-based (5 minutes) + manual invalidation on updates
**Rationale**: Simple and sufficient for product data update frequency

## Risks / Trade-offs
- **Risk**: Stale data for up to 5 minutes → **Mitigation**: Acceptable for product catalog
- **Trade-off**: Additional Redis dependency → **Justification**: Performance gain worth the complexity
```

### specs/caching/spec.md
```markdown
# Caching Specification

## Purpose
In-memory caching for frequently accessed data.

## ADDED Requirements

### Requirement: Cache Storage
The system SHALL store cached data in Redis with configurable TTL.

#### Scenario: Cache write
- **WHEN** data is added to cache
- **THEN** store in Redis with 5-minute TTL
- **AND** serialize data as JSON

### Requirement: Cache Retrieval
The system SHALL return cached data when available.

#### Scenario: Cache hit
- **GIVEN** valid cached data exists
- **WHEN** data is requested
- **THEN** return cached data
- **AND** do not query database

#### Scenario: Cache miss
- **GIVEN** no cached data exists
- **WHEN** data is requested
- **THEN** query database
- **AND** populate cache
- **AND** return data
```

### specs/data-access/spec.md
```markdown
# Delta for Data Access

## MODIFIED Requirements

### Requirement: Product Catalog Query
The system SHALL query product catalog data with caching support.

#### Scenario: Cached product data
- **WHEN** product catalog is requested
- **THEN** check cache first
- **AND** return cached data if available
- **AND** query database only on cache miss

#### Scenario: Product data update
- **WHEN** product data is updated
- **THEN** update database
- **AND** invalidate related cache entries
```

## Summary

These examples demonstrate:
1. **Simple changes**: Single capability, straightforward additions
2. **Multi-capability changes**: Coordinated updates across specs
3. **Breaking changes**: Design docs, migration plans
4. **Modifications**: Complete updated requirement text
5. **Architectural changes**: Design docs for technical decisions

Key patterns:
- Proposal explains "why" and "what"
- Tasks provide implementation checklist
- Spec deltas show precise behavior changes
- Design docs capture complex technical decisions
- Every requirement has testable scenarios
