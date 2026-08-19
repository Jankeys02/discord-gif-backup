# How to Create a Release

## Versioning

This project follows [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

- **MAJOR** — breaking changes (incompatible API / behavior).
- **MINOR** — new functionality, backwards-compatible.
- **PATCH** — backwards-compatible bug fixes only.

The version in `package.json` is the source of truth. Release tags are that version prefixed with `v` (e.g. `v1.2.0`), which is what triggers the release workflow. Pre-releases use a suffix: `v1.2.0-rc.1`.

## Prerequisites

1. Make sure the project is properly versioned in `package.json`
2. Ensure `npm test` and `npm run lint` pass
3. Clean git working tree

## Steps

### 1. Update the version

```json
{
  "version": "1.2.0"
}
```

### 2. Update the changelog

Move items from `## [Unreleased]` into a new dated version section in [CHANGELOG.md](CHANGELOG.md).

### 3. Commit and tag

```bash
git add package.json CHANGELOG.md
git commit -m "Update version to 1.2.0"
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin main v1.2.0
```

## What happens next

Pushing a `v*` tag triggers [`.github/workflows/release.yml`](.github/workflows/release.yml), which
runs `npm ci` and creates a GitHub Release with auto-generated notes. Add your build/package steps
(installer, zip, etc.) to that workflow — it ships as a skeleton with a commented slot for them.
