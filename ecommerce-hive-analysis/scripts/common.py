"""Shared loader: applies the same cleaning rules as 01_create_tables.hql."""
import pandas as pd

def load_raw(path="data/raw/orders.csv"):
    return pd.read_csv(path, keep_default_na=False)

def load_clean(path="data/raw/orders.csv"):
    df = load_raw(path)
    df["order_date"] = pd.to_datetime(df["order_date"])
    df = df[(df["order_id"] != "") & (df["customer_id"] != "") &
            (df["city"].str.strip() != "") & (df["quantity"] > 0) & (df["unit_price"] > 0)]
    df = df.drop_duplicates(subset="order_id", keep="first").copy()
    df["order_month"] = df["order_date"].dt.strftime("%Y-%m")
    df["net_amount"] = (df["quantity"] * df["unit_price"] * (1 - df["discount_pct"] / 100)).round(2)
    return df
