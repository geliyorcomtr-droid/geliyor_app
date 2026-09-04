/// Firestore koleksiyon ve alan sabitleri (mobil + admin ortak).
class FirestoreCollections {
  FirestoreCollections._();

  static const users = 'users';
  static const products = 'products';
  static const orders = 'orders';
  static const reviews = 'reviews';
  static const banners = 'banners';
  static const campaigns = 'campaigns';
  static const broadcasts = 'broadcasts';
  static const supportTickets = 'support_tickets';
  static const categories = 'categories';
  static const brands = 'brands';
  static const trustBadges = 'trust_badges';
  static const productAdvantages = 'product_advantages';
  static const settings = 'settings';
  static const coupons = 'coupons';
  static const foodCouponQueue = 'food_coupon_queue';
}

/// `users/{uid}` alanları
class UserFields {
  UserFields._();

  static const uid = 'uid';
  static const displayName = 'display_name';
  static const phoneNumber = 'phone_number';

  /// Uygulama: `customer` | Admin panel: `admin`
  static const userRole = 'user_role';

  /// Alternatif alan (manuel Console yazımları için)
  static const role = 'role';
  static const isGuest = 'is_guest';
  static const email = 'email';
  static const emailVerified = 'email_verified';
  static const birthDate = 'birth_date';
  static const gender = 'gender';
  static const membershipType = 'membership_type';
  static const memberGroup = 'member_group';
  static const specialDiscount = 'special_discount';
  static const riskyCustomer = 'risky_customer';
  static const active = 'active';
  static const createdTime = 'created_time';
  static const updatedAt = 'updatedAt';
  static const smsWelcomeAt = 'smsWelcomeAt';
  static const smsWelcomeJobId = 'smsWelcomeJobId';
  static const smsLastError = 'smsLastError';
  static const pets = 'pets';
  static const activePetIndex = 'active_pet_index';
  static const foodTracking = 'food_tracking';
  static const cart = 'cart';
  static const favorites = 'favorites';
  static const addresses = 'addresses';
  static const lastOrder = 'last_order';
  static const notificationSettings = 'notification_settings';
  static const earnedCouponIds = 'earned_coupon_ids';
  static const foodReminder = 'food_reminder';
  static const healthCalendar = 'health_calendar';
}

class NotificationFields {
  NotificationFields._();

  static const title = 'title';
  static const body = 'body';
  static const category = 'category';
  static const unread = 'unread';
  static const createdAt = 'createdAt';
  static const data = 'data';
}

class FcmTokenFields {
  FcmTokenFields._();

  static const token = 'token';
  static const platform = 'platform';
  static const updatedAt = 'updatedAt';
}

class FoodReminderFields {
  FoodReminderFields._();

  static const collection = 'food_reminders';
  static const currentId = 'current';
  static const enabled = 'enabled';
  static const prefsEnabled = 'prefsEnabled';
  static const daysBefore = 'daysBefore';
  static const reminderDate = 'reminderDate';
  static const estimatedEndDate = 'estimatedEndDate';
  static const remainingDays = 'remainingDays';
  static const petName = 'petName';
  static const foodTitle = 'foodTitle';
  static const sentFor = 'sentFor';
  static const updatedAt = 'updatedAt';
  static const autoOrderEnabled = 'autoOrderEnabled';
  static const autoOrderDate = 'autoOrderDate';
  static const autoOrderSentFor = 'autoOrderSentFor';
}

class HealthCalendarFields {
  HealthCalendarFields._();

  static const enabled = 'enabled';
  static const daysBefore = 'daysBefore';
  static const timeHour = 'timeHour';
  static const items = 'items';
  static const title = 'title';
  static const category = 'category';
  static const frequency = 'frequency';
  static const intervalMonths = 'intervalMonths';
  static const lastDoneDate = 'lastDoneDate';
  static const nextDueDate = 'nextDueDate';
  static const reminderDate = 'reminderDate';
  static const sentFor = 'sentFor';
}

class FoodTrackingFields {
  FoodTrackingFields._();

  static const active = 'active';
  static const foodName = 'foodName';
  static const bagKg = 'bagKg';
  static const purchaseDate = 'purchaseDate';
  static const petName = 'petName';
  static const petSpecies = 'petSpecies';
}

class PetFields {
  PetFields._();

  static const name = 'name';
  static const species = 'species';
  static const ageRange = 'ageRange';
  static const weight = 'weight';
  static const bodyType = 'bodyType';
  static const neutered = 'neutered';
  static const activityLevel = 'activityLevel';
  static const extraFood = 'extraFood';
  static const dailyFoodGrams = 'dailyFoodGrams';
  static const allergies = 'allergies';
}

/// `products/{id}` alanları
class ProductFields {
  ProductFields._();

  static const title = 'title';
  static const brand = 'brand';
  static const weight = 'weight';
  static const barcode = 'barcode';
  static const vatRate = 'vatRate';
  static const skt = 'skt';
  static const sktLabel = 'sktLabel';
  static const sktMonth = 'sktMonth';
  static const sktYear = 'sktYear';
  static const unitPrice = 'unitPrice';
  static const oldPrice = 'oldPrice';
  static const discountPercent = 'discountPercent';
  static const imageUrl = 'imageUrl';
  static const category = 'category';
  static const extraCategories = 'extraCategories';
  static const placements = 'placements';
  static const mainCategory = 'mainCategory';
  static const description = 'description';
  static const active = 'active';
  static const stock = 'stock';
  static const features = 'features';
  static const technicalFeatures = 'technicalFeatures';
  static const trustBadgeIds = 'trustBadgeIds';
  static const productAdvantageIds = 'productAdvantageIds';
  static const productAdvantageValues = 'productAdvantageValues';
  static const proteinValue = 'proteinValue';
  static const preferredRank = 'preferredRank';
  static const repurchaseRate = 'repurchaseRate';
  static const rating = 'rating';
  static const reviewCount = 'reviewCount';
  static const gallery = 'gallery';
  static const seoTitle = 'seoTitle';
  static const metaDescription = 'metaDescription';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';

  static const vatRates = [0, 1, 10, 20];

  /// Kayıtta yoksa %20. Geçersiz değerler %20'ye çekilir.
  static int vatRateFrom(dynamic raw) {
    final n = raw is num
        ? raw.round()
        : int.tryParse('$raw'.replaceAll('%', '').trim());
    if (n == null) return 20;
    if (n == 8 || n == 18 || vatRates.contains(n)) return n;
    return 20;
  }
}

/// Ürünün ana kategorisine ek olarak görünebileceği vitrinler.
class ProductPlacements {
  ProductPlacements._();

  /// Hediye Seç → Hediye Seçenekleri
  static const gift = 'gift';

  /// Hediye Seç → Premium Hediyeler
  static const giftPremium = 'gift_premium';
}

/// `orders/{id}` alanları
class OrderFields {
  OrderFields._();

  static const userId = 'userId';
  static const status = 'status';
  static const total = 'total';
  static const subtotal = 'subtotal';
  static const courierFee = 'courierFee';
  static const couponId = 'couponId';
  static const couponCode = 'couponCode';
  static const couponTitle = 'couponTitle';
  static const couponDiscount = 'couponDiscount';
  static const gifts = 'gifts';
  static const items = 'items';
  static const orderNo = 'orderNo';
  static const address = 'address';
  static const city = 'city';
  static const district = 'district';
  static const billing = 'billing';
  static const invoiceLink = 'invoiceLink';
  static const invoiceNumber = 'invoiceNumber';
  static const invoiceDate = 'invoiceDate';
  static const cargoCompany = 'cargoCompany';
  static const cargoTrackingCode = 'cargoTrackingCode';
  static const cargoTrackingUrl = 'cargoTrackingUrl';
  static const customerName = 'customerName';
  static const phone = 'phone';
  static const paymentMethod = 'paymentMethod';
  static const deliverySlot = 'deliverySlot';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const statusMessage = 'statusMessage';
  static const smsCreatedAt = 'smsCreatedAt';
  static const smsCreatedJobId = 'smsCreatedJobId';
  static const smsShippingAt = 'smsShippingAt';
  static const smsShippingJobId = 'smsShippingJobId';
  static const smsCancelledAt = 'smsCancelledAt';
  static const smsCancelledJobId = 'smsCancelledJobId';
  static const smsDeliveredAt = 'smsDeliveredAt';
  static const smsDeliveredJobId = 'smsDeliveredJobId';
  static const smsLastError = 'smsLastError';
  static const stockAppliedAt = 'stockAppliedAt';
  static const stockRestoredAt = 'stockRestoredAt';
  static const stockDeltas = 'stockDeltas';
}

/// Sipariş durumları
class OrderStatuses {
  OrderStatuses._();

  static const preparing = 'preparing';
  static const shipping = 'shipping';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';
}

/// `categories/{id}` alanları
class CategoryFields {
  CategoryFields._();

  static const id = 'id';
  static const title = 'title';
  static const imageUrl = 'imageUrl';
  static const order = 'order';
  static const active = 'active';
  static const subcategories = 'subcategories';
  static const updatedAt = 'updatedAt';
}

/// `brands/{id}` alanları
class BrandFields {
  BrandFields._();

  static const name = 'name';
  static const imageUrl = 'imageUrl';
  static const assetPath = 'assetPath';
  static const order = 'order';
  static const active = 'active';
  static const updatedAt = 'updatedAt';
}

/// `trust_badges/{id}` alanları
class TrustBadgeFields {
  TrustBadgeFields._();

  static const name = 'name';
  static const imageUrl = 'imageUrl';
  static const assetPath = 'assetPath';
  static const order = 'order';
  static const active = 'active';
  static const updatedAt = 'updatedAt';
}

/// `product_advantages/{id}` alanları
class ProductAdvantageFields {
  ProductAdvantageFields._();

  static const name = 'name';
  static const description = 'description';
  static const value = 'value';
  static const isStat = 'isStat';
  static const imageUrl = 'imageUrl';
  static const assetPath = 'assetPath';
  static const order = 'order';
  static const active = 'active';
  static const updatedAt = 'updatedAt';
}

/// `banners/{id}` alanları
class BannerFields {
  BannerFields._();

  static const title = 'title';
  static const imageUrl = 'imageUrl';
  static const assetPath = 'assetPath';
  static const placement = 'placement';
  static const order = 'order';
  static const active = 'active';
  static const updatedAt = 'updatedAt';
}

/// `campaigns/{id}` alanları
class CampaignFields {
  CampaignFields._();

  static const title = 'title';
  static const subtitle = 'subtitle';
  static const imageUrl = 'imageUrl';
  static const assetPath = 'assetPath';
  static const mainCategory = 'mainCategory';
  static const subCategory = 'subCategory';
  static const order = 'order';
  static const active = 'active';
  static const updatedAt = 'updatedAt';
}

/// `support_tickets/{id}` alanları
class SupportTicketFields {
  SupportTicketFields._();

  static const name = 'name';
  static const email = 'email';
  static const subject = 'subject';
  static const message = 'message';
  static const userId = 'userId';
  static const status = 'status';
  static const reply = 'reply';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const kind = 'kind';
  static const imageUrl = 'imageUrl';
  static const phone = 'phone';
  static const productName = 'productName';
}

class SupportTicketKinds {
  SupportTicketKinds._();

  static const support = 'support';
  static const supply = 'supply';
}

class SupportTicketStatuses {
  SupportTicketStatuses._();

  static const open = 'open';
  static const replied = 'replied';
  static const closed = 'closed';
}

/// `settings/{docId}` belge kimlikleri
class SettingsDocs {
  SettingsDocs._();

  static const bankTransfer = 'bank_transfer';
  static const foodCoupon = 'food_coupon';
}

/// `settings/bank_transfer` alanları — Havale / EFT alıcı bilgileri
class BankTransferFields {
  BankTransferFields._();

  static const holder = 'holder';
  static const iban = 'iban';
  static const updatedAt = 'updatedAt';
}

class CouponFields {
  CouponFields._();

  static const code = 'code';
  static const title = 'title';
  static const description = 'description';
  static const type = 'type';
  static const value = 'value';
  static const minSubtotal = 'minSubtotal';
  static const publicCoupon = 'public';
  static const singleUse = 'singleUse';
  static const active = 'active';
  static const order = 'order';
  static const updatedAt = 'updatedAt';
}

class CouponTypes {
  CouponTypes._();

  static const amount = 'amount';
  static const percent = 'percent';
}

class FoodCouponModes {
  FoodCouponModes._();

  static const off = 'off';
  static const automatic = 'automatic';
  static const manual = 'manual';
}

class FoodCouponSettingsFields {
  FoodCouponSettingsFields._();

  static const mode = 'mode';
  static const couponId = 'couponId';
  static const updatedAt = 'updatedAt';
}

class FoodCouponQueueFields {
  FoodCouponQueueFields._();

  static const userId = 'userId';
  static const customerName = 'customerName';
  static const phone = 'phone';
  static const petName = 'petName';
  static const foodTitle = 'foodTitle';
  static const remainingDays = 'remainingDays';
  static const reminderDate = 'reminderDate';
  static const status = 'status';
  static const couponId = 'couponId';
  static const couponCode = 'couponCode';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
}

class FoodCouponQueueStatuses {
  FoodCouponQueueStatuses._();

  static const pending = 'pending';
  static const assigned = 'assigned';
  static const skipped = 'skipped';
}
