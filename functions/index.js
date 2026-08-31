const crypto = require("crypto");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {defineSecret} = require("firebase-functions/params");
const {onDocumentCreated, onDocumentUpdated} =
  require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {setGlobalOptions} = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");

initializeApp();
setGlobalOptions({region: "europe-west1"});

const netgsmUser = defineSecret("NETGSM_USERCODE");
const netgsmPass = defineSecret("NETGSM_PASSWORD");
const netgsmHeader = defineSecret("NETGSM_MSGHEADER");

const DEFAULT_TEMPLATES = {
  welcome:
    "Sn. {{name}}, geliyor.tr uyeliginiz olusturulmustur. " +
    "Alisverise hemen baslayabilirsiniz.",
  orderCreated:
    "Sn. {{name}}, siparisiniz alinmistir. Siparis no: {{orderNo}}. " +
    "Toplam: {{total}} TL. geliyor.tr",
  orderDelivered:
    "Sn. {{name}}, {{orderNo}} nolu siparisiniz teslim edilmistir. " +
    "Bizi tercih ettiginiz icin tesekkurler. geliyor.tr",
  otp: "geliyor.tr dogrulama kodunuz: {{code}}",
};

function db() {
  return getFirestore();
}

function triggerOpts(document) {
  return {
    document,
    region: "europe-west1",
    secrets: [netgsmUser, netgsmPass, netgsmHeader],
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
  const id = String(orderId || "");
  return id.slice(0, 8).toUpperCase();
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
      orderDelivered: data.orderDelivered || DEFAULT_TEMPLATES.orderDelivered,
      otp: data.otp || DEFAULT_TEMPLATES.otp,
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

  const usercode = netgsmUser.value();
  const password = netgsmPass.value();
  const msgheader = netgsmHeader.value();
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

async function notifyUser(uid, {title, body, category, data}) {
  const userId = String(uid || "").trim();
  if (!userId || !title || !body) return;
  const payloadData = {};
  const extra = data && typeof data === "object" ? data : {};
  for (const [key, value] of Object.entries(extra)) {
    if (value == null) continue;
    payloadData[String(key)] = String(value);
  }
  payloadData.category = String(category || "system");

  try {
    await db().collection("users").doc(userId).collection("notifications").add({
      title,
      body,
      category: category || "system",
      unread: true,
      createdAt: FieldValue.serverTimestamp(),
      data: extra,
    });
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
    if (!entries.length) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens: entries.map((item) => item.token),
      notification: {title, body},
      data: payloadData,
      android: {
        priority: "high",
        notification: {channelId: "geliyor_default"},
      },
      apns: {payload: {aps: {sound: "default", badge: 1}}},
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
  } catch (error) {
    logger.error("FCM send failed", {userId, error});
  }
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
      });
    },
);

exports.onOrderCreated = onDocumentCreated(
    triggerOpts("orders/{orderId}"),
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data() || {};
      if (data.smsCreatedAt) return;

      const templates = await loadTemplates();
      const vars = {
        name: String(data.customerName || "Uye").trim() || "Uye",
        orderNo: shortOrderNo(event.params.orderId),
        total: formatTotal(data.total),
      };
      const result = await sendNetgsmSms({
        phone: data.phone || "",
        message: fillTemplate(templates.orderCreated, vars),
        kind: "order_created",
        docPath: snap.ref.path,
      });

      await markSms(snap.ref, result.ok
        ? {
          smsCreatedAt: FieldValue.serverTimestamp(),
          smsCreatedJobId: result.jobid || "",
          smsLastError: FieldValue.delete(),
        }
        : {smsLastError: result.error || "order-created-failed"});

      await notifyUser(data.userId, {
        title: "Siparişiniz alındı",
        body: `${vars.orderNo} numaralı siparişiniz alındı. Toplam: ${vars.total} TL.`,
        category: "order",
        data: {type: "order_created", orderId: event.params.orderId},
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
      const orderNo = shortOrderNo(orderId);
      const uid = after.userId || "";

      if (before.status !== after.status) {
        if (after.status === "shipping") {
          await notifyUser(uid, {
            title: "Siparişiniz yola çıktı",
            body: `${orderNo} numaralı siparişiniz kargoya verildi.`,
            category: "order",
            data: {type: "order_shipping", orderId},
          });
        } else if (after.status === "cancelled") {
          await notifyUser(uid, {
            title: "Sipariş iptal edildi",
            body: `${orderNo} numaralı siparişiniz iptal edildi.`,
            category: "order",
            data: {type: "order_cancelled", orderId},
          });
        } else if (after.status === "delivered") {
          await notifyUser(uid, {
            title: "Siparişiniz teslim edildi",
            body: `${orderNo} numaralı siparişiniz teslim edildi.`,
            category: "order",
            data: {type: "order_delivered", orderId},
          });
        }
      }

      if (before.status === "delivered" || after.status !== "delivered") {
        return;
      }
      if (after.smsDeliveredAt) return;

      const templates = await loadTemplates();
      const vars = {
        name: String(after.customerName || "Uye").trim() || "Uye",
        orderNo,
        total: formatTotal(after.total),
      };
      const result = await sendNetgsmSms({
        phone: after.phone || "",
        message: fillTemplate(templates.orderDelivered, vars),
        kind: "order_delivered",
        docPath: change.after.ref.path,
      });

      await markSms(change.after.ref, result.ok
        ? {
          smsDeliveredAt: FieldValue.serverTimestamp(),
          smsDeliveredJobId: result.jobid || "",
          smsLastError: FieldValue.delete(),
        }
        : {smsLastError: result.error || "order-delivered-failed"});
    },
);

function callOpts() {
  return {
    region: "europe-west1",
    secrets: [netgsmUser, netgsmPass, netgsmHeader],
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
    user = await auth.getUserByPhoneNumber(phoneE164);
  } catch (error) {
    if (error.code !== "auth/user-not-found") {
      logger.error("getUserByPhoneNumber failed", error);
      throw new HttpsError("internal", "Giris dogrulanamadi. Daha sonra tekrar deneyin.");
    }
    user = null;
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

function daysUntil(fromYmd, toYmd) {
  const from = new Date(`${fromYmd}T00:00:00+03:00`);
  const to = new Date(`${toYmd}T00:00:00+03:00`);
  return Math.round((to.getTime() - from.getTime()) / 86400000);
}

exports.checkFoodReminders = onSchedule(
    {
      region: "europe-west1",
      schedule: "0 7 * * *",
      timeZone: "Europe/Istanbul",
    },
    async () => {
      const today = istanbulYmd();
      const snap = await db().collection("users")
          .where("food_reminder.enabled", "==", true)
          .get();

      let sent = 0;
      for (const doc of snap.docs) {
        const data = doc.data()?.food_reminder || {};
        if (String(data.reminderDate || "") > today) continue;
        if (data.sentFor === today) continue;
        const uid = doc.id;

        const endDate = String(data.estimatedEndDate || "");
        const remaining = endDate
          ? Math.max(0, daysUntil(today, endDate))
          : Number(data.remainingDays || 0);
        const petName = String(data.petName || "Dostunuz").trim() || "Dostunuz";
        const foodTitle = String(data.foodTitle || "mama").trim() || "mama";
        const body = remaining <= 0
          ? `${petName} için ${foodTitle} stoğu bitmek üzere. Yeni paket için Pet Market’e göz atın.`
          : `${petName} için ${foodTitle} yaklaşık ${remaining} gün içinde bitecek.`;

        await notifyUser(uid, {
          title: "Mama hatırlatması",
          body,
          category: "reminder",
          data: {type: "food_reminder", remainingDays: String(remaining)},
        });
        await doc.ref.set({
          food_reminder: {
            ...data,
            sentFor: today,
            remainingDays: remaining,
          },
        }, {merge: true});
        sent += 1;
      }
      logger.info("Food reminders processed", {today, matched: snap.size, sent});
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

exports.sendBroadcast = onCall(
    {
      region: "europe-west1",
      cors: true,
      invoker: "public",
      timeoutSeconds: 300,
      memory: "512MiB",
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
