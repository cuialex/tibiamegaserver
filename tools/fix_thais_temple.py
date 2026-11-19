#!/usr/bin/env python3
"""
Corrige la posicion del templo de una ciudad dentro de un mapa .otbm.

Por que existe: en el mapa 'maptest.otbm' el templo de Thais (ciudad 1) estaba
guardado con z=3, un lugar sin terreno. Resultado en el juego:
"temple position is wrong" / "character could not be loaded".

Uso:
    python3 tools/fix_thais_temple.py compiler/data/world/maptest.otbm
    python3 tools/fix_thais_temple.py MAPA.otbm --town Thais --id 1 --pos 32369 32241 7

- Hace una copia MAPA.otbm.bak (si no existe ya) antes de tocar nada.
- No cambia el tamano del archivo (solo sobreescribe 5 bytes).
- Es seguro ejecutarlo mas de una vez.
"""
import argparse, shutil, struct, sys, os

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mapa")
    ap.add_argument("--town", default="Thais")
    ap.add_argument("--id", type=int, default=1, help="id de la ciudad en el mapa")
    ap.add_argument("--pos", type=int, nargs=3, default=[32369, 32241, 7],
                    metavar=("X", "Y", "Z"))
    a = ap.parse_args()

    x, y, z = a.pos
    for v in (x, y):
        # En OTBM los bytes 0xFD/0xFE/0xFF son especiales; evitamos escribirlos.
        if any(b >= 0xFD for b in struct.pack("<H", v)):
            sys.exit("Esa posicion contiene bytes reservados de OTBM; elige otra.")

    data = bytearray(open(a.mapa, "rb").read())
    name = a.town.encode()
    key = struct.pack("<IH", a.id, len(name)) + name
    i = data.rfind(key)
    if i == -1:
        sys.exit(f"No encontre la ciudad {a.town} (id {a.id}) en {a.mapa}")
    j = i + len(key)
    antes = struct.unpack("<HHB", data[j:j + 5])
    nuevo = struct.pack("<HHB", x, y, z)
    print(f"Templo de {a.town}: antes {antes} -> ahora {(x, y, z)}")
    if bytes(data[j:j + 5]) == nuevo:
        print("Ya estaba corregido; no se cambia nada.")
        return
    bak = a.mapa + ".bak"
    if not os.path.exists(bak):
        shutil.copyfile(a.mapa, bak)
        print("Copia de seguridad:", bak)
    data[j:j + 5] = nuevo
    open(a.mapa, "wb").write(data)
    print("Listo. Reinicia el servidor para que cargue el mapa.")

if __name__ == "__main__":
    main()
