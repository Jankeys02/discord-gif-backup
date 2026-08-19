# 🗃️ discord-gif-backup

[![Release](https://img.shields.io/github/v/release/Jankeys02/discord-gif-backup)](https://github.com/Jankeys02/discord-gif-backup/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![PowerShell 7+](https://img.shields.io/badge/PowerShell-7%2B-blue)
![No API calls](https://img.shields.io/badge/Discord%20API%20calls-0-brightgreen)

**Back up every GIF you ever favorited on Discord — before link rot gets them.**

Google shut down the Tenor API in June 2026 and Discord's GIF search already runs on replacements — your favorites still load from Tenor's media CDN *for now*, with no promise of tomorrow. This tool saves all of them to disk, oldest → newest, with filenames that preserve your favoriting order.

No bot. No extension. No Discord API calls. No messages sent. Two steps, done.

## 📜 Why this exists

Discord's GIF picker was powered by Tenor, which Google acquired in 2018. On **January 13, 2026**, Google [announced the deprecation of the Tenor API](https://www.shacknews.com/article/149852/google-tenor-api-service-discontinued-twitter-discord-whatsapp-bluesky), halting new integrations immediately; on **June 30, 2026**, it [pulled the plug entirely](https://tech.slashdot.org/story/26/06/30/2131216/google-pulls-the-plug-on-tenor-api-killing-gif-pickers-around-the-web) — GIF search broke the same day across Discord, WhatsApp, X, and Bluesky, and Discord began [testing Giphy and Klipy as replacements](https://piunikaweb.com/2026/01/14/discord-gif-search-change-tenor-api-shutdown/).

Favorited GIFs [still render for now](https://www.pcgamesn.com/discord/not-losing-gifs) because favorites are stored in your Discord settings and loaded straight from Tenor's media CDN rather than through the dead API. But that CDN's future has no guarantee — and history says don't wait: Tenor already deleted its previous media URL scheme once (during the Google migration), which silently killed every favorite saved under old-format links. In the library this tool was built against, **~26% of favorites pointed at URLs that no longer existed** and had to be recovered through fallback routes — or were lost for good. This tool gets the rest onto your own disk while the current CDN still answers.

## ✨ What it does

Your GIF favorites are client-side state in Discord's `UserSettingsProtoStore` (the "frecency" settings blob) — each entry holds the media URL, the Tenor page URL, and an `order` field. This tool reads that list straight out of the client's memory and downloads everything with a few link-rot countermeasures:

| Problem | Countermeasure |
|---|---|
| Tenor favorites stored as silent `.mp4` | Rendition code rewritten to `AAAAC` → real animated `.gif` (falls back if none exists) |
| Old-format Tenor media URLs (`/videos/<hash>/mp4`) — that CDN scheme is **gone** | Recovered live via the favorite's still-working `tenor.com/view/…` page |
| Discord attachment links with expired signatures (`ex=` hex timestamp) | Detected up front and reported, so you can re-favorite instead of getting silent 404s |
| "Did I get everything?" | Every unrecoverable favorite is listed at the end with its reason — nothing vanishes silently |

Files are named `001_funny-cat.gif`, `002_deal-with-it.gif`, … so any file explorer shows them in the order you favorited them.

## 🚀 Usage

**Requirements:** [PowerShell 7+](https://github.com/PowerShell/PowerShell) (Windows, macOS, or Linux), a browser logged into Discord.

**Get the scripts:** grab both from the [latest release](https://github.com/Jankeys02/discord-gif-backup/releases/latest) — direct links: [`backup-gifs.js`](https://github.com/Jankeys02/discord-gif-backup/releases/latest/download/backup-gifs.js) · [`download.ps1`](https://github.com/Jankeys02/discord-gif-backup/releases/latest/download/download.ps1) (these always point at the newest version).

**Step 1 — extract** (in the browser)

1. Open `discord.com/app`, press <kbd>F12</kbd> → **Console**
2. Paste the contents of [`backup-gifs.js`](backup-gifs.js) and hit Enter
3. Your ordered favorites list is now on the clipboard as JSON — save it as `gifs.json` next to `download.ps1`

> Chrome may make you type `allow pasting` first. Any *"Requested message … does not have a value"* warnings are harmless client noise.

**Step 2 — download** (in a terminal)

```powershell
pwsh -File download.ps1
```

GIFs land in `Downloads\discord-gifs\`. Downloads run **8-wide in parallel** and are **resumable** — re-running skips anything already saved.

## 🔒 Privacy

Everything runs locally. Your token is never read, stored, or transmitted. Step 1 makes **zero** Discord API calls (it reads the client's own memory); step 2 talks only to media CDNs. `gifs.json` and all output are gitignored because they contain your personal favorites list and signed URLs.

## ⚠️ Disclaimer

This tool is provided **as is, without warranty of any kind** — see [LICENSE](LICENSE). Use it at your own risk. Running scripts in the Discord client console may violate Discord's Terms of Service; the authors accept no liability for any consequences to your account, your data, or anything else arising from the use of this software. This project is not affiliated with or endorsed by Discord or Tenor.

## 📄 License

[MIT](LICENSE)
