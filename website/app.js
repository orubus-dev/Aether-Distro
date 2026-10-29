// app.js — build metadata, sha copy, tab active state.
(() => {
  const $ = (id) => document.getElementById(id);

  const fmtGB = (b) => `${(b / 1e9).toFixed(2)} GB`;
  const fmtDate = (iso) =>
    new Date(iso).toLocaleString(undefined, {
      month: "short", day: "numeric", hour: "2-digit", minute: "2-digit",
    });

  async function loadLatest() {
    try {
      const res = await fetch("/api/latest");
      const data = await res.json();
      if (!data.ok) throw new Error(data.error || "unavailable");

      const run = data.run, art = data.artifact, iso = data.iso;
      const size = fmtGB(iso?.size_bytes ?? art.size_bytes);
      const r = `r${run.number}`;

      $("chip-meta").textContent = `${r} · ${size} · verified boot`;
      $("f-run").textContent = r;
      $("f-artifact").textContent = art.name;
      $("f-size").textContent = size;
      $("f-date").textContent = fmtDate(run.created_at);
      $("dl-size").textContent = size ? ` · ${size}` : "";

      $("build-meta").innerHTML = `
        <li>${r}</li>
        <li>${size} ISO</li>
        <li>built ${fmtDate(run.created_at)}</li>
        <li class="mono">sha ${run.sha.slice(0, 7)}</li>`;

      $("expected-sha").textContent =
        iso?.sha256 ||
        "Extract the ZIP — SHA256SUMS ships inside every build.";
    } catch (e) {
      $("chip-meta").textContent = "metadata offline";
      $("expected-sha").textContent =
        "Metadata API unreachable — SHA256SUMS ships inside the artifact ZIP.";
      console.error(e);
    }
  }

  $("copy-sha").addEventListener("click", async () => {
    const text = $("expected-sha").textContent.trim();
    try {
      await navigator.clipboard.writeText(text);
      $("copy-sha").textContent = "Copied";
      setTimeout(() => ($("copy-sha").textContent = "Copy"), 1600);
    } catch { /* clipboard unavailable */ }
  });

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
