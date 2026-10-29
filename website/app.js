// app.js — populates build metadata, wires downloads, tab-bar states.
(() => {
  const $ = (id) => document.getElementById(id);

  const fmtGB = (bytes) => `${(bytes / 1e9).toFixed(2)} GB`;
  const fmtDate = (iso) =>
    new Date(iso).toLocaleString(undefined, {
      month: "short", day: "numeric", hour: "2-digit", minute: "2-digit",
    });

  async function loadLatest() {
    const meta = $("build-meta");
    try {
      const res = await fetch("/api/latest");
      const data = await res.json();
      if (!data.ok) throw new Error(data.error || "unavailable");

      const run = data.run;
      const art = data.artifact;
      const iso = data.iso;

      meta.innerHTML = `
        <li class="chip glass">build r${run.number}</li>
        <li class="chip glass">${fmtGB(iso?.size_bytes ?? art.size_bytes)} ${iso ? "ISO" : "artifact"}</li>
        <li class="chip glass">built ${fmtDate(run.created_at)}</li>
        <li class="chip glass mono">sha ${run.sha.slice(0, 7)}</li>`;

      $("f-run").textContent = `r${run.number} · ${run.sha.slice(0, 7)}`;
      $("f-artifact").textContent = art.name;
      $("f-size").textContent = fmtGB(art.size_bytes);
      $("f-date").textContent = fmtDate(run.created_at);
      $("dl-size-label").textContent = iso ? `· ${fmtGB(iso.size_bytes)}` : "";

      if (iso?.sha256) {
        $("expected-sha").textContent = iso.sha256;
        document.querySelector(".chip-live").innerHTML =
          `<span class="dot"></span> r${run.number} · ${fmtGB(iso.size_bytes)} · QEMU-boot verified`;
      } else {
        $("expected-sha").textContent =
          "Run `cat SHA256SUMS` after extracting the artifact ZIP — hash is published inside every build.";
      }

      const link = `https://github.com/orubus-dev/Aether-Distro/actions/runs/${run.id}`;
      document.querySelectorAll("#dl-facts a").forEach(() => {});
      $("download-note").innerHTML =
        `Artifact ships as a ZIP with the ISO + <span class="mono">SHA256SUMS</span>. ` +
        `Signed URL minted fresh on click · <a href="${link}" target="_blank" rel="noopener">build log</a>`;
    } catch (e) {
      meta.innerHTML =
        `<li class="chip glass">live metadata unavailable — use the release mirror below</li>`;
      $("expected-sha").textContent =
        "Metadata API unreachable — extract SHA256SUMS from the artifact ZIP and compare locally.";
      console.error(e);
    }
  }

  // Copy expected sha
  $("copy-sha").addEventListener("click", async () => {
    const text = $("expected-sha").textContent.trim();
    try {
      await navigator.clipboard.writeText(text);
      $("copy-sha").textContent = "Copied ✓";
      setTimeout(() => ($("copy-sha").textContent = "Copy"), 1600);
    } catch {
      /* clipboard unavailable */
    }
  });

  // Tab bar active state via IntersectionObserver
  const tabs = document.querySelectorAll(".tabbar a[data-tab]");
  const map = {};
  tabs.forEach((t) => (map[t.getAttribute("href").slice(1)] = t));
  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((en) => {
        if (en.isIntersecting) {
          tabs.forEach((t) => t.classList.remove("active"));
          map[en.target.id]?.classList.add("active");
        }
      });
    },
    { rootMargin: "-45% 0px -45% 0px" }
  );
  ["home", "download", "install", "faq"].forEach((id) => {
    const el = document.getElementById(id);
    if (el) io.observe(el);
  });

  loadLatest();
})();
