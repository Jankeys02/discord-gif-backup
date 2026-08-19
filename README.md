# discord-gif-backup

Back up all your favorited Discord GIFs before they rot — Tenor link schemes die, Discord attachment signatures expire, and Discord's Tenor integration is being decommissioned. This tool downloads every favorite to disk, oldest → newest, with order-preserving filenames.

No bot, no extension, no Discord API calls, no messages sent. Step 1 reads your favorites from the Discord web client's own in-memory store; step 2 downloads from the media CDNs directly.

## How it works

Your GIF favorites are client-side state stored in Discord's `UserSettingsProtoStore` (the "frecency" settings blob), including each favorite's media URL and an `order` field. The extractor dumps that list; the downloader fetches it with a few tricks:

- **Tenor favorites** are rewritten from silent `.mp4` renditions to real animated `.gif` files (rendition code → `AAAAC`), with fallback to the original if no gif variant exists.
- **Dead old-format Tenor links** (`media.tenor.com/videos/<hash>/mp4` — a URL scheme Tenor deleted) are recovered via their still-alive `tenor.com/view/...` page.
- **Expired Discord attachment links** (hex `ex=` signature timestamp) are detected up front and reported so you can re-favorite them instead of getting silent 404s.
- Files are named `001_funny-cat.gif`, `002_deal-with-it.gif`, … so any file explorer shows them in the order you favorited them.

## Usage

**Requirements:** Windows with [PowerShell 7+](https://github.com/PowerShell/PowerShell), a browser logged into Discord.

1. Open `discord.com/app` in your browser, press <kbd>F12</kbd> → Console, and paste the contents of [`backup-gifs.js`](backup-gifs.js). (Chrome may require typing `allow pasting` first. "Requested message … does not have a value" warnings are harmless.)
2. The ordered favorites list is now on your clipboard as JSON. Save it as `gifs.json` next to `download.ps1`.
3. Run the downloader:

   ```powershell
   pwsh -File download.ps1
   ```

Files land in `Downloads\discord-gifs\`. Downloads run 8-wide in parallel and are resumable — re-running skips anything already saved. Unrecoverable favorites (deleted from Tenor, dead unsigned proxy links) are listed at the end so nothing goes missing silently.

## Privacy

Everything runs locally. Your token is never read, stored, or transmitted; `gifs.json` and all output files are gitignored because they contain your personal favorites list and signed URLs.

## Disclaimer

This tool is provided **as is, without warranty of any kind** — see [LICENSE](LICENSE). Use it at your own risk. Running scripts in the Discord client console may violate Discord's Terms of Service; the authors accept no liability for any consequences to your account, your data, or anything else arising from the use of this software. This project is not affiliated with or endorsed by Discord or Tenor.

## License

[MIT](LICENSE)
