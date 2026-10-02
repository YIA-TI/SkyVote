<template>
  <div class="hasil-page">
    <div class="page-heading">
      <div class="page-heading-text">
        <RouterLink to="/admin/survey-result" class="back-link">
          <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
            <path d="M12 4 6 10l6 6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          Kembali
        </RouterLink>
        <h1 class="page-title">{{ survey?.nama ?? "Hasil Survei" }}</h1>
        <p class="page-subtitle">Rekap jawaban survei internal, per pertanyaan.</p>
      </div>
      <div v-if="!loading && results.length > 0" class="export-actions">
        <button type="button" class="btn-export" @click="exportToPdf">
          <svg width="15" height="15" viewBox="0 0 20 20" fill="none">
            <path d="M10 3v9m0 0 3.5-3.5M10 12l-3.5-3.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
            <path d="M4 14v2a1.5 1.5 0 0 0 1.5 1.5h9A1.5 1.5 0 0 0 16 16v-2" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
          </svg>
          Ekspor ke PDF
        </button>
        <button type="button" class="btn-export btn-export-excel" @click="exportToExcel">
          <svg width="15" height="15" viewBox="0 0 20 20" fill="none">
            <path d="M10 3v9m0 0 3.5-3.5M10 12l-3.5-3.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
            <path d="M4 14v2a1.5 1.5 0 0 0 1.5 1.5h9A1.5 1.5 0 0 0 16 16v-2" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
          </svg>
          Ekspor ke Excel
        </button>
      </div>
    </div>

    <div v-if="loading" class="state-card">Memuat hasil...</div>

    <template v-else>
      <div class="trend-card">
        <div class="trend-header">
          <span class="trend-title">Tren Pengisian</span>
          <span class="trend-total">{{ totalResponden }} total pengisian</span>
        </div>

        <div v-if="trendPath.coords.length < 2" class="trend-empty">
          Belum cukup data untuk menampilkan tren (butuh pengisian di minimal 2 tanggal berbeda).
        </div>
        <div v-else class="trend-chart-wrap">
          <svg
            :viewBox="`0 0 ${CHART_W} ${CHART_H}`"
            class="trend-svg"
            preserveAspectRatio="none"
            @pointermove="handleTrendHover"
            @pointerleave="hoverIndex = null"
          >
            <line
              v-for="gl in trendGridlines"
              :key="gl.value"
              :x1="PAD_LEFT"
              :x2="CHART_W - PAD_RIGHT"
              :y1="gl.y"
              :y2="gl.y"
              class="trend-gridline"
              vector-effect="non-scaling-stroke"
            />
            <text
              v-for="gl in trendGridlines"
              :key="`t${gl.value}`"
              :x="PAD_LEFT - 6"
              :y="gl.y + 3"
              class="trend-tick-label"
              text-anchor="end"
            >{{ gl.value }}</text>

            <path :d="trendPath.area" class="trend-area" />
            <path :d="trendPath.line" class="trend-line" vector-effect="non-scaling-stroke" />

            <line
              v-if="hoverIndex !== null"
              :x1="trendPath.coords[hoverIndex].x"
              :x2="trendPath.coords[hoverIndex].x"
              :y1="PAD_TOP"
              :y2="CHART_H - PAD_BOTTOM"
              class="trend-crosshair"
              vector-effect="non-scaling-stroke"
            />

            <circle
              v-for="(c, i) in trendPath.coords"
              :key="i"
              :cx="c.x"
              :cy="c.y"
              r="4"
              class="trend-dot"
              :class="{ 'trend-dot-hover': hoverIndex === i }"
              vector-effect="non-scaling-stroke"
            />

            <text
              v-for="(c, i) in trendPath.coords"
              v-show="shouldShowLabel(i)"
              :key="`lbl${i}`"
              :x="c.x"
              :y="CHART_H - 8"
              class="trend-x-label"
              :text-anchor="xLabelAnchor(i, trendPath.coords.length)"
            >{{ formatShortDate(c.tanggal) }}</text>
          </svg>

          <div v-if="hoverIndex !== null" class="trend-tooltip" :style="trendTooltipStyle">
            <strong>{{ trendPath.coords[hoverIndex].count }}</strong> pengisian
            <span class="trend-tooltip-date">{{ formatFullDate(trendPath.coords[hoverIndex].tanggal) }}</span>
          </div>
        </div>
      </div>

      <div v-if="results.length === 0" class="state-card">Belum ada pertanyaan pada survei ini.</div>

      <div v-else class="results">
        <div v-for="q in results" :key="q.id" class="question-card">
          <div class="question-header">
            <span class="question-text">
              {{ q.pertanyaan }}
              <span v-if="q.tipe === 'PilihanMulti'" class="question-tipe-badge">Multi Choice</span>
            </span>
            <span class="question-total">{{ q.totalJawaban }} jawaban</span>
          </div>

          <template v-if="q.tipe === 'Pilihan' || q.tipe === 'PilihanMulti'">
            <div v-if="q.options.length === 0" class="no-options">Tidak ada opsi jawaban.</div>
            <template v-else>
            <p class="chart-subheading">Diagram Batang</p>
            <svg
              :viewBox="`0 0 ${BAR_W} ${BAR_H}`"
              class="bar-chart-svg"
              preserveAspectRatio="none"
            >
              <line
                v-for="gl in barChartFor(q).gridlines"
                :key="gl.value"
                :x1="BAR_PAD_LEFT"
                :x2="BAR_W - BAR_PAD_RIGHT"
                :y1="gl.y"
                :y2="gl.y"
                class="bar-gridline"
                vector-effect="non-scaling-stroke"
              />
              <text
                v-for="gl in barChartFor(q).gridlines"
                :key="`t${gl.value}`"
                :x="BAR_PAD_LEFT - 6"
                :y="gl.y + 3"
                class="bar-tick-label"
                text-anchor="end"
              >{{ gl.value }}%</text>

              <line
                :x1="BAR_PAD_LEFT"
                :x2="BAR_W - BAR_PAD_RIGHT"
                :y1="barChartFor(q).baselineY"
                :y2="barChartFor(q).baselineY"
                class="bar-baseline"
                vector-effect="non-scaling-stroke"
              />

              <g v-for="col in barChartFor(q).columns" :key="col.opsi">
                <path :d="roundedTopRectPath(col.x, col.y, col.width, col.height, 4)" class="bar-col">
                  <title>{{ col.opsi }}: {{ col.count }} jawaban ({{ col.pct }}%)</title>
                </path>
                <text :x="col.labelX" :y="col.y - 6" class="bar-value-label" text-anchor="middle">
                  {{ col.count }} ({{ col.pct }}%)
                </text>
                <text :x="col.labelX" :y="BAR_H - 10" class="bar-x-label" text-anchor="middle">
                  {{ truncateLabel(col.opsi) }}
                </text>
              </g>
            </svg>

            <p class="chart-subheading">Diagram Garis</p>
            <svg
              :viewBox="`0 0 ${BAR_W} ${BAR_H}`"
              class="bar-chart-svg"
              preserveAspectRatio="none"
            >
              <line
                v-for="gl in barChartFor(q).gridlines"
                :key="gl.value"
                :x1="BAR_PAD_LEFT"
                :x2="BAR_W - BAR_PAD_RIGHT"
                :y1="gl.y"
                :y2="gl.y"
                class="bar-gridline"
                vector-effect="non-scaling-stroke"
              />
              <text
                v-for="gl in barChartFor(q).gridlines"
                :key="`lt${gl.value}`"
                :x="BAR_PAD_LEFT - 6"
                :y="gl.y + 3"
                class="bar-tick-label"
                text-anchor="end"
              >{{ gl.value }}%</text>

              <line
                :x1="BAR_PAD_LEFT"
                :x2="BAR_W - BAR_PAD_RIGHT"
                :y1="barChartFor(q).baselineY"
                :y2="barChartFor(q).baselineY"
                class="bar-baseline"
                vector-effect="non-scaling-stroke"
              />

              <path :d="lineAreaFor(barChartFor(q))" class="line-area" />
              <path :d="linePathFor(barChartFor(q))" class="line-path" vector-effect="non-scaling-stroke" />

              <g v-for="col in barChartFor(q).columns" :key="`dot-${col.opsi}`">
                <circle :cx="col.labelX" :cy="col.y" r="4" class="line-dot" vector-effect="non-scaling-stroke">
                  <title>{{ col.opsi }}: {{ col.count }} jawaban ({{ col.pct }}%)</title>
                </circle>
                <text :x="col.labelX" :y="col.y - 10" class="bar-value-label" text-anchor="middle">
                  {{ col.count }} ({{ col.pct }}%)
                </text>
                <text :x="col.labelX" :y="BAR_H - 10" class="bar-x-label" text-anchor="middle">
                  {{ truncateLabel(col.opsi) }}
                </text>
              </g>
            </svg>
            </template>
          </template>

          <div v-else class="lisan-answers">
            <p v-if="q.answers.length === 0" class="no-options">Belum ada jawaban.</p>
            <ul v-else class="lisan-list">
              <li v-for="(ans, i) in q.answers" :key="i" class="lisan-item">
                <span class="lisan-item-number">{{ i + 1 }}</span>
                <span class="lisan-item-text">{{ ans }}</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import * as XLSX from "xlsx";
import { computed, onMounted, ref } from "vue";
import { useRoute } from "vue-router";
import { useSurveyStore } from "./stores/surveyStore";
import { useToastStore } from "./stores/toastStore";

const store = useSurveyStore();
const toast = useToastStore();
const route = useRoute();

const surveyId = computed(() => Number(route.params.id));
const survey = computed(() => store.findSurvey(surveyId.value));

const loading = ref(true);
const results = ref([]);

function percentage(count, total) {
  if (!total) return 0;
  return Math.round((count / total) * 1000) / 10;
}

// ── Per-question bar chart (vertical columns): one SVG per "Pilihan"/
// "PilihanMulti" question, columns = answer options. Column width is capped
// (never fills its slot — "let the band's leftover be air") and only the
// top corners are rounded, square at the baseline, per the bar mark spec.
const BAR_W = 600;
const BAR_H = 200;
const BAR_PAD_LEFT = 34;
const BAR_PAD_RIGHT = 10;
const BAR_PAD_TOP = 24;
const BAR_PAD_BOTTOM = 30;
const COL_MAX_WIDTH = 40;

function barChartFor(q) {
  const innerW = BAR_W - BAR_PAD_LEFT - BAR_PAD_RIGHT;
  const innerH = BAR_H - BAR_PAD_TOP - BAR_PAD_BOTTOM;
  const n = q.options.length;
  const slotW = innerW / n;
  const colWidth = Math.min(COL_MAX_WIDTH, slotW * 0.5);
  const baselineY = BAR_PAD_TOP + innerH;

  const gridlines = [0, 25, 50, 75, 100].map((pct) => ({
    value: pct,
    y: BAR_PAD_TOP + innerH - (pct / 100) * innerH,
  }));

  const columns = q.options.map((opt, i) => {
    const pct = percentage(opt.count, q.totalJawaban);
    const barHeight = (pct / 100) * innerH;
    const slotCenterX = BAR_PAD_LEFT + slotW * i + slotW / 2;
    return {
      x: slotCenterX - colWidth / 2,
      width: colWidth,
      y: baselineY - barHeight,
      height: barHeight,
      labelX: slotCenterX,
      opsi: opt.opsi,
      count: opt.count,
      pct,
    };
  });

  return { gridlines, columns, baselineY };
}

function roundedTopRectPath(x, y, width, height, radius) {
  if (height <= 0) return "";
  const r = Math.min(radius, width / 2, height);
  return `M ${x} ${y + height} L ${x} ${y + r} Q ${x} ${y} ${x + r} ${y} L ${x + width - r} ${y} Q ${x + width} ${y} ${x + width} ${y + r} L ${x + width} ${y + height} Z`;
}

function truncateLabel(text) {
  return text.length > 14 ? `${text.slice(0, 13)}…` : text;
}

// Line-chart variant of the same per-question data: reuses barChartFor's
// column x/y (same scale, same gridlines) and just connects the column tops
// instead of drawing bars — asked for alongside the bar chart, not instead
// of it.
function linePathFor({ columns }) {
  if (columns.length === 0) return "";
  return columns.map((c, i) => `${i === 0 ? "M" : "L"} ${c.labelX} ${c.y}`).join(" ");
}

function lineAreaFor({ columns, baselineY }) {
  if (columns.length === 0) return "";
  const line = linePathFor({ columns });
  const first = columns[0];
  const last = columns[columns.length - 1];
  return `${line} L ${last.labelX} ${baselineY} L ${first.labelX} ${baselineY} Z`;
}

onMounted(async () => {
  await store.ensureBaseData();
  try {
    results.value = await store.fetchSurveyResults(surveyId.value);
  } catch (err) {
    toast.show("Gagal memuat hasil survei.", "error");
  } finally {
    loading.value = false;
  }
});

// ── Tren Pengisian (line chart): one point per distinct tanggal with at
// least one submission for this survey, count = how many submissions that
// day. Single series, so per dataviz's job table ("trend over time" -> line,
// one hue) — no legend needed, the card title already names what's plotted.
const totalResponden = computed(() => store.submissionsBySurvey(surveyId.value).length);

const trendPoints = computed(() => {
  const counts = new Map();
  for (const s of store.submissionsBySurvey(surveyId.value)) {
    counts.set(s.tanggal, (counts.get(s.tanggal) ?? 0) + 1);
  }
  return Array.from(counts.entries())
    .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
    .map(([tanggal, count]) => ({ tanggal, count }));
});

const CHART_W = 600;
const CHART_H = 160;
const PAD_LEFT = 28;
const PAD_RIGHT = 12;
const PAD_TOP = 12;
const PAD_BOTTOM = 26;

function niceCeil(value) {
  if (value <= 0) return 1;
  const exp = Math.floor(Math.log10(value));
  const base = Math.pow(10, exp);
  const fraction = value / base;
  let niceFraction = 10;
  if (fraction <= 1) niceFraction = 1;
  else if (fraction <= 2) niceFraction = 2;
  else if (fraction <= 5) niceFraction = 5;
  return niceFraction * base;
}

const trendMaxCount = computed(() => niceCeil(Math.max(1, ...trendPoints.value.map((p) => p.count))));

const trendGridlines = computed(() => {
  const max = trendMaxCount.value;
  const innerH = CHART_H - PAD_TOP - PAD_BOTTOM;
  return [0, max / 2, max].map((v) => ({
    value: Math.round(v),
    y: PAD_TOP + innerH - (v / max) * innerH,
  }));
});

const trendPath = computed(() => {
  const points = trendPoints.value;
  if (points.length < 2) return { line: "", area: "", coords: [] };

  const innerW = CHART_W - PAD_LEFT - PAD_RIGHT;
  const innerH = CHART_H - PAD_TOP - PAD_BOTTOM;
  const maxCount = trendMaxCount.value;

  const coords = points.map((p, i) => ({
    x: PAD_LEFT + (innerW * i) / (points.length - 1),
    y: PAD_TOP + innerH - (p.count / maxCount) * innerH,
    ...p,
  }));

  const line = coords.map((c, i) => `${i === 0 ? "M" : "L"} ${c.x} ${c.y}`).join(" ");
  const baseline = PAD_TOP + innerH;
  const area = `${line} L ${coords[coords.length - 1].x} ${baseline} L ${coords[0].x} ${baseline} Z`;

  return { line, area, coords };
});

const hoverIndex = ref(null);

function handleTrendHover(event) {
  const coords = trendPath.value.coords;
  if (!coords.length) return;
  const rect = event.currentTarget.getBoundingClientRect();
  const x = ((event.clientX - rect.left) / rect.width) * CHART_W;
  let nearest = 0;
  let nearestDist = Infinity;
  coords.forEach((c, i) => {
    const d = Math.abs(c.x - x);
    if (d < nearestDist) {
      nearestDist = d;
      nearest = i;
    }
  });
  hoverIndex.value = nearest;
}

const trendTooltipStyle = computed(() => {
  if (hoverIndex.value === null) return {};
  const c = trendPath.value.coords[hoverIndex.value];
  return {
    left: `${(c.x / CHART_W) * 100}%`,
    top: `${(c.y / CHART_H) * 100}%`,
  };
});

function shouldShowLabel(i) {
  const n = trendPath.value.coords.length;
  if (n <= 6) return true;
  const step = Math.ceil(n / 6);
  return i % step === 0 || i === n - 1;
}

// Keeps the first/last x-axis date labels from overflowing past the chart
// edge: centering them on their point (like the middle labels) pushes half
// the text outside the plot area, so the end labels anchor inward instead.
function xLabelAnchor(i, total) {
  if (i === 0) return "start";
  if (i === total - 1) return "end";
  return "middle";
}

function formatShortDate(dateStr) {
  return new Date(dateStr).toLocaleDateString("id-ID", { day: "2-digit", month: "short" });
}

function formatFullDate(dateStr) {
  return new Date(dateStr).toLocaleDateString("id-ID", { day: "2-digit", month: "short", year: "numeric" });
}

function slugify(text) {
  return text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

function questionHeading(q) {
  return q.tipe === "PilihanMulti" ? `${q.pertanyaan} (Multi Choice)` : q.pertanyaan;
}

function exportToPdf() {
  const surveyLabel = survey.value?.nama ?? "Survei";
  const doc = new jsPDF();
  const pageWidth = doc.internal.pageSize.getWidth() - 14 - 14;

  doc.setFontSize(14);
  doc.text("Hasil Survei Internal - SkyVote", 14, 15);

  doc.setFontSize(10);
  let cursorY = 21;
  const surveyLines = doc.splitTextToSize(`Survei: ${surveyLabel}`, pageWidth);
  doc.text(surveyLines, 14, cursorY);
  cursorY += surveyLines.length * 5;
  doc.text(`Total Responden: ${totalResponden.value}`, 14, cursorY);
  cursorY += 5;
  doc.text(`Diekspor pada: ${new Date().toLocaleString("id-ID")}`, 14, cursorY);
  cursorY += 12;

  if (trendPoints.value.length > 0) {
    doc.setFontSize(12);
    doc.text("Tren Pengisian", 14, cursorY);
    autoTable(doc, {
      head: [["Tanggal", "Jumlah Pengisian"]],
      body: trendPoints.value.map((p) => [formatFullDate(p.tanggal), p.count]),
      startY: cursorY + 3,
      theme: "grid",
      styles: { fontSize: 9 },
      headStyles: { fillColor: [0, 93, 172] },
    });
    cursorY = doc.lastAutoTable.finalY + 10;
  }

  for (const q of results.value) {
    doc.setFontSize(11);
    const headingLines = doc.splitTextToSize(questionHeading(q), pageWidth);
    const headingHeight = headingLines.length * 5;

    if (cursorY + headingHeight > 270) {
      doc.addPage();
      cursorY = 15;
    }
    doc.text(headingLines, 14, cursorY);
    cursorY += headingHeight + 2;

    if (q.tipe === "Lisan") {
      autoTable(doc, {
        head: [["No", "Jawaban"]],
        body: q.answers.length ? q.answers.map((a, i) => [i + 1, a]) : [["-", "Belum ada jawaban"]],
        startY: cursorY,
        theme: "grid",
        styles: { fontSize: 9 },
        headStyles: { fillColor: [0, 93, 172] },
        columnStyles: { 0: { cellWidth: 12 } },
      });
    } else {
      autoTable(doc, {
        head: [["Opsi", "Jumlah", "Persentase"]],
        body: q.options.length
          ? q.options.map((o) => [o.opsi, o.count, `${percentage(o.count, q.totalJawaban)}%`])
          : [["-", "-", "-"]],
        startY: cursorY,
        theme: "grid",
        styles: { fontSize: 9 },
        headStyles: { fillColor: [0, 93, 172] },
      });
    }
    cursorY = doc.lastAutoTable.finalY + 10;
  }

  const dateStamp = new Date().toISOString().slice(0, 10);
  doc.save(`hasil-survei-${slugify(surveyLabel)}-${dateStamp}.pdf`);
}

function exportToExcel() {
  const surveyLabel = survey.value?.nama ?? "Survei";
  const wb = XLSX.utils.book_new();

  if (trendPoints.value.length > 0) {
    const trendAoa = [
      ["Tanggal", "Jumlah Pengisian"],
      ...trendPoints.value.map((p) => [formatFullDate(p.tanggal), p.count]),
    ];
    XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet(trendAoa), "Tren Pengisian");
  }

  const resultsAoa = [[`Survei: ${surveyLabel}`], [`Total Responden: ${totalResponden.value}`], []];
  const percentCells = [];

  for (const q of results.value) {
    resultsAoa.push([questionHeading(q)]);
    if (q.tipe === "Lisan") {
      resultsAoa.push(["No", "Jawaban"]);
      if (q.answers.length) {
        q.answers.forEach((a, i) => resultsAoa.push([i + 1, a]));
      } else {
        resultsAoa.push(["-", "Belum ada jawaban"]);
      }
    } else {
      resultsAoa.push(["Opsi", "Jumlah", "Persentase"]);
      if (q.options.length) {
        q.options.forEach((o) => {
          percentCells.push({ row: resultsAoa.length, col: 2 });
          resultsAoa.push([o.opsi, o.count, percentage(o.count, q.totalJawaban) / 100]);
        });
      } else {
        resultsAoa.push(["-", "-", "-"]);
      }
    }
    resultsAoa.push([]);
  }

  const resultsWs = XLSX.utils.aoa_to_sheet(resultsAoa);
  resultsWs["!cols"] = [{ wch: 32 }, { wch: 12 }, { wch: 12 }];
  for (const { row, col } of percentCells) {
    const cell = resultsWs[XLSX.utils.encode_cell({ r: row, c: col })];
    if (cell) cell.z = "0.0%";
  }
  XLSX.utils.book_append_sheet(wb, resultsWs, "Hasil Survei");

  const dateStamp = new Date().toISOString().slice(0, 10);
  XLSX.writeFile(wb, `hasil-survei-${slugify(surveyLabel)}-${dateStamp}.xlsx`);
}
</script>

<style scoped>
.hasil-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
  width: 100%;
}

.page-heading {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 16px;
}

.page-heading-text {
  min-width: 0;
}

.export-actions {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
}

.btn-export {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
  padding: 10px 18px;
  border: none;
  border-radius: var(--radius-md);
  background-color: var(--color-primary);
  color: #ffffff;
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(0, 93, 172, 0.3);
  transition: background-color 0.15s ease, box-shadow 0.15s ease;
}

.btn-export:hover {
  background-color: var(--color-primary-dark);
  box-shadow: 0 3px 10px rgba(0, 93, 172, 0.4);
}

.btn-export-excel {
  background-color: var(--color-success);
  box-shadow: 0 2px 6px rgba(18, 183, 106, 0.3);
}

.btn-export-excel:hover {
  background-color: #0e9c5a;
  box-shadow: 0 3px 10px rgba(18, 183, 106, 0.4);
}

.back-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
  color: var(--color-text-muted);
  font-size: 13px;
  font-weight: 600;
  text-decoration: none;
}

.back-link:hover {
  color: var(--color-primary);
}

.page-title {
  font-size: 22px;
  font-weight: 800;
  color: var(--color-text);
  letter-spacing: -0.025em;
}

.page-subtitle {
  font-size: 14px;
  color: var(--color-text-muted);
  line-height: 1.5;
}

.state-card {
  padding: 32px;
  text-align: center;
  color: var(--color-text-muted);
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
}

/* ── Trend line chart ────────────────────────────────────────────────── */
.trend-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 22px 24px;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.trend-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.trend-title {
  font-size: 15px;
  font-weight: 700;
  color: var(--color-text);
}

.trend-total {
  font-size: 12px;
  font-weight: 600;
  color: var(--color-text-muted);
  white-space: nowrap;
}

.trend-empty {
  padding: 24px 0;
  font-size: 13px;
  color: var(--color-text-muted);
  font-style: italic;
}

.trend-chart-wrap {
  position: relative;
}

.trend-svg {
  display: block;
  width: 100%;
  aspect-ratio: 600 / 160;
}

.trend-gridline {
  stroke: var(--color-border);
  stroke-width: 1;
}

.trend-tick-label,
.trend-x-label {
  font-size: 10px;
  fill: var(--color-text-muted);
  font-family: var(--font-sans);
}

.trend-area {
  fill: var(--color-primary);
  fill-opacity: 0.1;
  stroke: none;
}

.trend-line {
  fill: none;
  stroke: var(--color-primary);
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.trend-dot {
  fill: var(--color-primary);
  stroke: var(--color-surface);
  stroke-width: 2;
}

.trend-dot-hover {
  fill: var(--color-primary-dark);
}

.trend-crosshair {
  stroke: var(--color-border-strong);
  stroke-width: 1;
  pointer-events: none;
}

.trend-tooltip {
  position: absolute;
  transform: translate(-50%, calc(-100% - 12px));
  padding: 6px 10px;
  border-radius: var(--radius-md);
  background-color: var(--color-text);
  color: #ffffff;
  font-size: 12px;
  white-space: nowrap;
  pointer-events: none;
  box-shadow: var(--shadow-lg);
}

.trend-tooltip-date {
  display: block;
  margin-top: 1px;
  font-size: 11px;
  color: rgba(255, 255, 255, 0.7);
}

/* ── Per-question bar breakdown ──────────────────────────────────────── */
.results {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.question-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 22px 24px;
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.question-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.question-text {
  font-size: 15px;
  font-weight: 700;
  color: var(--color-text);
}

.question-tipe-badge {
  margin-left: 6px;
  padding: 2px 7px;
  border-radius: var(--radius-full);
  background-color: var(--color-bg);
  color: var(--color-text-muted);
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.03em;
  text-transform: uppercase;
  vertical-align: middle;
}

.question-total {
  flex-shrink: 0;
  font-size: 12px;
  font-weight: 600;
  color: var(--color-text-muted);
  white-space: nowrap;
}

.no-options {
  font-size: 13px;
  color: var(--color-text-muted);
  font-style: italic;
}

.chart-subheading {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--color-text-muted);
  margin: 4px 0 -8px;
}

.bar-chart-svg {
  display: block;
  width: 100%;
  aspect-ratio: 600 / 200;
}

.line-area {
  fill: var(--color-primary);
  fill-opacity: 0.1;
  stroke: none;
}

.line-path {
  fill: none;
  stroke: var(--color-primary);
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.line-dot {
  fill: var(--color-primary);
  stroke: var(--color-surface);
  stroke-width: 2;
}

.bar-gridline {
  stroke: var(--color-border);
  stroke-width: 1;
}

.bar-baseline {
  stroke: var(--color-border-strong);
  stroke-width: 1.5;
}

.bar-tick-label {
  font-size: 10px;
  fill: var(--color-text-muted);
  font-family: var(--font-sans);
}

.bar-col {
  fill: var(--color-primary);
  transition: fill 0.15s ease;
}

.bar-col:hover {
  fill: var(--color-primary-dark);
}

.bar-value-label {
  font-size: 11px;
  font-weight: 700;
  fill: var(--color-text);
  font-family: var(--font-sans);
}

.bar-x-label {
  font-size: 11px;
  fill: var(--color-text-secondary);
  font-family: var(--font-sans);
}

.lisan-answers {
  display: flex;
  flex-direction: column;
}

.lisan-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.lisan-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 10px 12px;
  border-radius: var(--radius-md);
  background-color: var(--color-bg);
  font-size: 13px;
  color: var(--color-text-secondary);
  line-height: 1.5;
}

.lisan-item-number {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 20px;
  height: 20px;
  border-radius: var(--radius-full);
  background-color: var(--color-surface);
  color: var(--color-text-muted);
  font-size: 11px;
  font-weight: 700;
}

.lisan-item-text {
  flex: 1;
  min-width: 0;
}
</style>
