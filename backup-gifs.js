// Step 1 of 2: paste into DevTools console on discord.com/app (F12 -> Console).
// Reads your GIF favorites from Discord's in-memory UserSettingsProtoStore — zero API calls.
// Copies an ordered JSON manifest (oldest -> newest) to your clipboard.
// Then save it as gifs.json next to download.ps1 and run that script.
// NOTE: "Requested message ... does not have a value" warnings are harmless — ignore them.

(() => {
  const wpChunk = window.webpackChunkdiscord_app;
  const modules = [];
  wpChunk.push([[Symbol()], {}, (req) => {
    for (const id in req.c) modules.push(req.c[id].exports);
  }]);
  wpChunk.pop();

  // Find the store by its registered name — Flux stores expose getName()
  let store = null;
  outer: for (const m of modules) {
    if (!m || typeof m !== 'object') continue;
    for (const key of ['default', 'Z', 'ZP', ...Object.keys(m)]) {
      try {
        const exp = key === 'default' || key === 'Z' || key === 'ZP' ? m[key] : m[key];
        if (exp && typeof exp.getName === 'function' && exp.getName() === 'UserSettingsProtoStore') {
          store = exp;
          break outer;
        }
      } catch {}
    }
  }
  if (!store) {
    console.error('UserSettingsProtoStore not found — Discord may have renamed it. Tell Claude.');
    return;
  }

  const frecency = store.frecencyWithoutFetchingLatest ?? store.frecency;
  let gifs = frecency?.favoriteGifs?.gifs;
  if (!gifs) {
    console.error('Store found but no favoriteGifs in it. Open the GIF picker Favorites tab once, then re-run.');
    return;
  }

  // gifs may be a plain object or a Map depending on client version
  const entries = gifs instanceof Map ? [...gifs.entries()] : Object.entries(gifs);
  const list = entries
    .map(([key, g]) => ({ url: g.src || key, key, order: Number(g.order ?? 0) }))
    .sort((a, b) => a.order - b.order)
    .map((e, i) => ({ index: i + 1, url: e.url, key: e.key }));

  copy(JSON.stringify(list, null, 2)); // DevTools built-in: puts it on the clipboard
  console.log(`${list.length} favorites copied to clipboard as JSON (oldest first).`);
  console.log('Paste into gifs.json, then run download.ps1');
})();
