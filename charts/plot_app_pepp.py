"""Observed vs fitted APP/PEPP yield reactions by country (Estimates_spread.m output).

usage: python3 plot_app_pepp.py <chart_data.csv> <out.png> [subtitle]
CSV columns: country,event,maturity,observed_pp,fitted_pp (percentage points)
"""
import csv
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

SURFACE = "#fcfcfb"
INK = "#0b0b0b"
INK_2 = "#52514e"
GRID = "#e4e3df"
OBSERVED = "#2a78d6"  # categorical slot 1
FITTED = "#eb6834"    # categorical slot 2

src, out = sys.argv[1], sys.argv[2]
subtitle = sys.argv[3] if len(sys.argv) > 3 else ""

rows = list(csv.DictReader(open(src)))
panels = [("DE", "APP"), ("IT", "APP"), ("DE", "PEPP"), ("IT", "PEPP")]
names = {"DE": "Germany", "IT": "Italy"}

plt.rcParams.update({
    "font.family": "DejaVu Sans", "font.size": 10,
    "axes.edgecolor": GRID, "axes.labelcolor": INK_2,
    "xtick.color": INK_2, "ytick.color": INK_2,
})
fig, axes = plt.subplots(2, 2, figsize=(10, 7.2), sharex=True, facecolor=SURFACE)

for ax, (cty, ev) in zip(axes.flat, panels):
    sel = [r for r in rows if r["country"] == cty and r["event"] == ev]
    m = [float(r["maturity"]) for r in sel]
    obs = [100 * float(r["observed_pp"]) for r in sel]
    fit = [100 * float(r["fitted_pp"]) for r in sel]
    ax.set_facecolor(SURFACE)
    ax.axhline(0, color=INK_2, lw=0.8)
    ax.plot(m, obs, color=OBSERVED, lw=2, marker="o", ms=6, label="Observed (event study)")
    ax.plot(m, fit, color=FITTED, lw=2, ls="--", marker="s", ms=5, label="Fitted (model)")
    for y, c, va in ((obs[-1], OBSERVED, "bottom"), (fit[-1], FITTED, "top")):
        ax.annotate(f"{y:.0f}", (m[-1], y), xytext=(6, 0), textcoords="offset points",
                    color=INK, fontsize=9, va="center")
    ax.set_title(f"{names[cty]} – {ev}", loc="left", color=INK, fontsize=11, fontweight="bold")
    ax.grid(axis="y", color=GRID, lw=0.8)
    ax.spines[["top", "right"]].set_visible(False)
    ax.set_xticks(range(5, 11))
    ax.set_xlim(4.7, 10.6)

for ax in axes[1]:
    ax.set_xlabel("Maturity (years)")
for ax in axes[:, 0]:
    ax.set_ylabel("Change in yield (bp)")

handles, labels = axes[0, 0].get_legend_handles_labels()
fig.legend(handles, labels, loc="upper left", ncol=2, frameon=False, bbox_to_anchor=(0.012, 0.915))
fig.suptitle("APP and PEPP yield reactions: observed vs fitted", x=0.02, y=0.975, ha="left",
             color=INK, fontsize=13, fontweight="bold")
if subtitle:
    fig.text(0.02, 0.925, subtitle, ha="left", color=INK_2, fontsize=9)
fig.tight_layout(rect=(0, 0, 1, 0.87))
fig.savefig(out, dpi=160, facecolor=SURFACE)
print("wrote", out)
