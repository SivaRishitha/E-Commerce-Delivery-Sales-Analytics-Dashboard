
import pandas as pd
from sqlalchemy import create_engine
from urllib.parse import quote_plus

# ---- connection settings — edit these ----
USER = 'root'
PASSWORD = 'Rishitha@3110'
HOST = 'localhost'
PORT = 3306
DATABASE = 'olist'

# ---- path to the folder where you extracted cleaned_data.zip ----
DATA_DIR = 'C:/Users/intur/Downloads/olist/cleaned_data'    # e.g. 'C:/Users/you/Desktop/olist_project/cleaned_data'

# quote_plus escapes special characters (like @) in the password so the
# connection string doesn't get misread — e.g. a password containing "@"
# would otherwise be parsed as part of the hostname.
engine = create_engine(
    f'mysql+pymysql://{USER}:{quote_plus(PASSWORD)}@{HOST}:{PORT}/{DATABASE}'
)

# Load order matters — parents before children, or foreign keys will reject rows
load_order = [
    ('category_translation_clean.csv', 'category_translation'),
    ('customers_clean.csv',            'customers'),
    ('sellers_clean.csv',              'sellers'),
    ('geolocation_clean.csv',          'geolocation'),
    ('products_clean.csv',             'products'),
    ('orders_clean.csv',               'orders'),
    ('order_items_clean.csv',          'order_items'),
    ('order_payments_clean.csv',       'order_payments'),
    ('order_reviews_clean.csv',        'order_reviews'),
]

for csv_file, table_name in load_order:
    df = pd.read_csv(f'{DATA_DIR}/{csv_file}')
    df.to_sql(table_name, engine, if_exists='append', index=False)
    print(f"Loaded {len(df):>6} rows into {table_name}")

    # Right after category_translation loads, patch in any category names
    # that appear in products but are missing from the translation table —
    # this includes the 'unknown' placeholder from cleaning, plus a couple
    # of category names genuinely missing from Olist's own translation file.
    if table_name == 'category_translation':
        products_df = pd.read_csv(f'{DATA_DIR}/products_clean.csv')
        existing_cats = set(
            pd.read_sql('SELECT product_category_name FROM category_translation', engine)
            ['product_category_name']
        )
        product_cats = set(products_df['product_category_name'].dropna().unique())
        missing_cats = product_cats - existing_cats

        if missing_cats:
            patch_df = pd.DataFrame({
                'product_category_name': sorted(missing_cats),
                'product_category_name_english': sorted(missing_cats),  # no translation available
            })
            patch_df.to_sql('category_translation', engine, if_exists='append', index=False)
            print(f"  Patched {len(missing_cats)} missing categories: {sorted(missing_cats)}")
        else:
            print("  No missing categories to patch.")

print("\nAll tables loaded.")