#!/usr/bin/env python3
"""号数と送料の計算ロジックの写しと自己点検。

Swift 側（CanvasSize.swift, ReverseLookup.swift, PackingSpec.swift,
ShippingRateData.swift, ShippingEstimate.swift）と同じ式を Python に写し、
収録したデータと計算の境界が意図どおりかを確かめる。

データは Swift のソースから読み取る。写しの表と突き合わせるので、
どちらかを直したときに食い違いが見つかる。
"""

import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

ZONES = ["kansai", "chubuHokuriku", "kantoShinetsu", "kyushu", "hokkaido"]
ZONE_LABEL = {
    "kansai": "関西",
    "chubuHokuriku": "中部・北陸",
    "kantoShinetsu": "関東・信越",
    "kyushu": "九州",
    "hokkaido": "北海道",
}

GOLDEN = 1.618
NUMBERS = [0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 25, 30, 40, 50, 60, 80, 100]

# 日本サイズ（長辺, 短辺）。全日本画材協議会の表と画材店の一覧で確認した値。
CANVAS = {
    "F": {
        0: (180, 140), 1: (220, 160), 2: (240, 190), 3: (273, 220),
        4: (333, 242), 5: (350, 270), 6: (410, 318), 8: (455, 380),
        10: (530, 455), 12: (606, 500), 15: (652, 530), 20: (727, 606),
        25: (803, 652), 30: (910, 727), 40: (1000, 803), 50: (1167, 910),
        60: (1303, 970), 80: (1455, 1120), 100: (1620, 1303),
    },
    "P": {
        0: (180, 120), 1: (220, 140), 2: (240, 160), 3: (273, 190),
        4: (333, 220), 5: (350, 240), 6: (410, 273), 8: (455, 333),
        10: (530, 410), 12: (606, 455), 15: (652, 500), 20: (727, 530),
        25: (803, 606), 30: (910, 652), 40: (1000, 727), 50: (1167, 803),
        60: (1303, 894), 80: (1455, 970), 100: (1620, 1120),
    },
    "M": {
        0: (180, 100), 1: (220, 120), 2: (240, 140), 3: (273, 160),
        4: (333, 190), 5: (350, 220), 6: (410, 242), 8: (455, 273),
        10: (530, 333), 12: (606, 410), 15: (652, 455), 20: (727, 500),
        25: (803, 530), 30: (910, 606), 40: (1000, 652), 50: (1167, 727),
        60: (1303, 803), 80: (1455, 894), 100: (1620, 970),
    },
    "S": {},
}
# S は号数と同じ長辺の正方形。
CANVAS["S"] = {n: (v[0], v[0]) for n, v in CANVAS["F"].items()}
SAM_HALL = (227, 158)

# 三社の運賃（関西発・税込）。ZONES の順。
YAMATO_FARES = {
    60: [940, 940, 1060, 1060, 1920],
    80: [1230, 1230, 1350, 1350, 2200],
    100: [1530, 1530, 1650, 1650, 2510],
    120: [2040, 2040, 2170, 2170, 3120],
    140: [2630, 2630, 2780, 2780, 3810],
    160: [3020, 3020, 3160, 3160, 4180],
    180: [3680, 3680, 4480, 4480, 6820],
    200: [4470, 4470, 5410, 5410, 8410],
}
JAPAN_POST_FARES = {
    60: [970, 970, 1090, 1090, 1910],
    80: [1320, 1320, 1440, 1440, 2240],
    100: [1650, 1650, 1780, 1780, 2590],
    120: [2010, 2010, 2130, 2130, 2920],
    140: [2600, 2600, 2760, 2760, 3610],
    160: [3000, 3000, 3130, 3130, 4000],
    170: [3680, 3680, 4500, 4500, 6040],
}
SAGAWA_FARES = {
    60: [910, 910, 1040, 1040, 1820],
    80: [1220, 1220, 1340, 1340, 2100],
    100: [1520, 1520, 1630, 1630, 2350],
    140: [2180, 2180, 2310, 2310, 3090],
    160: [2440, 2440, 2570, 2570, 3340],
    170: [2600, 2770, 3360, 3130, 4890],
    180: [2890, 2950, 3660, 3360, 5480],
    200: [3480, 3480, 4480, 4070, 6900],
    220: [4070, 4070, 5240, 4710, 8300],
    240: [5240, 5240, 6830, 6130, 11070],
    260: [6420, 6420, 8420, 7480, 13890],
}
SAGAWA_LARGE = {170, 180, 200, 220, 240, 260}

FAILURES = []


def check(condition, message):
    if not condition:
        FAILURES.append(message)
        print(f"FAIL  {message}")


# ---------------------------------------------------------------- Swift を読む

def read_source(relative):
    return (ROOT / relative).read_text(encoding="utf-8")


def parse_catalog():
    """CanvasSize.swift から号数の表を読み取る。"""
    text = read_source("Sources/Models/CanvasSize.swift")
    found = {}
    for key in ["f", "p", "m", "s"]:
        match = re.search(
            rf"static let {key}Sizes: \[CanvasSize\] = rows\(\.{key}, \[(.*?)\]\)",
            text,
            re.S,
        )
        check(match is not None, f"{key.upper()} の表が読めません")
        if not match:
            continue
        triples = re.findall(r"\((\d+),\s*(\d+),\s*(\d+)\)", match.group(1))
        found[key.upper()] = {int(n): (int(a), int(b)) for n, a, b in triples}
    sm = re.search(r"samHall = CanvasSize\(type: \.sm, number: nil, longMm: (\d+), shortMm: (\d+)\)", text)
    check(sm is not None, "サムホールが読めません")
    if sm:
        found["SM"] = (int(sm.group(1)), int(sm.group(2)))
    return found


def parse_tables():
    """ShippingRateData.swift から三社の表を読み取る。"""
    text = read_source("Sources/Models/ShippingRateData.swift")
    tables = {}
    pattern = re.compile(
        r"CarrierTable\(carrier: \.(\w+),\s*"
        r"maxCm: (\d+),\s*maxKg: ([\d.]+),\s*"
        r"maxLongSideCm: (nil|\d+),\s*rows: \[(.*?)\n\s*\]\)",
        re.S,
    )
    for match in pattern.finditer(text):
        carrier, max_cm, max_kg, max_side, rows_text = match.groups()
        rows = {}
        large = set()
        for row in re.finditer(r"row\((\d+), \[([\d,\s]+)\](, large: true)?\)", rows_text):
            size = int(row.group(1))
            values = [int(v.strip()) for v in row.group(2).split(",") if v.strip()]
            rows[size] = values
            if row.group(3):
                large.add(size)
        tables[carrier] = {
            "maxCm": int(max_cm),
            "maxKg": float(max_kg),
            "maxLongSideCm": None if max_side == "nil" else int(max_side),
            "rows": rows,
            "large": large,
        }
    return tables


# ---------------------------------------------------------------- 計算の写し

def reverse_lookup(long_mm, short_mm, catalog):
    """長辺・短辺から近い号数を並べる（4件）。0 以下は対象外。"""
    if long_mm <= 0 or short_mm <= 0:
        return []
    order = list(catalog.keys())
    long_side = max(long_mm, short_mm)
    short_side = min(long_mm, short_mm)
    matches = []
    for index, name in enumerate(order):
        long_value, short_value = catalog[name]
        distance = math.hypot(long_value - long_side, short_value - short_side)
        matches.append((distance, index, name))
    matches.sort(key=lambda item: (round(item[0], 4), item[1]))
    return matches[:4]


def packed_size(long_mm, short_mm, margin=50, thickness=30, framed=False):
    extra = 30 if framed else 0
    depth = 20 if framed else 0
    packed = (long_mm + margin + extra, short_mm + margin + extra, thickness + depth)
    total_mm = sum(packed)
    total_cm = math.ceil(round(total_mm / 10, 6))
    return packed, total_mm, total_cm


def size_class(table, total_cm, long_side_cm, weight_kg=0.0):
    """区分と運賃を出す。送れないときは (None, 理由)。"""
    if total_cm > table["maxCm"]:
        return None, f"上限{table['maxCm']}cmを超えます"
    limit = table["maxLongSideCm"]
    if limit is not None and long_side_cm > limit:
        return None, f"1辺{limit}cmを超えます"
    if weight_kg > table["maxKg"]:
        return None, f"重さ{int(table['maxKg'])}kgを超えます"
    for size in sorted(table["rows"]):
        if total_cm <= size:
            return size, None
    return None, "上限を超えます"


def fare(table, size, zone_index):
    values = table["rows"].get(size)
    return None if values is None else values[zone_index]


def advisories(total_cm, long_side_cm):
    messages = []
    if total_cm > 260:
        messages.append("over260")
    elif total_cm > 200:
        messages.append("over200")
    elif total_cm > 170:
        messages.append("over170")
    if long_side_cm > 170 and total_cm <= 200:
        messages.append("side170")
    return messages


# ---------------------------------------------------------------- 点検

def main():
    catalog = parse_catalog()

    # 1. 号数の網羅
    flat = {}
    for key, rows in catalog.items():
        if key == "SM":
            flat["SM"] = rows
            continue
        for number, dims in rows.items():
            flat[f"{key}{number}"] = dims

    check(len(flat) == 77, f"号数が 77 件ではありません（{len(flat)} 件）")
    check(len(catalog.get("F", {})) == 19, "F が 19 号ではありません")
    check(len(catalog.get("P", {})) == 19, "P が 19 号ではありません")
    check(len(catalog.get("M", {})) == 19, "M が 19 号ではありません")
    check(len(catalog.get("S", {})) == 19, "S が 19 号ではありません")
    check(catalog.get("SM") == SAM_HALL, f"サムホールが {SAM_HALL} ではありません")

    for key in ["F", "P", "M", "S"]:
        check(sorted(catalog[key]) == NUMBERS, f"{key} の号数が揃っていません")

    for name, (long_side, short_side) in flat.items():
        check(long_side > short_side or (name.startswith("S") and long_side == short_side),
              f"{name} の長辺が短辺以下です（{long_side} × {short_side}）")

    # 2. 主要号数の実寸（写しの表と一致するか）
    for key, rows in CANVAS.items():
        for number, dims in rows.items():
            check(catalog[key][number] == dims,
                  f"{key}{number} が {dims} ではなく {catalog[key][number]}")

    for name, dims in [("F0", (180, 140)), ("F6", (410, 318)), ("F100", (1620, 1303)),
                       ("P6", (410, 273)), ("M6", (410, 242)), ("S6", (410, 410)),
                       ("SM", (227, 158))]:
        check(flat[name] == dims, f"{name} が {dims} ではありません")

    # 3. 逆引き
    best = reverse_lookup(410, 318, flat)
    check(best[0][2] == "F6" and best[0][0] < 0.001, f"410×318 の最短が {best[0]} です")
    rotated = reverse_lookup(318, 410, flat)
    check(rotated[0][2] == "F6", "長辺・短辺を入れ替えると結果が変わります")

    near = reverse_lookup(400, 320, flat)
    check(near[0][2] == "F6", f"400×320 の最短が {near[0][2]} です")
    check(len(near) == 4, "候補が4件ではありません")
    distances = [item[0] for item in near]
    check(distances == sorted(distances), "候補が近い順に並んでいません")
    print("  400×320 の候補:", [(name, round(d, 1)) for d, _, name in near])

    check(reverse_lookup(1000, 800, flat)[0][2] == "F40",
          f"1000×800 の最短が {reverse_lookup(1000, 800, flat)[0][2]} です")
    check(reverse_lookup(227, 158, flat)[0][2] == "SM", "227×158 でサムホールが出ません")
    check(reverse_lookup(0, 100, flat) == [], "0 を入れたら候補が出ています")

    # 4. 梱包
    packed, total_mm, total_cm = packed_size(410, 318)
    check(packed == (460, 368, 30), f"F6 の梱包が {packed} です")
    check(total_mm == 858 and total_cm == 86, f"F6 の3辺合計が {total_mm}mm / {total_cm}cm です")

    framed, framed_mm, framed_cm = packed_size(410, 318, framed=True)
    check(framed == (490, 398, 50), f"F6 額装の梱包が {framed} です")
    check(framed_mm == 938 and framed_cm == 94, f"F6 額装の3辺合計が {framed_mm}mm / {framed_cm}cm です")

    check(packed_size(1000, 803)[2] == 194, "F40 の3辺合計が 194cm ではありません")
    check(packed_size(180, 140)[2] == 45, "F0 の3辺合計が 45cm ではありません")

    # 5. 運賃表（写しと一致するか）
    tables = parse_tables()
    check(set(tables) == {"yamato", "japanPost", "sagawa"}, f"三社の表が揃っていません: {sorted(tables)}")

    expected = {
        "yamato": (200, 30, 170, YAMATO_FARES, set()),
        "japanPost": (170, 25, None, JAPAN_POST_FARES, set()),
        "sagawa": (260, 50, None, SAGAWA_FARES, SAGAWA_LARGE),
    }
    for carrier, (max_cm, max_kg, max_side, fares, large) in expected.items():
        table = tables[carrier]
        check(table["maxCm"] == max_cm, f"{carrier} の上限が {table['maxCm']} です")
        check(table["maxKg"] == max_kg, f"{carrier} の重量上限が {table['maxKg']} です")
        check(table["maxLongSideCm"] == max_side, f"{carrier} の1辺上限が {table['maxLongSideCm']} です")
        check(set(table["rows"]) == set(fares), f"{carrier} のサイズ区分が違います: {sorted(table['rows'])}")
        check(table["large"] == large, f"{carrier} の大型区分が違います: {sorted(table['large'])}")
        for size, values in fares.items():
            check(table["rows"].get(size) == values,
                  f"{carrier} {size} の運賃が {table['rows'].get(size)} です（期待 {values}）")
            check(len(values) == len(ZONES), f"{carrier} {size} の着地が5つではありません")

    # 6. 区分の境界
    yamato = tables["yamato"]
    for total, want in [(60, 60), (61, 80), (100, 100), (159, 160), (160, 160),
                        (161, 180), (170, 180), (180, 180), (199, 200), (200, 200)]:
        size, _ = size_class(yamato, total, 100)
        check(size == want, f"ヤマト {total}cm が {want} ではなく {size}")
    size, reason = size_class(yamato, 201, 100)
    check(size is None and "上限200cm" in reason, "ヤマト 201cm が送れる判定です")
    size, reason = size_class(yamato, 180, 171)
    check(size is None and "1辺170cm" in reason, "ヤマト 1辺171cm が送れる判定です")

    post = tables["japanPost"]
    for total, want in [(60, 60), (160, 160), (161, 170), (170, 170)]:
        size, _ = size_class(post, total, 100)
        check(size == want, f"ゆうパック {total}cm が {want} ではなく {size}")
    size, reason = size_class(post, 171, 100)
    check(size is None and "上限170cm" in reason, "ゆうパック 171cm が送れる判定です")

    sagawa = tables["sagawa"]
    for total, want in [(60, 60), (100, 100), (101, 140), (160, 160), (161, 170),
                        (220, 220), (260, 260)]:
        size, _ = size_class(sagawa, total, 100)
        check(size == want, f"佐川 {total}cm が {want} ではなく {size}")
    size, reason = size_class(sagawa, 261, 100)
    check(size is None and "上限260cm" in reason, "佐川 261cm が送れる判定です")

    # 7. 運賃の拾い読み
    check(fare(yamato, 160, 0) == 3020, "ヤマト 160 の関西が 3,020 円ではありません")
    check(fare(yamato, 200, 2) == 5410, "ヤマト 200 の関東が 5,410 円ではありません")
    check(fare(post, 170, 2) == 4500, "ゆうパック 170 の関東が 4,500 円ではありません")
    check(fare(sagawa, 260, 0) == 6420, "佐川 260 の関西が 6,420 円ではありません")
    check(fare(sagawa, 200, 2) == 4480, "佐川 200 の関東が 4,480 円ではありません")

    # 8. 大型便の案内
    check(advisories(86, 46) == [], "86cm で注意が出ています")
    check(advisories(171, 100) == ["over170"], "171cm の注意が違います")
    check(advisories(201, 100) == ["over200"], "201cm の注意が違います")
    check(advisories(261, 100) == ["over260"], "261cm の注意が違います")
    check(advisories(180, 171) == ["over170", "side170"], "1辺超過の注意が違います")

    # 9. 代表的な号数の3辺合計と判定
    print()
    for name in ["F0", "F6", "F10", "F20", "F30", "F50", "F100", "SM"]:
        long_side, short_side = flat[name]
        _, _, total = packed_size(long_side, short_side)
        y_size, _ = size_class(yamato, total, long_side / 10)
        p_size, _ = size_class(post, total, long_side / 10)
        s_size, _ = size_class(sagawa, total, long_side / 10)
        print(f"  {name:>4}  {long_side}×{short_side}  3辺 {total:>3}cm  "
              f"ヤマト {y_size}  ゆう {p_size}  佐川 {s_size}")

    print()
    if FAILURES:
        print(f"{len(FAILURES)} 件の不一致")
        return 1
    print(f"すべて一致（号数 {len(flat)} 件、三社 {len(tables)} 表）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
