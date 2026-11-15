#!/usr/bin/env python3
"""Generates assets/mock/*.json in the exact shapes of the Binance Spot REST API.

    python3 tool/generate_mock_data.py

All numbers are SAMPLE data (seeded random walks), not real market data.
The series are internally consistent: every /ticker/24hr value is aggregated
from the generated 1-minute candles, and every coarser kline interval is
aggregated from finer ones.

ANCHOR must match `kMockAnchor` in
lib/features/market/data/datasources/market_mock_datasource.dart.
At runtime the mock data source shifts all timestamps by whole days so the
data ends within 24 h of "now" while staying aligned to UTC candle boundaries.
"""
import json
import math
import random
import zlib
from datetime import datetime, timezone
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "mock"
ANCHOR = int(datetime(2026, 11, 14, 12, 0, tzinfo=timezone.utc).timestamp() * 1000)
MIN, HOUR, DAY = 60_000, 3_600_000, 86_400_000

USD = {"USDT": 1.0, "FDUSD": 1.0, "BTC": 67420.50, "ETH": 3540.20, "EUR": 1.08}

# (symbol, base, quote, last price, 24h change %, 24h quote volume in quote units)
BTC, ETH = USD["BTC"], USD["ETH"]
PAIRS = [
    ("BTCUSDT", "BTC", "USDT", 67420.50, 3.42, 12.4e9),
    ("ETHUSDT", "ETH", "USDT", 3540.20, 2.18, 6.8e9),
    ("SOLUSDT", "SOL", "USDT", 178.45, 12.84, 3.9e9),
    ("BNBUSDT", "BNB", "USDT", 594.10, -0.85, 1.2e9),
    ("XRPUSDT", "XRP", "USDT", 0.5842, 1.15, 940e6),
    ("ADAUSDT", "ADA", "USDT", 0.4820, -2.41, 420e6),
    ("DOGEUSDT", "DOGE", "USDT", 0.1428, -4.12, 620e6),
    ("AVAXUSDT", "AVAX", "USDT", 34.18, 8.20, 512e6),
    ("NEARUSDT", "NEAR", "USDT", 7.32, 9.45, 680e6),
    ("SUIUSDT", "SUI", "USDT", 1.92, 5.60, 410e6),
    ("PEPEUSDT", "PEPE", "USDT", 0.0000104, 7.15, 930e6),
    ("LINKUSDT", "LINK", "USDT", 14.62, 1.84, 380e6),
    ("DOTUSDT", "DOT", "USDT", 5.31, -1.22, 190e6),
    ("POLUSDT", "POL", "USDT", 0.4120, -0.64, 150e6),
    ("LTCUSDT", "LTC", "USDT", 71.80, 0.90, 210e6),
    ("TRXUSDT", "TRX", "USDT", 0.1624, 0.32, 330e6),
    ("ATOMUSDT", "ATOM", "USDT", 6.84, -3.05, 70e6),
    ("UNIUSDT", "UNI", "USDT", 9.43, 2.76, 120e6),
    ("APTUSDT", "APT", "USDT", 8.12, 4.41, 140e6),
    ("ARBUSDT", "ARB", "USDT", 0.5460, -1.87, 160e6),
    ("OPUSDT", "OP", "USDT", 1.82, 3.30, 130e6),
    ("INJUSDT", "INJ", "USDT", 21.40, 6.12, 220e6),
    ("TONUSDT", "TON", "USDT", 5.38, -0.42, 180e6),
    ("SHIBUSDT", "SHIB", "USDT", 0.00001842, 2.20, 260e6),
    ("FILUSDT", "FIL", "USDT", 4.96, -2.95, 90e6),
    ("AAVEUSDT", "AAVE", "USDT", 168.30, 1.40, 170e6),
    ("ETHBTC", "ETH", "BTC", round(ETH / BTC, 5), -1.18, 3200),
    ("BNBBTC", "BNB", "BTC", round(594.10 / BTC, 6), -4.10, 420),
    ("SOLBTC", "SOL", "BTC", round(178.45 / BTC, 6), 9.10, 880),
    ("XRPBTC", "XRP", "BTC", round(0.5842 / BTC, 8), -2.20, 210),
    ("ADABTC", "ADA", "BTC", round(0.4820 / BTC, 8), -5.60, 95),
    ("LINKETH", "LINK", "ETH", round(14.62 / ETH, 6), -0.30, 5200),
    ("BNBETH", "BNB", "ETH", round(594.10 / ETH, 5), -2.90, 1800),
    ("BTCFDUSD", "BTC", "FDUSD", 67419.80, 3.40, 1.1e9),
    ("ETHFDUSD", "ETH", "FDUSD", 3540.00, 2.20, 520e6),
    ("SOLFDUSD", "SOL", "FDUSD", 178.40, 12.70, 210e6),
    ("BTCEUR", "BTC", "EUR", round(BTC / 1.08, 2), 3.10, 280e6),
    ("ETHEUR", "ETH", "EUR", round(ETH / 1.08, 2), 1.90, 95e6),
]
# Present in exchangeInfo but NOT tradable spot pairs (tests the filter).
INACTIVE = [
    ("LUNAUSDT", "LUNA", "USDT", "BREAK", True),
    ("WAVESUSDT", "WAVES", "USDT", "TRADING", False),
]

STORED = {  # interval -> (ms, number of candles kept)
    "1m": (MIN, 60), "5m": (5 * MIN, 48), "15m": (15 * MIN, 96),
    "1h": (HOUR, 168), "4h": (4 * HOUR, 180), "1d": (DAY, 365),
}


def decimals_for(price):
    if price >= 100: return 2
    if price >= 10: return 3
    if price >= 1: return 4
    if price >= 0.1: return 5
    if price >= 0.01: return 6
    if price >= 0.0001: return 7
    return 8


def fmt_qty(v):
    return f"{v:.0f}" if v >= 1_000_000 else f"{v:.5f}"


def sigma_for(usd_qv):
    if usd_qv > 1e9: return 0.00035
    if usd_qv > 3e8: return 0.0007
    return 0.0011


def aggregate(candles, interval_ms):
    """Group candles by epoch-aligned bucket and merge OHLCV."""
    out, cur, bucket = [], None, None
    for c in candles:
        b = (c["t"] // interval_ms) * interval_ms
        if b != bucket:
            if cur: out.append(cur)
            bucket = b
            cur = dict(c, t=b)
        else:
            cur["h"] = max(cur["h"], c["h"])
            cur["l"] = min(cur["l"], c["l"])
            cur["c"] = c["c"]
            for k in ("v", "q", "n", "tb", "tq"):
                cur[k] += c[k]
    if cur: out.append(cur)
    return out


def build_symbol(symbol, base, quote, last, pct, qv):
    rng = random.Random(zlib.crc32(symbol.encode()))
    dec = decimals_for(last)
    tick = 10 ** -dec
    usd_qv = qv * USD[quote]
    sigma = sigma_for(usd_qv)
    n = 1440
    start = ANCHOR - n * MIN

    last = round(last, dec)
    open24 = round(last / (1 + pct / 100), dec)
    rets = [rng.gauss(0, sigma) for _ in range(n)]
    total = math.log(last / open24)
    s = sum(rets)
    cum, closes = 0.0, []
    for i in range(n):
        cum += rets[i]
        closes.append(round(math.exp(math.log(open24) + cum + (i + 1) / n * (total - s)), dec))
    closes[-1] = last
    opens = [open24] + closes[:-1]

    weights = [math.exp(rng.gauss(0, 0.7)) for _ in range(n)]
    mids = [(o + c) / 2 for o, c in zip(opens, closes)]
    k = qv / sum(w * m for w, m in zip(weights, mids))
    total_trades = max(1000, int(math.sqrt(usd_qv) * 40))
    wsum = sum(weights)

    m1 = []
    for i in range(n):
        o, c = opens[i], closes[i]
        h = round(max(o, c) * (1 + abs(rng.gauss(0, sigma * 0.5))), dec)
        l = round(min(o, c) * (1 - abs(rng.gauss(0, sigma * 0.5))), dec)
        h, l = max(h, o, c), min(l, o, c)
        v = k * weights[i]
        q = v * mids[i]
        f = min(0.9, max(0.1, rng.gauss(0.5 + (0.02 if c >= o else -0.02), 0.06)))
        m1.append({"t": start + i * MIN, "o": o, "h": h, "l": l, "c": c, "v": v, "q": q,
                   "n": max(1, round(weights[i] / wsum * total_trades)), "tb": v * f, "tq": q * f})

    # Hourly history before the 24 h window (random walk backwards from open24).
    sig_h = sigma * math.sqrt(60)
    hist, cur = [], open24
    h_old = 365 * 24 - 24
    for _ in range(h_old):
        prev = round(cur * math.exp(-rng.gauss(0, sig_h)), dec)
        if prev < tick * 5: prev = cur
        v = (qv / 24) / cur * math.exp(rng.gauss(0, 0.5))
        q = v * (prev + cur) / 2
        f = min(0.9, max(0.1, rng.gauss(0.5, 0.06)))
        hist.append({"o": prev, "c": cur,
                     "h": max(prev, cur, round(max(prev, cur) * (1 + abs(rng.gauss(0, sig_h * 0.5))), dec)),
                     "l": min(prev, cur, round(min(prev, cur) * (1 - abs(rng.gauss(0, sig_h * 0.5))), dec)),
                     "v": v, "q": q, "n": max(1, int(total_trades / 24 * math.exp(rng.gauss(0, 0.4)))),
                     "tb": v * f, "tq": q * f})
        cur = prev
    hist.reverse()
    for i, c in enumerate(hist):
        c["t"] = start - (h_old - i) * HOUR

    series = {"1m": m1, "5m": aggregate(m1, 5 * MIN), "15m": aggregate(m1, 15 * MIN)}
    h1 = hist + aggregate(m1, HOUR)
    series["1h"], series["4h"], series["1d"] = h1, aggregate(h1, 4 * HOUR), aggregate(h1, DAY)

    def row(c, ms):
        return [c["t"], f"{c['o']:.{dec}f}", f"{c['h']:.{dec}f}", f"{c['l']:.{dec}f}",
                f"{c['c']:.{dec}f}", fmt_qty(c["v"]), c["t"] + ms - 1, f"{c['q']:.{dec}f}",
                c["n"], fmt_qty(c["tb"]), f"{c['tq']:.{dec}f}", "0"]

    klines = {iv: [row(c, ms) for c in series[iv][-cnt:]] for iv, (ms, cnt) in STORED.items()}

    vol = sum(c["v"] for c in m1)
    quote = sum(c["q"] for c in m1)
    count = sum(c["n"] for c in m1)
    change = last - open24
    ticker = {
        "symbol": symbol,
        "priceChange": f"{change:.{dec}f}",
        "priceChangePercent": f"{change / open24 * 100:.3f}",
        "weightedAvgPrice": f"{quote / vol:.{dec}f}",
        "prevClosePrice": f"{open24:.{dec}f}",
        "lastPrice": f"{last:.{dec}f}",
        "lastQty": fmt_qty(vol / count),
        "bidPrice": f"{last:.{dec}f}",
        "bidQty": fmt_qty(vol / count * 3),
        "askPrice": f"{last + tick:.{dec}f}",
        "askQty": fmt_qty(vol / count * 2),
        "openPrice": f"{open24:.{dec}f}",
        "highPrice": f"{max(c['h'] for c in m1):.{dec}f}",
        "lowPrice": f"{min(c['l'] for c in m1):.{dec}f}",
        "volume": fmt_qty(vol),
        "quoteVolume": f"{quote:.{dec}f}",
        "openTime": start,
        "closeTime": ANCHOR,
        "firstId": 1,
        "lastId": count,
        "count": count,
    }

    avg_qty = vol / count
    bid_f, ask_f = rng.uniform(0.8, 1.4), 1 / rng.uniform(0.8, 1.4)
    depth = {
        "lastUpdateId": 1_000_000 + rng.randint(0, 9_999_999),
        "bids": [[f"{last - tick * i:.{dec}f}",
                  fmt_qty(avg_qty * math.exp(rng.gauss(0, 0.8)) * (1 + i * 0.03) * bid_f)]
                 for i in range(100)],
        "asks": [[f"{last + tick * (i + 1):.{dec}f}",
                  fmt_qty(avg_qty * math.exp(rng.gauss(0, 0.8)) * (1 + i * 0.03) * ask_f)]
                 for i in range(100)],
    }

    trades, t, tid = [], ANCHOR - rng.randint(0, 800), count
    buy_bias = 0.5 + (0.03 if pct >= 0 else -0.03)
    for _ in range(40):
        price = round(last + rng.choice([-2, -1, 0, 0, 1, 2]) * tick, dec)
        qty = avg_qty * math.exp(rng.gauss(0, 0.9))
        trades.append({"id": tid, "price": f"{price:.{dec}f}", "qty": fmt_qty(qty),
                       "quoteQty": f"{price * qty:.{dec}f}", "time": t,
                       "isBuyerMaker": rng.random() > buy_bias, "isBestMatch": True})
        tid -= 1
        t -= int(rng.expovariate(1 / 600))
    trades.reverse()  # oldest first, like the real endpoint
    return ticker, klines, depth, trades


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    tickers, klines, depth, trades = [], {}, {}, {}
    for sym, base, quote, last, pct, qv in PAIRS:
        t, kl, d, tr = build_symbol(sym, base, quote, last, pct, qv)
        tickers.append(t); klines[sym] = kl; depth[sym] = d; trades[sym] = tr

    zero = {k: "0.00000000" for k in (
        "priceChange", "priceChangePercent", "weightedAvgPrice", "prevClosePrice", "lastPrice",
        "lastQty", "bidPrice", "bidQty", "askPrice", "askQty", "openPrice", "highPrice",
        "lowPrice", "volume", "quoteVolume")}
    for sym, *_ in INACTIVE:
        tickers.append({"symbol": sym, **zero, "openTime": ANCHOR - DAY, "closeTime": ANCHOR,
                        "firstId": -1, "lastId": -1, "count": 0})

    symbols = [{"symbol": s, "status": "TRADING", "baseAsset": b, "quoteAsset": q,
                "isSpotTradingAllowed": True, "isMarginTradingAllowed": False}
               for s, b, q, *_ in PAIRS]
    symbols += [{"symbol": s, "status": st, "baseAsset": b, "quoteAsset": q,
                 "isSpotTradingAllowed": spot, "isMarginTradingAllowed": False}
                for s, b, q, st, spot in INACTIVE]
    exchange_info = {"timezone": "UTC", "serverTime": ANCHOR, "symbols": symbols}

    dump = lambda name, obj: (OUT / name).write_text(json.dumps(obj, separators=(",", ":")))
    dump("trading_pairs.json", exchange_info)
    dump("ticker_24hr.json", tickers)
    dump("klines.json", klines)
    dump("depth.json", depth)
    dump("recent_trades.json", trades)

    # Self-checks -----------------------------------------------------------
    for t in tickers[:len(PAIRS)]:
        sym = t["symbol"]
        m1 = klines[sym]["1m"]
        assert t["lastPrice"] == m1[-1][4], sym
        assert float(t["highPrice"]) >= float(t["lastPrice"]) >= float(t["lowPrice"]), sym
        h1_last = klines[sym]["1h"][-1]
        assert h1_last[4] == t["lastPrice"], sym
        assert klines[sym]["1d"][-1][4] == t["lastPrice"], sym
        assert len(klines[sym]["1d"]) == 365 and len(klines[sym]["4h"]) == 180, sym
        assert all(float(r[2]) >= float(r[3]) for r in klines[sym]["1h"]), sym
    for name in ("trading_pairs", "ticker_24hr", "klines", "depth", "recent_trades"):
        print(f"{name}.json  {(OUT / (name + '.json')).stat().st_size / 1024:.0f} KB")
    print(f"anchor ms = {ANCHOR}  symbols = {len(PAIRS)} active + {len(INACTIVE)} inactive")


if __name__ == "__main__":
    main()
