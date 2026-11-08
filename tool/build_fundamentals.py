#!/usr/bin/env python3
import csv
import datetime
import io
import json
import os
import sys
import urllib.request
import zipfile

BASE = "https://dados.cvm.gov.br/dados/CIA_ABERTA/DOC"
OUTPUT = os.path.join(os.path.dirname(__file__), "..", "hosting-invest", "public", "fundamentals.json")
csv.field_size_limit(10_000_000)


def download(url):
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=120) as response:
        return zipfile.ZipFile(io.BytesIO(response.read()))


def rows(archive, name):
    with archive.open(name) as raw:
        yield from csv.DictReader(io.TextIOWrapper(raw, encoding="latin-1"), delimiter=";")

TREASURY_URL = (
    "https://www.tesourotransparente.gov.br/ckan/dataset/df56aa42-484a-4a59-8184-7676580c81e3/"
    "resource/796d2059-14e9-44e3-80c9-2d9e30b405c1/download/PrecoTaxaTesouroDireto.csv"
)


def number(value):
    try:
        return float(value.replace(".", "").replace(",", "."))
    except (AttributeError, ValueError):
        return None


def build_treasury():
    request = urllib.request.Request(TREASURY_URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=180) as response:
        text = response.read().decode("latin-1")

    latest, titles = None, []
    for row in csv.DictReader(io.StringIO(text), delimiter=";"):
        day = datetime.datetime.strptime(row["Data Base"], "%d/%m/%Y").date()
        if latest is None or day > latest:
            latest, titles = day, []
        if day == latest:
            maturity = datetime.datetime.strptime(row["Data Vencimento"], "%d/%m/%Y").date()
            rate, price = number(row["Taxa Compra Manha"]), number(row["PU Compra Manha"])
            if rate and price and maturity > latest:
                titles.append({"name": row["Tipo Titulo"], "maturity": maturity.isoformat(), "rate": rate, "price": price})

    path = os.path.join(os.path.dirname(OUTPUT), "treasury.json")
    with open(path, "w", encoding="utf-8") as output:
        json.dump({"date": latest.isoformat(), "source": "Tesouro Transparente", "titles": titles}, output, ensure_ascii=False, separators=(",", ":"))
    print(f"{len(titles)} títulos de {latest}")


def clean_cnpj(value):
    return "".join(ch for ch in value if ch.isdigit())


def tickers_by_company(year):
    archive = download(f"{BASE}/FCA/DADOS/fca_cia_aberta_{year}.zip")
    result = {}
    for row in rows(archive, f"fca_cia_aberta_valor_mobiliario_{year}.csv"):
        ticker = (row.get("Codigo_Negociacao") or "").strip().upper()
        if ticker and ticker[-1].isdigit():
            result.setdefault(clean_cnpj(row["CNPJ_Companhia"]), set()).add(ticker)
    return result


def statement(archive, year, kind, scope):
    values = {}
    for row in rows(archive, f"dfp_cia_aberta_{kind}_{scope}_{year}.csv"):
        if row.get("ORDEM_EXERC") != "ÚLTIMO":
            continue
        scale = {"MIL": 1000, "MILHAO": 1_000_000}.get(row.get("ESCALA_MOEDA", ""), 1)
        try:
            amount = float(row["VL_CONTA"]) * scale
        except (KeyError, ValueError):
            continue
        values.setdefault(clean_cnpj(row["CNPJ_CIA"]), {})[row["CD_CONTA"]] = (amount, row.get("DS_CONTA", ""))
    return values


def net_income(accounts):
    best = None
    for code, (amount, label) in accounts.items():
        text = label.lower()
        if code.startswith("3.") and code.count(".") == 1 and "lucro" in text and "líquido" in text and "consolidado" in text:
            return amount
        if code.startswith("3.") and code.count(".") == 1 and "lucro" in text and "período" in text:
            best = amount
    return best


def equity_of(accounts):
    for code, (amount, label) in accounts.items():
        if code.startswith("2.") and code.count(".") == 1 and "patrim" in label.lower() and "quido" in label.lower():
            return amount
    return None


def main():
    year = int(sys.argv[1]) if len(sys.argv) > 1 else datetime.date.today().year - 1
    tickers = tickers_by_company(year + 1)
    archive = download(f"{BASE}/DFP/DADOS/dfp_cia_aberta_{year}.zip")

    income = {**statement(archive, year, "DRE", "ind"), **statement(archive, year, "DRE", "con")}
    assets = {**statement(archive, year, "BPA", "ind"), **statement(archive, year, "BPA", "con")}
    liabilities = {**statement(archive, year, "BPP", "ind"), **statement(archive, year, "BPP", "con")}

    companies = {}
    for cnpj, symbols in tickers.items():
        dre, bpa, bpp = income.get(cnpj), assets.get(cnpj), liabilities.get(cnpj)
        if not dre or not bpp:
            continue
        revenue = dre.get("3.01", (None, ""))[0]
        profit = net_income(dre)
        equity = equity_of(bpp)
        total_assets = bpa.get("1", (None, ""))[0] if bpa else None
        if profit is None or not equity:
            continue
        entry = {
            "year": year,
            "revenue": revenue,
            "netIncome": profit,
            "equity": equity,
            "assets": total_assets,
            "roe": round(profit / equity * 100, 2),
            "netMargin": round(profit / revenue * 100, 2) if revenue else None,
            "debtToAssets": round((total_assets - equity) / total_assets * 100, 2) if total_assets else None,
        }
        for symbol in symbols:
            companies[symbol] = entry

    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    with open(OUTPUT, "w", encoding="utf-8") as output:
        json.dump(
            {"updatedAt": datetime.date.today().isoformat(), "source": "CVM Dados Abertos", "year": year, "companies": companies},
            output, ensure_ascii=False, separators=(",", ":"),
        )
    print(f"{len(companies)} tickers de {year}")
    build_treasury()


if __name__ == "__main__":
    main()
