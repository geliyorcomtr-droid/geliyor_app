const crypto = require("crypto");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

const SETTINGS_PATH = "settings/birfatura";
const VAT_RATE = 20;
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const PAYMENTS = [
  {Id: 1, Value: "Kapıda Nakit"},
  {Id: 2, Value: "Kapıda Kredi Kartı / POS"},
  {Id: 3, Value: "Havale / EFT"},
];
const STATUSES = [
  {Id: 1, Value: "Hazırlanıyor", key: "preparing"},
  {Id: 2, Value: "Kuryede", key: "shipping"},
  {Id: 3, Value: "Teslim", key: "delivered"},
  {Id: 4, Value: "İptal", key: "cancelled"},
];

function db() {
  return getFirestore();
}

function decimal(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return 0;
  return n;
}

function taxExclusive(gross, rate = VAT_RATE) {
  const n = decimal(gross);
  if (!n) return 0;
  return n / (1 + rate / 100);
}

function toLongId(value) {
  const raw = String(value || "").trim();
  if (/^\d+$/.test(raw)) {
    const n = Number(raw);
    if (Number.isSafeInteger(n) && n > 0) return n;
  }
  const buf = crypto.createHash("sha256").update(raw || "x").digest();
  return buf.readUIntBE(0, 6) || 1;
}

function displayOrderCode(id, data) {
  const stored = String((data && data.orderNo) || "").trim().replace(/^#/, "");
  if (stored) return stored.toUpperCase();
  const raw = String(id || "").trim();
  if (!raw) return "SIPARIS";
  return (raw.length <= 6 ? raw : raw.slice(-6)).toUpperCase();
}

function compactOrderId(code) {
  let n = 0;
  const src = String(code || "X").toUpperCase();
  for (let i = 0; i < src.length; i++) {
    const d = parseInt(src[i], 36);
    n = n * 36 + (Number.isFinite(d) ? d : 0);
  }
  if (Number.isSafeInteger(n) && n > 0) return n;
  return toLongId(code);
}

function requiredText(value, fallback) {
  const text = String(value || "").trim();
  return text || fallback;
}

function readToken(req) {
  const headers = req.headers || {};
  const headerToken = String(headers.token || "").trim();
  if (headerToken) return headerToken;
  const auth = String(headers.authorization || "").trim();
  if (/^bearer\s+/i.test(auth)) return auth.replace(/^bearer\s+/i, "").trim();
  if (auth) return auth;
  return String(req.query?.token || "").trim();
}

function endpointName(req) {
  const fromQuery = String(req.query?.endpoint || "").trim();
  if (fromQuery) return fromQuery.replace(/^\//, "");
  const path = String(req.path || req.url || "").split("?")[0];
  const parts = path.split("/").filter(Boolean);
  const last = parts[parts.length - 1] || "orders";
  return last.replace(/\.json$/i, "");
}

function parseDate(raw, endOfDay = false) {
  const value = String(raw || "").trim();
  if (!value) return null;
  const dotted = value.match(
      /^(\d{1,2})[./](\d{1,2})[./](\d{4})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$/,
  );
  if (dotted) {
    const [, d, m, y, hh, mm = "0", ss = "0"] = dotted;
    const hasTime = hh != null;
    return new Date(
        Number(y),
        Number(m) - 1,
        Number(d),
        hasTime ? Number(hh) : (endOfDay ? 23 : 0),
        hasTime ? Number(mm) : (endOfDay ? 59 : 0),
        hasTime ? Number(ss) : (endOfDay ? 59 : 0),
    );
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return null;
  if (endOfDay && !/[T ]\d/.test(value)) {
    parsed.setHours(23, 59, 59, 999);
  }
  return parsed;
}

function formatTr(date) {
  const d = date instanceof Date ? date : new Date(date);
  if (Number.isNaN(d.getTime())) return "";
  const pad = (n) => String(n).padStart(2, "0");
  return `${pad(d.getDate())}.${pad(d.getMonth() + 1)}.${d.getFullYear()} ` +
      `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

function requestBody(req) {
  if (req.body && typeof req.body === "object" && !Buffer.isBuffer(req.body)) {
    return req.body;
  }
  if (typeof req.body === "string" && req.body.trim()) {
    try {
      return JSON.parse(req.body);
    } catch (_) {
      return {};
    }
  }
  return {};
}

function cityFromAddress(address) {
  const text = String(address || "").trim();
  const parts = text.split("/").map((part) => part.trim()).filter(Boolean);
  if (parts.length >= 2) {
    return {
      city: requiredText(parts[parts.length - 1], "İstanbul"),
      town: requiredText(
          parts[parts.length - 2].replace(/,.*/, "").trim(),
          "Merkez",
      ),
    };
  }
  return {city: "İstanbul", town: "Merkez"};
}

function locationOf(primary, fallback, address) {
  const city = String(
      (primary && (primary.city || primary.City)) ||
      (fallback && (fallback.city || fallback.City)) ||
      "",
  ).trim();
  const town = String(
      (primary && (primary.district || primary.town || primary.Town)) ||
      (fallback && (fallback.district || fallback.town || fallback.Town)) ||
      "",
  ).trim();
  if (city && town) return {city, town};
  const parsed = cityFromAddress(address);
  return {
    city: city || parsed.city,
    town: town || parsed.town,
  };
}

function paymentOf(method) {
  const raw = String(method || "").toLowerCase();
  if (raw.includes("havale") || raw.includes("eft")) return PAYMENTS[2];
  if (raw.includes("pos") || raw.includes("kart")) return PAYMENTS[1];
  const found = PAYMENTS.find((item) =>
    item.Value.toLowerCase() === String(method || "").toLowerCase(),
  );
  return found || PAYMENTS[0];
}

function statusById(id) {
  return STATUSES.find((item) => String(item.Id) === String(id)) || null;
}

function statusMessage(key) {
  if (key === "shipping") return "Siparişiniz kuryeye verildi.";
  if (key === "delivered") return "Siparişiniz teslim edildi.";
  if (key === "cancelled") return "Siparişiniz iptal edildi.";
  return "Siparişiniz hazırlanıyor.";
}

async function ensureBirfaturaSettings() {
  const ref = db().doc(SETTINGS_PATH);
  const snap = await ref.get();
  const data = snap.data() || {};
  let token = String(data.token || "").trim();
  if (!token) {
    token = crypto.randomUUID();
    await ref.set({
      token,
      enabled: true,
      vatRate: VAT_RATE,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  return {
    token,
    enabled: data.enabled !== false,
    vatRate: Number(data.vatRate || VAT_RATE),
    siteUrl: "https://geliyortrapp.web.app",
    apiBase: "https://geliyortrapp.web.app/api",
    tokenIsGuid: UUID_RE.test(token),
  };
}

async function assertToken(req) {
  const settings = await ensureBirfaturaSettings();
  const provided = readToken(req);
  if (!provided || provided !== settings.token) {
    const err = new Error("unauthorized");
    err.status = 403;
    throw err;
  }
  return settings;
}

function lineVat(item, fallback) {
  const n = Number(item.vatRate);
  if (n === 0 || n === 1 || n === 8 || n === 10 || n === 18 || n === 20) {
    return n;
  }
  return fallback;
}

function looksLikeFirestoreId(value) {
  return /^[A-Za-z0-9]{20}$/.test(String(value || "").trim());
}

function normalizeBarcode(raw) {
  return String(raw || "").trim().replace(/\s+/g, "");
}

function barcodeFromProduct(product) {
  if (!product || typeof product !== "object") return "";
  for (const key of ["barcode", "barkod", "sku", "stockCode", "stokKodu"]) {
    const value = normalizeBarcode(product[key]);
    if (value && !looksLikeFirestoreId(value)) return value;
  }
  return "";
}

function possibleCatalogIds(item) {
  const weight = String(item.weight || "").trim();
  const ids = [];
  const add = (raw) => {
    let id = String(raw || "").trim();
    if (!id) return;
    ids.push(id);
    if (weight && id.endsWith(`-${weight}`)) {
      ids.push(id.slice(0, -(weight.length + 1)));
    }
    const dash = id.lastIndexOf("-");
    if (dash > 0) {
      const prefix = id.slice(0, dash);
      if (looksLikeFirestoreId(prefix)) ids.push(prefix);
    }
  };
  add(item.catalogProductId);
  add(item.productId);
  return [...new Set(ids)];
}

function catalogIdOf(item) {
  const ids = possibleCatalogIds(item);
  return ids.find((id) => looksLikeFirestoreId(id)) || ids[0] || "";
}

function productNameOf(item) {
  const name = requiredText(item.title, "Ürün").trim();
  const weight = String(item.weight || "").trim();
  if (!weight) return name.slice(0, 120);
  const lower = name.toLowerCase();
  if (lower.includes(weight.toLowerCase())) return name.slice(0, 120);
  const suffix = ` ${weight}`;
  const maxBase = Math.max(0, 120 - suffix.length);
  return `${name.slice(0, maxBase)}${suffix}`;
}

function stockCodeOf(item) {
  const barcode = normalizeBarcode(item.barcode);
  if (barcode && !looksLikeFirestoreId(barcode)) return barcode;
  return "";
}

function titleKey(value) {
  return String(value || "").trim().toLowerCase();
}

async function loadProductCatalog(productCache) {
  if (productCache.has("__all_products__")) {
    return productCache.get("__all_products__");
  }
  const snap = await db().collection("products").limit(300).get();
  const list = snap.docs.map((doc) => ({id: doc.id, ...(doc.data() || {})}));
  productCache.set("__all_products__", list);
  for (const product of list) {
    productCache.set(product.id, product);
  }
  return list;
}

async function productForItem(item, productCache) {
  const ids = possibleCatalogIds(item);
  const all = await loadProductCatalog(productCache);
  for (const id of ids) {
    const hit = productCache.get(id);
    if (hit) return hit;
  }
  const title = titleKey(item.title);
  if (!title) return {};
  const exact = all.find((product) => titleKey(product.title) === title);
  if (exact) return exact;
  return all.find((product) => title && titleKey(product.title).includes(title)) ||
    {};
}

async function enrichOrderItems(data, productCache, fallbackVat) {
  const items = Array.isArray(data.items) ? data.items : [];
  const next = [];
  for (const item of items) {
    const product = await productForItem(item, productCache);
    const barcode = stockCodeOf(item) || barcodeFromProduct(product);
    next.push({
      ...item,
      catalogProductId: catalogIdOf(item) || item.catalogProductId,
      vatRate: item.vatRate ?? product.vatRate ?? fallbackVat,
      barcode,
      weight: String(item.weight || product.weight || "").trim(),
    });
  }
  return {...data, items: next};
}

function toOrderPayload(id, numericId, data, user, vatRate) {
  const created = data.createdAt;
  const createdDate = created && typeof created.toDate === "function"
    ? created.toDate()
    : (created instanceof Date ? created : new Date());
  const billing = data.billing && typeof data.billing === "object"
    ? data.billing
    : {};
  const shippingAddress = requiredText(
      data.address || billing.address,
      "Adres belirtilmedi",
  );
  const billingAddress = requiredText(
      billing.address || data.address,
      shippingAddress,
  );
  const shipCity = locationOf(data, null, shippingAddress);
  const billCity = locationOf(billing, data, billingAddress);
  const name = requiredText(
      billing.contactName || data.customerName || user.display_name,
      "Müşteri",
  );
  const phone = requiredText(
      String(data.phone || user.phone_number || user.phone || "")
          .replace(/\D/g, ""),
      "00000000000",
  );
  const nationalId = String(billing.nationalId || "").replace(/\D/g, "");
  const taxId = String(billing.taxId || "").replace(/\D/g, "");
  const taxOffice = String(billing.taxOffice || "").trim();
  const payment = paymentOf(data.paymentMethod);
  const items = Array.isArray(data.items) ? data.items : [];
  const details = [];
  let productsGross = 0;
  let productsNet = 0;
  for (const item of items) {
    const qty = Math.max(1, decimal(item.quantity || 1));
    const unitGross = decimal(item.unitPrice || 0);
    const vat = lineVat(item, vatRate);
    productsGross += unitGross * qty;
    productsNet += taxExclusive(unitGross, vat) * qty;
    const code = stockCodeOf(item);
    if (!code) {
      logger.warn("BirFatura barcode missing", {
        title: item.title,
        productId: item.productId,
        catalogProductId: item.catalogProductId,
      });
    }
    details.push({
      ProductId: toLongId(item.productId || item.catalogProductId || code || id),
      ProductCode: code || catalogIdOf(item),
      Barcode: code,
      ProductName: productNameOf(item),
      ProductQuantityType: "Adet",
      ProductQuantity: qty,
      VatRate: vat,
      ProductUnitPriceTaxIncluding: unitGross,
      ProductUnitPriceTaxExcluding: taxExclusive(unitGross, vat),
    });
  }
  const shipping = Math.max(0, decimal(data.courierFee || 0));
  const discount = Math.max(0, decimal(data.couponDiscount || 0));
  const paid = decimal(data.total || (productsGross + shipping - discount));
  const shippingNet = taxExclusive(shipping, vatRate);
  const discountNet = taxExclusive(discount, vatRate);
  const payload = {
    OrderId: numericId,
    OrderCode: displayOrderCode(id, data),
    OrderDate: formatTr(createdDate),
    InvoiceDate: formatTr(createdDate),
    BillingName: name,
    BillingAddress: billingAddress,
    BillingTown: billCity.town,
    BillingCity: billCity.city,
    BillingMobilePhone: phone,
    TaxOffice: taxOffice || null,
    TaxNo: taxId || null,
    SSNTCNo: nationalId || null,
    Email: String(user.email || billing.email || "").trim() || null,
    ShippingName: requiredText(data.customerName, name),
    ShippingAddress: shippingAddress,
    ShippingTown: shipCity.town,
    ShippingCity: shipCity.city,
    ShippingCountry: "Türkiye",
    PaymentTypeId: payment.Id,
    PaymentType: payment.Value,
    Currency: "TRY",
    CurrencyRate: 1,
    TotalPaidTaxExcluding: productsNet + shippingNet - discountNet,
    TotalPaidTaxIncluding: paid,
    ProductsTotalTaxExcluding: productsNet,
    ProductsTotalTaxIncluding: productsGross,
    DiscountTotalTaxExcluding: taxExclusive(discount, vatRate),
    DiscountTotalTaxIncluding: discount,
    OrderDetails: details,
  };
  const userId = String(data.userId || "").trim();
  if (userId) payload.CustomerId = toLongId(userId);
  if (shipping > 0) {
    payload.ShippingChargeTotalTaxExcluding = taxExclusive(shipping, vatRate);
    payload.ShippingChargeTotalTaxIncluding = shipping;
  }
  for (const key of Object.keys(payload)) {
    if (payload[key] === null || payload[key] === "") delete payload[key];
  }
  return payload;
}

async function listOrders(req, settings) {
  const body = {...(req.query || {}), ...requestBody(req)};
  const start = parseDate(body.startDateTime || body.StartDateTime);
  const end = parseDate(body.endDateTime || body.EndDateTime, true);
  const status = statusById(body.orderStatusId || body.OrderStatusId || "");
  let query = db().collection("orders").orderBy("createdAt", "desc").limit(200);
  if (status?.key) {
    query = db().collection("orders")
        .where("status", "==", status.key)
        .orderBy("createdAt", "desc")
        .limit(200);
  }
  const snap = await query.get();
  const userCache = new Map();
    const productCache = new Map();
    const orders = [];
    const pendingWrites = [];
    for (const doc of snap.docs) {
      const data = doc.data() || {};
      if (data.status === "cancelled" && status?.key !== "cancelled") continue;
      const created = data.createdAt;
      const createdDate = created && typeof created.toDate === "function"
        ? created.toDate()
        : null;
      if (start && createdDate && createdDate < start) continue;
      if (end && createdDate && createdDate > end) continue;
      const uid = String(data.userId || "");
      let user = {};
      if (uid) {
        if (!userCache.has(uid)) {
          const userSnap = await db().collection("users").doc(uid).get();
          userCache.set(uid, userSnap.data() || {});
        }
        user = userCache.get(uid) || {};
      }
      const orderCode = displayOrderCode(doc.id, data);
      const numericId = compactOrderId(orderCode);
      if (data.orderNo !== orderCode || Number(data.birfaturaOrderId) !== numericId) {
        pendingWrites.push(doc.ref.set({
          orderNo: orderCode,
          birfaturaOrderId: numericId,
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true}));
      }
      const enriched = await enrichOrderItems(
          data,
          productCache,
          settings.vatRate || VAT_RATE,
      );
      orders.push(toOrderPayload(
          doc.id,
          numericId,
          enriched,
          user,
          settings.vatRate || VAT_RATE,
      ));
    }
  if (pendingWrites.length) {
    await Promise.all(pendingWrites);
  }
  return {Orders: orders};
}

async function findOrderDoc(orderId) {
  const raw = String(orderId ?? "").trim();
  if (!raw) return null;
  const col = db().collection("orders");
  const direct = await col.doc(raw).get();
  if (direct.exists) return direct;
  const code = raw.replace(/^#/, "").toUpperCase();
  if (code) {
    const byNo = await col.where("orderNo", "==", code).limit(1).get();
    if (!byNo.empty) return byNo.docs[0];
  }
  if (/^\d+$/.test(raw)) {
    const byNum = await col
        .where("birfaturaOrderId", "==", Number(raw))
        .limit(1)
        .get();
    if (!byNum.empty) return byNum.docs[0];
  }
  return null;
}

function success(message) {
  return {Success: true, Message: message};
}

async function updateInvoice(req) {
  const body = requestBody(req);
  const orderId = body.orderId ?? body.OrderId ?? body.Id;
  const doc = await findOrderDoc(orderId);
  if (!doc) {
    const err = new Error("missing-order");
    err.status = 400;
    throw err;
  }
  await doc.ref.set({
    invoiceLink: String(
        body.faturaUrl || body.InvoiceLink || body.invoiceLink || "",
    ).trim(),
    invoiceNumber: String(
        body.faturaNo || body.InvoiceNumber || body.invoiceNumber || "",
    ).trim(),
    invoiceDate: String(
        body.faturaTarihi || body.InvoiceDate || body.invoiceDate || "",
    ).trim(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return success("Fatura bağlantısı güncellendi.");
}

async function updateCargo(req) {
  const body = requestBody(req);
  const orderId = body.orderId ?? body.OrderId ?? body.Id;
  const doc = await findOrderDoc(orderId);
  if (!doc) {
    const err = new Error("missing-order");
    err.status = 400;
    throw err;
  }
  const patch = {
    cargoCompany: String(body.cargoCompany || body.CargoCompany || "").trim(),
    cargoTrackingCode: String(
        body.cargoTrackingCode || body.CargoTrackingCode || "",
    ).trim(),
    cargoTrackingUrl: String(
        body.cargoTrackingCodeUrl ||
        body.CargoTrackingUrl ||
        body.cargoTrackingUrl ||
        "",
    ).trim(),
    updatedAt: FieldValue.serverTimestamp(),
  };
  const next = statusById(body.orderStatusId || body.OrderStatusId || "");
  if (next?.key) {
    const current = String(doc.data()?.status || "");
    if (current !== next.key && current !== "cancelled") {
      patch.status = next.key;
      patch.statusMessage = statusMessage(next.key);
    }
  }
  await doc.ref.set(patch, {merge: true});
  return success("Kargo bilgisi güncellendi.");
}

async function handleBirfaturaRequest(req, res) {
  res.set("Content-Type", "application/json; charset=utf-8");
  try {
    const settings = await assertToken(req);
    const name = endpointName(req);
    if (name === "orderStatus") {
      res.status(200).json({
        OrderStatus: STATUSES.map(({Id, Value}) => ({Id, Value})),
      });
      return;
    }
    if (name === "paymentMethods") {
      res.status(200).json({PaymentMethods: PAYMENTS});
      return;
    }
    if (name === "invoiceLinkUpdate") {
      res.status(200).json(await updateInvoice(req));
      return;
    }
    if (name === "orderCargoUpdate") {
      res.status(200).json(await updateCargo(req));
      return;
    }
    if (name === "orders" || name === "api" || name === "birfaturaApi") {
      res.status(200).json(await listOrders(req, settings));
      return;
    }
    res.status(404).json({error: "not-found", endpoint: name});
  } catch (error) {
    const status = error.status || 500;
    if (status >= 500) {
      logger.error("BirFatura API failed", {error: String(error)});
    }
    res.status(status).json({error: error.message || "failed"});
  }
}

module.exports = {
  handleBirfaturaRequest,
  ensureBirfaturaSettings,
};
