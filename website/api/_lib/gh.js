// _lib/gh.js — shared GitHub API helper for the aether-distro site functions.
// Zero-dependency: Node 20+ fetch only. Token stays server-side.

export const REPO = process.env.GITHUB_REPO || "orubus-dev/Aether-Distro";
export const WORKFLOW = "iso.yml";
export const ARTIFACT_NAME = "aetheros-iso";

export function gh(path, extra = {}) {
  return fetch(`https://api.github.com${path}`, {
    ...extra,
    headers: {
      Authorization: `Bearer ${process.env.GITHUB_TOKEN || ""}`,
      Accept: "application/vnd.github+json",
      "User-Agent": "aether-distro-site",
      ...(extra.headers || {}),
    },
  });
}

// Resolve the newest successful ISO build + its live artifact.
export async function latestBuild() {
  const runsRes = await gh(
    `/repos/${REPO}/actions/workflows/${WORKFLOW}/runs?status=success&per_page=5`
  );
  if (!runsRes.ok) throw new Error(`runs ${runsRes.status}`);
  const runs = (await runsRes.json()).workflow_runs || [];
  for (const run of runs) {
    const artRes = await gh(`/repos/${REPO}/actions/runs/${run.id}/artifacts`);
    if (!artRes.ok) continue;
    const arts = (await artRes.json()).artifacts || [];
    const iso = arts.find((a) => a.name === ARTIFACT_NAME && !a.expired);
    if (iso) return { run, artifact: iso };
  }
  return null;
}

// 302 target: the signed Azure blob URL behind the artifact endpoint.
// Valid ~10 minutes, serves from Microsoft's edge — no GitHub throttle.
export async function signedArtifactUrl() {
  const hit = await latestBuild();
  if (!hit) return null;
  const res = await gh(
    `/repos/${REPO}/actions/artifacts/${hit.artifact.id}/zip`,
    { redirect: "manual" }
  );
  if (res.status !== 302) throw new Error(`zip ${res.status}`);
  const location = res.headers.get("location");
  if (!location) throw new Error("no location");
  return { hit, location };
}

const ISO_LINE = /ISO: (dist\/\S+\.(?:iso)) \((\d+) bytes\)/;
const SHA_LINE = /\b([a-f0-9]{64})\b/;

// Pull the exact ISO filename/size/sha256 from the assemble job log (cached 10 min).
export async function isoFacts(runId) {
  const key = `isoFacts:${runId}`;
  if (globalThis[key]) return globalThis[key];
  const jobsRes = await gh(`/repos/${REPO}/actions/runs/${runId}/jobs`);
  if (!jobsRes.ok) return null;
  const jobs = (await jobsRes.json()).jobs || [];
  const assemble = jobs.find((j) => /assemble/i.test(j.name)) || jobs[0];
  if (!assemble) return null;
  const logRes = await gh(`/repos/${REPO}/actions/jobs/${assemble.id}/logs`);
  if (!logRes.ok) return null;
  const text = await logRes.text();
  const isoMatch = text.match(ISO_LINE);
  const shaMatch = text.match(/SHA256SUMS[\s\S]{0,200}?([a-f0-9]{64})/);
  const facts = isoMatch
    ? {
        filename: isoMatch[1].split("/").pop(),
        size_bytes: Number(isoMatch[2]),
        sha256: shaMatch ? shaMatch[1] : null,
      }
    : null;
  globalThis[key] = facts;
  setTimeout(() => delete globalThis[key], 10 * 60 * 1000).unref?.();
  return facts;
}

export function json(res, obj, code = 200) {
  res.statusCode = code;
  res.setHeader("Content-Type", "application/json");
  res.setHeader("Cache-Control", "no-store");
  res.end(JSON.stringify(obj, null, 2));
}
