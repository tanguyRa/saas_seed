<script lang="ts">
	import { signIn } from '$lib/auth-client';
	import { goto } from '$app/navigation';

	let email = $state('');
	let password = $state('');
	let error = $state('');
	let loading = $state(false);

	async function handleSubmit(e: Event) {
		e.preventDefault();
		error = '';
		loading = true;

		try {
			const result = await signIn.email({
				email,
				password
			});

			if (result.error) {
				error = result.error.message || 'Login failed';
			} else {
				goto('/app');
			}
		} catch (err) {
			error = 'An unexpected error occurred';
		} finally {
			loading = false;
		}
	}
</script>

<div class="auth-header">
	<a href="/" class="auth-logo">SaaS Seed</a>
	<div>
		<h1>Sign in</h1>
		<p class="auth-subtitle">Access your workspace</p>
	</div>
</div>

{#if error}
	<div class="auth-error">{error}</div>
{/if}

<form onsubmit={handleSubmit}>
	<div class="form-group">
		<label for="email">Email</label>
		<input
			type="email"
			id="email"
			bind:value={email}
			required
			placeholder="you@example.com"
		/>
	</div>

	<div class="form-group">
		<label for="password">Password</label>
		<input
			type="password"
			id="password"
			bind:value={password}
			required
			placeholder="••••••••"
		/>
	</div>

	<button type="submit" class="btn btn-primary" disabled={loading}>
		{loading ? 'Signing in...' : 'Sign In'}
	</button>
</form>

<p class="auth-footer">
	Don't have an account? <a href="/register">Sign up</a>
</p>
