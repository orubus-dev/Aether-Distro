// api/health.js — liveness + capability report.
import { json, REPO } from "./_lib/gh.js";

export default async function handler(req, res) {
  return json(res, {
    ok: true,
    service: "aether-distro-site",
    repo: REPO,
    token: process.env.GITHUB_TOKEN ? "configured" : "missing",
    capabilities: { latest: true, download: true },
  });
}
