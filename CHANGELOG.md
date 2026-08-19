# Changelog

All notable changes to this project are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-08-19

### Added

- `backup-gifs.js` — console extractor reading GIF favorites (ordered, with page keys) from Discord's in-memory `UserSettingsProtoStore`; zero API calls
- `download.ps1` — parallel (8 threads), resumable downloader with Tenor gif-variant rewriting, dead old-format Tenor rescue via `tenor.com/view` pages, and expired Discord-signature detection
