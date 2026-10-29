// api/latest.js — metadata for the newest CI ISO build.
import { latestBuild, isoFacts, json, REPO } from "./_lib/gh.js";

export default async function handler(req, res) {
  try {
    const hit = await latestBuild();
    if (!hit) return json(res, { ok: false, error: "no live artifact" }, 404);
    const facts = await isoFacts(hit.run.id).catch(() => null);
    return json(res, {
      ok: true,
      repo: REPO,
      run: {
        id: hit.run.id,
        number: hit.run.run_number,
        sha: hit.run.head_sha,
        created_at: hit.run.created_at,
        url: hit.run.html_url,
      },
      artifact: {
        id: hit.artifact.id,
        name: hit.artifact.name,
        size_bytes: hit.artifact.size_in_bytes,
        updated_at: hit.artifact.updated_at,
      },
      iso: facts,
    });
  } catch (e) {
    return json(res, { ok: false, error: e.message }, 502);
  }
}
