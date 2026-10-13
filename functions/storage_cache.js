const {getStorage} = require("firebase-admin/storage");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

const FLAG_PATH = "settings/storage_cache";
const CACHE_CONTROL = "public, max-age=31536000, immutable";
const PREFIXES = [
  "products/",
  "banners/",
  "brands/",
  "categories/",
  "trust_badges/",
  "product_advantages/",
  "knowledge_articles/",
  "knowledge_topics/",
];

function db() {
  return getFirestore();
}

async function backfillStorageCacheControl({force = false} = {}) {
  const flagRef = db().doc(FLAG_PATH);
  if (!force) {
    const flag = await flagRef.get();
    if (flag.get("done") === true) {
      return {skipped: true, updated: 0};
    }
  }

  const bucket = getStorage().bucket();
  let updated = 0;
  let scanned = 0;
  for (const prefix of PREFIXES) {
    const [files] = await bucket.getFiles({prefix});
    for (const file of files) {
      scanned += 1;
      const [metadata] = await file.getMetadata();
      const current = String(metadata.cacheControl || "");
      if (!force && current.includes("max-age=31536000")) continue;
      const contentType = metadata.contentType || "image/jpeg";
      await file.setMetadata({
        contentType,
        cacheControl: CACHE_CONTROL,
      });
      updated += 1;
    }
  }

  await flagRef.set({
    done: true,
    scanned,
    updated,
    at: FieldValue.serverTimestamp(),
  }, {merge: true});
  logger.info("Storage cache headers backfilled", {scanned, updated});
  return {skipped: false, scanned, updated};
}

module.exports = {backfillStorageCacheControl};
