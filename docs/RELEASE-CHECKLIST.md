# Release Checklist (GitHub + F-Droid)

Use this checklist for every stable release.

## Stable release flow

1. Finalize release content on `main`
   - `pubspec.yaml` version is final (e.g. `0.3.3+10`)
   - `CHANGELOG.md` has matching release entry (`0.3.3`)
   - F-Droid changelog file exists: `fdroid/metadata/com.d0dg3r.gitsyncmarks/en-US/changelogs/10.txt`

2. Verify F-Droid submit metadata
   - `CurrentVersion` and `CurrentVersionCode` match `pubspec.yaml`
   - `AllowedAPKSigningKeys` is set
   - current build block contains `binary:`
   - `UpdateCheckMode: Tags ^v[0-9.]+$`

3. Tag final merge commit

```bash
git checkout main
git pull
git tag vX.Y.Z
git push origin vX.Y.Z
```

- Verify tag hash vs submit metadata commit

```bash
git rev-parse vX.Y.Z
rg "^\\s*commit:\\s" fdroid/metadata/com.d0dg3r.gitsyncmarks-fdroid-submit.yml
```

Both hashes must be identical.

- Wait for GitHub `Build & Release` workflow to pass
  - includes Android signing checks and APK signer fingerprint verification

- Submit to F-Droid via script

```bash
./fdroid/submit-to-gitlab.sh YOUR_GITLAB_USER
```

The script enforces release gates and writes a proof file to `fdroid/proofs/`.

## Recovery flow for wrong tag

If tag/release was created on the wrong commit:

```bash
git checkout main
git pull
git tag -d vX.Y.Z
git push origin :refs/tags/vX.Y.Z
git tag vX.Y.Z
git push origin vX.Y.Z
```

Then update submit metadata `commit:` to the new `git rev-parse vX.Y.Z` hash and re-run:

```bash
./fdroid/submit-to-gitlab.sh --validate-only
./fdroid/submit-to-gitlab.sh YOUR_GITLAB_USER
```
