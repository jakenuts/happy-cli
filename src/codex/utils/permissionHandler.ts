/**
 * Permission Handler for Codex tool approval integration
 * 
 * Handles tool permission requests and responses for Codex sessions.
 * Simpler than Claude's permission handler since we get tool IDs directly.
 */

import { logger } from "@/ui/logger";
import { ApiSessionClient } from "@/api/apiSession";
import { AgentState } from "@/api/types";

// Timeout for permission requests - 2 minutes should be enough for user to respond
const PERMISSION_TIMEOUT = 2 * 60 * 1000; // 2 minutes

interface PermissionResponse {
    id: string;
    approved: boolean;
    decision?: 'approved' | 'approved_for_session' | 'denied' | 'abort';
}

interface PendingRequest {
    resolve: (value: PermissionResult) => void;
    reject: (error: Error) => void;
    toolName: string;
    input: unknown;
    timeoutId: NodeJS.Timeout;
}

interface PermissionResult {
    decision: 'approved' | 'approved_for_session' | 'denied' | 'abort';
}

export class CodexPermissionHandler {
    private pendingRequests = new Map<string, PendingRequest>();
    private session: ApiSessionClient;

    constructor(session: ApiSessionClient) {
        this.session = session;
        this.setupRpcHandler();
    }

    /**
     * Handle a tool permission request
     * @param toolCallId - The unique ID of the tool call
     * @param toolName - The name of the tool being called
     * @param input - The input parameters for the tool
     * @returns Promise resolving to permission result
     */
    async handleToolCall(
        toolCallId: string,
        toolName: string,
        input: unknown
    ): Promise<PermissionResult> {
        return new Promise<PermissionResult>((resolve, reject) => {
            // Set timeout for permission request
            const timeoutId = setTimeout(() => {
                const pending = this.pendingRequests.get(toolCallId);
                if (pending) {
                    this.pendingRequests.delete(toolCallId);
                    logger.warn(`[Codex] Permission request timed out for ${toolName} (${toolCallId})`);

                    // Update agent state to mark as timed out
                    this.session.updateAgentState((currentState) => {
                        const request = currentState.requests?.[toolCallId];
                        if (!request) return currentState;

                        const { [toolCallId]: _, ...remainingRequests } = currentState.requests || {};
                        return {
                            ...currentState,
                            requests: remainingRequests,
                            completedRequests: {
                                ...currentState.completedRequests,
                                [toolCallId]: {
                                    ...request,
                                    completedAt: Date.now(),
                                    status: 'canceled',
                                    reason: 'Permission request timed out'
                                }
                            }
                        };
                    });

                    reject(new Error(`Permission request timed out after ${PERMISSION_TIMEOUT / 1000}s`));
                }
            }, PERMISSION_TIMEOUT);

            // Store the pending request
            this.pendingRequests.set(toolCallId, {
                resolve,
                reject,
                toolName,
                input,
                timeoutId
            });

            // Send push notification
            // this.session.api.push().sendToAllDevices(
            //     'Permission Request',
            //     `Codex wants to use ${toolName}`,
            //     {
            //         sessionId: this.session.sessionId,
            //         requestId: toolCallId,
            //         tool: toolName,
            //         type: 'permission_request'
            //     }
            // );

            // Update agent state with pending request
            this.session.updateAgentState((currentState) => ({
                ...currentState,
                requests: {
                    ...currentState.requests,
                    [toolCallId]: {
                        tool: toolName,
                        arguments: input,
                        createdAt: Date.now()
                    }
                }
            }));

            logger.debug(`[Codex] Permission request sent for tool: ${toolName} (${toolCallId})`);
        });
    }

    /**
     * Setup RPC handler for permission responses
     */
    private setupRpcHandler(): void {
        this.session.rpcHandlerManager.registerHandler<PermissionResponse, void>(
            'permission',
            async (response) => {
                // console.log(`[Codex] Permission response received:`, response);

                const pending = this.pendingRequests.get(response.id);
                if (!pending) {
                    logger.debug('[Codex] Permission request not found or already resolved');
                    return;
                }

                // Clear the timeout
                clearTimeout(pending.timeoutId);

                // Remove from pending
                this.pendingRequests.delete(response.id);

                // Resolve the permission request
                const result: PermissionResult = response.approved
                    ? { decision: response.decision === 'approved_for_session' ? 'approved_for_session' : 'approved' }
                    : { decision: response.decision === 'denied' ? 'denied' : 'abort' };

                pending.resolve(result);

                // Move request to completed in agent state
                this.session.updateAgentState((currentState) => {
                    const request = currentState.requests?.[response.id];
                    if (!request) return currentState;

                    // console.log(`[Codex] Permission ${response.approved ? 'approved' : 'denied'} for ${pending.toolName}`);

                    const { [response.id]: _, ...remainingRequests } = currentState.requests || {};

                    let res = {
                        ...currentState,
                        requests: remainingRequests,
                        completedRequests: {
                            ...currentState.completedRequests,
                            [response.id]: {
                                ...request,
                                completedAt: Date.now(),
                                status: response.approved ? 'approved' : 'denied',
                                decision: result.decision
                            }
                        }
                    } satisfies AgentState;
                    // console.log(`[Codex] Updated agent state:`, res);
                    return res;
                });

                logger.debug(`[Codex] Permission ${response.approved ? 'approved' : 'denied'} for ${pending.toolName}`);
            }
        );
    }

    /**
     * Reset state for new sessions
     */
    reset(): void {
        // Reject all pending requests and clear timeouts
        for (const [id, pending] of this.pendingRequests.entries()) {
            clearTimeout(pending.timeoutId);
            pending.reject(new Error('Session reset'));
        }
        this.pendingRequests.clear();

        // Clear requests in agent state
        this.session.updateAgentState((currentState) => {
            const pendingRequests = currentState.requests || {};
            const completedRequests = { ...currentState.completedRequests };

            // Move all pending to completed as canceled
            for (const [id, request] of Object.entries(pendingRequests)) {
                completedRequests[id] = {
                    ...request,
                    completedAt: Date.now(),
                    status: 'canceled',
                    reason: 'Session reset'
                };
            }

            return {
                ...currentState,
                requests: {},
                completedRequests
            };
        });

        logger.debug('[Codex] Permission handler reset');
    }
}