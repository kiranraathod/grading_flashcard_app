$ErrorActionPreference = "Stop"

Write-Host "Checking for uncommitted changes..."
$status = git status --porcelain
if ($LASTEXITCODE -ne 0) {
  throw "Unable to determine git working tree status."
}

if ($status) {
  Write-Error "Git history rewrite requires a clean working tree. Commit or stash your changes, then rerun this script."
  exit 1
}

Write-Host "Creating backup tag before history rewrite..."
git tag backup/pre_secret_cleanup

Write-Host "Rewriting history to remove exposed secret-bearing files..."
git filter-branch --force --index-filter `
  "git rm --cached --ignore-unmatch --quiet server/.env.local client/docs/production_deployment/task_1_3_render_deployment_implementation.md server/.env.test" `
  --prune-empty --tag-name-filter cat -- --all

Write-Host "Cleaning rewritten refs..."
if (Test-Path .git/refs/original) {
  Remove-Item -LiteralPath .git/refs/original -Recurse -Force
}

git reflog expire --expire=now --all
git gc --prune=now --aggressive

Write-Host ""
Write-Host "History rewrite complete."
Write-Host "Next steps:"
Write-Host "1. Re-add the sanitized files from your working tree if needed."
Write-Host "2. Verify with: git log --all -- server/.env.local"
Write-Host "3. Force-push with: git push origin --force --all"
Write-Host "4. Force-push tags if needed: git push origin --force --tags"
