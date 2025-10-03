import os

# Ordner, in dem gesucht werden soll
#root_dir = "D:\lightweight\lib"   # <--- hier anpassen
root_dir = "/Users/richard/Projects/Lightweight/lightweight"
output_file = "alle_dateien.txt"

with open(output_file, "w", encoding="utf-8") as outfile:
    for folder, _, files in os.walk(root_dir):
        for file in files:
            if file.endswith(".dart"):  # ggf. erweitern (z.B. (".dart", ".txt"))
                filepath = os.path.join(folder, file)
                outfile.write(f"\n===== Datei: {filepath} =====\n\n")
                try:
                    with open(filepath, "r", encoding="utf-8") as infile:
                        outfile.write(infile.read())
                        outfile.write("\n")
                except Exception as e:
                    outfile.write(f"[Fehler beim Lesen: {e}]\n")

print(f"Fertig! Alles steht in {output_file}")
