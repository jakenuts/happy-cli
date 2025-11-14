# Happy CLI - Technical Architecture Documentation

## System Overview

Happy CLI is a command-line wrapper for Claude Code and OpenAI Codex CLI that enables remote control via mobile app and session sharing. It consists of three components:

1. **handy-cli** (this project) - CLI wrapper
2. **handy** - React Native mobile client
3. **handy-server** - Node.js server at https://api.happy-servers.com/

## Agent Integration Architecture

### Supported Agents

- **Claude Code**: Integrated via `@anthropic-ai/claude-code` SDK
- **OpenAI Codex**: Integrated via Model Context Protocol (MCP) subprocess

### Agent Communication Flow

```
Mobile App (user input)
  ↓ WebSocket (encrypted)
Server
  ↓ WebSocket 'update' event
ApiSessionClient
  ↓ onUserMessage callback
MessageQueue
  ↓ batch processing
Agent MCP Client (Claude/Codex)
  ↓ MCP tool calls (startSession/continueSession)
Agent subprocess
  ↓ MCP event notifications
Message handlers
  ↓ sendCodexMessage/sendClaudeSessionMessage
Server
  ↓ WebSocket broadcast
Mobile App
```

## Critical Components

### /src/api/apiSession.ts - WebSocket Session Client

**Purpose**: Manages WebSocket connection to server with end-to-end encryption

**Key Features**:
- Lazy connection via `ensureConnected()` to prevent race conditions
- E2E encryption using TweetNaCl (NaCl crypto library)
- Optimistic concurrency control for metadata/state updates
- RPC handler registration for bidirectional communication
- Message queue buffering during initialization

**Connection Lifecycle**:
1. Constructor creates socket with `autoConnect: false`
2. Registers event handlers for 'update', 'connect', 'disconnect'
3. `onUserMessage(callback)` sets callback and calls `ensureConnected()`
4. `ensureConnected()` initiates connection, returns Promise
5. Socket 'connect' event resolves promise
6. Messages flow directly to registered callback

**Race Condition Prevention**:
- Old behavior: Socket connected immediately in constructor → messages arrived before callback set
- New behavior: Connection deferred until `onUserMessage()` called → callback registered BEFORE connect

### /src/codex/codexMcpClient.ts - Codex MCP Integration

**Purpose**: Wrapper for Codex CLI via Model Context Protocol (stdio transport)

**Key Features**:
- Spawns Codex as subprocess using `StdioClientTransport`
- Bidirectional MCP communication over stdio
- Session ID extraction and tracking
- Permission request handling via `ElicitRequestSchema`
- Windows console window hiding workaround

**Windows-Specific Issue**:
- MCP SDK only sets `windowsHide: true` when `isElectron()` returns true
- Workaround: Temporarily set `process.type` during transport creation
- Result: Prevents visible CMD windows on Windows platforms

**Session Management**:
- `startSession(config)` - Creates new Codex session via 'codex' tool
- `continueSession(prompt)` - Continues existing session via 'codex-reply' tool
- `sessionId` and `conversationId` extracted from MCP responses
- Session persistence for resume functionality

**Permission Flow**:
1. Codex requests permission via MCP `ElicitRequestSchema`
2. CodexMcpClient receives request in `setRequestHandler`
3. Delegates to `CodexPermissionHandler.handleToolCall()`
4. Handler sends RPC request to mobile app
5. Mobile app responds with approval/denial
6. Response returned to Codex via MCP

### /src/codex/runCodex.ts - Codex Runtime Orchestrator

**Purpose**: Main entry point for Codex agent mode, coordinates all Codex operations

**Key Components**:
- `MessageQueue2`: Batches user messages with mode tracking (normal/direct/plan/edit)
- `MessageBuffer`: Accumulates Codex output for streaming to mobile
- `CodexMcpClient`: MCP communication with Codex subprocess
- `CodexPermissionHandler`: Handles tool approval requests via RPC
- `ApiSessionClient`: Server communication and encryption

**Message Flow**:
1. `session.onUserMessage()` callback pushes to `messageQueue`
2. Main loop calls `messageQueue.waitForMessagesAndGetAsString()`
3. Batched messages sent to Codex via `client.startSession()` or `continueSession()`
4. Codex events flow through MCP to `client.setHandler()`
5. Handler processes events, updates `messageBuffer`
6. Buffer periodically flushed to server via `session.sendCodexMessage()`

**Session State Management**:
- `wasCreated`: Tracks if session was successfully created
- `storedSessionIdForResume`: Preserved session ID for crash recovery
- `currentModeHash`: Detects mode changes requiring session restart
- Resume logic: On abort/error, stores session ID for next message continuation

**Abort Handling**:
- AbortController signal passed to MCP tool calls
- On abort: Stores session ID, marks `wasCreated = false`
- Next message resumes from stored session instead of creating new one

### /src/codex/utils/permissionHandler.ts - Permission RPC Handler

**Purpose**: Bridges Codex permission requests to mobile app via RPC

**Flow**:
1. `handleToolCall(callId, toolName, args)` called by CodexMcpClient
2. Creates pending request entry in Map
3. Sends RPC request via `rpcManager.sendRequest('tool-approval-request')`
4. Waits for RPC response callback
5. Returns `{ decision: 'approved' | 'denied' }` to Codex
6. Updates agent state with permission status

**Issue**: No timeout on permission requests - will hang indefinitely if mobile doesn't respond

### /src/api/encryption.ts - E2E Encryption

**Purpose**: Encrypt all data before sending to server using TweetNaCl

**Encryption Variants**:
- `legacy`: Uses session's encryption key directly (backward compatibility)
- `dataKey`: Derives per-message key from base key + nonce (more secure)

**Key Operations**:
- `encrypt(key, variant, data)`: Encrypts JSON object → Uint8Array
- `decrypt(key, variant, encrypted)`: Decrypts Uint8Array → JSON object
- All messages encrypted before `socket.emit('message', ...)`
- All incoming messages decrypted in 'update' event handler

## Identified Issues & Fixes

### Issue #1: Windows Console Windows (FIXED)
**Cause**: MCP SDK only enables `windowsHide` when running in Electron
**Impact**: Visible CMD window appears for every Codex interaction on Windows
**Fix**: Temporarily set `process.type` to trick SDK into enabling windowsHide
**Location**: `/src/codex/codexMcpClient.ts:90-126`
**Status**: ✅ Committed (3ce58f6)

### Issue #2: Missed First Messages (FIXED)
**Cause**: WebSocket connected before `onUserMessage()` callback registered
**Impact**: First user message lost in race condition
**Fix**: Defer connection until `onUserMessage()` called, await connection
**Location**: `/src/api/apiSession.ts:161-209`
**Status**: ✅ Committed (f8a1fc2)

### Issue #3: Agent Disconnection/Offline
**Cause**: No subprocess health monitoring, no reconnection logic
**Impact**: Codex crashes silently, agent appears offline
**Fix Needed**:
- Add heartbeat mechanism to detect subprocess death
- Implement exponential backoff retry on MCP connection failure
- Monitor subprocess exit events, auto-restart
**Location**: `/src/codex/codexMcpClient.ts`, `/src/codex/runCodex.ts`
**Status**: ⏳ Pending

### Issue #4: Message Queue Timing
**Cause**: 400+ lines between callback registration and processing loop start
**Impact**: Messages queued but not processed immediately
**Fix Needed**:
- Start message processing loop immediately after `onUserMessage()`
- Reduce initialization gap between callback and loop
**Location**: `/src/codex/runCodex.ts:148-565`
**Status**: ⏳ Pending

### Issue #5: Missing Timeouts
**Cause**: No timeouts on MCP operations or permission requests
**Impact**: Operations hang indefinitely on failure
**Fix Needed**:
- Reduce MCP timeout from 14 days to reasonable value (e.g., 30s)
- Add timeout to permission handler RPC calls
- Add timeout to WebSocket operations
**Location**: Multiple files
**Status**: ⏳ Pending

## Code Patterns

### Error Handling
- Try-catch blocks with specific error logging
- AbortController for cancellable operations
- Exponential backoff for retryable operations (metadata/state updates)

### Logging
- All debugging via file logs (`~/.happy-dev/logs/`)
- Prevents interference with agent terminal UI
- `logger.debug()` for standard logs
- `logger.debugLargeJson()` for objects (auto-truncates)

### Type Safety
- Zod schemas for runtime validation (`UserMessageSchema`, etc.)
- Explicit TypeScript types throughout
- No `any` types except in MCP SDK interfaces

### Async Patterns
- Promise-based async/await throughout
- Lock mechanisms for concurrent state updates (`AsyncLock`)
- Fire-and-forget for non-critical operations (notifications)

## Testing

### Test Structure
- Unit tests using Vitest
- Tests colocated with source (`.test.ts`)
- No mocking - tests make real API calls
- Test authentication flow, encryption, session management

### Running Tests
```bash
npm test
```

## Build & Deployment

### Build Process
```bash
npm run build
# Uses pkgroll to bundle TypeScript
# Output: dist/ directory
```

### Entry Points
- CLI: `bin/happy.mjs`
- Daemon: Spawns via `src/daemon/run.ts`
- Codex: `src/codex/runCodex.ts`
- Claude: `src/claude/runClaude.ts`

## Future Improvements

1. **Upstream MCP SDK Fix**: Submit PR to always hide windows on Windows
2. **Heartbeat Implementation**: Monitor agent subprocess health
3. **Retry Logic**: Exponential backoff for failed agent connections
4. **Timeout Configuration**: Configurable timeouts for all operations
5. **Connection Pooling**: Reuse WebSocket connections across sessions
6. **Structured Logging**: JSON-formatted logs for better parsing

## Debug Tips

### Enable Debug Logging
```bash
DEBUG=1 happy codex
```

### View Logs
```bash
tail -f ~/.happy-dev/logs/$(ls -t ~/.happy-dev/logs/ | head -1)
```

### Check Daemon Status
```bash
happy daemon status
```

### Kill Stuck Sessions
```bash
# Find process
ps aux | grep codex
# Kill by PID
kill -9 <PID>
```
