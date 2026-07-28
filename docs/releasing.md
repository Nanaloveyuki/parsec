# Releasing parsec

Release from a clean, merged `main` only. The version in `moon.mod`, the Git
tag, the Mooncake package, and the GitHub release must match.

1. Update `moon.mod`, `CHANGELOG.md`, and installation examples when needed.
2. Merge the release preparation change and wait for the validation workflow.
3. Refresh dependencies, then run the release checks from the merged commit:

```powershell
moon update
moon install
moon fmt --check
moon check --target all
moon test --target all
moon info
git diff --check
moon package --list
moon publish --dry-run
```

4. Create and push an annotated tag, publish, then create the GitHub release:

```powershell
$version = "0.1.0"
git tag -a "v$version" -m "parsec $version"
git push origin "v$version"
moon publish
gh release create "v$version" --title "parsec $version" --notes-file CHANGELOG.md
```

After publishing, install the exact registry version in a clean fixture and
run `moon check` to verify the released public API.

