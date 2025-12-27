import os
import uuid
import datetime
import pandas as pd
import numpy as np
from sqlalchemy import create_engine
import pyarrow.parquet as pq
from tqdm import tqdm

# --- KONFIGURATION ---
parquet_file_path = "food.parquet"
sqlite_db_path = "vita_base_foods.db"
table_name = "products"
BATCH_SIZE = 50000 

# Namespace für UUIDs
NAMESPACE_FOOD = uuid.UUID('6ba7b810-9dad-11d1-80b4-00c04fd430c8')

# LÄNDER-FILTER (Hier anpassen!)
# Wir suchen nach diesen Tags in 'countries_tags'.
# 'en:germany' = Deutschland
# 'en:united-states' = USA
ALLOWED_COUNTRIES = ["en:germany", "en:united-states"]

def generate_uuid(barcode):
    if not barcode: return str(uuid.uuid4()) 
    return str(uuid.uuid5(NAMESPACE_FOOD, str(barcode)))

def extract_name(name_list):
    """Holt den besten Namen (DE > EN > Erste Wahl)."""
    if not isinstance(name_list, (list, np.ndarray)):
        return ""
    
    best_candidate = ""
    for item in name_list:
        if isinstance(item, dict):
            lang = item.get('lang')
            text = item.get('text')
            
            if lang == 'de': return text 
            if lang == 'en': best_candidate = text
            if not best_candidate: best_candidate = text
    return best_candidate

def extract_nutrients(nutriments_list):
    """Extrahiert Nährwerte und gibt Pandas-Series zurück."""
    # Leeres Template
    default_vals = pd.Series([0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], 
                             index=["calories", "protein", "carbs", "fat", "sugar", "fiber", "salt"])

    if not isinstance(nutriments_list, (list, np.ndarray)):
        return default_vals

    vals = {}
    key_map = {
        'energy-kcal': 'calories',
        'proteins': 'protein',
        'carbohydrates': 'carbs',
        'fat': 'fat',
        'sugars': 'sugar',
        'fiber': 'fiber',
        'salt': 'salt'
    }

    found_any = False
    for item in nutriments_list:
        if isinstance(item, dict):
            name = item.get('name')
            val = item.get('100g')
            
            target_key = key_map.get(name)
            if target_key and val is not None:
                try:
                    vals[target_key] = float(val)
                    found_any = True
                except (ValueError, TypeError):
                    pass
    
    if not found_any:
        return default_vals

    # Merge mit Defaults (damit fehlende Keys 0 sind)
    result = default_vals.copy()
    for k, v in vals.items():
        result[k] = v
        
    result['calories'] = int(result['calories'])
    return result

def is_relevant_country(tags_list):
    """Prüft, ob eines der erlaubten Länder in der Liste ist."""
    if not isinstance(tags_list, (list, np.ndarray)):
        return False
    # Schnittmenge prüfen (Ist irgendein erlaubtes Land in den Tags?)
    # Performance-Optimierung: early return
    for tag in tags_list:
        if tag in ALLOWED_COUNTRIES:
            return True
    return False

def process_batch(df):
    """Verarbeitet einen Chunk mit Filtern."""
    
    # 1. Länder-Filter (Der wichtigste Schritt für die Dateigröße!)
    # Wir filtern VOR der teuren Extraktion
    if "countries_tags" in df.columns:
        mask = df["countries_tags"].apply(is_relevant_country)
        df = df[mask]
    
    if df.empty: return df

    # 2. Basis-Filter (Barcode & Name müssen existieren)
    df = df.dropna(subset=["code"])
    df["code"] = df["code"].astype(str).str.strip()
    df = df[df["code"] != ""]
    
    # Namen extrahieren
    df['name'] = df['product_name'].apply(extract_name)
    df = df[df['name'] != ""]
    
    if df.empty: return df

    # 3. Nährwerte extrahieren
    nutrients_df = df['nutriments'].apply(extract_nutrients)
    
    # 4. Qualitäts-Filter: Produkte ohne Makros entfernen
    # (z.B. Wasser ist okay, aber "Leere Hülle" nicht)
    # Logik: Kalorien > 0 ODER (Protein+Carbs+Fat > 0)
    has_energy = nutrients_df['calories'] > 0
    has_macros = (nutrients_df['protein'] + nutrients_df['carbs'] + nutrients_df['fat']) > 0
    valid_mask = has_energy | has_macros
    
    # Filter anwenden
    df = df[valid_mask]
    nutrients_df = nutrients_df[valid_mask]
    
    if df.empty: return df

    # 5. Zusammenbauen
    df_clean = pd.concat([
        df[['code', 'brands', 'name']].reset_index(drop=True), 
        nutrients_df.reset_index(drop=True)
    ], axis=1)

    # 6. Finalisierung
    df_clean.rename(columns={"code": "barcode", "brands": "brand"}, inplace=True)
    df_clean["brand"] = df_clean["brand"].fillna("")
    
    df_clean = df_clean.drop_duplicates(subset=["barcode"], keep="first")
    df_clean["source"] = "base"
    df_clean["is_liquid"] = 0
    df_clean["id"] = df_clean["barcode"].apply(generate_uuid)
    
    return df_clean

def process_data():
    if not os.path.exists(parquet_file_path):
        print(f"Fehler: '{parquet_file_path}' nicht gefunden.")
        return

    print(f"Öffne '{parquet_file_path}' im Streaming-Modus...")
    print(f"Filter aktiv für: {ALLOWED_COUNTRIES}")
    
    parquet_file = pq.ParquetFile(parquet_file_path)
    total_rows = parquet_file.metadata.num_rows
    print(f"Gesamtanzahl Zeilen (ungefiltert): {total_rows:,}")

    engine = create_engine(f"sqlite:///{sqlite_db_path}")
    
    # WICHTIG: countries_tags mitladen!
    columns = ["code", "brands", "product_name", "nutriments", "countries_tags"]

    processed_count = 0
    is_first_batch = True
    
    pbar = tqdm(total=total_rows, unit="row", desc="Verarbeite")

    for batch in parquet_file.iter_batches(batch_size=BATCH_SIZE, columns=columns):
        df_batch = batch.to_pandas()
        
        # Logik anwenden
        df_clean = process_batch(df_batch)
        
        if not df_clean.empty:
            mode = 'replace' if is_first_batch else 'append'
            df_clean.to_sql(table_name, engine, if_exists=mode, index=False)
            is_first_batch = False
            processed_count += len(df_clean)
        
        pbar.update(len(df_batch))
        
        del df_batch
        del df_clean

    pbar.close()
    print(f"\nVerarbeitung abgeschlossen. {processed_count:,} Produkte gespeichert.")

    # Indizes & Metadata
    print("Erstelle Indizes und Metadaten...")
    with engine.connect() as conn:
        conn.exec_driver_sql("CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)")
        conn.exec_driver_sql("CREATE INDEX IF NOT EXISTS idx_products_id ON products(id)")

        conn.exec_driver_sql("CREATE TABLE IF NOT EXISTS metadata (key TEXT PRIMARY KEY, value TEXT)")
        version_id = datetime.datetime.now().strftime("%Y%m%d%H%M")
        conn.exec_driver_sql(f"INSERT OR REPLACE INTO metadata (key, value) VALUES ('version', '{version_id}')")

    print(f"Fertig! Datenbank '{sqlite_db_path}' erstellt (Version {version_id}).")

if __name__ == "__main__":
    process_data()