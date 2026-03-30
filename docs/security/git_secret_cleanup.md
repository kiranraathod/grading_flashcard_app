# Git Secret Cleanup

This repo previously exposed a Google API key in tracked Git history.

## Exposed paths identified

- `server/.env.local`
- `client/docs/production_deployment/task_1_3_render_deployment_implementation.md`
- `server/.env.test`

## Safe order of operations

1. Rotate the exposed Google API key before any git cleanup.
2. Commit the current sanitized working tree changes.
3. Run `scripts/cleanup_exposed_secret.ps1` to rewrite git history.
4. Re-add the sanitized versions of tracked files if the rewrite removed them from the latest commit.
5. Force-push the rewritten branch and tags.
6. Ask GitHub support to purge cached views if the secret still appears in old blob URLs.

## Notes

- The script creates a local backup tag named `backup/pre_secret_cleanup`.
- `git filter-branch` rewrites commit hashes for affected history.
- Anyone with an existing clone will need to re-sync carefully after the force-push.
