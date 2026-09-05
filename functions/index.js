const crypto = require("crypto");
const nodemailer = require("nodemailer");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue, Timestamp, FieldPath} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {defineSecret} = require("firebase-functions/params");
const {onDocumentCreated, onDocumentUpdated, onDocumentDeleted} =
  require("firebase-functions/v2/firestore");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {setGlobalOptions} = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");

const {handleBirfaturaRequest, ensureBirfaturaSettings} = require("./birfatura");

initializeApp();
setGlobalOptions({region: "europe-west1"});

const netgsmUser = defineSecret("NETGSM_USERCODE");
const netgsmPass = defineSecret("NETGSM_PASSWORD");
const netgsmHeader = defineSecret("NETGSM_MSGHEADER");
const smtpPassword = defineSecret("SMTP_PASSWORD");

const MAIL_HOST = "mail.geliyor.com.tr";
const MAIL_USER = "fatih@geliyor.com.tr";
const MAIL_FROM_NOREPLY = '"geliyor.tr" <noreply@geliyor.com.tr>';
const MAIL_FROM_ACTIVE = '"geliyor.tr" <fatih@geliyor.com.tr>';

const DEFAULT_TEMPLATES = {
  welcome:
    "Sn. {{name}}, geliyor.tr uyeliginiz olusturulmustur. " +
    "Alisverise hemen baslayabilirsiniz.",
  orderCreated:
    "Sn. {{name}}, siparisiniz alinmistir. Siparis no: {{orderNo}}. " +
    "Toplam: {{total}} TL. geliyor.tr",
  orderShipping:
    "Sn. {{name}}, {{orderNo}} nolu siparisiniz kuryeye verilmistir. geliyor.tr",
  orderCancelled:
    "Sn. {{name}}, {{orderNo}} nolu siparisiniz iptal edilmistir. geliyor.tr",
  orderDelivered:
    "Sn. {{name}}, {{orderNo}} nolu siparisiniz teslim edilmistir. " +
    "Bizi tercih ettiginiz icin tesekkurler. geliyor.tr",
  otp: "geliyor.tr dogrulama kodunuz: {{code}}",
  emailOtp: "geliyor.tr e-posta dogrulama kodunuz: {{code}}",
};

function db() {
  return getFirestore();
}

function triggerOpts(document) {
  return {
    document,
    region: "europe-west1",
    secrets: [netgsmUser, netgsmPass, netgsmHeader, smtpPassword],
  };
}

function normalizePhone(raw) {
  let digits = String(raw || "").replace(/\D/g, "");
  if (digits.startsWith("00")) digits = digits.slice(2);
  if (digits.startsWith("90") && digits.length >= 12) digits = digits.slice(2);
  if (digits.startsWith("0") && digits.length === 11) digits = digits.slice(1);
  if (digits.length === 10 && digits.startsWith("5")) return digits;
  return "";
}

function shortOrderNo(orderId) {
  const id = String(orderId || "").trim();
  if (!id) return "";
  return (id.length <= 6 ? id : id.slice(-6)).toUpperCase();
}

function formatTotal(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return "0";
  return String(Math.round(n));
}

function fillTemplate(template, vars) {
  return String(template || "").replace(/\{\{(\w+)\}\}/g, (_, key) => {
    return vars[key] != null ? String(vars[key]) : "";
  });
}

async function loadTemplates() {
  try {
    const snap = await db().doc("settings/sms").get();
    if (!snap.exists) return DEFAULT_TEMPLATES;
    const data = snap.data() || {};
    return {
      welcome: data.welcome || DEFAULT_TEMPLATES.welcome,
      orderCreated: data.orderCreated || DEFAULT_TEMPLATES.orderCreated,
      orderShipping: data.orderShipping || DEFAULT_TEMPLATES.orderShipping,
      orderCancelled: data.orderCancelled || DEFAULT_TEMPLATES.orderCancelled,
      orderDelivered: data.orderDelivered || DEFAULT_TEMPLATES.orderDelivered,
      otp: data.otp || DEFAULT_TEMPLATES.otp,
      emailOtp: data.emailOtp || DEFAULT_TEMPLATES.emailOtp,
    };
  } catch (error) {
    logger.warn("SMS templates could not be loaded", error);
    return DEFAULT_TEMPLATES;
  }
}

function isSuccessCode(code) {
  const value = String(code ?? "").trim();
  return value === "00" || value === "0" || value === "01" || value === "02";
}

async function sendNetgsmSms({phone, message, kind, docPath}) {
  const gsmno = normalizePhone(phone);
  if (!gsmno) {
    logger.warn("SMS skipped: invalid phone", {kind, docPath, phone});
    return {ok: false, error: "invalid-phone"};
  }

  let usercode = "";
  let password = "";
  let msgheader = "";
  try {
    usercode = String(netgsmUser.value() || "").trim();
    password = String(netgsmPass.value() || "").trim();
    msgheader = String(netgsmHeader.value() || "").trim();
  } catch (error) {
    logger.error("SMS skipped: NetGSM secret unavailable", {
      kind,
      error: String(error),
    });
    return {ok: false, error: "missing-credentials"};
  }
  if (!usercode || !password || !msgheader) {
    logger.error("SMS skipped: NetGSM secrets missing", {kind});
    return {ok: false, error: "missing-credentials"};
  }

  const payload = JSON.stringify({
    msgheader,
    encoding: "TR",
    iysfilter: "0",
    appname: "geliyor.tr",
    messages: [{msg: message, no: gsmno}],
  });
  const headers = {
    "Content-Type": "application/json",
    Authorization:
      "Basic " + Buffer.from(`${usercode}:${password}`).toString("base64"),
  };

  let response;
  let raw;
  try {
    response = await fetch("https://api.netgsm.com.tr/sms/rest/v2/send", {
      method: "POST",
      headers,
      body: payload,
      signal: AbortSignal.timeout(15000),
    });
    raw = await response.text();
  } catch (error) {
    logger.error("NetGSM fetch failed", {kind, docPath, gsmno, error: String(error)});
    try {
      response = await fetch("https://api.netgsm.com.tr/sms/rest/v2/send", {
        method: "POST",
        headers,
        body: payload,
        signal: AbortSignal.timeout(15000),
      });
      raw = await response.text();
    } catch (retryError) {
      logger.error("NetGSM fetch retry failed", {
        kind,
        docPath,
        gsmno,
        error: String(retryError),
      });
      return {ok: false, error: "netgsm-unreachable"};
    }
  }
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (_) {
    parsed = {code: String(response.status), description: raw};
  }

  const code = parsed.code ?? parsed.status ?? "";
  if (!response.ok || !isSuccessCode(code)) {
    logger.error("NetGSM send failed", {
      kind,
      docPath,
      gsmno,
      code,
      description: parsed.description,
      raw,
    });
    return {
      ok: false,
      error: String(parsed.description || code || "send-failed"),
      code: String(code),
    };
  }

  logger.info("NetGSM SMS sent", {
    kind,
    docPath,
    gsmno,
    jobid: parsed.jobid,
  });
  return {ok: true, jobid: parsed.jobid || "", code: String(code)};
}

async function markSms(docRef, fields) {
  await docRef.set(
      {
        ...fields,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
  );
}

async function resolveOrderPhone(data) {
  const fromOrder = String(data?.phone || "").trim();
  if (normalizePhone(fromOrder)) return fromOrder;
  const uid = String(data?.userId || "").trim();
  if (!uid) return "";
  try {
    const snap = await db().collection("users").doc(uid).get();
    const user = snap.data() || {};
    return String(user.phone_number || user.phone || "").trim();
  } catch (error) {
    logger.warn("Order phone lookup failed", {uid, error: String(error)});
    return "";
  }
}

async function sendOrderStatusSms(ref, data, {
  orderId,
  kind,
  templateKey,
  stampField,
  jobField,
  force = false,
}) {
  if (!force && data[stampField]) return {ok: true, skipped: true};
  const templates = await loadTemplates();
  const vars = {
    name: String(data.customerName || "Uye").trim() || "Uye",
    orderNo: shortOrderNo(orderId),
    total: formatTotal(data.total),
  };
  const phone = await resolveOrderPhone(data);
  const result = await sendNetgsmSms({
    phone,
    message: fillTemplate(templates[templateKey], vars),
    kind,
    docPath: ref.path,
  });
  const patch = result.ok
    ? {
      [stampField]: FieldValue.serverTimestamp(),
      [jobField]: result.jobid || "",
      smsLastError: FieldValue.delete(),
    }
    : {smsLastError: result.error || `${kind}-failed`};
  if (result.ok && !normalizePhone(data.phone) && normalizePhone(phone)) {
    patch.phone = phone;
  }
  await markSms(ref, patch);
  return result;
}

const STATUS_NOTICES = {
  shipping: {
    title: "Siparişiniz yola çıktı",
    body: (orderNo) => `${orderNo} numaralı siparişiniz kuryeye verildi.`,
    type: "order_shipping",
    noticeField: "noticeShippingAt",
    kind: "order_shipping",
    templateKey: "orderShipping",
    stampField: "smsShippingAt",
    jobField: "smsShippingJobId",
  },
  cancelled: {
    title: "Siparişiniz iptal edildi",
    body: (orderNo) => `${orderNo} numaralı siparişiniz iptal edildi.`,
    type: "order_cancelled",
    noticeField: "noticeCancelledAt",
    kind: "order_cancelled",
    templateKey: "orderCancelled",
    stampField: "smsCancelledAt",
    jobField: "smsCancelledJobId",
  },
  delivered: {
    title: "Siparişiniz teslim edildi",
    body: (orderNo) => `${orderNo} numaralı siparişiniz teslim edildi.`,
    type: "order_delivered",
    noticeField: "noticeDeliveredAt",
    kind: "order_delivered",
    templateKey: "orderDelivered",
    stampField: "smsDeliveredAt",
    jobField: "smsDeliveredJobId",
  },
};

async function dispatchOrderStatusNotice(orderRef, {force = false} = {}) {
  const snap = await orderRef.get();
  if (!snap.exists) return {ok: false, error: "missing-order"};
  const data = snap.data() || {};
  const status = String(data.status || "");
  const cfg = STATUS_NOTICES[status];
  if (!cfg) return {ok: true, skipped: true, reason: "no-template", status};

  const orderId = orderRef.id;
  const orderNo = shortOrderNo(orderId);

  let claimed = force;
  if (!force) {
    claimed = await db().runTransaction(async (tx) => {
      const fresh = await tx.get(orderRef);
      const current = fresh.data() || {};
      if (current[cfg.noticeField]) return false;
      tx.set(orderRef, {
        [cfg.noticeField]: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      return true;
    });
  } else {
    await orderRef.set({
      [cfg.noticeField]: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }

  if (claimed) {
    await notifyUser(data.userId, {
      title: cfg.title,
      body: cfg.body(orderNo),
      category: "order",
      data: {type: cfg.type, orderId},
      includeSms: false,
    });
  }

  const sms = await sendOrderStatusSms(orderRef, data, {
    orderId,
    kind: cfg.kind,
    templateKey: cfg.templateKey,
    stampField: cfg.stampField,
    jobField: cfg.jobField,
    force,
  });

  logger.info("Order status notice dispatched", {
    orderId,
    status,
    notified: claimed,
    smsOk: sms.ok === true,
    smsSkipped: sms.skipped === true,
    smsError: sms.error || "",
  });
  return {
    ok: true,
    status,
    notified: claimed,
    smsOk: sms.ok === true,
    smsError: sms.error || "",
  };
}

function prefKeyForCategory(category) {
  switch (String(category || "")) {
    case "order":
      return "orders";
    case "reminder":
      return "reminders";
    case "campaign":
      return "campaigns";
    default:
      return "";
  }
}

function readNotifyPrefs(userData) {
  const settings = userData?.notification_settings || {};
  const channels = settings.channels || {};
  return {
    allEnabled: settings.allEnabled !== false,
    preferences: settings.preferences || {},
    inApp: channels.inApp !== false,
    email: channels.email !== false,
    sms: channels.sms !== false,
  };
}

async function notifyUser(
    uid,
    {title, body, category, data, skipPrefs = false, includeSms = true},
) {
  const userId = String(uid || "").trim();
  if (!userId || !title || !body) return false;
  const payloadData = {};
  const extra = data && typeof data === "object" ? data : {};
  for (const [key, value] of Object.entries(extra)) {
    if (value == null) continue;
    payloadData[String(key)] = String(value);
  }
  payloadData.category = String(category || "system");

  let userData = {};
  try {
    const userSnap = await db().collection("users").doc(userId).get();
    userData = userSnap.data() || {};
  } catch (error) {
    logger.warn("notifyUser user lookup failed", {userId, error: String(error)});
  }
  const prefs = readNotifyPrefs(userData);
  if (!skipPrefs) {
    if (!prefs.allEnabled) return false;
    const prefKey = prefKeyForCategory(category);
    if (prefKey && prefs.preferences[prefKey] === false) return false;
  }

  const sendInApp = skipPrefs || prefs.inApp;
  const sendEmail = skipPrefs || prefs.email;
  const sendSms = includeSms && (skipPrefs || prefs.sms);

  if (sendInApp) {
    try {
      await db().collection("users").doc(userId).collection("notifications").add({
        title,
        body,
        category: category || "system",
        unread: true,
        createdAt: FieldValue.serverTimestamp(),
        data: extra,
      });
      logger.info("in-app notification written", {userId, title});
    } catch (error) {
      logger.error("in-app notification write failed", {userId, error});
    }

    try {
      const snap = await db()
          .collection("users")
          .doc(userId)
          .collection("fcm_tokens")
          .get();
      const entries = snap.docs
          .map((doc) => ({id: doc.id, token: doc.data()?.token}))
          .filter((item) => item.token);
      if (entries.length) {
        const response = await getMessaging().sendEachForMulticast({
          tokens: entries.map((item) => item.token),
          notification: {title, body},
          data: payloadData,
          android: {
            priority: "high",
            notification: {channelId: "geliyor_default"},
          },
          apns: {
            headers: {
              "apns-priority": "10",
              "apns-push-type": "alert",
            },
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        });
        await Promise.all(response.responses.map((item, index) => {
          if (item.success) return null;
          const code = item.error?.code || "";
          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token"
          ) {
            return snap.docs[index].ref.delete().catch(() => null);
          }
          logger.warn("FCM send failed", {code, userId});
          return null;
        }));
      }
    } catch (error) {
      logger.error("FCM send failed", {userId, error});
    }
  }

  if (sendEmail) {
    const email = normalizeEmail(userData.email);
    if (email) {
      try {
        await sendMail({
          to: email,
          kind: "notify",
          subject: String(title),
          text: String(body),
          html: `<p>${escapeHtml(body)}</p>`,
        });
      } catch (error) {
        logger.warn("Notify email skipped", {userId, error: String(error)});
      }
    }
  }

  if (sendSms) {
    const smsBody = `${title}: ${body}`.replace(/\s+/g, " ").trim().slice(0, 300);
    try {
      await sendNetgsmSms({
        phone: userData.phone_number || userData.phone || "",
        message: smsBody,
        kind: "notify",
        docPath: `users/${userId}`,
      });
    } catch (error) {
      logger.warn("Notify SMS skipped", {userId, error: String(error)});
    }
  }
  return true;
}

exports.onUserCreated = onDocumentCreated(
    triggerOpts("users/{userId}"),
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data() || {};
      if (data.is_guest === true) return;
      if (data.user_role === "admin" || data.role === "admin") return;
      if (data.smsWelcomeAt) return;

      const templates = await loadTemplates();
      const name = String(data.display_name || data.fullName || "Uye").trim();
      const message = fillTemplate(templates.welcome, {name});
      const result = await sendNetgsmSms({
        phone: data.phone_number || data.phone || "",
        message,
        kind: "welcome",
        docPath: snap.ref.path,
      });

      await markSms(snap.ref, result.ok
        ? {
          smsWelcomeAt: FieldValue.serverTimestamp(),
          smsWelcomeJobId: result.jobid || "",
          smsLastError: FieldValue.delete(),
        }
        : {smsLastError: result.error || "welcome-failed"});

      await notifyUser(event.params.userId, {
        title: "Hoş geldiniz",
        body: "geliyor.tr ailesine katıldığınız için teşekkürler.",
        category: "system",
        data: {type: "welcome"},
        includeSms: false,
      });
    },
);

function resolveCatalogProductId(item) {
  const catalog = String(item?.catalogProductId || "").trim();
  if (catalog) return catalog;
  const raw = String(item?.productId || item?.id || "").trim();
  if (!raw) return "";
  const weight = String(item?.weight || "").trim();
  if (weight && raw.endsWith(`-${weight}`)) {
    return raw.slice(0, -(weight.length + 1));
  }
  return raw;
}

function itemQuantitiesByProduct(items) {
  const qtyByProduct = new Map();
  for (const item of Array.isArray(items) ? items : []) {
    const productId = resolveCatalogProductId(item);
    const qty = Math.max(0, Math.floor(Number(item?.quantity) || 0));
    if (!productId || qty <= 0) continue;
    qtyByProduct.set(productId, (qtyByProduct.get(productId) || 0) + qty);
  }
  return qtyByProduct;
}

function qtyMapFromOrderData(data) {
  if (data?.stockDeltas && typeof data.stockDeltas === "object") {
    return new Map(Object.entries(data.stockDeltas).map(([id, qty]) => [
      id,
      Math.max(0, Math.floor(Number(qty) || 0)),
    ]));
  }
  return itemQuantitiesByProduct(data?.items);
}

async function incrementProductStocks(qtyByProduct, {orderId = ""} = {}) {
  const firestore = db();
  await firestore.runTransaction(async (tx) => {
    const productReads = [];
    for (const [productId, qty] of qtyByProduct.entries()) {
      if (!productId || qty <= 0) continue;
      const ref = firestore.collection("products").doc(productId);
      productReads.push({id: productId, qty, ref, snap: await tx.get(ref)});
    }
    for (const row of productReads) {
      if (!row.snap.exists) {
        logger.warn("Stock skipped, product missing", {
          orderId,
          productId: row.id,
        });
        continue;
      }
      const current = Math.floor(Number(row.snap.get("stock")) || 0);
      tx.update(row.ref, {
        stock: current + row.qty,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });
}

async function restoreOrderCoupon(data) {
  const userId = String(data?.userId || "").trim();
  const couponId = String(data?.couponId || "").trim();
  if (!userId || !couponId) return;
  const snap = await db().collection("coupons").doc(couponId).get();
  if (snap.exists && snap.get("publicCoupon") !== false) return;
  await db().collection("users").doc(userId).set({
    earned_coupon_ids: FieldValue.arrayUnion([couponId]),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}

async function applyOrderStock(orderRef, {restore = false, force = false} = {}) {
  const firestore = db();
  await firestore.runTransaction(async (tx) => {
    const orderSnap = await tx.get(orderRef);
    if (!orderSnap.exists) return;
    const data = orderSnap.data() || {};
    const cancelled = String(data.status || "") === "cancelled";

    if (restore) {
      if (!data.stockAppliedAt || data.stockRestoredAt) return;
      if (!force && !cancelled) return;
    } else if (data.stockAppliedAt || cancelled) {
      return;
    }

    const qtyByProduct = restore
      ? qtyMapFromOrderData(data)
      : itemQuantitiesByProduct(data.items);

    const productReads = [];
    for (const [productId, qty] of qtyByProduct.entries()) {
      if (!productId || qty <= 0) continue;
      const ref = firestore.collection("products").doc(productId);
      productReads.push({id: productId, qty, ref, snap: await tx.get(ref)});
    }

    const deltas = {};
    for (const row of productReads) {
      if (!row.snap.exists) {
        logger.warn("Stock skipped, product missing", {
          orderId: orderRef.id,
          productId: row.id,
        });
        continue;
      }
      const current = Math.floor(Number(row.snap.get("stock")) || 0);
      if (restore) {
        tx.update(row.ref, {
          stock: current + row.qty,
          updatedAt: FieldValue.serverTimestamp(),
        });
        continue;
      }
      const next = Math.max(0, current - row.qty);
      deltas[row.id] = current - next;
      tx.update(row.ref, {
        stock: next,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    if (restore) {
      tx.update(orderRef, {stockRestoredAt: FieldValue.serverTimestamp()});
      return;
    }
    tx.update(orderRef, {
      stockAppliedAt: FieldValue.serverTimestamp(),
      stockDeltas: deltas,
    });
  });
}

async function reconcilePendingOrderStock() {
  let applied = 0;
  let restored = 0;
  let skipped = 0;
  let failed = 0;
  let last = null;
  while (true) {
    let query = db().collection("orders").orderBy(FieldPath.documentId()).limit(50);
    if (last) query = query.startAfter(last);
    const page = await query.get();
    if (page.empty) break;
    for (const doc of page.docs) {
      const data = doc.data() || {};
      const cancelled = data.status === "cancelled";
      try {
        if (cancelled) {
          if (data.stockAppliedAt && !data.stockRestoredAt) {
            await applyOrderStock(doc.ref, {restore: true});
            restored += 1;
          } else {
            skipped += 1;
          }
        } else if (!data.stockAppliedAt) {
          await applyOrderStock(doc.ref);
          applied += 1;
        } else {
          skipped += 1;
        }
      } catch (error) {
        failed += 1;
        logger.error("Order stock sync failed", {
          orderId: doc.id,
          error: String(error),
        });
      }
    }
    last = page.docs[page.docs.length - 1];
    if (page.size < 50) break;
  }
  logger.info("Order stock reconcile finished", {applied, restored, skipped, failed});
  return {applied, restored, skipped, failed};
}

exports.onOrderCreated = onDocumentCreated(
    triggerOpts("orders/{orderId}"),
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data() || {};
      try {
        await applyOrderStock(snap.ref);
      } catch (error) {
        logger.error("Order stock apply failed", {
          orderId: event.params.orderId,
          error: String(error),
        });
      }
      if (data.smsCreatedAt) return;
      const orderId = event.params.orderId;
      const orderNo = shortOrderNo(orderId);
      const total = formatTotal(data.total);
      await sendOrderStatusSms(snap.ref, data, {
        orderId,
        kind: "order_created",
        templateKey: "orderCreated",
        stampField: "smsCreatedAt",
        jobField: "smsCreatedJobId",
      });

      await notifyUser(data.userId, {
        title: "Siparişiniz alındı",
        body: `${orderNo} numaralı siparişiniz alındı. Toplam: ${total} TL.`,
        category: "order",
        data: {type: "order_created", orderId},
        includeSms: false,
      });
    },
);

exports.onOrderUpdated = onDocumentUpdated(
    triggerOpts("orders/{orderId}"),
    async (event) => {
      const change = event.data;
      if (!change) return;
      const before = change.before.data() || {};
      const after = change.after.data() || {};
      const orderId = event.params.orderId;

      if (before.status !== after.status) {
        try {
          await dispatchOrderStatusNotice(change.after.ref);
        } catch (error) {
          logger.error("Order notice failed", {orderId, error: String(error)});
        }
      }

      try {
        if (after.status === "cancelled" && before.status !== "cancelled") {
          await applyOrderStock(change.after.ref, {restore: true});
        } else if (after.status !== "cancelled" && !after.stockAppliedAt) {
          await applyOrderStock(change.after.ref);
        }
      } catch (error) {
        logger.error("Order stock update sync failed", {orderId, error: String(error)});
      }
    },
);

exports.onOrderDeleted = onDocumentDeleted(
    {
      document: "orders/{orderId}",
      region: "europe-west1",
    },
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data() || {};
      const orderId = event.params.orderId;
      try {
        if (data.stockAppliedAt && !data.stockRestoredAt) {
          await incrementProductStocks(qtyMapFromOrderData(data), {orderId});
        }
      } catch (error) {
        logger.error("Order delete stock restore failed", {
          orderId,
          error: String(error),
        });
      }
      try {
        await restoreOrderCoupon(data);
      } catch (error) {
        logger.error("Order delete coupon restore failed", {
          orderId,
          error: String(error),
        });
      }
    },
);

exports.backfillOrderStock = onSchedule(
    {
      schedule: "every 1 minutes",
      region: "europe-west1",
      timeZone: "Europe/Istanbul",
      timeoutSeconds: 540,
    },
    async () => {
      const flagRef = db().doc("settings/stock_reconcile");
      const flagSnap = await flagRef.get();
      if (flagSnap.get("legacyApplied") === true) return;
      const result = await reconcilePendingOrderStock();
      if (result.failed > 0) {
        logger.warn("Stock backfill incomplete, will retry", result);
        return;
      }
      await flagRef.set({
        legacyApplied: true,
        applied: result.applied,
        restored: result.restored,
        skipped: result.skipped,
        at: FieldValue.serverTimestamp(),
      }, {merge: true});
    },
);

function callOpts() {
  return {
    region: "europe-west1",
    secrets: [netgsmUser, netgsmPass, netgsmHeader, smtpPassword],
    cors: true,
    invoker: "public",
  };
}

function emailCallOpts() {
  return {
    region: "europe-west1",
    secrets: [smtpPassword],
    cors: true,
    invoker: "public",
  };
}

function inviteCallOpts() {
  return {
    region: "europe-west1",
    secrets: [netgsmUser, netgsmPass, netgsmHeader, smtpPassword],
    cors: true,
    invoker: "public",
  };
}

function e164FromGsm(gsmno) {
  return `+90${gsmno}`;
}

function hashOtp(phone, code) {
  return crypto.createHash("sha256").update(`${phone}:${code}`).digest("hex");
}

function otpRef(gsmno) {
  return db().collection("otp_codes").doc(gsmno);
}

/** App Store Review: SMS almayan inceleme hesabı (telefon + kod). */
const APP_REVIEW_PHONE = "5555550000";
const APP_REVIEW_CODE = "246810";

function isAppReviewPhone(gsmno) {
  return gsmno === APP_REVIEW_PHONE;
}

function ymdPlusDays(days) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + days);
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

async function ensureAppReviewAccount(auth) {
  const phoneE164 = e164FromGsm(APP_REVIEW_PHONE);
  let user;
  try {
    user = await auth.getUserByPhoneNumber(phoneE164);
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
    user = await auth.createUser({
      phoneNumber: phoneE164,
      displayName: "Apple Reviewer",
    });
  }

  const ref = db().collection("users").doc(user.uid);
  const snap = await ref.get();
  const data = snap.data() || {};
  const pets = Array.isArray(data.pets) ? data.pets : [];
  if (pets.length > 0) return user;

  await ref.set(
      {
        uid: user.uid,
        display_name: "Apple Reviewer",
        phone_number: phoneE164,
        phone: phoneE164,
        user_role: "customer",
        is_guest: false,
        active: true,
        updatedAt: FieldValue.serverTimestamp(),
        ...(snap.exists ? {} : {created_time: FieldValue.serverTimestamp()}),
        pets: [
          {
            name: "Misket",
            species: "Kedi",
            ageRange: "Genç (1-6 yaş)",
            weight: "2-3 kg",
            bodyType: "Normal",
            neutered: "Kısır",
            activityLevel: "Orta",
            extraFood: "Hayır",
            dailyFoodGrams: 45,
            allergies: [],
          },
        ],
        active_pet_index: 0,
        food_tracking: {
          active: true,
          foodName: "Pro Plan Somonlu Kısır Kedi Maması",
          bagKg: 10,
          purchaseDate: ymdPlusDays(-20),
          petName: "Misket",
          petSpecies: "Kedi",
        },
        health_calendar: {
          enabled: true,
          daysBefore: 7,
          timeHour: 9,
          items: [
            {
              title: "Karma Aşı",
              category: "vaccine",
              frequency: "Yılda bir",
              intervalMonths: 12,
              lastDoneDate: ymdPlusDays(-350),
              nextDueDate: ymdPlusDays(6),
              sentFor: "",
              reminderDate: ymdPlusDays(-1),
            },
            {
              title: "Dış Parazit",
              category: "parasite",
              frequency: "Ayda bir",
              intervalMonths: 1,
              lastDoneDate: ymdPlusDays(-20),
              nextDueDate: ymdPlusDays(16),
              sentFor: "",
              reminderDate: ymdPlusDays(9),
            },
          ],
        },
        addresses: [
          {
            id: "review-home",
            title: "Ev",
            contactName: "Apple Reviewer",
            phone: `0${APP_REVIEW_PHONE}`,
            address: "Atatürk Cad. No:12 Daire:5",
            city: "İstanbul",
            district: "Kadıköy",
            icon: "home",
            isDefault: true,
            accountType: "individual",
            nationalId: "",
            taxId: "",
            taxOffice: "",
            isDelivery: true,
            isInvoice: true,
          },
        ],
      },
      {merge: true},
  );
  return user;
}

function isPlaceholderName(value) {
  const n = String(value || "").trim().toLowerCase();
  return !n || n === "uye" || n === "üye" || n === "member";
}

function realName(...candidates) {
  for (const raw of candidates) {
    const n = String(raw || "").trim();
    if (!isPlaceholderName(n)) return n;
  }
  return "";
}

function phoneLookupValues(phoneE164, gsmno) {
  return Array.from(new Set([
    phoneE164,
    gsmno,
    `0${gsmno}`,
    `90${gsmno}`,
    `+90${gsmno}`,
  ]));
}

async function findAuthUserByPhone(auth, phoneE164, gsmno) {
  try {
    return await auth.getUserByPhoneNumber(phoneE164);
  } catch (error) {
    if (error.code !== "auth/user-not-found") {
      throw error;
    }
  }

  const values = phoneLookupValues(phoneE164, gsmno);
  for (const field of ["phone_number", "phone"]) {
    for (const value of values) {
      const snap = await db().collection("users")
          .where(field, "==", value)
          .limit(5)
          .get();
      for (const doc of snap.docs) {
        try {
          let existing = await auth.getUser(doc.id);
          if (existing.phoneNumber !== phoneE164) {
            try {
              await auth.updateUser(doc.id, {phoneNumber: phoneE164});
              existing = await auth.getUser(doc.id);
            } catch (updateErr) {
              if (updateErr.code === "auth/phone-number-already-exists") {
                return await auth.getUserByPhoneNumber(phoneE164);
              }
              logger.warn("Could not attach phone to auth user", {
                uid: doc.id,
                error: String(updateErr),
              });
            }
          }
          return existing;
        } catch (error) {
          if (error.code !== "auth/user-not-found") {
            logger.warn("Auth lookup for firestore user failed", {
              uid: doc.id,
              error: String(error),
            });
            continue;
          }
          try {
            const name = realName(doc.data()?.display_name, doc.data()?.fullName);
            return await auth.createUser({
              uid: doc.id,
              phoneNumber: phoneE164,
              displayName: name || "Uye",
            });
          } catch (createErr) {
            if (createErr.code === "auth/phone-number-already-exists") {
              return await auth.getUserByPhoneNumber(phoneE164);
            }
            if (createErr.code === "auth/uid-already-exists") {
              return await auth.getUser(doc.id);
            }
            logger.error("createUser with existing firestore uid failed", createErr);
          }
        }
      }
    }
  }
  return null;
}

async function upsertCustomerProfile(user, {phoneE164, fullName}) {
  const ref = db().collection("users").doc(user.uid);
  const snap = await ref.get();
  const existing = snap.data() || {};
  const existingRole = existing.user_role || existing.role || "";
  const keepAdmin = existingRole === "admin";
  const name = realName(
      fullName,
      existing.display_name,
      existing.fullName,
      user.displayName,
  ) || "Uye";
  await ref.set(
      {
        uid: user.uid,
        display_name: name,
        phone_number: phoneE164,
        phone: phoneE164,
        user_role: keepAdmin ? "admin" : "customer",
        is_guest: false,
        active: existing.active !== false,
        updatedAt: FieldValue.serverTimestamp(),
        ...(snap.exists ? {} : {created_time: FieldValue.serverTimestamp()}),
      },
      {merge: true},
  );
  if (!isPlaceholderName(name) && user.displayName !== name) {
    await getAuth().updateUser(user.uid, {displayName: name});
  }
  return name;
}

exports.sendLoginCode = onCall(callOpts(), async (request) => {
  const gsmno = normalizePhone(request.data?.phone);
  if (!gsmno) {
    throw new HttpsError("invalid-argument", "Gecersiz telefon numarasi.");
  }

  const ref = otpRef(gsmno);
  if (isAppReviewPhone(gsmno)) {
    await ensureAppReviewAccount(getAuth());
    await ref.set({
      hash: hashOtp(gsmno, APP_REVIEW_CODE),
      sentAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000),
      attempts: 0,
      review: true,
    });
    return {ok: true};
  }
  const existing = await ref.get();
  const prev = existing.data() || {};
  const sentAtMs = typeof prev.sentAt?.toMillis === "function"
    ? prev.sentAt.toMillis()
    : 0;
  if (sentAtMs && Date.now() - sentAtMs < 45000) {
    throw new HttpsError(
        "resource-exhausted",
        "Kodu az once gonderdik. 45 saniye sonra tekrar deneyin.",
    );
  }

  const code = String(Math.floor(100000 + Math.random() * 900000));
  const templates = await loadTemplates();
  const message = fillTemplate(templates.otp, {code});
  const result = await sendNetgsmSms({
    phone: gsmno,
    message,
    kind: "otp",
    docPath: ref.path,
  });
  if (!result.ok) {
    logger.error("OTP SMS failed", result);
    throw new HttpsError(
        "unavailable",
        "SMS gonderilemedi. Biraz sonra tekrar deneyin.",
    );
  }

  await ref.set({
    hash: hashOtp(gsmno, code),
    sentAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(Date.now() + 5 * 60 * 1000),
    attempts: 0,
    jobid: result.jobid || "",
  });
  return {ok: true};
});

exports.verifyLoginCode = onCall(callOpts(), async (request) => {
  const gsmno = normalizePhone(request.data?.phone);
  const smsCode = String(request.data?.code || "").trim();
  const fullName = String(request.data?.fullName || "").trim();
  const requireExistingUser = request.data?.requireExistingUser === true;
  if (!gsmno || !/^\d{4,8}$/.test(smsCode)) {
    throw new HttpsError("invalid-argument", "Telefon veya kod gecersiz.");
  }

  const ref = otpRef(gsmno);
  const snap = await ref.get();
  const data = snap.data();
  if (!data?.hash) {
    throw new HttpsError("failed-precondition", "Once SMS kodu gonderin.");
  }
  if (data.expiresAt && data.expiresAt.toMillis() < Date.now()) {
    await ref.delete();
    throw new HttpsError("deadline-exceeded", "Kodun suresi doldu. Tekrar gonderin.");
  }
  const attempts = Number(data.attempts || 0);
  if (attempts >= 5) {
    await ref.delete();
    throw new HttpsError("resource-exhausted", "Cok fazla hatali deneme. Kodu tekrar gonderin.");
  }
  if (data.hash !== hashOtp(gsmno, smsCode)) {
    await ref.update({attempts: attempts + 1});
    throw new HttpsError("permission-denied", "SMS kodu hatali.");
  }

  const phoneE164 = e164FromGsm(gsmno);
  const auth = getAuth();
  let user;
  try {
    user = await findAuthUserByPhone(auth, phoneE164, gsmno);
  } catch (error) {
    logger.error("findAuthUserByPhone failed", error);
    throw new HttpsError("internal", "Giris dogrulanamadi. Daha sonra tekrar deneyin.");
  }

  if (!user && requireExistingUser) {
    throw new HttpsError(
        "not-found",
        "Bu telefon numarasi sistemde kayitli degil. Once kayit olun.",
    );
  }

  try {
    if (!user) {
      user = await auth.createUser({
        phoneNumber: phoneE164,
        displayName: realName(fullName) || "Uye",
      });
    } else {
      const nextName = realName(fullName);
      if (nextName && user.displayName !== nextName) {
        await auth.updateUser(user.uid, {displayName: nextName});
        user = await auth.getUser(user.uid);
      }
    }
  } catch (error) {
    if (error.code === "auth/phone-number-already-exists") {
      user = await auth.getUserByPhoneNumber(phoneE164);
    } else {
      logger.error("create/update auth user failed", error);
      throw new HttpsError("internal", "Hesap olusturulamadi. Daha sonra tekrar deneyin.");
    }
  }

  let token;
  try {
    token = await auth.createCustomToken(user.uid, {phone: phoneE164});
  } catch (error) {
    logger.error("createCustomToken failed", error);
    throw new HttpsError(
        "internal",
        "Giris tamamlanamadi. Lutfen tekrar deneyin.",
    );
  }

  user = await auth.getUser(user.uid);
  let savedName = "Uye";
  try {
    savedName = await upsertCustomerProfile(user, {phoneE164, fullName});
  } catch (error) {
    logger.error("upsertCustomerProfile failed", error);
    throw new HttpsError("internal", "Hesap kaydedilemedi. Tekrar deneyin.");
  }
  await ref.delete();
  return {token, uid: user.uid, phone: phoneE164, displayName: savedName};
});

function istanbulYmd(date = new Date()) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Istanbul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

function istanbulHour(date = new Date()) {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Europe/Istanbul",
    hour: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  return Number(parts.find((part) => part.type === "hour")?.value || "0");
}

function daysUntil(fromYmd, toYmd) {
  const from = new Date(`${fromYmd}T00:00:00+03:00`);
  const to = new Date(`${toYmd}T00:00:00+03:00`);
  return Math.round((to.getTime() - from.getTime()) / 86400000);
}

function couponDiscountLabel(coupon) {
  const value = Number(coupon?.value || 0);
  if (String(coupon?.type || "") === "percent") return `%${Math.round(value)}`;
  return `${Math.round(value)} TL`;
}

async function grantCouponToUser(uid, couponId) {
  const id = String(couponId || "").trim();
  const userId = String(uid || "").trim();
  if (!id || !userId) return null;
  const snap = await db().collection("coupons").doc(id).get();
  if (!snap.exists) return null;
  const coupon = snap.data() || {};
  if (coupon.active === false) return null;
  await db().collection("users").doc(userId).set({
    earned_coupon_ids: FieldValue.arrayUnion([id]),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {
    id,
    code: String(coupon.code || "").toUpperCase(),
    title: String(coupon.title || "Kupon"),
    label: couponDiscountLabel(coupon),
  };
}

async function enqueueFoodCouponJob({
  uid, customerName, phone, petName, foodTitle, remainingDays, reminderDate,
}) {
  const jobId = `${uid}_${reminderDate}`;
  const ref = db().collection("food_coupon_queue").doc(jobId);
  const existing = await ref.get();
  if (existing.exists) return;
  await ref.set({
    userId: uid,
    customerName: customerName || "",
    phone: phone || "",
    petName: petName || "",
    foodTitle: foodTitle || "",
    remainingDays: remainingDays || 0,
    reminderDate,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

exports.checkFoodReminders = onSchedule(
    {
      region: "europe-west1",
      schedule: "0 * * * *",
      timeZone: "Europe/Istanbul",
      secrets: [netgsmUser, netgsmPass, netgsmHeader, smtpPassword],
    },
    async () => {
      const today = istanbulYmd();
      const hour = istanbulHour();
      const settingsSnap = await db().doc("settings/food_coupon").get();
      const foodCoupon = settingsSnap.data() || {};
      const mode = String(foodCoupon.mode || "manual");
      const couponId = String(foodCoupon.couponId || "mama-25");

      const [foodSnap, autoSnap, healthSnap] = await Promise.all([
        db().collection("users").where("food_reminder.enabled", "==", true).get(),
        db().collection("users")
            .where("food_reminder.autoOrderEnabled", "==", true)
            .get(),
        db().collection("users").where("health_calendar.enabled", "==", true).get(),
      ]);
      const byId = new Map();
      for (const doc of foodSnap.docs) byId.set(doc.id, doc);
      for (const doc of autoSnap.docs) byId.set(doc.id, doc);
      for (const doc of healthSnap.docs) byId.set(doc.id, doc);

      let sent = 0;
      for (const doc of byId.values()) {
        const data = doc.data() || {};
        let food = data.food_reminder || {};
        const calendar = data.health_calendar || {};
        const ns = data.notification_settings || {};
        const prefs = readNotifyPrefs(data);
        const petName = String(
            (Array.isArray(data.pets) && data.pets[0]?.name) ||
            food.petName ||
            "Dostunuz",
        ).trim() || "Dostunuz";

        if (hour >= 7 && food.enabled === true) {
          const foodAllowed = prefs.allEnabled && prefs.preferences.reminders !== false;
          if (
            foodAllowed &&
            String(food.reminderDate || "") <= today &&
            food.sentFor !== today
          ) {
            const endDate = String(food.estimatedEndDate || "");
            const remaining = endDate
              ? Math.max(0, daysUntil(today, endDate))
              : Number(food.remainingDays || 0);
            const foodTitle = String(food.foodTitle || "mama").trim() || "mama";
            let body = remaining <= 0
              ? `${petName} için ${foodTitle} stoğu bitmek üzere. Yeni paket için Pet Market’e göz atın.`
              : `${petName} için ${foodTitle} yaklaşık ${remaining} gün içinde bitecek.`;
            const notifyData = {
              type: "food_reminder",
              remainingDays: String(remaining),
            };
            if (mode === "automatic" && couponId) {
              const granted = await grantCouponToUser(doc.id, couponId);
              if (granted) {
                body += ` Size özel ${granted.code} kuponu tanımlandı (${granted.label}).`;
                notifyData.couponId = granted.id;
                notifyData.couponCode = granted.code;
              }
            } else if (mode === "manual") {
              await enqueueFoodCouponJob({
                uid: doc.id,
                customerName: String(data.display_name || "").trim(),
                phone: String(data.phone_number || "").trim(),
                petName,
                foodTitle,
                remainingDays: remaining,
                reminderDate: today,
              });
            }
            const ok = await notifyUser(doc.id, {
              title: "Mama hatırlatması",
              body,
              category: "reminder",
              data: notifyData,
            });
            if (ok) {
              food.sentFor = today;
              food.remainingDays = remaining;
              await doc.ref.set({
                food_reminder: food,
              }, {merge: true});
              sent += 1;
            }
          }
        }

        if (
          hour >= 7 &&
          food.autoOrderEnabled === true &&
          ns.autoOrderNotifications !== false &&
          String(food.autoOrderDate || "") <= today &&
          food.autoOrderSentFor !== today &&
          prefs.preferences.orders !== false
        ) {
          const ok = await notifyUser(doc.id, {
            title: "Sipariş zamanı",
            body:
              `${petName} için mama bitmeye yaklaşıyor. Kolay Sipariş ile paketi ` +
              `yenileyebilirsiniz.`,
            category: "order",
            data: {type: "auto_order_reminder"},
          });
          if (ok) {
            food.autoOrderSentFor = today;
            await doc.ref.set({
              food_reminder: food,
            }, {merge: true});
            sent += 1;
          }
        }

        const timeHour = Number(calendar.timeHour || 20);
        const healthAllowed =
          calendar.enabled === true &&
          ns.vaccineCalendarEnabled !== false &&
          ns.healthRemindersEnabled !== false &&
          prefs.preferences.petWorld !== false &&
          prefs.preferences.reminders !== false;
        if (healthAllowed && hour >= timeHour) {
          const items = Array.isArray(calendar.items) ? [...calendar.items] : [];
          let changed = false;
          for (let i = 0; i < items.length; i++) {
            const item = items[i] || {};
            if (String(item.reminderDate || "") > today) continue;
            if (item.sentFor === today) continue;
            const title = String(item.title || "Sağlık kaydı").trim() || "Sağlık kaydı";
            const due = String(item.nextDueDate || "");
            const daysLeft = due ? Math.max(0, daysUntil(today, due)) : 0;
            const when = daysLeft <= 0
              ? "bugün / geçti"
              : `${daysLeft} gün içinde`;
            const ok = await notifyUser(doc.id, {
              title: "Sağlık hatırlatması",
              body: `${petName} için ${title} tarihi yaklaşıyor (${when}). Aşı Takvimi’nden kontrol edin.`,
              category: "reminder",
              data: {
                type: "health_reminder",
                procedure: title,
                nextDueDate: due,
              },
            });
            if (!ok) continue;
            items[i] = {...item, sentFor: today};
            changed = true;
            sent += 1;
          }
          if (changed) {
            await doc.ref.set({
              health_calendar: {...calendar, items},
            }, {merge: true});
          }
        }
      }
      logger.info("Reminders processed", {
        today,
        hour,
        matched: byId.size,
        sent,
      });
    },
);

async function assertAdmin(uid) {
  const snap = await db().collection("users").doc(uid).get();
  const data = snap.data() || {};
  const role = String(data.user_role || data.role || "").toLowerCase();
  if (role !== "admin") {
    throw new HttpsError("permission-denied", "Bu islem icin yetkiniz yok.");
  }
}

exports.birfaturaApi = onRequest({
  region: "europe-west1",
  cors: true,
  invoker: "public",
  timeoutSeconds: 60,
}, handleBirfaturaRequest);

exports.getBirfaturaConfig = onCall({
  region: "europe-west1",
  cors: true,
  invoker: "public",
}, async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Giris yapin.");
  }
  await assertAdmin(request.auth.uid);
  return ensureBirfaturaSettings();
});

exports.assignUserCoupon = onCall(callOpts(), async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Giris yapin.");
  }
  await assertAdmin(request.auth.uid);
  const userId = String(request.data?.userId || "").trim();
  const couponId = String(request.data?.couponId || "").trim();
  const queueId = String(request.data?.queueId || "").trim();
  const notify = request.data?.notify !== false;
  if (!userId || !couponId) {
    throw new HttpsError("invalid-argument", "Musteri ve kupon gerekli.");
  }
  const granted = await grantCouponToUser(userId, couponId);
  if (!granted) {
    throw new HttpsError("not-found", "Kupon bulunamadi veya pasif.");
  }
  if (queueId) {
    await db().collection("food_coupon_queue").doc(queueId).set({
      status: "assigned",
      couponId: granted.id,
      couponCode: granted.code,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  if (notify) {
    await notifyUser(userId, {
      title: "Kuponunuz tanımlandı",
      body: `${granted.code} kuponu hesabınıza eklendi. ${granted.label} indirim için sipariş onayında kullanabilirsiniz.`,
      category: "campaign",
      data: {
        type: "coupon_assigned",
        couponId: granted.id,
        couponCode: granted.code,
      },
    });
  }
  return {ok: true, code: granted.code, label: granted.label};
});

exports.dispatchOrderNotice = onCall(callOpts(), async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Giris yapin.");
  }
  await assertAdmin(request.auth.uid);
  const orderId = String(request.data?.orderId || "").trim();
  if (!orderId) {
    throw new HttpsError("invalid-argument", "Siparis no gerekli.");
  }
  const result = await dispatchOrderStatusNotice(
      db().collection("orders").doc(orderId),
      {force: request.data?.force === true},
  );
  if (!result.ok && result.error === "missing-order") {
    throw new HttpsError("not-found", "Siparis bulunamadi.");
  }
  return result;
});

exports.deleteOrder = onCall(callOpts(), async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Giris yapin.");
  }
  await assertAdmin(request.auth.uid);
  const orderId = String(request.data?.orderId || "").trim();
  if (!orderId) {
    throw new HttpsError("invalid-argument", "Siparis no gerekli.");
  }
  const orderRef = db().collection("orders").doc(orderId);
  const snap = await orderRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Siparis bulunamadi.");
  }
  const data = snap.data() || {};
  try {
    await applyOrderStock(orderRef, {restore: true, force: true});
  } catch (error) {
    logger.error("Order delete stock restore failed", {
      orderId,
      error: String(error),
    });
    throw new HttpsError("internal", "Stok geri yuklenemedi.");
  }
  try {
    await restoreOrderCoupon(data);
  } catch (error) {
    logger.error("Order delete coupon restore failed", {
      orderId,
      error: String(error),
    });
    throw new HttpsError("internal", "Kupon geri yuklenemedi.");
  }
  await orderRef.delete();
  logger.info("Order purged", {orderId, userId: data.userId || ""});
  return {ok: true};
});

exports.saveOrderGifts = onCall(callOpts(), async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Giris yapin.");
  }
  const orderId = String(request.data?.orderId || "").trim();
  const rawGifts = request.data?.gifts;
  if (!orderId || !Array.isArray(rawGifts) || rawGifts.length === 0) {
    throw new HttpsError("invalid-argument", "Siparis ve hediye gerekli.");
  }
  const gifts = [];
  for (const item of rawGifts) {
    const title = String(item?.title || "").trim();
    if (!title) continue;
    gifts.push({
      productId: String(item?.productId || item?.id || "").trim(),
      title,
      imageUrl: String(item?.imageUrl || item?.imagePath || "").trim(),
      premium: item?.premium === true,
    });
  }
  if (gifts.length === 0) {
    throw new HttpsError("invalid-argument", "Gecerli hediye yok.");
  }
  const orderRef = db().collection("orders").doc(orderId);
  const snap = await orderRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Siparis bulunamadi.");
  }
  if (String(snap.get("userId") || "") !== request.auth.uid) {
    throw new HttpsError("permission-denied", "Bu siparis size ait degil.");
  }
  await orderRef.set({
    gifts,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  logger.info("Order gifts saved", {orderId, count: gifts.length});
  return {ok: true, count: gifts.length};
});

function emailOtpRef(uid) {
  return db().collection("email_otp").doc(uid);
}

function normalizeEmail(raw) {
  const email = String(raw || "").trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return "";
  return email;
}

async function assertEmailAvailable(email, uid) {
  try {
    const other = await getAuth().getUserByEmail(email);
    if (other.uid !== uid) {
      throw new HttpsError(
          "already-exists",
          "Bu e-posta baska bir hesapta kayitli.",
      );
    }
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    if (error.code !== "auth/user-not-found") {
      logger.warn("Email lookup failed", {email, error: String(error)});
    }
  }
}

function escapeHtml(value) {
  return String(value || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
}

async function sendMail({to, subject, text, html, kind = "email"}) {
  let pass = "";
  try {
    pass = String(smtpPassword.value() || "").trim();
  } catch (error) {
    logger.error("Email skipped: SMTP secret unavailable", {
      kind,
      error: String(error),
    });
    return {ok: false, error: "missing-smtp"};
  }
  if (!pass) {
    logger.error("Email skipped: SMTP_PASSWORD missing", {kind});
    return {ok: false, error: "missing-smtp"};
  }

  const users = [MAIL_USER, "fatih"];
  const ports = [
    {port: 587, secure: false},
    {port: 465, secure: true},
  ];
  const payload = {to, subject, text, html};

  let lastError = "smtp-failed";
  for (const authUser of users) {
    for (const {port, secure} of ports) {
      const transporter = nodemailer.createTransport({
        host: MAIL_HOST,
        port,
        secure,
        auth: {user: authUser, pass},
        tls: {rejectUnauthorized: false},
        connectionTimeout: 10000,
        greetingTimeout: 10000,
        socketTimeout: 15000,
      });
      try {
        await transporter.sendMail({...payload, from: MAIL_FROM_NOREPLY});
        return {ok: true, from: "noreply", port, authUser};
      } catch (noreplyError) {
        lastError = String(
            noreplyError && noreplyError.message
              ? noreplyError.message
              : noreplyError,
        );
        logger.warn("noreply@ send failed, retrying as fatih@", {
          error: lastError,
          port,
          authUser,
          kind,
        });
        try {
          await transporter.sendMail({...payload, from: MAIL_FROM_ACTIVE});
          return {ok: true, from: "fatih", port, authUser};
        } catch (error) {
          lastError = String(error && error.message ? error.message : error);
          logger.warn("fatih@ send failed", {error: lastError, port, authUser, kind});
        }
      }
    }
  }
  logger.error("Email send failed", {kind, error: lastError});
  return {ok: false, error: lastError};
}

async function sendOtpEmail({email, code, message}) {
  return sendMail({
    to: email,
    kind: "email-otp",
    subject: "geliyor.tr e-posta dogrulama kodu",
    text: message,
    html:
      `<p>geliyor.tr e-posta dogrulama kodunuz:</p>` +
      `<p style="font-size:28px;font-weight:700;letter-spacing:4px">${escapeHtml(code)}</p>` +
      `<p>Kod 5 dakika gecerlidir. Bu istegi siz yapmadiysaniz yok sayin.</p>`,
  });
}

exports.sendEmailCode = onCall(emailCallOpts(), async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Giris yapin.");
  }
  const uid = request.auth.uid;
  const email = normalizeEmail(request.data?.email);
  if (!email) {
    throw new HttpsError("invalid-argument", "Gecerli bir e-posta girin.");
  }
  await assertEmailAvailable(email, uid);

  const ref = emailOtpRef(uid);
  const existing = await ref.get();
  const prev = existing.data() || {};
  const sentAtMs = typeof prev.sentAt?.toMillis === "function"
    ? prev.sentAt.toMillis()
    : 0;
  if (sentAtMs && Date.now() - sentAtMs < 45000) {
    throw new HttpsError(
        "resource-exhausted",
        "Kodu az once gonderdik. 45 saniye sonra tekrar deneyin.",
    );
  }

  const code = String(Math.floor(100000 + Math.random() * 900000));
  const templates = await loadTemplates();
  const message = fillTemplate(templates.emailOtp, {code});
  const result = await sendOtpEmail({email, code, message});
  if (!result.ok) {
    throw new HttpsError(
        "unavailable",
        "Dogrulama kodu e-postaya gonderilemedi. Adresi kontrol edip tekrar deneyin.",
    );
  }

  await ref.set({
    hash: hashOtp(`${uid}:${email}`, code),
    email,
    sentAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(Date.now() + 5 * 60 * 1000),
    attempts: 0,
    channel: "email",
  });
  await db().collection("users").doc(uid).set({
    email,
    email_verified: false,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {ok: true, channel: "email"};
});

exports.verifyEmailCode = onCall(callOpts(), async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Giris yapin.");
  }
  const uid = request.auth.uid;
  const email = normalizeEmail(request.data?.email);
  const smsCode = String(request.data?.code || "").trim();
  if (!email || !/^\d{4,8}$/.test(smsCode)) {
    throw new HttpsError("invalid-argument", "E-posta veya kod gecersiz.");
  }

  const ref = emailOtpRef(uid);
  const snap = await ref.get();
  const data = snap.data();
  if (!data?.hash) {
    throw new HttpsError("failed-precondition", "Once dogrulama kodu gonderin.");
  }
  if (data.email && data.email !== email) {
    throw new HttpsError("invalid-argument", "E-posta adresi degismis. Kodu tekrar gonderin.");
  }
  if (data.expiresAt && data.expiresAt.toMillis() < Date.now()) {
    await ref.delete();
    throw new HttpsError("deadline-exceeded", "Kodun suresi doldu. Tekrar gonderin.");
  }
  const attempts = Number(data.attempts || 0);
  if (attempts >= 5) {
    await ref.delete();
    throw new HttpsError("resource-exhausted", "Cok fazla hatali deneme. Kodu tekrar gonderin.");
  }
  if (data.hash !== hashOtp(`${uid}:${email}`, smsCode)) {
    await ref.update({attempts: attempts + 1});
    throw new HttpsError("permission-denied", "Dogrulama kodu hatali.");
  }
  await assertEmailAvailable(email, uid);

  await db().collection("users").doc(uid).set({
    email,
    email_verified: true,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  await ref.delete();
  return {ok: true, email};
});

exports.sendBroadcast = onCall(
    {
      region: "europe-west1",
      cors: true,
      invoker: "public",
      timeoutSeconds: 300,
      memory: "512MiB",
      secrets: [netgsmUser, netgsmPass, netgsmHeader, smtpPassword],
    },
    async (request) => {
      if (!request.auth || !request.auth.uid) {
        throw new HttpsError("unauthenticated", "Giris yapin.");
      }
      await assertAdmin(request.auth.uid);

      const title = String(request.data?.title || "").trim().slice(0, 80);
      const body = String(request.data?.body || "").trim().slice(0, 500);
      const selfOnly = request.data?.target === "self";
      if (!title || !body) {
        throw new HttpsError("invalid-argument", "Baslik ve metin gerekli.");
      }

      const uids = [];
      if (selfOnly) {
        uids.push(request.auth.uid);
      } else {
        const snap = await db().collection("users").get();
        for (const doc of snap.docs) {
          const data = doc.data() || {};
          if (data.is_guest === true) continue;
          if (data.active === false) continue;
          uids.push(doc.id);
        }
      }

      const broadcastRef = db().collection("broadcasts").doc();
      await broadcastRef.set({
        title,
        body,
        category: "campaign",
        target: selfOnly ? "self" : "all",
        sentBy: request.auth.uid,
        sentByEmail: request.auth.token?.email || "",
        recipientCount: uids.length,
        sentCount: 0,
        status: "sending",
        createdAt: FieldValue.serverTimestamp(),
      });

      let sentCount = 0;
      for (let i = 0; i < uids.length; i += 8) {
        const chunk = uids.slice(i, i + 8);
        await Promise.all(chunk.map((uid) => notifyUser(uid, {
          title,
          body,
          category: "campaign",
          data: {type: "broadcast", broadcastId: broadcastRef.id},
        })));
        sentCount += chunk.length;
      }

      await broadcastRef.set({
        sentCount,
        status: "sent",
      }, {merge: true});

      logger.info("Broadcast sent", {
        id: broadcastRef.id,
        sentCount,
        selfOnly,
      });
      return {
        id: broadcastRef.id,
        sentCount,
        recipientCount: uids.length,
        selfOnly,
      };
    },
);

const REFERRAL_INVITE_CODE = "GELIYOR100";
const REFERRAL_INVITE_COOLDOWN_MS = 45 * 1000;
const REFERRAL_INVITE_DAILY_LIMIT = 8;

function istanbulDayKey() {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Istanbul",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
}

function firstNameOf(value) {
  const name = String(value || "").trim().split(/\s+/)[0] || "";
  return name.slice(0, 24);
}

exports.sendReferralInvite = onCall(inviteCallOpts(), async (request) => {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Giris yapin.");
  }
  const uid = request.auth.uid;
  const channel = String(request.data?.channel || "").trim().toLowerCase();
  if (channel !== "phone" && channel !== "email") {
    throw new HttpsError("invalid-argument", "Telefon veya e-posta secin.");
  }

  const userSnap = await db().collection("users").doc(uid).get();
  const user = userSnap.data() || {};
  const inviterName = firstNameOf(
      realName(user.display_name, user.fullName, request.auth.token?.name),
  ) || "Arkadasin";

  const quotaRef = db().collection("referral_invite_quota").doc(uid);
  const quotaSnap = await quotaRef.get();
  const quota = quotaSnap.data() || {};
  const lastMs = typeof quota.lastSentAt?.toMillis === "function"
    ? quota.lastSentAt.toMillis()
    : 0;
  if (lastMs && Date.now() - lastMs < REFERRAL_INVITE_COOLDOWN_MS) {
    throw new HttpsError(
        "resource-exhausted",
        "Daveti az once gonderdik. 45 saniye sonra tekrar deneyin.",
    );
  }
  const dayKey = istanbulDayKey();
  const dayCount = quota.dayKey === dayKey ? Number(quota.dayCount || 0) : 0;
  if (dayCount >= REFERRAL_INVITE_DAILY_LIMIT) {
    throw new HttpsError(
        "resource-exhausted",
        "Gunluk davet limitine ulastiniz. Yarin tekrar deneyin.",
    );
  }

  let destination = "";
  let result;
  if (channel === "phone") {
    const gsmno = normalizePhone(request.data?.to || request.data?.phone);
    if (!gsmno) {
      throw new HttpsError("invalid-argument", "Gecerli bir telefon numarasi girin.");
    }
    const mine = normalizePhone(user.phone_number || user.phone || "");
    if (mine && mine === gsmno) {
      throw new HttpsError("invalid-argument", "Kendinizi davet edemezsiniz.");
    }
    destination = gsmno;
    const message =
      `${inviterName} seni geliyor.tr'ye davet etti. Davet kodun: ` +
      `${REFERRAL_INVITE_CODE}. Ilk alisverisinde kullan, ikiniz de ` +
      `Dost Puan kazanin. geliyor.tr`;
    result = await sendNetgsmSms({
      phone: gsmno,
      message,
      kind: "referral-invite",
      docPath: quotaRef.path,
    });
    if (!result.ok) {
      throw new HttpsError(
          "unavailable",
          "SMS gonderilemedi. Biraz sonra tekrar deneyin.",
      );
    }
  } else {
    const email = normalizeEmail(request.data?.to || request.data?.email);
    if (!email) {
      throw new HttpsError("invalid-argument", "Gecerli bir e-posta girin.");
    }
    const mine = normalizeEmail(user.email || "");
    if (mine && mine === email) {
      throw new HttpsError("invalid-argument", "Kendinizi davet edemezsiniz.");
    }
    destination = email;
    const safeName = escapeHtml(inviterName);
    const safeCode = escapeHtml(REFERRAL_INVITE_CODE);
    result = await sendMail({
      to: email,
      kind: "referral-invite",
      subject: "geliyor.tr davet kodu",
      text:
        `${inviterName} seni geliyor.tr'ye davet etti.\n\n` +
        `Davet kodun: ${REFERRAL_INVITE_CODE}\n\n` +
        `Ilk alisverisinde bu kodu kullan; sen avantajli basla, ` +
        `davet eden Dost Puan kazansin.\n\ngeliyor.tr`,
      html:
        `<p><strong>${safeName}</strong> seni geliyor.tr'ye davet etti.</p>` +
        `<p>Davet kodun:</p>` +
        `<p style="font-size:28px;font-weight:700;letter-spacing:2px">${safeCode}</p>` +
        `<p>Ilk alisverisinde bu kodu kullan; sen avantajli basla, ` +
        `davet eden Dost Puan kazansin.</p>` +
        `<p>geliyor.tr</p>`,
    });
    if (!result.ok) {
      throw new HttpsError(
          "unavailable",
          "E-posta gonderilemedi. Adresi kontrol edip tekrar deneyin.",
      );
    }
  }

  await quotaRef.set({
    lastSentAt: FieldValue.serverTimestamp(),
    dayKey,
    dayCount: dayCount + 1,
    lastChannel: channel,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  await db().collection("referral_invites").add({
    uid,
    inviterName,
    channel,
    destination,
    code: REFERRAL_INVITE_CODE,
    jobid: result.jobid || "",
    createdAt: FieldValue.serverTimestamp(),
  });
  logger.info("Referral invite sent", {uid, channel, destination});
  return {ok: true, channel};
});
