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

# 三社の運賃は都道府県の地帯番号で引く。写しの地帯分け。
PREFECTURES = [
    "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
    "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県", "山梨県",
    "新潟県", "長野県", "富山県", "石川県", "福井県",
    "岐阜県", "静岡県", "愛知県", "三重県",
    "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県",
    "鳥取県", "島根県", "岡山県", "広島県", "山口県",
    "徳島県", "香川県", "愛媛県", "高知県",
    "福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県",
]

YAMATO_ZONE = {
    "北海道": 0,
    "青森県": 1, "秋田県": 1, "岩手県": 1,
    "宮城県": 2, "山形県": 2, "福島県": 2,
    "茨城県": 3, "栃木県": 3, "群馬県": 3, "埼玉県": 3, "千葉県": 3,
    "神奈川県": 3, "東京都": 3, "山梨県": 3,
    "新潟県": 4, "長野県": 4,
    "富山県": 5, "石川県": 5, "福井県": 5,
    "静岡県": 6, "愛知県": 6, "三重県": 6, "岐阜県": 6,
    "大阪府": 7, "京都府": 7, "滋賀県": 7, "奈良県": 7, "和歌山県": 7, "兵庫県": 7,
    "岡山県": 8, "広島県": 8, "山口県": 8, "鳥取県": 8, "島根県": 8,
    "香川県": 9, "徳島県": 9, "愛媛県": 9, "高知県": 9,
    "福岡県": 10, "佐賀県": 10, "長崎県": 10, "熊本県": 10, "大分県": 10,
    "宮崎県": 10, "鹿児島県": 10,
    "沖縄県": 11,
}

SAGAWA_ZONE = {
    "北海道": 0,
    "青森県": 1, "岩手県": 1, "秋田県": 1,
    "宮城県": 2, "山形県": 2, "福島県": 2,
    "茨城県": 3, "栃木県": 3, "群馬県": 3, "埼玉県": 3, "千葉県": 3,
    "東京都": 3, "神奈川県": 3, "山梨県": 3,
    "新潟県": 4, "長野県": 4,
    "静岡県": 5, "愛知県": 5, "岐阜県": 5, "三重県": 5,
    "富山県": 6, "石川県": 6, "福井県": 6,
    "滋賀県": 7, "京都府": 7, "大阪府": 7, "兵庫県": 7, "奈良県": 7, "和歌山県": 7,
    "鳥取県": 8, "島根県": 8, "岡山県": 8, "広島県": 8, "山口県": 8,
    "徳島県": 9, "香川県": 9, "愛媛県": 9, "高知県": 9,
    "福岡県": 10, "佐賀県": 10, "長崎県": 10, "大分県": 10,
    "熊本県": 11, "宮崎県": 11, "鹿児島県": 11,
    "沖縄県": 12,
}

POST_ZONE = {
    "北海道": 0,
    "青森県": 1, "岩手県": 1, "宮城県": 1, "秋田県": 1, "山形県": 1, "福島県": 1,
    "茨城県": 2, "栃木県": 2, "群馬県": 2, "埼玉県": 2, "千葉県": 2,
    "東京都": 2, "神奈川県": 2, "山梨県": 2,
    "新潟県": 3, "長野県": 3,
    "富山県": 4, "石川県": 4, "福井県": 4,
    "静岡県": 5, "岐阜県": 5, "愛知県": 5, "三重県": 5,
    "滋賀県": 6, "京都府": 6, "大阪府": 6, "兵庫県": 6, "奈良県": 6, "和歌山県": 6,
    "鳥取県": 7, "島根県": 7, "岡山県": 7, "広島県": 7, "山口県": 7,
    "徳島県": 8, "香川県": 8, "愛媛県": 8, "高知県": 8,
    "福岡県": 9, "佐賀県": 9, "長崎県": 9, "熊本県": 9, "大分県": 9,
    "宮崎県": 9, "鹿児島県": 9,
    "沖縄県": 10,
}

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
CANVAS["S"] = {n: (v[0], v[0]) for n, v in CANVAS["F"].items()}
SAM_HALL = (227, 158)

# 三社の公表値からの拾い読み（2026年11月時点）。
YAMATO_SPOT = {
    ("大阪府", "大阪府", 60): 790,
    ("大阪府", "東京都", 160): 3160,
    ("大阪府", "東京都", 100): 1650,
    ("北海道", "福岡県", 200): 9770,
    ("沖縄県", "東京都", 60): 1460,
}
POST_SPOT = {
    ("大阪府", "大阪府", 60): 840,
    ("大阪府", "京都府", 60): 970,
    ("大阪府", "東京都", 60): 1090,
    ("大阪府", "北海道", 60): 1910,
    ("東京都", "東京都", 60): 840,
    ("北海道", "東京都", 60): 1550,
}
SAGAWA_SPOT = {
    ("大阪府", "大阪府", 60): 910,
    ("大阪府", "東京都", 60): 1040,
    ("大阪府", "大阪府", 170): 2600,
    ("大阪府", "沖縄県", 170): 13266,
    ("東京都", "大阪府", 60): 1040,
}

# 補償と大きさの境目（各社の公表値）。
COMPENSATION = {
    "yamato": "30万",
    "japanPost": "30万(50万)",
    "sagawa": "30万",
}

LIMITS = {
    "yamato": (200, 30, 170),
    "japanPost": (170, 25, None),
    "sagawa": (260, 50, None),
}

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


def parse_zone_switch(text, header):
    start = text.index(header)
    body = text[start:text.index("\n    }", start)]
    mapping = {}
    for case, value in re.findall(r"case \.(\w+): return (\d+)", body):
        mapping[case] = int(value)
    return mapping


def parse_rates():
    """ShippingRateData.swift から地帯と運賃の表を読み取る。"""
    text = read_source("Sources/Models/ShippingRateData.swift")

    name_block = text[text.index("var name: String {"):]
    name_block = name_block[:name_block.index("\n    }")]
    names = {case: name for case, name in re.findall(r'case \.(\w+): return "([^"]+)"', name_block)}

    zones = {
        "yamato": parse_zone_switch(text, "var yamatoZone: Int {"),
        "sagawa": parse_zone_switch(text, "var sagawaZone: Int {"),
        "post": parse_zone_switch(text, "var postZone: Int {"),
    }

    def rows(header, keys, follow):
        start = text.index(header)
        block = text[start:text.index(follow, start)]
        parsed = []
        for values, label in re.findall(r"\[([\d, ]+)\],\s*// ([^\n]+)", block):
            numbers = [int(v.strip()) for v in values.split(",") if v.strip()]
            parsed.append((label.strip(), numbers))
        return parsed

    yamato = rows("static let yamato: [[[Int]]] = [", None, "// MARK: 日本郵便")
    post = rows("static let post: [[[Int]]] = [", None, "/// 県内運賃")
    local = rows("static let postLocal: [[Int]] = [", None, "// MARK: 佐川急便")
    sagawa = rows("static let sagawa: [[[Int]]] = [", None, "// MARK: 引き当て")

    return names, zones, yamato, post, local, sagawa


def chunk(rows, origin_count, size_count):
    """行の並びを [発地][サイズ] に組み直す。"""
    check(len(rows) == origin_count * size_count,
          f"行数が {origin_count * size_count} ではなく {len(rows)}")
    table = []
    for origin in range(origin_count):
        table.append([rows[origin * size_count + size][1] for size in range(size_count)])
    return table


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


def yacco_sheet(long_mm, short_mm, margin=50, thickness=30, framed=False, fold=15):
    long_packed, short_packed, depth = packed_size(long_mm, short_mm, margin, thickness, framed)[0]
    width = 2 * short_packed + 2 * depth + 2 * fold
    height = 2 * long_packed + 2 * depth + 2 * fold
    round_up = lambda value: math.ceil(value / 10) * 10
    return round_up(width), round_up(height)


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


def choose_number(numbers, number):
    """型を変えたときの号数。写し。"""
    if number in numbers:
        return number
    best = numbers[0]
    best_distance = 10**9
    for candidate in numbers:
        distance = abs(candidate - number)
        if distance < best_distance:
            best = candidate
            best_distance = distance
    return best


def art_summary(total_cm, long_side_cm):
    if long_side_cm > 250 or total_cm > 450:
        return "over450"
    if total_cm > 260:
        return "over260"
    if total_cm > 200:
        return "over200"
    if total_cm > 170:
        return "over170"
    if long_side_cm > 170:
        return "side170"
    return None


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

    # 5. ヤッコ包み（段ボール1枚）
    check(yacco_sheet(410, 318) == (830, 1010),
          f"F6 のヤッコ包みが {yacco_sheet(410, 318)} です")
    check(yacco_sheet(410, 318, framed=True) == (930, 1110),
          f"F6 額装のヤッコ包みが {yacco_sheet(410, 318, framed=True)} です")
    check(yacco_sheet(180, 140) == (470, 550),
          f"F0 のヤッコ包みが {yacco_sheet(180, 140)} です")
    # 折り返し代を増やすと、両方向に 20mm ずつ広がる。
    check(yacco_sheet(410, 318, fold=25) == (850, 1030),
          f"折り返し25ミリのヤッコ包みが {yacco_sheet(410, 318, fold=25)} です")

    # 6. 号数の選び方
    for key in ["F", "P", "M", "S"]:
        check(sorted(catalog[key]) == NUMBERS, f"{key} の号数が揃っていません")
    check(choose_number(NUMBERS, 6) == 6, "同じ号数が残りません")
    check(choose_number(NUMBERS, 7) == 6, "7 号の近い号数が 6 ではありません")
    check(choose_number([0, 1, 2], 100) == 2, "遠い号数の寄せ先が違います")
    print("  F の数字:", ", ".join(str(n) for n in NUMBERS[:8]), "…")

    # 7. 運賃表の形
    names, zones, yamato_rows, post_rows, local_rows, sagawa_rows = parse_rates()

    check(len(names) == 47, f"都道府県が 47 件ではありません（{len(names)} 件）")
    for prefecture in PREFECTURES:
        check(prefecture in names.values(), f"{prefecture} の表示名がありません")
    for key in ["yamato", "sagawa", "post"]:
        check(len(zones[key]) == 47, f"{key} の地帯が 47 件ではありません")

    romaji = {name: case for case, name in names.items()}
    for prefecture in PREFECTURES:
        case = romaji.get(prefecture)
        check(case is not None, f"{prefecture} の case がありません")
        if case is None:
            continue
        check(zones["yamato"].get(case) == YAMATO_ZONE[prefecture],
              f"{prefecture} のヤマトの地帯が違います")
        check(zones["sagawa"].get(case) == SAGAWA_ZONE[prefecture],
              f"{prefecture} の佐川の地帯が違います")
        check(zones["post"].get(case) == POST_ZONE[prefecture],
              f"{prefecture} の郵便の地帯が違います")

    yamato = chunk(yamato_rows, 12, 8)
    post = chunk(post_rows, 11, 7)
    check(len(local_rows) == 47, f"県内運賃が 47 件ではありません（{len(local_rows)} 件）")
    local = [row[1] for row in local_rows]
    sagawa = chunk(sagawa_rows, 13, 11)

    check(all(len(row) == 12 for origin in yamato for row in origin), "ヤマトの着地が12地帯ではありません")
    check(all(len(row) == 11 for origin in post for row in origin), "郵便の着地が11地帯ではありません")
    check(all(len(row) == 13 for origin in sagawa for row in origin), "佐川の着地が13地帯ではありません")

    # 8. 引き当て（写しと突き合わせ）
    yamato_local = [790, 1090, 1410, 1730, 2090, 2410, 3030, 3690]

    def yamato_fare(origin, destination, size):
        index = [60, 80, 100, 120, 140, 160, 180, 200].index(size)
        if origin == destination and origin != "沖縄県":
            return yamato_local[index]
        return yamato[YAMATO_ZONE[origin]][index][YAMATO_ZONE[destination]]

    def post_fare(origin, destination, size):
        index = [60, 80, 100, 120, 140, 160, 170].index(size)
        if origin == destination:
            return local[PREFECTURES.index(origin)][index]
        return post[POST_ZONE[origin]][index][POST_ZONE[destination]]

    def sagawa_fare(origin, destination, size):
        index = [60, 80, 100, 140, 160, 170, 180, 200, 220, 240, 260].index(size)
        return sagawa[SAGAWA_ZONE[origin]][index][SAGAWA_ZONE[destination]]

    for (origin, destination, size), want in YAMATO_SPOT.items():
        got = yamato_fare(origin, destination, size)
        check(got == want, f"ヤマト {origin}→{destination} {size} が {got} です（期待 {want}）")
    for (origin, destination, size), want in POST_SPOT.items():
        got = post_fare(origin, destination, size)
        check(got == want, f"ゆうパック {origin}→{destination} {size} が {got} です（期待 {want}）")
    for (origin, destination, size), want in SAGAWA_SPOT.items():
        got = sagawa_fare(origin, destination, size)
        check(got == want, f"佐川 {origin}→{destination} {size} が {got} です（期待 {want}）")

    # 8b. 同一都道府県内運賃（ヤマト）。沖縄県発は対象外なので地帯の額のまま。
    check(yamato_fare("大阪府", "大阪府", 60) == 790, "ヤマト 大阪→大阪 60 が県内運賃ではありません")
    check(yamato_fare("東京都", "東京都", 200) == 3690, "ヤマト 東京→東京 200 が県内運賃ではありません")
    check(yamato_fare("沖縄県", "沖縄県", 60) == 940, "ヤマト 沖縄→沖縄 60 が地帯の額ではありません")
    check(yamato_fare("大阪府", "京都府", 60) == 940, "ヤマト 大阪→京都 60 が地帯の額ではありません")

    # 9. 全組み合わせの整合（対称・区分の単調増加）
    for origin in PREFECTURES:
        for destination in PREFECTURES:
            for size in [60, 80, 100, 140, 160]:
                check(sagawa_fare(origin, destination, size) == sagawa_fare(destination, origin, size),
                      f"佐川 {origin}↔{destination} {size} が対称ではありません")
            for size in [60, 80, 100, 120, 140, 160, 180, 200]:
                check(yamato_fare(origin, destination, size) == yamato_fare(destination, origin, size),
                      f"ヤマト {origin}↔{destination} {size} が対称ではありません")
            for size in [60, 80, 100, 120, 140, 160]:
                check(post_fare(origin, destination, size) == post_fare(destination, origin, size),
                      f"ゆうパック {origin}↔{destination} {size} が対称ではありません")

    for origin in PREFECTURES:
        for destination in PREFECTURES:
            for fares in (yamato[YAMATO_ZONE[origin]], post[POST_ZONE[origin]], sagawa[SAGAWA_ZONE[origin]]):
                for row in fares:
                    check(row[0] > 0, "0 円の運賃があります")

    # 10. 三社の上限と判定
    yamato_table = {"maxCm": 200, "maxKg": 30.0, "maxLongSideCm": 170,
                    "rows": {size: None for size in [60, 80, 100, 120, 140, 160, 180, 200]}}
    post_table = {"maxCm": 170, "maxKg": 25.0, "maxLongSideCm": None,
                  "rows": {size: None for size in [60, 80, 100, 120, 140, 160, 170]}}
    sagawa_table = {"maxCm": 260, "maxKg": 50.0, "maxLongSideCm": None,
                    "rows": {size: None for size in [60, 80, 100, 140, 160, 170, 180, 200, 220, 240, 260]}}

    for total, want in [(60, 60), (61, 80), (86, 100), (160, 160), (161, 180), (200, 200)]:
        size, _ = size_class(yamato_table, total, 100)
        check(size == want, f"ヤマト {total}cm が {want} ではなく {size}")
    size, reason = size_class(yamato_table, 201, 100)
    check(size is None and "上限200cm" in reason, "ヤマト 201cm が送れる判定です")
    size, reason = size_class(yamato_table, 180, 171)
    check(size is None and "1辺170cm" in reason, "ヤマト 1辺171cm が送れる判定です")

    for total, want in [(60, 60), (160, 160), (161, 170), (170, 170)]:
        size, _ = size_class(post_table, total, 100)
        check(size == want, f"ゆうパック {total}cm が {want} ではなく {size}")
    size, reason = size_class(post_table, 171, 100)
    check(size is None and "上限170cm" in reason, "ゆうパック 171cm が送れる判定です")

    for total, want in [(60, 60), (100, 100), (101, 140), (160, 160), (161, 170), (260, 260)]:
        size, _ = size_class(sagawa_table, total, 100)
        check(size == want, f"佐川 {total}cm が {want} ではなく {size}")

    # 11. 補償の表示
    text = read_source("Sources/Models/ShippingRateData.swift")
    for carrier, message in COMPENSATION.items():
        check(f'case .{carrier}: return "{message}"' in text,
              f"{carrier} の補償の文言が違います")
    for carrier, (max_cm, max_kg, max_side) in LIMITS.items():
        for header, want in [("var maxCm: Int {", max_cm), ("var maxKg: Double {", max_kg)]:
            start = text.index(header)
            block = text[start:text.index("\n    }", start)]
            found = dict(re.findall(r"case \.(\w+): return ([\d.]+)", block))
            check(found.get(carrier) is not None and float(found[carrier]) == float(want),
                  f"{carrier} の {header} が {found.get(carrier)} です（期待 {want}）")

    # 12. アート便の境目
    check(art_summary(86, 46) is None, "86cm で注意が出ています")
    check(art_summary(171, 100) == "over170", "171cm の注意が違います")
    check(art_summary(201, 100) == "over200", "201cm の注意が違います")
    check(art_summary(261, 100) == "over260", "261cm の注意が違います")
    check(art_summary(451, 100) == "over450", "451cm の注意が違います")
    check(art_summary(300, 251) == "over450", "最長辺251cm の注意が違います")

    # 14. 記録（条件・履歴・展示・再参照）
    records_text = read_source("Sources/Models/RecordModels.swift")
    store_text = read_source("Sources/Store/RecordStore.swift")
    content_text = read_source("Sources/Views/ContentView.swift")
    panel_text = read_source("Sources/Views/ShippingPanel.swift")
    notes_text = read_source("Sources/Views/ShippingNotesSheet.swift")
    links_text = read_source("Sources/Models/OfficialLinks.swift")

    conditions_block = records_text[records_text.index("struct CalculationConditions"):]
    conditions_block = conditions_block[:conditions_block.index("\n}")]
    for field in ["sizeName", "marginMm", "thicknessMm", "framed", "origin", "destination"]:
        check(f"var {field}" in conditions_block, f"条件に {field} がありません")

    check("quotes.compactMap(\\.fare).min()" in records_text, "最安運賃の求め方が変わりました")
    check('defaultsKey = "canvasRecords"' in store_text, "保存の鍵が違います")
    check("historyLimit = 80" in store_text, "履歴の上限が違います")
    check("records[index].exhibitionID = nil" in store_text,
          "展示を消したときに記録が未整理へ戻りません")
    check("$0.conditions == conditions" in store_text, "同じ条件の重複をまとめていません")
    check("UserDefaults.standard.set(data" in store_text, "端末内へ保存していません")
    for line in ["selected = conditions.size",
                 "marginMm = conditions.marginMm",
                 "thicknessMm = conditions.thicknessMm",
                 "framed = conditions.framed",
                 "originRaw = conditions.origin",
                 "destinationRaw = conditions.destination"]:
        check(line in content_text, f"再参照で {line} を戻していません")

    # 15. 最安の判定と展示の合計
    def lowest_fare(origin, destination, total_cm, long_cm):
        fares = []
        size, _ = size_class(yamato_table, total_cm, long_cm)
        if size is not None:
            fares.append(yamato_fare(origin, destination, size))
        size, _ = size_class(post_table, total_cm, long_cm)
        if size is not None:
            fares.append(post_fare(origin, destination, size))
        size, _ = size_class(sagawa_table, total_cm, long_cm)
        if size is not None:
            fares.append(sagawa_fare(origin, destination, size))
        return min(fares) if fares else None

    # F0 は梱包後 45cm（三社とも60サイズ）、F6 は 86cm（100サイズ）。
    check(lowest_fare("大阪府", "大阪府", 45, 18) == 790,
          f"F0 大阪→大阪 の最安が {lowest_fare('大阪府', '大阪府', 45, 18)} 円です")
    check(lowest_fare("大阪府", "東京都", 45, 18) == 1040,
          f"F0 大阪→東京 の最安が {lowest_fare('大阪府', '東京都', 45, 18)} 円です")
    check(lowest_fare("大阪府", "東京都", 86, 46) == 1630,
          f"F6 大阪→東京 の最安が {lowest_fare('大阪府', '東京都', 86, 46)} 円です")
    check(lowest_fare("大阪府", "大阪府", 86, 46) == 1410,
          f"F6 大阪→大阪 の最安が {lowest_fare('大阪府', '大阪府', 86, 46)} 円です")
    show_total = lowest_fare("大阪府", "大阪府", 45, 18) + lowest_fare("大阪府", "東京都", 45, 18)
    check(show_total == 1830, f"展示の送料目安の合計が {show_total} 円です")

    # 16. 短い表示と公式リンク
    short_names = {}
    for case, name in names.items():
        short = name[:-1] if name.endswith(("都", "府", "県")) else name
        short_names[case] = short
        check(bool(short), f"{name} の短い表示が空です")
    check(len(set(short_names.values())) == 47, "都道府県の短い表示が重なっています")
    check(short_names.get("osaka") == "大阪", "大阪府の短い表示が違います")
    check(short_names.get("hokkaido") == "北海道", "北海道の短い表示が違います")
    check(short_names.get("tokyo") == "東京", "東京都の短い表示が違います")

    urls = [
        "https://date.kuronekoyamato.co.jp/date/Main",
        "https://business.kuronekoyamato.co.jp/promotion/art/bijutsubin.html",
        "https://www.post.japanpost.jp/cgi-simulator/youpack.php/",
        "https://www.sagawa-exp.co.jp/customer/send/service/takuhai/",
        "https://www.sagawa-exp.co.jp/business/send/service/art/",
        "https://www.008008.jp/transport/",
    ]
    for url in urls:
        check(url in links_text, f"公式ページ {url} がありません")
    check("Link(destination:" in panel_text, "一覧の行が公式ページへのリンクになっていません")
    for header in ["配送", "サイズ", "補償", "運賃"]:
        check(f'Text("{header}")' in panel_text, f"一覧の見出し {header} がありません")
    check("lowestFare" in panel_text and "semibold" in panel_text,
          "最安の行が濃く太くなっていません")
    check('Text("3辺合計")' in panel_text, "3辺合計のラベルがありません")

    # 17. 画面から逃がした長い注記
    for phrase in ["2026年11月時点", "セキュリティ", "美術品専門のスタッフ", "引き受けられない", "15号以下"]:
        check(phrase not in panel_text, f"「{phrase}」が計算の画面に残っています")
        check(phrase in notes_text, f"「{phrase}」が注記シートにありません")

    # 13. 代表的な号数の3辺合計と判定
    print()
    for name in ["F0", "F6", "F10", "F20", "F30", "F50", "F100", "SM"]:
        long_side, short_side = flat[name]
        _, _, total = packed_size(long_side, short_side)
        y_size, _ = size_class(yamato_table, total, long_side / 10)
        p_size, _ = size_class(post_table, total, long_side / 10)
        s_size, _ = size_class(sagawa_table, total, long_side / 10)
        sheet = yacco_sheet(long_side, short_side)
        print(f"  {name:>4}  {long_side}×{short_side}  3辺 {total:>3}cm  "
              f"ヤマト {y_size}  ゆう {p_size}  佐川 {s_size}  段ボール {sheet[0]}×{sheet[1]}")

    print()
    if FAILURES:
        print(f"{len(FAILURES)} 件の不一致")
        return 1
    print(f"すべて一致（号数 {len(flat)} 件、三社 {len(yamato)}/{len(post)}/{len(sagawa)} 地帯）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
