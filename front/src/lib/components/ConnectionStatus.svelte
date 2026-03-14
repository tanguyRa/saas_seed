<script lang="ts">
    import type { ConnectionState } from '$lib/services/terminalSocket';
    import Spinner from './Spinner.svelte';

    interface Props {
        state: ConnectionState;
        error?: string;
        reconnectAttempt?: number;
        reconnectDelay?: number;
        onReconnect: () => void;
    }

    let { state, error, reconnectAttempt, reconnectDelay, onReconnect }: Props = $props();

    const isVisible = $derived(state !== 'connected' && state !== 'idle');
</script>

<div class="connection-status" class:visible={isVisible}>
    {#if state === 'connecting'}
        <div class="status-content connecting">
            <Spinner size="small" />
            <span>Connecting to environment...</span>
        </div>
    {:else if state === 'disconnected'}
        <div class="status-content disconnected">
            <span class="dot"></span>
            {#if reconnectAttempt && reconnectAttempt > 0}
                <span>Reconnecting... (attempt {reconnectAttempt}/5)</span>
            {:else}
                <span>Disconnected</span>
                <button class="reconnect-btn" onclick={onReconnect}>Reconnect</button>
            {/if}
        </div>
    {:else if state === 'error'}
        <div class="status-content error">
            <span class="dot"></span>
            <span>{error || 'Connection error'}</span>
            <button class="reconnect-btn" onclick={onReconnect}>Retry</button>
        </div>
    {/if}
</div>

{#if state === 'connected'}
    <div class="connected-indicator" title="Connected">
        <span class="dot connected"></span>
    </div>
{/if}

<style>
    .connection-status {
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        background: var(--color-deep-92);
        border-bottom: 1px solid var(--color-border-strong);
        padding: 12px 16px;
        opacity: 0;
        transform: translateY(-100%);
        transition: opacity 0.2s ease, transform 0.2s ease;
        z-index: 10;
    }

    .connection-status.visible {
        opacity: 1;
        transform: translateY(0);
    }

    .status-content {
        display: flex;
        align-items: center;
        gap: 10px;
        color: var(--color-text-75);
        font-size: 14px;
        font-family: var(--font-mono);
    }

    .dot {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        flex-shrink: 0;
    }

    .disconnected .dot {
        background: var(--color-warning);
    }

    .error .dot {
        background: var(--color-danger);
    }

    .connected-indicator .dot {
        background: var(--color-success);
        animation: pulse-green 2s ease-in-out infinite;
    }

    @keyframes pulse-green {
        0%, 100% {
            opacity: 1;
        }
        50% {
            opacity: 0.5;
        }
    }

    .reconnect-btn {
        margin-left: auto;
        padding: 6px 14px;
        background: var(--color-deep);
        border: 1px solid var(--color-border-strong);
        border-radius: 6px;
        color: var(--color-text-75);
        font-size: 13px;
        font-family: inherit;
        cursor: pointer;
        transition: background 0.15s ease, border-color 0.15s ease;
    }

    .reconnect-btn:hover {
        background: var(--color-ink-soft);
        border-color: var(--color-border);
    }

    .connected-indicator {
        position: absolute;
        top: 12px;
        right: 12px;
        z-index: 10;
    }
</style>
