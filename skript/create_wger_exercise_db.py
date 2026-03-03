import requests
import pandas as pd
import sqlite3
import re
import json
import datetime
import os

def clean_html(raw_html):
    """Entfernt HTML-Tags aus einem String."""
    if not isinstance(raw_html, str):
        return ''
    cleanr = re.compile('<.*?>')
    cleantext = re.sub(cleanr, '', raw_html)
    return cleantext.strip()

def get_id(x):
    """Extrahiert die 'id' aus einem dict oder gibt den Wert zurück."""
    if isinstance(x, dict):
        return x.get('id')
    return x

def process_and_create_db():
    print("🚀 Starte: Lade Daten von wger.de ...")

    try:
        # API Abfragen
        categories_res = requests.get("https://wger.de/api/v2/exercisecategory/")
        muscles_res = requests.get("https://wger.de/api/v2/muscle/")
        # Limit erhöht, um sicher alle zu haben
        exercises_info_res = requests.get("https://wger.de/api/v2/exerciseinfo/?limit=9999") 

        categories_data = categories_res.json().get('results', [])
        muscles_data = muscles_res.json().get('results', [])
        exercises_info_data = exercises_info_res.json().get('results', [])
    except requests.RequestException as e:
        print(f"❌ Fehler beim Download: {e}")
        return

    print(f"📦 Geladen: {len(exercises_info_data)} Übungen, {len(categories_data)} Kategorien, {len(muscles_data)} Muskeln.")

    # Maps erstellen
    category_map = {cat['id']: cat.get('name') for cat in categories_data}
    muscle_map = {m['id']: m.get('name_en') or m.get('name') for m in muscles_data}

    processed_exercises = {}

    for exercise_info in exercises_info_data:
        exercise_id = str(exercise_info.get('id')) # ID als String für Drift
        if not exercise_id:
            continue

        if exercise_id not in processed_exercises:
            # Muskeln als Liste sammeln (für JSON)
            prim_muscles = sorted({muscle_map.get(get_id(m)) for m in exercise_info.get('muscles', []) if muscle_map.get(get_id(m))})
            sec_muscles = sorted({muscle_map.get(get_id(m)) for m in exercise_info.get('muscles_secondary', []) if muscle_map.get(get_id(m))})

            processed_exercises[exercise_id] = {
                'id': exercise_id,
                'category_name': category_map.get(get_id(exercise_info.get('category')), 'Andere'),
                # WICHTIG: Als JSON-String speichern, damit die App es parsen kann
                'muscles_primary': json.dumps(prim_muscles),
                'muscles_secondary': json.dumps(sec_muscles),
                'name_de': '', 'description_de': '',
                'name_en': '', 'description_en': '',
                # Neue Felder für deine App-Logik
                'is_custom': 0,
                'created_by': 'system',
                'source': 'base',
                'image_path': ''
            }

        # Übersetzungen verarbeiten
        for t in exercise_info.get('translations', []):
            lang = t.get('language') 
            name = (t.get('name') or '').strip()
            desc = clean_html(t.get('description') or '')
            
            if lang == 1:  # Deutsch
                if name: processed_exercises[exercise_id]['name_de'] = name
                if desc: processed_exercises[exercise_id]['description_de'] = desc
            elif lang == 2:  # Englisch
                if name: processed_exercises[exercise_id]['name_en'] = name
                if desc: processed_exercises[exercise_id]['description_en'] = desc

    # In DataFrame umwandeln
    final_list = list(processed_exercises.values())
    df = pd.DataFrame(final_list)

    # Fallbacks für Sprachen
    df['name_de'] = df.apply(lambda row: row['name_en'] if not row['name_de'] else row['name_de'], axis=1)
    df['name_en'] = df.apply(lambda row: row['name_de'] if not row['name_en'] else row['name_en'], axis=1)
    df['description_de'] = df.apply(lambda row: row['description_en'] if not row['description_de'] else row['description_de'], axis=1)
    df['description_en'] = df.apply(lambda row: row['description_de'] if not row['description_en'] else row['description_en'], axis=1)

    # Leere entfernen
    df.dropna(subset=['name_de', 'name_en'], how='all', inplace=True)

    print(f"✨ {len(df)} Übungen fertig verarbeitet.")

    # DB erstellen
    db_name = 'hypertrack_training.db'
    if os.path.exists(db_name):
        os.remove(db_name) # Alte löschen für sauberen Neustart

    conn = sqlite3.connect(db_name)
    cursor = conn.cursor()

    # Tabelle exakt wie in Drift definieren
    cursor.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name_de TEXT, 
        name_en TEXT,
        description_de TEXT, 
        description_en TEXT,
        category_name TEXT,
        muscles_primary TEXT, 
        muscles_secondary TEXT,
        image_path TEXT,
        is_custom INTEGER DEFAULT 0,
        created_by TEXT DEFAULT 'system',
        source TEXT DEFAULT 'base'
      )''')

    # Metadaten für Versionierung
    cursor.execute('CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT)')
    version = datetime.datetime.now().strftime("%Y%m%d%H%M")
    cursor.execute("INSERT INTO metadata VALUES ('version', ?)", (version,))

    # Daten schreiben
    df.to_sql('exercises', conn, if_exists='append', index=False)
    
    conn.commit()
    conn.close()

    print(f"\n✅ ERFOLG: '{db_name}' erstellt (Version: {version}).")
    print("👉 Kopiere diese Datei jetzt nach 'assets/db/'!")

if __name__ == '__main__':
    process_and_create_db()