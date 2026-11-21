"""Prints the expected answers (computed with pandas) so they can be compared with Hive's output."""
import pandas as pd
from common import load_raw, load_clean

pd.set_option("display.width", 200)
raw, df = load_raw(), load_clean()
d = df[df["status"] == "Delivered"]
print("raw_records:", len(raw), " valid_records:", len(df), " delivered:", len(d))
print("\nKPIs: net_revenue", round(d.net_amount.sum(), 2), " AOV", round(d.net_amount.mean(), 2),
      " gross", round((d.quantity * d.unit_price).sum(), 2))
print(df.status.value_counts().to_string())
for col in ["category", "city", "payment_method", "order_month"]:
    print(f"\n--- by {col} ---")
    print(d.groupby(col).agg(orders=("order_id", "count"), revenue=("net_amount", "sum"),
                             aov=("net_amount", "mean")).round(2).sort_values("revenue", ascending=False))
print("\n--- top 5 products ---")
print(d.groupby(["product", "category"]).net_amount.sum().round(2).sort_values(ascending=False).head(5))
