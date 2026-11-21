"""Draws the figures used in the report (pandas + Matplotlib, run after the Hive job)."""
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from common import load_clean

df = load_clean()
d = df[df["status"] == "Delivered"]
BLUE, RED = "#1f4e79", "#c0504d"

def bar(ax, s, title, color=BLUE, fmt="{:g}"):
    b = ax.bar(s.index.astype(str), s.values, color=color)
    for r in b:
        ax.text(r.get_x() + r.get_width() / 2, r.get_height(), fmt.format(r.get_height()),
                ha="center", va="bottom", fontsize=8)
    ax.set_title(title, fontweight="bold", fontsize=10)
    ax.spines[["top", "right"]].set_visible(False)
    ax.set_ylim(0, max(s.values) * 1.18)
    plt.setp(ax.get_xticklabels(), rotation=15, fontsize=8)

def save(fig, name):
    fig.tight_layout(); fig.savefig(f"figures/{name}.png", dpi=200); plt.close(fig)

# Figure 3: revenue by category
fig, ax = plt.subplots(figsize=(6.2, 3.4))
bar(ax, (d.groupby("category").net_amount.sum() / 1000).round(1).sort_values(ascending=False),
    "Net revenue by category (Rs. thousand)")
save(fig, "fig_category")

# Figure 4: orders and average order value by category
g = d.groupby("category").agg(orders=("order_id", "count"), aov=("net_amount", "mean")).sort_values("orders", ascending=False)
fig, (a, b) = plt.subplots(1, 2, figsize=(8, 3.5))
bar(a, g["orders"], "Delivered orders by category", RED)
bar(b, g["aov"].round(0), "Average order value (Rs.)", fmt="{:,.0f}")
save(fig, "fig_category_aov")

# Figure 5: monthly orders/revenue and payment method
m = d.groupby("order_month").agg(orders=("order_id", "count"), rev=("net_amount", "sum"))
fig, (a, b) = plt.subplots(1, 2, figsize=(8, 3.5), gridspec_kw={"width_ratios": [1, 1.3]})
bar(a, (m["rev"] / 1000).round(1), "Net revenue by month (Rs. thousand)")
bar(b, (d.groupby("payment_method").net_amount.sum() / 1000).round(1).sort_values(ascending=False),
    "Net revenue by payment method (Rs. thousand)", RED)
save(fig, "fig_month_payment")

# Figure 6: city revenue and order status
fig, (a, b) = plt.subplots(1, 2, figsize=(8, 3.5))
bar(a, (d.groupby("city").net_amount.sum() / 1000).round(1).sort_values(ascending=False),
    "Net revenue by city (Rs. thousand)")
oc = df["status"].value_counts()
b.pie(oc.values, labels=[f"{k} ({v})" for k, v in oc.items()], colors=[BLUE, RED, "#9bb7d4"],
      autopct="%1.0f%%", startangle=90, textprops={"fontsize": 8})
b.set_title("Order status", fontweight="bold", fontsize=10)
save(fig, "fig_city_status")

# Figure 7: top products
p = (d.groupby("product").net_amount.sum() / 1000).round(1).sort_values(ascending=False).head(8)
fig, ax = plt.subplots(figsize=(7.2, 3.4))
bar(ax, p, "Top 8 products by net revenue (Rs. thousand)", RED)
save(fig, "fig_products")

# Figure 8: heat map category x payment
ct = pd.crosstab(d["category"], d["payment_method"])
fig, ax = plt.subplots(figsize=(7.2, 3.4))
ax.imshow(ct.values, cmap="Blues")
ax.set_xticks(range(len(ct.columns)), ct.columns, rotation=20, fontsize=8)
ax.set_yticks(range(len(ct.index)), ct.index, fontsize=8)
for i in range(ct.shape[0]):
    for j in range(ct.shape[1]):
        ax.text(j, i, ct.values[i, j], ha="center", va="center",
                color="white" if ct.values[i, j] >= ct.values.max() * 0.6 else "black")
ax.set_title("Delivered orders by category and payment method", fontweight="bold", fontsize=10)
save(fig, "fig_heatmap")

# Figure 9: weekly revenue trend
w = d.set_index("order_date").net_amount.resample("W-SUN").sum() / 1000
fig, ax = plt.subplots(figsize=(7.2, 3.2))
ax.plot([x.strftime("%d %b") for x in w.index], w.values.round(1), marker="o", color=BLUE)
ax.set_title("Weekly net revenue (Rs. thousand, week ending Sunday)", fontweight="bold", fontsize=10)
ax.spines[["top", "right"]].set_visible(False); plt.setp(ax.get_xticklabels(), fontsize=8)
save(fig, "fig_weekly")
