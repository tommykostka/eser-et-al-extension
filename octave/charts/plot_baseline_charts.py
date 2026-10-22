"""Draws the baseline charts from the CSV files written by baseline_charts.m
(for machines where Octave cannot render plots).
usage: python3 octave/charts/plot_baseline_charts.py [Output_runs/baseline_charts]"""
import csv, math, sys
from collections import defaultdict
from datetime import date
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

D = sys.argv[1] if len(sys.argv) > 1 else "Output_runs/baseline_charts"
RUNS = ["PEPP_GQ3_e50_baseline", "PEPP_GR4_e50_baseline", "PEPP_GQ6_e40_baseline", "APP_HO2_baseline"]
LAB = {"PEPP_GQ3_e50_baseline": "PEPP GQ3 (floor 50)", "PEPP_GR4_e50_baseline": "PEPP GR4 (floor 50)",
       "PEPP_GQ6_e40_baseline": "PEPP GQ6 (floor 40)", "APP_HO2_baseline": "APP HO2"}
COL = dict(zip(RUNS, ["#2a78d6", "#eb6834", "#1baf7a", "#6250d6"]))
SER = {"DE": "OIS", "SP": "IT–OIS spread", "IT": "Italy"}
SURFACE, INK, INK2, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3df"
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 9.5, "axes.edgecolor": GRID,
                     "axes.labelcolor": INK2, "xtick.color": INK2, "ytick.color": INK2})
rmse = lambda o, f: math.sqrt(sum((a - b) ** 2 for a, b in zip(o, f)) / len(o))
read = lambda n: list(csv.DictReader(open(f"{D}/{n}.csv")))

def style(ax):
    ax.set_facecolor(SURFACE); ax.grid(axis="y", color=GRID, lw=0.8)
    ax.spines[["top", "right"]].set_visible(False); ax.axhline(0, color=INK2, lw=0.6)

def finish(fig, title, sub, handles, labels, name, top):
    w, h = fig.get_size_inches(); y = 1 - 0.12 / h          # header laid out in inches from the top
    fig.suptitle(title, x=0.02, y=y, ha="left", va="top", color=INK, fontsize=13, fontweight="bold")
    fig.text(0.02, y - 0.32 / h, sub, ha="left", va="top", color=INK2, fontsize=9)
    ncol = 5 if w > 10 else 3
    fig.legend(handles, labels, loc="upper left", ncol=ncol, frameon=False, bbox_to_anchor=(0.012, y - 0.52 / h))
    rows = math.ceil(len(labels) / ncol)
    fig.tight_layout(rect=(0, 0, 1, y - (0.62 + 0.25 * rows) / h)); fig.savefig(f"{D}/{name}.png", dpi=150, facecolor=SURFACE); plt.close(fig)

def events(name, ev):
    rows = read(name); runs = [r for r in RUNS if any(x["run"] == r for x in rows)]
    fig, axes = plt.subplots(1, 3, figsize=(13, 5.6), facecolor=SURFACE)
    for ax, s in zip(axes, ["DE", "SP", "IT"]):
        style(ax); parts = []
        for k, r in enumerate(runs):
            sel = [x for x in rows if x["run"] == r and x["series"] == s]
            m = [int(x["maturity"]) for x in sel]; o = [float(x["observed_bp"]) for x in sel]; f = [float(x["fitted_bp"]) for x in sel]
            if k == 0: ax.plot(m, o, color=INK, lw=2.2, marker="o", ms=6, label="Observed")
            ax.plot(m, f, color=COL[r], lw=1.8, ls="--", marker="s", ms=5, label=LAB[r]); parts.append(f"{rmse(o, f):.1f}")
        ax.set_title(f"{SER[s]} – {ev}\nRMSE " + " / ".join(parts) + " bp", loc="left", fontsize=9.5, fontweight="bold", color=INK)
        ax.set_xticks(m); ax.set_xlabel("Maturity (years)")
    axes[0].set_ylabel("Change (bp)"); h, l = axes[0].get_legend_handles_labels()
    sub = "18–20 Mar 2020" if ev == "PEPP" else "average over the APP announcement dates, Sep 2014 – Mar 2015"
    finish(fig, f"{ev} reaction at 5–10y: observed vs baseline fits", f"OIS anchor; {sub}", h, l, name, 0.88)

def series(name, panels, title):
    rows = read(name); data = defaultdict(lambda: ([], [], []))
    for x in rows:
        t = data[(x["run"], x["series"], x["maturity"])]
        y, mo, d = map(int, x["date"].split("-")); t[0].append(date(y, mo, d)); t[1].append(float(x["observed_pct"])); t[2].append(float(x["fitted_pct"]))
    nc = len(panels)
    fig, axes = plt.subplots(3, nc, figsize=(6.6 * nc, 10), facecolor=SURFACE, squeeze=False)
    for i, m in enumerate(["2", "5", "10"]):
        for p, s in enumerate(panels):
            ax = axes[i][p]; style(ax); parts = []
            for k, r in enumerate(RUNS):
                d, o, f = data[(r, s, m)]
                if k == 0: ax.plot(d, o, color=INK, lw=1.8, label="Observed")
                ax.plot(d, f, color=COL[r], lw=1.1, ls="--", label=LAB[r]); parts.append(f"{100 * rmse(o, f):.0f}")
            ax.set_title(f"{SER[s]} – {m}y   RMSE " + " / ".join(parts) + " bp", loc="left", fontsize=9.5, fontweight="bold", color=INK)
            if p == 0: ax.set_ylabel("Percent")
    h, l = axes[0][0].get_legend_handles_labels()
    finish(fig, title, "OIS anchor; monthly, in sample", h, l, name, 0.92)

def elasticity():
    rows = read("elasticity")
    fig, ax = plt.subplots(figsize=(9, 5.6), facecolor=SURFACE); style(ax)
    for r in RUNS:
        sel = [x for x in rows if x["run"] == r]
        ax.plot([int(x["maturity"]) for x in sel], [float(x["bp_per_10pp"]) for x in sel], color=COL[r], lw=1.9, marker="o", ms=5, label=LAB[r])
        ax.annotate(f"{float(sel[-1]['bp_per_10pp']):+.0f}", (10.15, float(sel[-1]["bp_per_10pp"])), color=COL[r], fontsize=9, va="center")
    ax.set_xticks(range(1, 11)); ax.set_xlim(0.7, 10.8); ax.set_xlabel("Maturity (years)"); ax.set_ylabel("bp")
    h, l = ax.get_legend_handles_labels()
    finish(fig, "IT–OIS spread effect of +10 pp of the fiscal factor", "fiscal factor: IT purchases / GDP; PEPP baselines have a floor on the 5–10y effect", h, l, "elasticity", 0.86)

events("pepp_event", "PEPP"); events("app_event", "APP")
series("yields", ["DE", "IT"], "Yield fit, Mar 2009 – Dec 2021")
series("spread", ["SP"], "IT–OIS spread fit, Mar 2009 – Dec 2021")
elasticity()
print("done")
