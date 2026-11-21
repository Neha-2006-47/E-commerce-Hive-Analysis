"""Generate the synthetic e-commerce orders file used by the Hive project.

Creates data/raw/orders.csv: 100 valid orders plus 3 deliberately faulty rows
(a duplicate order_id, a blank city and a zero quantity) so that the cleaning
step in Hive has something to remove. Fixed seed => identical file every run.
"""
import csv, random
from datetime import date, timedelta

random.seed(2026)

CATALOG = {
    "Electronics":    [("Wireless Earbuds", 2499), ("Smart Watch", 5999), ("Power Bank", 1299), ("Bluetooth Speaker", 3299)],
    "Fashion":        [("Running Shoes", 2799), ("Denim Jacket", 2199), ("Cotton Kurta", 899), ("Backpack", 1499)],
    "Home & Kitchen": [("Air Fryer", 6499), ("Mixer Grinder", 3999), ("Bedsheet Set", 1199), ("Cookware Set", 2899)],
    "Books":          [("Data Science Handbook", 699), ("Python Cookbook", 549), ("Novel Collection", 799)],
    "Beauty":         [("Face Serum", 899), ("Hair Dryer", 1599), ("Perfume", 1999)],
}
CAT_WEIGHTS = [0.28, 0.24, 0.20, 0.14, 0.14]
CITIES = ["Bengaluru", "Hyderabad", "Chennai", "Mumbai", "Delhi", "Kolkata"]
CITY_W = [0.22, 0.20, 0.16, 0.18, 0.16, 0.08]
PAY = ["UPI", "Credit Card", "Debit Card", "Cash on Delivery", "Net Banking"]
PAY_W = [0.38, 0.20, 0.16, 0.18, 0.08]
STATUS = ["Delivered", "Cancelled", "Returned"]
STATUS_W = [0.83, 0.09, 0.08]

start, end = date(2026, 10, 1), date(2026, 11, 15)
span = (end - start).days
days = sorted(random.randrange(span + 1) for _ in range(100))

rows = []
for i, d in enumerate(days, 1):
    cat = random.choices(list(CATALOG), CAT_WEIGHTS)[0]
    prod, price = random.choice(CATALOG[cat])
    qty = random.choices([1, 2, 3], [0.70, 0.22, 0.08])[0]
    if price > 5000:
        qty = 1
    disc = random.choice([0, 0, 5, 10, 10, 15, 20])
    rows.append([
        f"O{i:04d}", f"C{random.randint(1, 45):03d}", (start + timedelta(days=d)).isoformat(),
        cat, prod, qty, price, disc,
        random.choices(PAY, PAY_W)[0], random.choices(CITIES, CITY_W)[0],
        random.choices(STATUS, STATUS_W)[0],
    ])

# three deliberately faulty rows
dup = list(rows[9]);                        rows.insert(10, dup)          # duplicate order_id
bad_city = list(rows[39]); bad_city[0] = "O0201"; bad_city[9] = ""        # blank city
bad_qty = list(rows[69]);  bad_qty[0] = "O0202"; bad_qty[5] = 0           # zero quantity
rows.insert(41, bad_city); rows.insert(72, bad_qty)

with open("data/raw/orders.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["order_id", "customer_id", "order_date", "category", "product",
                "quantity", "unit_price", "discount_pct", "payment_method", "city", "status"])
    w.writerows(rows)
print("rows written:", len(rows))
