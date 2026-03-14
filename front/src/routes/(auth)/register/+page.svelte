<script lang="ts">
	import { signUp } from '$lib/auth-client';
	import { goto } from '$app/navigation';

	let name = $state('');
	let email = $state('');
	let password = $state('');
	let error = $state('');
	let loading = $state(false);

	async function handleSubmit(e: Event) {
		e.preventDefault();
		error = '';
		loading = true;

		try {
			const result = await signUp.email({
				email,
				password,
				name
			});

			if (result.error) {
				error = result.error.message || 'Registration failed';
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
		<h1>Create account</h1>
		<p class="auth-subtitle">Set up your workspace</p>
	</div>
</div>

{#if error}
	<div class="auth-error">{error}</div>
{/if}

<form onsubmit={handleSubmit}>
	<div class="form-group">
		<label for="name">Name</label>
		<input
			type="text"
			id="name"
			bind:value={name}
			required
			placeholder="John Doe"
		/>
	</div>

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
			minlength="8"
		/>
	</div>

	<button type="submit" class="btn btn-primary" disabled={loading}>
		{loading ? 'Creating account...' : 'Create Account'}
	</button>
</form>

<p class="auth-footer">
	Already have an account? <a href="/login">Sign in</a>
</p>
