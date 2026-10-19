"""Observed vs model-implied yields over the estimation window, DE and IT, 2y/5y/10y."""
import csv, sys, math
from datetime import date
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

SURFACE, INK, INK_2, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3df"
OBS, FIT = "#2a78d6", "#eb6834"
src, out, title, subtitle = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
R = list(csv.DictReader(open(src)))
names = {"DE": "Germany", "IT": "Italy"}
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 9.5, "axes.edgecolor": GRID,
                     "axes.labelcolor": INK_2, "xtick.color": INK_2, "ytick.color": INK_2})
fig, axes = plt.subplots(3, 2, figsize=(11, 8.6), sharex=True, facecolor=SURFACE)
for col, cty in enumerate(["DE", "IT"]):
    for row, mat in enumerate([2, 5, 10]):
        ax = axes[row, col]
        sel = [r for r in R if r["country"] == cty and int(r["maturity"]) == mat]
        d = [date.fromisoformat(r["date"]) for r in sel]
        o = [float(r["observed_pct"]) for r in sel]; f = [float(r["fitted_pct"]) for r in sel]
        rmse = 100 * math.sqrt(sum((a - b) ** 2 for a, b in zip(o, f)) / len(o))
        ax.set_facecolor(SURFACE); ax.grid(axis="y", color=GRID, lw=0.8); ax.spines[["top", "right"]].set_visible(False)
        ax.axhline(0, color=INK_2, lw=0.6)
        ax.plot(d, o, color=OBS, lw=2, label="Observed")
        ax.plot(d, f, color=FIT, lw=1.6, ls="--", label="Model")
        ax.set_title(f"{names[cty]} – {mat}y   (RMSE {rmse:.1f} bp)", loc="left", color=INK, fontsize=10.5, fontweight="bold")
        if col == 0: ax.set_ylabel("Yield (%)")
h, l = axes[0, 0].get_legend_handles_labels()
fig.legend(h, l, loc="upper left", ncol=2, frameon=False, bbox_to_anchor=(0.012, 0.925))
fig.suptitle(title, x=0.02, y=0.985, ha="left", color=INK, fontsize=13, fontweight="bold")
fig.text(0.02, 0.94, subtitle, ha="left", color=INK_2, fontsize=9)
fig.tight_layout(rect=(0, 0, 1, 0.9))
fig.savefig(out, dpi=150, facecolor=SURFACE)
print("wrote", out)
