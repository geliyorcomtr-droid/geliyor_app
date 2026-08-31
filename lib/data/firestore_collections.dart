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
}

/// `products/{id}` alanları
class ProductFields {
  ProductFields._();

  static const title = 'title';
  static const brand = 'brand';
  static const weight = 'weight';
  static const barcode = 'barcode';
  static const skt = 'skt';
  static const sktLabel = 'sktLabel';
  static const sktMonth = 'sktMonth';
  static const sktYear = 'sktYear';
  static const unitPrice = 'unitPrice';
  static const oldPrice = 'oldPrice';
  static const discountPercent = 'discountPercent';
  static const imageUrl = 'imageUrl';
  static const category = 'category';
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
}

/// `orders/{id}` alanları
class OrderFields {
  OrderFields._();

  static const userId = 'userId';
  static const status = 'status';
  static const total = 'total';
  static const items = 'items';
  static const address = 'address';
  static const customerName = 'customerName';
  static const phone = 'phone';
  static const paymentMethod = 'paymentMethod';
  static const deliverySlot = 'deliverySlot';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const statusMessage = 'statusMessage';
  static const smsCreatedAt = 'smsCreatedAt';
  static const smsCreatedJobId = 'smsCreatedJobId';
  static const smsDeliveredAt = 'smsDeliveredAt';
  static const smsDeliveredJobId = 'smsDeliveredJobId';
  static const smsLastError = 'smsLastError';
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
}

class SupportTicketStatuses {
  SupportTicketStatuses._();

  static const open = 'open';
  static const replied = 'replied';
  static const closed = 'closed';
}
