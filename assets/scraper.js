(async function(mode) {
  const DIFFICULTIES = ["BEGINNER", "NORMAL", "HYPER", "ANOTHER", "LEGGENDARIA"];
  const LAMP_MAP = {
    "0": "NO PLAY", "1": "FAILED", "2": "ASSIST CLEAR", "3": "EASY CLEAR",
    "4": "CLEAR", "5": "HARD CLEAR", "6": "EX HARD CLEAR", "7": "FULLCOMBO CLEAR"
  };
  const LEVEL_LABELS = ["☆1","☆2","☆3","☆4","☆5","☆6","☆7","☆8","☆9","☆10","☆11","☆12"];
  const HEADERS = [
    "バージョン","タイトル","ジャンル","アーティスト","プレー回数",
    ...DIFFICULTIES.flatMap(d => [
      `${d} 難易度`, `${d} スコア`, `${d} PGreat`, `${d} Great`,
      `${d} ミスカウント`, `${d} クリアタイプ`, `${d} DJ LEVEL`
    ]),
    "最終プレー日時"
  ];

  const ver = (location.href.match(/\/game\/2dx\/(\d+)\//) || [null, "33"])[1];
  const POST_URL = `https://p.eagate.573.jp/game/2dx/${ver}/djdata/music/difficulty.html`;

  const notify = (data) => window.flutter_inappwebview.callHandler('ScraperChannel', JSON.stringify(data));

  const escapeCsv = (v) => /[",\n]/.test(v) ? `"${v.replace(/"/g, '""')}"` : v;

  const parseTable = (html) => {
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, "text/html");
    const rows = doc.querySelectorAll(".series-difficulty table tr");
    const results = [];
    rows.forEach(row => {
      const tds = row.querySelectorAll("td");
      if (tds.length < 4) return;
      const titleEl = tds[0].querySelector("a");
      if (!titleEl) return;
      const title = titleEl.textContent?.trim() ?? "";
      const difficulty = tds[1].textContent?.trim() ?? "";
      const scoreMatch = (tds[3]?.textContent?.trim() ?? "").match(/(\d+)\s*\((\d+)\/(\d+)\)/);
      const lampNum = (tds[4]?.querySelector("img")?.getAttribute("src") ?? "").match(/clflg(\d+)\.gif/)?.[1] ?? "0";
      const djSrc = tds[2]?.querySelector("img")?.getAttribute("src") ?? "";
      const djLevel = djSrc.match(/\/([^/]+)\.gif/)?.[1]?.toUpperCase() ?? "---";
      const levelMatch = row.closest("table")?.querySelector("th")?.textContent?.match(/LEVEL\s*(\d+)/i);
      results.push({
        title, difficulty,
        level: levelMatch ? levelMatch[1] : "-",
        score: scoreMatch ? scoreMatch[1] : "0",
        pgreat: scoreMatch ? scoreMatch[2] : "0",
        great: scoreMatch ? scoreMatch[3] : "0",
        lamp: LAMP_MAP[lampNum] ?? "NO PLAY",
        djLevel
      });
    });
    return results;
  };

  const fetchPage = async (difficult, offset) => {
    const body = new URLSearchParams({ difficult: String(difficult), style: "0", disp: "1" });
    if (offset > 0) body.append("offset", String(offset));
    const resp = await fetch(POST_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: body.toString(),
      credentials: "include"
    });
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    return resp.text();
  };

  const songMap = {};
  const levelIndices = mode === "all" ? [...Array(12).keys()] : [10, 11];
  let totalPages = 0;

  try {
    for (const lv of levelIndices) {
      const label = LEVEL_LABELS[lv];
      let offset = 0, pageNum = 1;
      while (true) {
        notify({ type: "progress", level: label, page: pageNum, songs: Object.keys(songMap).length });
        const html = await fetchPage(lv, offset);
        const rows = parseTable(html);
        if (rows.length === 0) break;
        rows.forEach(r => {
          if (!songMap[r.title]) songMap[r.title] = {};
          if (DIFFICULTIES.includes(r.difficulty)) songMap[r.title][r.difficulty] = r;
        });
        totalPages++;
        offset += 50;
        pageNum++;
        await new Promise(resolve => setTimeout(resolve, 400));
      }
    }

    const csvRows = [HEADERS.join(",")];
    Object.keys(songMap).sort().forEach(title => {
      const data = songMap[title];
      const row = ["-", escapeCsv(title), "-", "-", "-"];
      DIFFICULTIES.forEach(diff => {
        const d = data[diff];
        if (d) row.push(d.level, d.score, d.pgreat, d.great, "-", d.lamp, d.djLevel);
        else row.push("-", "0", "0", "0", "-", "NO PLAY", "---");
      });
      row.push("-");
      csvRows.push(row.join(","));
    });

    notify({ type: "done", csv: csvRows.join("\n"), songs: Object.keys(songMap).length, pages: totalPages });
  } catch (e) {
    notify({ type: "error", message: e.message });
  }
})("__MODE__");
