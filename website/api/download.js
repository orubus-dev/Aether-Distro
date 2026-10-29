// api/download.js — the click endpoint.
// Resolves GitHub's signed Azure blob URL for the latest CI ISO artifact and
// 302-redirects the browser straight to it: Microsoft's edge serves the bytes,
// bypassing GitHub's throttled api.github.com download path entirely.
import { signedArtifactUrl, json, REPO } from "./_lib/gh.js";

export default async function handler(req, res) {
  try {
    const target = await signedArtifactUrl();
    if (!target) return json(res, { ok: false, error: "no live artifact" }, 404);
    const { hit, location } = target;
    const run = hit.run;
    const filename = `AetherOS-iso-r${run.run_number}-${run.head_sha.slice(0, 7)}.zip`;
    res.statusCode = 302;
    res.setHeader("Location", location);
    res.setHeader("Cache-Control", "no-store");
    // Suggest a friendly client filename (blob honors rscd=attachment; we
    // re-state ours — browsers prefer the redirect target's Content-Disposition,
    // so this is best-effort for the zip name).
    res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
    res.end();
  } catch (e) {
    return json(res, { ok: false, error: e.message, repo: REPO }, 502);
  }
}
