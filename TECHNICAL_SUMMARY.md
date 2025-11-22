# Happy Ecosystem Technical Summary

## System Components

### 1. happy-cli (this repository)
- **Purpose**: CLI wrapper for Claude Code enabling remote control and session sharing
- **Language**: TypeScript/Node.js
- **Key Dependencies**: @anthropic-ai/claude-code SDK, socket.io-client, tweetnacl
- **Repository**: Current working directory (fork of slopus/happy)

### 2. happy-server
- **Purpose**: Synchronization backend for E2E encrypted Claude sessions
- **Language**: TypeScript/Node.js (Fastify framework)
- **Repository**: https://github.com/slopus/happy-server
- **Hosted Instance**: https://api.happy-servers.com/

### 3. happy-mobile
- **Purpose**: React Native mobile client for iOS/Android
- **Language**: TypeScript/React Native
- **Repository**: Private (not publicly available)
- **Distribution**: App Store / TestFlight

## Architecture Overview

```
┌─────────────────┐     WebSocket/HTTPS    ┌──────────────────┐
│   Mobile App    │◄──────────────────────►│   happy-server   │
│  (React Native) │                         │   (Fastify/Node) │
└────────┬────────┘                         └──────────────────┘
         │                                            ▲
         │                                            │
         │ QR Code Auth                               │ WebSocket/HTTPS
         │ Remote Control                             │
         │                                            │
         ▼                                            │
┌─────────────────┐                                   │
│   happy-cli     │◄──────────────────────────────────┘
│  (Claude Code)  │
└─────────────────┘
```

## Communication Protocols

### Authentication Flow
1. **CLI generates ephemeral keypair** (TweetNaCl)
2. **CLI sends public key** to server: `POST /v1/auth/request`
3. **CLI displays QR code** containing: `happy://terminal?{base64_public_key}`
4. **Mobile scans QR** and sends encrypted credentials to server
5. **CLI polls server** for authorization status
6. **Server returns JWT token** and encrypted credentials
7. **CLI stores credentials** in `~/.happy/access.key`

### Session Management

#### WebSocket Connection
- **Protocol**: Socket.IO v4
- **Namespace**: `/session`
- **Authentication**: JWT token in handshake
- **Encryption**: End-to-end using TweetNaCl

#### Message Flow
```typescript
// CLI → Server → Mobile
{
  type: 'message',
  sessionId: string,
  content: encrypted_bytes, // E2E encrypted
  metadata: {
    timestamp: number,
    messageId: string
  }
}
```

#### RPC Handlers
- CLI registers handlers via `ApiSession.registerRPCHandler()`
- Mobile invokes via WebSocket events
- Common RPCs: permission requests, file operations, command execution

### Key API Endpoints

#### Authentication
- `POST /v1/auth/request` - Initialize auth flow
- `POST /v1/auth/challenge` - Challenge-response auth
- `DELETE /v1/auth/revoke` - Revoke tokens

#### Sessions
- `POST /v1/session` - Create encrypted session
- `GET /v1/session/:id` - Get session metadata
- `DELETE /v1/session/:id` - Delete session
- `GET /v1/session/:id/messages` - Get message history

#### Machines (CLI Instances)
- `POST /v1/machine` - Register CLI instance
- `GET /v1/machine` - List registered machines
- `DELETE /v1/machine/:id` - Unregister machine

#### Voice (Token Broker Only)
- `POST /v1/voice/token` - Get ElevenLabs conversation token
  - Request: `{ agentId: string, revenueCatPublicKey?: string }`
  - Response: `{ allowed: boolean, token?: string, error?: string }`

## Data Encryption

### Encryption Types

#### Legacy Mode
- **Secret**: 32-byte shared secret
- **Method**: Symmetric encryption using TweetNaCl secretbox
- **Storage**: Direct secret storage

#### DataKey Mode
- **Public Key**: Account public key
- **Machine Key**: Device-specific 32-byte key
- **Method**: Asymmetric + symmetric hybrid
- **Storage**: Separate key storage

### Encryption Flow
1. **Message creation**: Plaintext → TweetNaCl box/secretbox → Base64
2. **Transmission**: Encrypted payload sent via WebSocket
3. **Reception**: Base64 → TweetNaCl unbox → Plaintext
4. **Storage**: Server stores encrypted blobs (zero-knowledge)

## Voice Feature Architecture

### Current Implementation
- **Server Role**: Token broker only (no audio processing)
- **Voice Provider**: ElevenLabs API
- **Audio Flow**: Mobile ↔ ElevenLabs (direct, no server relay)
- **Subscription**: RevenueCat validation (production only)

### Voice Flow
1. Mobile requests token: `POST /v1/voice/token`
2. Server validates subscription (if production)
3. Server fetches token from ElevenLabs API
4. Server returns token to mobile
5. Mobile establishes direct connection to ElevenLabs
6. All audio processing happens client-side + ElevenLabs

### Voice Issue (Current)
- **Symptom**: Voice recognition not working on mobile
- **Timeline**: Started recently, mobile app unchanged for 1 month
- **Hypothesis**: Server-side change (Sept 8 commit added RevenueCat paywall)
- **Potential Causes**:
  - Subscription validation failing
  - ElevenLabs API key expired/rate-limited
  - Token endpoint returning errors

## Self-Hosting Requirements

### Infrastructure
```yaml
services:
  postgresql:
    version: 17
    port: 5432
    purpose: Primary data store

  redis:
    version: 7-alpine
    port: 6379
    purpose: Socket.IO adapter, pub/sub

  minio:
    port: 9000
    purpose: S3-compatible object storage
    alternative: Any S3 API (AWS, DigitalOcean)
```

### Environment Variables
```bash
# Core
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://localhost:6379
MASTER_SECRET=random_string

# S3 Storage
S3_ENDPOINT=localhost
S3_PORT=9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_BUCKET=happy

# Voice (Required for voice features)
ELEVENLABS_API_KEY=sk_...

# Development Mode (bypasses RevenueCat)
NODE_ENV=development
```

### Database Schema (Prisma)
```prisma
model Account {
  id            String @id
  publicKey     String @unique
  sessions      Session[]
  machines      Machine[]
  // ... social features
}

model Session {
  id            String @id
  accountId     String
  messages      SessionMessage[]
  encrypted     Boolean
  // ... metadata
}

model SessionMessage {
  id            String @id
  sessionId     String
  content       Bytes // Encrypted
  timestamp     DateTime
  // ... tracking fields
}

model Machine {
  id            String @id
  accountId     String
  name          String
  // ... device info
}
```

## CLI Operation Modes

### Interactive Mode
- **Process**: Spawns `claude` process via PTY
- **Monitoring**: File watcher on `~/.claude/projects/*/SESSION_ID.jsonl`
- **Message Capture**: Parses JSONL stream, sends to server
- **Limitations**: OS-specific PTY handling

### Remote Mode (SDK)
- **Integration**: Direct `@anthropic-ai/claude-code` SDK usage
- **Message Flow**: Mobile → Server → SDK → Server → Mobile
- **Advantages**: Cross-platform, cleaner integration
- **Status**: Primary mode for remote control

### Daemon Mode
- **Purpose**: Background service for persistent connection
- **Commands**: `happy daemon start/stop/status`
- **Logs**: `~/.happy-dev/logs/TIMESTAMP-daemon.log`
- **Auto-start**: Can be configured as system service

## MCP Permission Integration
- **Protocol**: Model Context Protocol
- **Server**: `src/claude/mcp/startPermissionServer.ts`
- **Purpose**: Intercept and approve/deny tool use requests
- **Flow**: Claude → MCP → Mobile → User → Mobile → MCP → Claude
- **Status**: Partially implemented

## Critical Files Reference

### happy-cli
- `src/api/api.ts` - Server communication client
- `src/api/apiSession.ts` - WebSocket session management
- `src/api/encryption.ts` - E2E encryption utilities
- `src/claude/loop.ts` - Main control loop
- `src/claude/claudeSdk.ts` - SDK integration
- `src/ui/auth.ts` - Authentication flow UI

### happy-server
- `sources/app/api/routes/voiceRoutes.ts` - Voice token endpoint
- `sources/app/api/routes/sessionRoutes.ts` - Session management
- `sources/app/auth/auth.ts` - Authentication logic
- `sources/app/socket/sessionSocket.ts` - WebSocket handlers
- `sources/storage/encrypt.ts` - Server-side encryption

## Key Differences from Original Repository
- **Binary name**: `happy-next` instead of `happy`
- **Package name**: `@happy-sdk/cli-next`
- **Preview publishing**: Automated via GitHub Actions
- **Fork status**: User fork with custom modifications

## External Dependencies

### Required Services
- **ElevenLabs**: Voice conversations (no self-host alternative)
- **RevenueCat**: Subscription management (can bypass in dev mode)

### Optional Services
- **GitHub OAuth**: Social authentication
- **Prometheus**: Metrics collection
- **Grafana**: Metrics visualization

## Security Model
- **Zero-knowledge**: Server cannot decrypt user data
- **E2E Encryption**: All messages encrypted client-side
- **No passwords**: Challenge-response authentication only
- **Device-specific keys**: Each CLI instance has unique keys
- **Session isolation**: Messages bound to specific sessions

## Recent Modifications (happy-next fork)
- Fixed first message handling bug in codex module
- Automated preview publishing workflow
- Fixed CI/smoke test failures for fork naming
- Improved Claude response handling for title setting