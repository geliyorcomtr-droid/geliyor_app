const {getFirestore, FieldValue, FieldPath} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

const SETTINGS_PATH = "settings/softtr";
const DEFAULT_BASE_URL = "https://www.geliyor.com.tr/api";
const PAGE_SIZE = 100;

const BARCODE_KEYS = [
  "barcode",
  "barkod",
  "barkodno",
  "barcodeno",
  "productcode",
  "stockcode",
  "itemcode",
  "sku",
  "stokkodu",
  "stokkod",
  "urunkodu",
  "urunbarkod",
  "urunbarkodu",
  "ean",
  "gtin",
];

const PRODUCT_ID_KEYS = [
  "productid",
  "variantid",
  "id",
  "product_id",
  "itemid",
];

const STOCK_KEYS = [
  "stockamount",
  "totalstock",
  "productstock",
  "variantstock",
  "availablestock",
  "remainingstock",
  "stockquantity",
  "currentstock",
  "availablequantity",
  "quantityonhand",
  "stockcount",
  "stockqty",
  "stokadedi",
  "stokmiktari",
  "stokmiktar",
  "stokadet",
  "urunstok",
  "urunstokadedi",
  "varyantstok",
  "satilabilirstok",
  "quantity",
  "qty",
  "stok",
  "inventory",
  "stock",
];

const NESTED_STOCK_KEYS = [
  "stockamount",
  "amount",
  "quantity",
  "qty",
  "value",
  "total",
  "count",
  "adet",
  "available",
  "stock",
  "stok",
];

const VARIANT_KEYS = [
  "variants",
  "variantlist",
  "productvariants",
  "productvariantlist",
  "varyantlar",
  "varyantlistesi",
  "urunvaryantlari",
  "subproducts",
  "childproducts",
  "items",
];

function db() {
  return getFirestore();
}

function asBool(value, fallback = false) {
  if (value === true || value === "true" || value === 1 || value === "1") return true;
  if (value === false || value === "false" || value === 0 || value === "0") return false;
  return fallback;
}

function normalizeBarcode(raw) {
  return String(raw || "").replace(/\s+/g, "").trim();
}

function barcodeAliases(raw) {
  const exact = normalizeBarcode(raw);
  if (!exact) return [];
  const digits = exact.replace(/\D/g, "");
  return digits && digits !== exact ? [exact, digits] : [exact];
}

function asInt(value) {
  if (typeof value === "boolean") return null;
  if (typeof value === "number") {
    if (!Number.isFinite(value)) return null;
    return Math.max(0, Math.floor(value));
  }
  if (typeof value === "string") {
    const text = value.trim().replace(/\s+/g, "").replace(",", ".");
    if (!text) return null;
    const n = Number(text);
    if (Number.isFinite(n)) return Math.max(0, Math.floor(n));
    const match = value.replace(",", ".").match(/-?\d+(?:\.\d+)?/);
    if (!match) return null;
    const parsed = Number(match[0]);
    if (!Number.isFinite(parsed)) return null;
    return Math.max(0, Math.floor(parsed));
  }
  return null;
}

function normKey(key) {
  return String(key || "").toLowerCase().replace(/[_\-\s]/g, "");
}

function lowerKeyMap(row) {
  const map = {};
  if (!row || typeof row !== "object" || Array.isArray(row)) return map;
  for (const [key, value] of Object.entries(row)) {
    const lower = String(key).toLowerCase();
    map[lower] = value;
    map[normKey(key)] = value;
  }
  return map;
}

function firstByKeys(row, keys) {
  const map = lowerKeyMap(row);
  for (const key of keys) {
    const lookup = normKey(key);
    if (!Object.prototype.hasOwnProperty.call(map, lookup)) continue;
    const value = map[lookup];
    if (value == null || value === "") continue;
    if (typeof value === "boolean") continue;
    return value;
  }
  return undefined;
}

function firstText(row, keys) {
  const value = firstByKeys(row, keys);
  if (value == null) return "";
  if (typeof value === "object") return "";
  const text = String(value).trim();
  return text;
}

let highPriceSample = "";

function noteHighPrice(raw, amount) {
  if (highPriceSample || amount == null || amount < 10000) return;
  highPriceSample = `${raw}=>${amount}`;
}

function roundMoney(n) {
  return Math.max(0, Math.round(n * 100) / 100);
}

// Softtr "149.000" was once read as 149000. Real catalog prices stay under 10.000 TL.
function undoThousandFold(amount) {
  const n = Number(amount);
  if (!Number.isFinite(n) || n < 10000) return null;
  const fixed = roundMoney(n / 1000);
  if (fixed < 1 || fixed >= 10000) return null;
  return fixed;
}

function asMoney(value) {
  if (typeof value === "boolean") return null;
  if (typeof value === "number") {
    if (!Number.isFinite(value)) return null;
    const amount = roundMoney(value);
    noteHighPrice(value, amount);
    return amount;
  }
  if (typeof value === "string") {
    let text = value.trim().replace(/\s+/g, "").replace(/₺/g, "").replace(/TL/gi, "");
    if (!text) return null;
    // Softtr salePrice: "149.000" means 149.00 TL. A single dot plus exactly
    // three digits is a decimal, not a thousand separator.
    if (/^\d+\.\d{3}$/.test(text)) {
      const decimal = Number(text);
      if (!Number.isFinite(decimal)) return null;
      const amount = roundMoney(decimal);
      noteHighPrice(value, amount);
      return amount;
    }
    if (text.includes(",") && text.includes(".")) {
      text = text.replace(/\./g, "").replace(",", ".");
    } else if (text.includes(",")) {
      text = text.replace(",", ".");
    } else if (/^\d{1,3}(\.\d{3}){2,}$/.test(text)) {
      text = text.replace(/\./g, "");
    }
    const n = Number(text);
    if (!Number.isFinite(n)) return null;
    const amount = roundMoney(n);
    noteHighPrice(value, amount);
    return amount;
  }
  return null;
}

function moneyFrom(row, keys) {
  const direct = firstByKeys(row, keys);
  let amount = null;
  if (direct != null && typeof direct !== "object") {
    amount = asMoney(direct);
  } else if (direct && typeof direct === "object") {
    amount = asMoney(firstByKeys(direct, ["amount", "value", "price", "fiyat"]));
  }
  if (amount == null || amount <= 0) return null;
  return amount;
}

function nestedPriceObject(row) {
  const map = lowerKeyMap(row);
  for (const key of ["price", "prices", "fiyat", "fiyatlar", "pricing"]) {
    const value = map[normKey(key)];
    if (value && typeof value === "object" && !Array.isArray(value)) return value;
  }
  return null;
}

const BUYING_PRICE_KEYS = [
  "alisfiyati",
  "alisfiyat",
  "alisfiyatikdvsiz",
  "alisfiyatikdvdahil",
  "buyingprice",
  "buyprice",
  "productbuyingprice",
  "purchaseprice",
  "costprice",
  "wholesaleprice",
  "tedarikfiyati",
  "maliyet",
  "maliyetfiyati",
  "cost",
];

const SELLING_PRICE_KEYS = [
  "satisfiyati",
  "satisfiyat",
  "satisfiyatikdvdahil",
  "satisfiyatikdvsiz",
  "sellingprice",
  "productsellingprice",
  "urunsatisfiyati",
];

const LIST_PRICE_KEYS = [
  "marketprice",
  "piyasafiyati",
  "piyasafiyat",
  "listprice",
  "listefiyati",
  "listefiyat",
  "originalprice",
  "oldprice",
  "pricebeforediscount",
  "normalfiyat",
];

const CAMPAIGN_PRICE_KEYS = [
  "indirimlifiyati",
  "indirimlifiyat",
  "indirimlifiyatikdvdahil",
  "discountedprice",
  "discountprice",
  "productdiscountprice",
  "productdiscountedprice",
  "kampanyafiyati",
  "campaignprice",
  "specialprice",
  "saleprice",
  "salesprice",
];

const CURRENT_PRICE_KEYS = [
  "mainproductprice",
  "urunfiyati",
  "currentprice",
  "webprice",
  "sitefiyati",
  "finalprice",
];

const DISCOUNT_RATE_KEYS = [
  "discountrate",
  "indirimorani",
  "indirimyuzdesi",
  "discountpercent",
  "indirimoraniyuzde",
];

const VARIANT_PRICE_KEYS = [
  "variantprice",
  "varyantfiyati",
  "varyantfiyat",
  "ekfiyat",
];

function withVariantExtra(amount, extra) {
  if (amount == null) return null;
  if (!extra) return amount;
  return roundMoney(amount + extra);
}

function isGreater(a, b) {
  if (a == null || b == null) return false;
  return a > b + 0.009;
}

function firstGreater(candidates, floor) {
  for (const value of candidates) {
    if (value == null) continue;
    if (floor == null || isGreater(value, floor)) return value;
  }
  return null;
}

function discountRateFrom(row) {
  const n = moneyFrom(row, DISCOUNT_RATE_KEYS);
  if (n == null) return null;
  if (n > 0 && n < 1) return n * 100;
  if (n >= 1 && n <= 90) return n;
  return null;
}

function priceArrayFrom(source) {
  for (const key of ["prices", "fiyatlar", "pricelist"]) {
    const value = firstByKeys(source, [key]);
    if (!Array.isArray(value) || value.length < 2) continue;
    const nums = value.map((item) => {
      if (item && typeof item === "object" && !Array.isArray(item)) {
        return moneyFrom(item, ["amount", "value", "price", "fiyat"]);
      }
      const amount = asMoney(item);
      return amount != null && amount > 0 ? amount : null;
    }).filter((n) => n != null);
    if (nums.length >= 3) {
      return {purchasePrice: nums[0], sellingPrice: nums[1], discountedPrice: nums[2]};
    }
    if (nums.length === 2) {
      return {purchasePrice: null, sellingPrice: nums[0], discountedPrice: nums[1]};
    }
  }
  return null;
}

function samplePriceFields(row) {
  if (!row || typeof row !== "object" || Array.isArray(row)) return "";
  const parts = [];
  for (const [key, value] of Object.entries(row)) {
    if (!/price|fiyat|indirim|kampanya|piyasa|tutar|cost|maliyet/i.test(key)) continue;
    if (value != null && typeof value === "object") {
      parts.push(`${key}={${Object.keys(value).slice(0, 8).join(",")}}`);
    } else {
      parts.push(`${key}=${value}`);
    }
  }
  return parts.join(" | ").slice(0, 1200);
}

function pricesFrom(row) {
  if (!row || typeof row !== "object") {
    return {purchasePrice: null, sellingPrice: null, discountedPrice: null};
  }
  const nested = nestedPriceObject(row);
  const source = nested ? {...row, ...nested} : row;
  const fromArray = priceArrayFrom(source);
  const purchasePrice = moneyFrom(source, BUYING_PRICE_KEYS) ?? fromArray?.purchasePrice ?? null;
  const satis = moneyFrom(source, SELLING_PRICE_KEYS) ?? fromArray?.sellingPrice ?? null;
  const liste = moneyFrom(source, LIST_PRICE_KEYS);
  const kampanya = moneyFrom(source, CAMPAIGN_PRICE_KEYS) ?? fromArray?.discountedPrice ?? null;
  const guncel = moneyFrom(source, CURRENT_PRICE_KEYS);
  const generic = moneyFrom(source, ["price", "fiyat", "unitprice", "urunfiyat"]);
  const variantExtra = moneyFrom(source, VARIANT_PRICE_KEYS) || 0;
  const rate = discountRateFrom(source);

  let customer = kampanya ?? guncel ?? null;
  if (customer == null) customer = satis ?? generic ?? fromArray?.discountedPrice ?? null;

  let crossed = firstGreater([satis, liste], customer);
  if (crossed == null && customer != null && rate != null) {
    const rebuilt = roundMoney(customer / (1 - rate / 100));
    if (isGreater(rebuilt, customer)) crossed = rebuilt;
  }

  if (customer == null) customer = crossed;

  return {
    purchasePrice,
    sellingPrice: withVariantExtra(crossed, variantExtra),
    discountedPrice: withVariantExtra(customer, variantExtra),
  };
}

function mergePrices(base, extra) {
  return {
    purchasePrice: extra?.purchasePrice ?? base?.purchasePrice ?? null,
    sellingPrice: extra?.sellingPrice ?? base?.sellingPrice ?? null,
    discountedPrice: extra?.discountedPrice ?? base?.discountedPrice ?? null,
  };
}

function numbersDiffer(current, next) {
  if (next == null) return false;
  const left = Number(current);
  const right = Number(next);
  const a = Number.isFinite(left) ? left : 0;
  const b = Number.isFinite(right) ? right : 0;
  return Math.abs(a - b) > 0.009;
}

function stockFrom(row) {
  const direct = firstByKeys(row, STOCK_KEYS);
  if (direct != null && typeof direct !== "object") {
    return asInt(direct);
  }
  if (direct && typeof direct === "object") {
    const nested = firstByKeys(direct, NESTED_STOCK_KEYS);
    const n = asInt(nested);
    if (n != null) return n;
  }
  return null;
}

function looksLikeStockKey(key) {
  const k = normKey(key);
  if (!k) return false;
  if (/(price|fiyat|tutar|tax|kdv|vat|discount|weight|gram|width|height|rate|percent|barcode|barkod|sku|code|id)$/.test(k)) {
    return false;
  }
  return /(stock|stok|qty|quantity|inventory|available|remaining|adet|onhand)/.test(k);
}

function looksLikeNestedAmountKey(key) {
  const k = normKey(key);
  return /^(amount|value|total|count|adet|qty|quantity|available|stock|stok)$/.test(k);
}

function deepStock(row, depth = 0, fromStockKey = false) {
  const direct = stockFrom(row);
  if (direct != null) return direct;
  if (depth > 4 || row == null) return null;
  if (Array.isArray(row)) {
    for (const item of row) {
      const n = deepStock(item, depth + 1, fromStockKey);
      if (n != null) return n;
    }
    return null;
  }
  if (typeof row !== "object") return null;
  for (const [key, value] of Object.entries(row)) {
    const stockish = looksLikeStockKey(key) || (fromStockKey && looksLikeNestedAmountKey(key));
    if (!stockish) continue;
    if (value != null && typeof value !== "object") {
      const n = asInt(value);
      if (n != null) return n;
    }
    const nested = deepStock(value, depth + 1, true);
    if (nested != null) return nested;
  }
  return null;
}

function publicSettings(data = {}) {
  return {
    enabled: data.enabled === true,
    baseUrl: String(data.baseUrl || DEFAULT_BASE_URL).trim() || DEFAULT_BASE_URL,
    username: String(data.username || "").trim(),
    passwordSet: Boolean(String(data.password || "").trim()),
    lastSyncAt: data.lastSyncAt || null,
    lastError: String(data.lastError || ""),
    lastPulled: Number(data.lastPulled || 0),
    lastMatched: Number(data.lastMatched || 0),
    lastUpdated: Number(data.lastUpdated || 0),
    lastPushed: Number(data.lastPushed || 0),
    lastStockFound: Number(data.lastStockFound || 0),
    lastPriceFound: Number(data.lastPriceFound || 0),
    lastSampleKeys: String(data.lastSampleKeys || ""),
  };
}

async function readSettings() {
  const snap = await db().doc(SETTINGS_PATH).get();
  const data = snap.data() || {};
  return {
    enabled: data.enabled === true,
    baseUrl: String(data.baseUrl || DEFAULT_BASE_URL).trim() || DEFAULT_BASE_URL,
    username: String(data.username || "").trim(),
    password: String(data.password || "").trim(),
    lastError: String(data.lastError || ""),
  };
}

async function saveSettings(input = {}) {
  const current = await readSettings();
  const username = String(input.username ?? current.username).trim();
  const incomingPassword = String(input.password ?? "").trim();
  const password = incomingPassword || current.password;
  const baseUrl = String(input.baseUrl ?? current.baseUrl).trim() || DEFAULT_BASE_URL;
  const enabled = input.enabled == null ? current.enabled : asBool(input.enabled, current.enabled);
  const payload = {
    enabled,
    baseUrl: baseUrl.replace(/\/+$/, ""),
    username,
    password,
    updatedAt: FieldValue.serverTimestamp(),
  };
  await db().doc(SETTINGS_PATH).set(payload, {merge: true});
  return publicSettings({...current, ...payload, password});
}

function joinUrl(baseUrl, path) {
  const base = String(baseUrl || DEFAULT_BASE_URL).replace(/\/+$/, "");
  const suffix = String(path || "").replace(/^\/+/, "");
  return `${base}/${suffix}`;
}

async function softtrFetch(settings, method, path, {query, body} = {}) {
  const url = new URL(joinUrl(settings.baseUrl, path));
  for (const [key, value] of Object.entries(query || {})) {
    if (value == null || value === "") continue;
    url.searchParams.set(key, String(value));
  }
  const auth = Buffer.from(`${settings.username}:${settings.password}`).toString("base64");
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Basic ${auth}`,
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: body == null ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json = null;
  if (text) {
    try {
      json = JSON.parse(text);
    } catch (_) {
      json = null;
    }
  }
  if (!res.ok) {
    const detail = (json && (json.message?.detail || json.message || json.error)) || text.slice(0, 240);
    throw new Error(`Softtr ${res.status}: ${detail || res.statusText}`);
  }
  return json;
}

function collectArrays(node, acc = []) {
  if (Array.isArray(node)) {
    acc.push(node);
    for (const item of node) collectArrays(item, acc);
    return acc;
  }
  if (node && typeof node === "object") {
    for (const value of Object.values(node)) collectArrays(value, acc);
  }
  return acc;
}

function looksLikeProduct(row) {
  if (!row || typeof row !== "object" || Array.isArray(row)) return false;
  return Boolean(firstText(row, BARCODE_KEYS) || firstText(row, PRODUCT_ID_KEYS));
}

function variantList(row) {
  const map = lowerKeyMap(row);
  for (const key of VARIANT_KEYS) {
    if (Array.isArray(map[key])) return map[key];
  }
  return [];
}

function sampleObjectKeys(row) {
  if (!row || typeof row !== "object" || Array.isArray(row)) return "";
  const parts = [];
  for (const [key, value] of Object.entries(row)) {
    let extra = typeof value;
    if (Array.isArray(value)) {
      extra = `array(${value.length})`;
      if (value[0] && typeof value[0] === "object") {
        extra += `{${Object.keys(value[0]).slice(0, 10).join(",")}}`;
      }
    } else if (value && typeof value === "object") {
      extra = `{${Object.keys(value).slice(0, 10).join(",")}}`;
    } else if (value != null && value !== "") {
      extra = String(value).slice(0, 32);
    }
    parts.push(`${key}=${extra}`);
  }
  return parts.join(" | ").slice(0, 900);
}

function firstObject(node) {
  if (!node || typeof node !== "object") return null;
  if (!Array.isArray(node) && looksLikeProduct(node)) return node;
  const arrays = collectArrays(node);
  for (const list of arrays) {
    for (const item of list) {
      if (item && typeof item === "object" && !Array.isArray(item)) return item;
    }
  }
  return null;
}

function toStockRow(parent, variant) {
  const idSource = variant && typeof variant === "object" ? variant : parent;
  const merged = {...(parent || {}), ...(variant || {})};
  const barcode = normalizeBarcode(firstText(merged, BARCODE_KEYS));
  if (!barcode) return null;
  const productId = firstText(idSource, PRODUCT_ID_KEYS) || firstText(merged, PRODUCT_ID_KEYS);
  const stock = stockFrom(variant) ??
      deepStock(variant) ??
      stockFrom(parent) ??
      deepStock(parent) ??
      stockFrom(merged) ??
      deepStock(merged);
  const prices = mergePrices(pricesFrom(parent), pricesFrom(variant || merged));
  return {
    barcode,
    productId,
    stock,
    ...prices,
  };
}

function betterRow(current, next) {
  if (!current) return next;
  const stock = next.stock != null && (current.stock == null || next.stock > current.stock) ?
    next.stock :
    (current.stock ?? next.stock);
  return {
    barcode: next.barcode || current.barcode,
    productId: next.productId || current.productId,
    stock,
    purchasePrice: next.purchasePrice ?? current.purchasePrice,
    sellingPrice: next.sellingPrice ?? current.sellingPrice,
    discountedPrice: next.discountedPrice ?? current.discountedPrice,
  };
}

function collectProductRows(node, inherited, acc) {
  if (Array.isArray(node)) {
    for (const item of node) collectProductRows(item, inherited, acc);
    return;
  }
  if (!node || typeof node !== "object") return;

  const ownBarcode = normalizeBarcode(firstText(node, BARCODE_KEYS));
  const barcode = ownBarcode || inherited.barcode;
  const productId = firstText(node, PRODUCT_ID_KEYS) || inherited.productId;
  const ownStock = stockFrom(node);
  const prices = mergePrices(inherited, pricesFrom(node));
  const variants = variantList(node);
  if (variants.length) {
    for (const variant of variants) {
      collectProductRows(variant, {barcode, productId, ...prices}, acc);
    }
  }
  if (ownBarcode) {
    acc.push({
      barcode: ownBarcode,
      productId,
      stock: ownStock ?? deepStock(node),
      ...prices,
    });
  }

  for (const [key, value] of Object.entries(node)) {
    if (value == null || typeof value !== "object") continue;
    if (VARIANT_KEYS.includes(normKey(key))) continue;
    collectProductRows(value, {barcode, productId, ...prices}, acc);
  }
}

function extractStockRows(payload) {
  const collected = [];
  collectProductRows(payload, {barcode: "", productId: ""}, collected);
  if (!collected.length) {
    const arrays = collectArrays(payload);
    for (const list of arrays) {
      for (const item of list) {
        if (!looksLikeProduct(item)) continue;
        const variants = variantList(item);
        const parts = variants.length ?
          variants.map((variant) => toStockRow(item, variant)) :
          [toStockRow(item, null)];
        for (const row of parts) {
          if (row) collected.push(row);
        }
      }
    }
  }
  const byBarcode = new Map();
  for (const row of collected) {
    if (!row || !row.barcode) continue;
    byBarcode.set(row.barcode, betterRow(byBarcode.get(row.barcode), row));
  }
  return [...byBarcode.values()];
}

function productListPage(json) {
  const root = json && typeof json === "object" ? json : {};
  const data = root.data && typeof root.data === "object" ? root.data : root;
  const content = data.content;
  const items = Array.isArray(content) ?
    content :
    (content && typeof content === "object" ? [content] : []);
  return {
    items,
    page: Number(data.page || 0),
    pageCount: Number(data.pageCount || data.totalPages || 0),
    size: Number(data.size || data.pageSize || PAGE_SIZE),
  };
}

async function listSofttrProducts(settings) {
  const all = [];
  const seen = new Set();
  let sampleKeys = "";
  highPriceSample = "";
  let pageCount = 0;
  for (let page = 1; page <= 50; page++) {
    const json = await softtrFetch(settings, "GET", "products/list", {
      query: {page, pageSize: PAGE_SIZE},
    });
    const listed = productListPage(json);
    if (!sampleKeys) {
      const first = listed.items[0] || firstObject(json);
      const parsed = pricesFrom(first);
      const priceDump = samplePriceFields(first);
      sampleKeys = `alış=${parsed.purchasePrice} satış=${parsed.sellingPrice} indirimli=${parsed.discountedPrice} | ${priceDump || sampleObjectKeys(first)}`;
      if (highPriceSample) sampleKeys = `${sampleKeys} | yuksek=${highPriceSample}`;
    }
    if (listed.pageCount > 0) pageCount = listed.pageCount;
    const source = listed.items.length ? listed.items : json;
    const rows = extractStockRows(source);
    let added = 0;
    for (const row of rows) {
      if (seen.has(row.barcode)) {
        const idx = all.findIndex((item) => item.barcode === row.barcode);
        if (idx >= 0) all[idx] = betterRow(all[idx], row);
        continue;
      }
      seen.add(row.barcode);
      all.push(row);
      added += 1;
    }
    if (pageCount > 0 && page >= pageCount) break;
    if (!listed.items.length && added === 0) break;
    if (listed.items.length && listed.items.length < PAGE_SIZE && pageCount <= 0) break;
    if (!listed.items.length && added > 0 && added < PAGE_SIZE) break;
  }
  if (highPriceSample && !sampleKeys.includes("yuksek=")) {
    sampleKeys = `${sampleKeys} | yuksek=${highPriceSample}`;
  }
  const stockFound = all.filter((row) => row.stock != null).length;
  const priceFound = all.filter((row) =>
    row.purchasePrice != null || row.sellingPrice != null || row.discountedPrice != null
  ).length;
  logger.info("Softtr products parsed", {
    pulled: all.length,
    stockFound,
    priceFound,
    sampleKeys,
    sampleStock: all.find((row) => row.stock != null) || all[0] || null,
  });
  return {rows: all, sampleKeys, stockFound, priceFound};
}

async function loadAllProducts() {
  const docs = [];
  let last = null;
  while (true) {
    let query = db().collection("products").orderBy(FieldPath.documentId()).limit(100);
    if (last) query = query.startAfter(last);
    const page = await query.get();
    if (page.empty) break;
    docs.push(...page.docs);
    last = page.docs[page.docs.length - 1];
    if (page.size < 100) break;
  }
  return docs;
}

async function writeBatches(updates) {
  for (let i = 0; i < updates.length; i += 400) {
    const batch = db().batch();
    for (const row of updates.slice(i, i + 400)) {
      batch.set(row.ref, row.data, {merge: true});
    }
    await batch.commit();
  }
}

async function pushStockRows(settings, rows) {
  if (!settings.enabled || !rows.length) return {pushed: 0, failed: 0};
  let pushed = 0;
  let failed = 0;
  for (let i = 0; i < rows.length; i += 100) {
    const chunk = rows.slice(i, i + 100);
    const withId = chunk.filter((row) => row.productId);
    const missingId = chunk.filter((row) => !row.productId);
    for (const row of missingId) {
      row.error = "Softtr urun id yok; once stok esitleyin.";
      failed += 1;
    }
    try {
      if (withId.length) {
        await softtrFetch(settings, "POST", "products/updateStocks", {
          body: withId.map((row) => ({
            productId: row.productId,
            stockAmount: row.stock,
          })),
        });
        pushed += withId.length;
      }
    } catch (error) {
      failed += withId.length;
      logger.error("Softtr updateStocks failed", {error: String(error)});
      for (const row of withId) row.error = String(error);
    }
  }
  return {pushed, failed};
}

function pendingRowFromDoc(doc) {
  const data = doc.data() || {};
  if (data.softtrPendingSource !== "order") return null;
  const pending = asInt(data.softtrPendingStock);
  if (pending == null) return null;
  const barcode = normalizeBarcode(data.barcode);
  if (!barcode && !data.softtrProductId) return null;
  return {
    ref: doc.ref,
    barcode,
    productId: String(data.softtrProductId || "").trim(),
    stock: pending,
    price: Number(data.unitPrice || 0),
  };
}

async function pushProductIds(productIds) {
  const ids = [...new Set((productIds || []).map((id) => String(id || "").trim()).filter(Boolean))];
  if (!ids.length) return {pushed: 0, failed: 0};
  const settings = await readSettings();
  if (!settings.enabled || !settings.username || !settings.password) {
    return {pushed: 0, failed: 0};
  }
  const snaps = await Promise.all(ids.map((id) => db().collection("products").doc(id).get()));
  const rows = [];
  for (const snap of snaps) {
    if (!snap.exists) continue;
    const data = snap.data() || {};
    const stock = asInt(data.softtrPendingStock != null ? data.softtrPendingStock : data.stock);
    const barcode = normalizeBarcode(data.barcode);
    if (stock == null || (!barcode && !data.softtrProductId)) continue;
    rows.push({
      ref: snap.ref,
      barcode,
      productId: String(data.softtrProductId || "").trim(),
      stock,
      price: Number(data.unitPrice || 0),
    });
  }
  const result = await pushStockRows(settings, rows);
  const updates = [];
  for (const row of rows) {
    if (row.error) {
      updates.push({
        ref: row.ref,
        data: {
          softtrLastError: row.error.slice(0, 240),
          updatedAt: FieldValue.serverTimestamp(),
        },
      });
      continue;
    }
    updates.push({
      ref: row.ref,
      data: {
        softtrPendingStock: FieldValue.delete(),
        softtrPendingSource: FieldValue.delete(),
        softtrLastError: FieldValue.delete(),
        softtrSyncedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
    });
  }
  await writeBatches(updates);
  return result;
}

async function flushPending(docs, settings) {
  const rows = [];
  for (const doc of docs) {
    const row = pendingRowFromDoc(doc);
    if (row) rows.push(row);
  }
  if (!rows.length) return {pushed: 0, failed: 0};
  const result = await pushStockRows(settings, rows);
  const updates = [];
  for (const row of rows) {
    if (row.error) {
      updates.push({
        ref: row.ref,
        data: {softtrLastError: row.error.slice(0, 240)},
      });
      continue;
    }
    updates.push({
      ref: row.ref,
      data: {
        softtrPendingStock: FieldValue.delete(),
        softtrPendingSource: FieldValue.delete(),
        softtrLastError: FieldValue.delete(),
        softtrSyncedAt: FieldValue.serverTimestamp(),
      },
    });
  }
  await writeBatches(updates);
  return result;
}

function remoteByBarcode(remote) {
  const map = new Map();
  for (const row of remote) {
    for (const key of barcodeAliases(row.barcode)) {
      if (!map.has(key)) map.set(key, row);
    }
  }
  return map;
}

function matchRemote(byBarcode, barcode) {
  for (const key of barcodeAliases(barcode)) {
    const row = byBarcode.get(key);
    if (row) return row;
  }
  return null;
}

async function syncFromSofttr() {
  const settings = await readSettings();
  if (!settings.enabled) {
    throw new Error("Softtr stok esitleme kapali. Anahtari acip Kaydet'e basin.");
  }
  if (!settings.username || !settings.password) {
    throw new Error("Softtr API kullanici adi ve sifre gerekli.");
  }

  const docs = await loadAllProducts();
  const pending = await flushPending(docs, settings);
  const listed = await listSofttrProducts(settings);
  const remote = listed.rows;
  const sampleKeys = listed.sampleKeys;
  const stockFound = listed.stockFound || 0;
  const priceFound = listed.priceFound || 0;

  if (!remote.length) {
    const lastError = sampleKeys ?
      `Softtr urun listesi okundu ama barkod/stok alani bulunamadi. Alanlar: ${sampleKeys}` :
      "Softtr urun listesi bos dondu. API kullanici/sifre veya barkod alanlarini kontrol edin.";
    await db().doc(SETTINGS_PATH).set({
      lastPulled: 0,
      lastMatched: 0,
      lastUpdated: 0,
      lastPushed: pending.pushed || 0,
      lastStockFound: stockFound,
      lastPriceFound: priceFound,
      lastError,
      lastSampleKeys: sampleKeys,
      lastSyncAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    logger.warn("Softtr stock pull empty", {sampleKeys});
    return {pulled: 0, matched: 0, updated: 0, pushed: pending.pushed || 0};
  }

  const byBarcode = remoteByBarcode(remote);
  const updates = [];
  let matched = 0;
  let changed = 0;

  for (const doc of docs) {
    const data = doc.data() || {};
    const barcode = normalizeBarcode(data.barcode);
    const remoteRow = barcode ? matchRemote(byBarcode, barcode) : null;
    const stalePending = data.softtrPendingStock != null && data.softtrPendingSource !== "order";
    if (!remoteRow) {
      const next = {};
      if (data.softtrMatched === true) {
        next.softtrMatched = false;
        next.softtrProductId = FieldValue.delete();
      }
      if (stalePending) {
        next.softtrPendingStock = FieldValue.delete();
        next.softtrPendingSource = FieldValue.delete();
      }
      const foldedUnit = undoThousandFold(data.unitPrice);
      if (foldedUnit != null) next.unitPrice = foldedUnit;
      const foldedOld = undoThousandFold(data.oldPrice);
      if (foldedOld != null) {
        const sale = next.unitPrice ?? Number(data.unitPrice || 0);
        next.oldPrice = foldedOld > sale + 0.009 ? foldedOld : 0;
      }
      if (next.unitPrice != null || next.oldPrice != null) {
        const sale = Number(next.unitPrice ?? data.unitPrice ?? 0);
        const list = Number(next.oldPrice ?? data.oldPrice ?? 0);
        if (list > sale && sale > 0) {
          next.discountPercent = Math.round(((list - sale) / list) * 100);
        } else if (asInt(data.discountPercent)) {
          next.discountPercent = 0;
        }
      }
      if (Object.keys(next).length) {
        updates.push({ref: doc.ref, data: next});
      }
      continue;
    }
    matched += 1;
    const pendingStock = data.softtrPendingSource === "order" ? asInt(data.softtrPendingStock) : null;
    if (pendingStock != null) continue;
    const next = {};
    if (data.softtrMatched !== true) next.softtrMatched = true;
    const productId = String(remoteRow.productId || data.softtrProductId || "");
    if (productId && String(data.softtrProductId || "") !== productId) {
      next.softtrProductId = productId;
    }
    if (stalePending) {
      next.softtrPendingStock = FieldValue.delete();
      next.softtrPendingSource = FieldValue.delete();
    }
    if (remoteRow.stock != null && asInt(data.stock) !== remoteRow.stock) {
      next.stock = remoteRow.stock;
    }
    if (numbersDiffer(data.purchasePrice, remoteRow.purchasePrice)) {
      next.purchasePrice = remoteRow.purchasePrice;
    }
    if (remoteRow.sellingPrice != null) {
      if (numbersDiffer(data.oldPrice, remoteRow.sellingPrice)) {
        next.oldPrice = remoteRow.sellingPrice;
      }
    } else if (
      Number(data.oldPrice || 0) > 0 &&
      remoteRow.discountedPrice != null &&
      Math.abs(Number(data.oldPrice) - Number(remoteRow.discountedPrice)) <= 0.009
    ) {
      next.oldPrice = 0;
    }
    if (numbersDiffer(data.unitPrice, remoteRow.discountedPrice)) {
      next.unitPrice = remoteRow.discountedPrice;
    } else {
      const foldedUnit = undoThousandFold(data.unitPrice);
      if (foldedUnit != null && remoteRow.discountedPrice == null) {
        next.unitPrice = foldedUnit;
      }
    }
    if (next.oldPrice == null) {
      const foldedOld = undoThousandFold(data.oldPrice);
      if (foldedOld != null && remoteRow.sellingPrice == null) {
        const sale = Number(next.unitPrice ?? data.unitPrice ?? 0);
        next.oldPrice = foldedOld > sale + 0.009 ? foldedOld : 0;
      }
    }
    const listPrice = next.oldPrice ?? data.oldPrice;
    const salePrice = next.unitPrice ?? data.unitPrice;
    if (listPrice > 0 && salePrice > 0 && listPrice > salePrice) {
      const discount = Math.round(((listPrice - salePrice) / listPrice) * 100);
      if (asInt(data.discountPercent) !== discount) next.discountPercent = discount;
    } else if (asInt(data.discountPercent) && !(listPrice > salePrice)) {
      next.discountPercent = 0;
    }
    if (!Object.keys(next).length) continue;
    changed += 1;
    next.softtrSyncedAt = FieldValue.serverTimestamp();
    updates.push({ref: doc.ref, data: next});
  }

  await writeBatches(updates);
  const summary = {
    lastPulled: remote.length,
    lastMatched: matched,
    lastUpdated: changed,
    lastPushed: pending.pushed || 0,
    lastStockFound: stockFound,
    lastPriceFound: priceFound,
    lastError: matched === 0 ?
      "Softtr urunleri geldi ama uygulamadaki barkodlarla eslesmedi. Barkodlar birebir ayni olmali." :
      (stockFound === 0 && priceFound === 0 ?
        `Softtr ${remote.length} urun getirdi ama stok/fiyat alani okunamadi. ${sampleKeys}` :
        ""),
    lastSampleKeys: sampleKeys,
    lastSyncAt: FieldValue.serverTimestamp(),
  };
  await db().doc(SETTINGS_PATH).set(summary, {merge: true});
  logger.info("Softtr stock sync finished", {
    pulled: remote.length,
    matched,
    updated: changed,
    pushed: pending.pushed,
    stockFound,
    priceFound,
    sampleKeys,
  });
  return {
    pulled: remote.length,
    matched,
    updated: changed,
    pushed: pending.pushed || 0,
  };
}

async function pushProductById(productId) {
  const id = String(productId || "").trim();
  if (!id) throw new Error("Urun id gerekli.");
  const ref = db().collection("products").doc(id);
  const snap = await ref.get();
  if (!snap.exists) throw new Error("Urun bulunamadi.");
  const stock = asInt(snap.get("stock")) ?? 0;
  await ref.set({
    softtrPendingStock: stock,
    softtrPendingSource: "order",
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return pushProductIds([id]);
}

module.exports = {
  SETTINGS_PATH,
  DEFAULT_BASE_URL,
  publicSettings,
  readSettings,
  saveSettings,
  syncFromSofttr,
  pushProductIds,
  pushProductById,
  extractStockRows,
};
