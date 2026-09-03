enum Direction { moneyIn, moneyOut }

enum InvoiceStatus {
  unpaid,
  partiallyPaid,
  paid,
  cancelled;

  String get key => name;
  static InvoiceStatus fromKey(String key) {
    switch (key) {
      case 'paid':
        return InvoiceStatus.paid;
      case 'partially_paid':
      case 'partiallyPaid':
        return InvoiceStatus.partiallyPaid;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.unpaid;
    }
  }
}

enum StaffRole {
  owner,
  manager,
  staff;

  String get key => name;
  static StaffRole fromKey(String key) {
    switch (key) {
      case 'owner':
        return StaffRole.owner;
      case 'manager':
        return StaffRole.manager;
      default:
        return StaffRole.staff;
    }
  }
}

enum HealthGrade { A, B, C, D }

class Txn {
  const Txn({
    required this.id,
    required this.occurredAt,
    required this.createdAt,
    required this.direction,
    required this.amountMinor,
    this.partyId,
    this.partyName,
    this.category,
    this.note,
    this.isCredit = false,
    this.isAdjustment = false,
    this.isWriteOff = false,
    this.photoPath,
    this.nlRaw,
    this.aiInferred = false,
    this.branchId,
    this.staffId,
    this.staffName,
    this.invoiceId,
    this.inventoryItemId,
  });

  final String id;
  final DateTime occurredAt;
  final DateTime createdAt;
  final Direction direction;
  final int amountMinor;
  final String? partyId;
  final String? partyName;
  final String? category;
  final String? note;
  final bool isCredit;
  final bool isAdjustment;
  final bool isWriteOff;
  final String? photoPath;
  final String? nlRaw;
  final bool aiInferred;
  final String? branchId;
  final String? staffId;
  final String? staffName;
  final String? invoiceId;
  final String? inventoryItemId;

  bool get movesCash => !isCredit && !isWriteOff;
}

class Party {
  const Party({
    required this.id,
    required this.name,
    this.phone,
    required this.createdAt,
    this.remindEnabled = false,
    this.remindEveryDays = 14,
    this.lastRemindedAt,
    this.settledAt,
    this.balanceMinor = 0,
  });

  final String id;
  final String name;
  final String? phone;
  final DateTime createdAt;
  final bool remindEnabled;
  final int remindEveryDays;
  final DateTime? lastRemindedAt;
  final DateTime? settledAt;
  final int balanceMinor;
}

class InvoiceItem {
  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPriceMinor,
    required this.totalMinor,
    this.inventoryItemId,
  });

  final String id;
  final String invoiceId;
  final String description;
  final double quantity;
  final int unitPriceMinor;
  final int totalMinor;
  final String? inventoryItemId;
}

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    this.partyId,
    this.partyName,
    required this.issueDate,
    this.dueDate,
    required this.subtotalMinor,
    this.taxRatePct = 0.0,
    this.taxMinor = 0,
    required this.totalMinor,
    this.paidAmountMinor = 0,
    this.status = InvoiceStatus.unpaid,
    this.notes,
    this.branchId,
    required this.createdAt,
  });

  final String id;
  final String invoiceNumber;
  final String? partyId;
  final String? partyName;
  final DateTime issueDate;
  final DateTime? dueDate;
  final int subtotalMinor;
  final double taxRatePct;
  final int taxMinor;
  final int totalMinor;
  final int paidAmountMinor;
  final InvoiceStatus status;
  final String? notes;
  final String? branchId;
  final DateTime createdAt;

  int get dueAmountMinor => totalMinor - paidAmountMinor;
  bool get isFullyPaid => paidAmountMinor >= totalMinor;
}

class InvoiceWithItems {
  const InvoiceWithItems({required this.invoice, required this.items});

  final Invoice invoice;
  final List<InvoiceItem> items;
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    this.sku,
    this.unit = 'pcs',
    this.currentQuantity = 0.0,
    this.lowStockThreshold = 5.0,
    this.costPriceMinor = 0,
    this.salePriceMinor = 0,
    this.branchId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? sku;
  final String unit;
  final double currentQuantity;
  final double lowStockThreshold;
  final int costPriceMinor;
  final int salePriceMinor;
  final String? branchId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLowStock => currentQuantity <= lowStockThreshold;
  int get inventoryValueMinor => (currentQuantity * costPriceMinor).round();
}

class Branch {
  const Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.isDefault = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final bool isDefault;
  final DateTime createdAt;
}

class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    this.phone,
    this.role = StaffRole.staff,
    this.pinHash,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? phone;
  final StaffRole role;
  final String? pinHash;
  final bool isActive;
  final DateTime createdAt;
}

class ReconciliationRecord {
  const ReconciliationRecord({
    required this.id,
    required this.occurredAt,
    required this.countedCashMinor,
    this.bankBalanceMinor,
    required this.expectedCashMinor,
    required this.discrepancyMinor,
    this.note,
    this.adjustmentTxnId,
    this.branchId,
  });

  final String id;
  final DateTime occurredAt;
  final int countedCashMinor;
  final int? bankBalanceMinor;
  final int expectedCashMinor;
  final int discrepancyMinor;
  final String? note;
  final String? adjustmentTxnId;
  final String? branchId;

  bool get hasDiscrepancy => discrepancyMinor != 0;
}

class BusinessHealthMetric {
  const BusinessHealthMetric({
    required this.label,
    required this.value,
    required this.status, // 'good', 'warning', 'critical'
    required this.description,
  });

  final String label;
  final String value;
  final String status;
  final String description;
}

class BusinessHealthReport {
  const BusinessHealthReport({
    required this.overallScore,
    required this.grade,
    required this.headline,
    required this.summary,
    required this.metrics,
    required this.actionableInsights,
  });

  final int overallScore; // 0 - 100
  final HealthGrade grade;
  final String headline;
  final String summary;
  final List<BusinessHealthMetric> metrics;
  final List<String> actionableInsights;
}

class DailySummary {
  const DailySummary({
    required this.date,
    required this.inMinor,
    required this.outMinor,
    required this.cashOnHandMinor,
    required this.openingCashMinor,
  });

  final DateTime date;
  final int inMinor;
  final int outMinor;
  final int cashOnHandMinor;
  final int openingCashMinor;
  int get netMinor => inMinor - outMinor;
}

class ReportPeriod {
  const ReportPeriod({
    required this.start,
    required this.end,
    required this.label,
  });
  final DateTime start;
  final DateTime end;
  final String label;
}

class SimpleReport {
  const SimpleReport({
    required this.period,
    required this.moneyInMinor,
    required this.moneyOutMinor,
    required this.cashInMinor,
    required this.cashOutMinor,
    required this.udhaarGivenMinor,
    required this.udhaarTakenMinor,
    required this.taxMinor,
  });

  final ReportPeriod period;
  final int moneyInMinor;
  final int moneyOutMinor;
  final int cashInMinor;
  final int cashOutMinor;
  final int udhaarGivenMinor;
  final int udhaarTakenMinor;
  final int taxMinor;
  int get leftMinor => moneyInMinor - moneyOutMinor;
}

class AppSettings {
  const AppSettings({
    this.locale = 'en',
    this.currency = 'NPR',
    this.businessName = '',
    this.taxRatePct = 0,
    this.lockEnabled = false,
    this.pinHash,
    this.onboardingDone = false,
    this.isLoggedIn = false,
    this.authEmail,
    this.authIsDemo = false,
    this.notifyPaymentDue = true,
    this.notifyLowCash = true,
    this.notifyLowStock = true,
    this.lowCashThresholdMinor = 0,
    this.lastDirection = Direction.moneyIn,
    this.activeBranchId,
    this.activeStaffId,
    this.activeStaffName,
    this.activeStaffRole = StaffRole.owner,
  });

  final String locale;
  final String currency;
  final String businessName;
  final double taxRatePct;
  final bool lockEnabled;
  final String? pinHash;
  final bool onboardingDone;
  final bool isLoggedIn;
  final String? authEmail;
  final bool authIsDemo;
  final bool notifyPaymentDue;
  final bool notifyLowCash;
  final bool notifyLowStock;
  final int lowCashThresholdMinor;
  final Direction lastDirection;
  final String? activeBranchId;
  final String? activeStaffId;
  final String? activeStaffName;
  final StaffRole activeStaffRole;

  bool get isStaffRestricted => activeStaffRole == StaffRole.staff;

  AppSettings copyWith({
    String? locale,
    String? currency,
    String? businessName,
    double? taxRatePct,
    bool? lockEnabled,
    String? pinHash,
    bool? onboardingDone,
    bool? isLoggedIn,
    String? authEmail,
    bool? authIsDemo,
    bool? notifyPaymentDue,
    bool? notifyLowCash,
    bool? notifyLowStock,
    int? lowCashThresholdMinor,
    Direction? lastDirection,
    String? activeBranchId,
    String? activeStaffId,
    String? activeStaffName,
    StaffRole? activeStaffRole,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
      businessName: businessName ?? this.businessName,
      taxRatePct: taxRatePct ?? this.taxRatePct,
      lockEnabled: lockEnabled ?? this.lockEnabled,
      pinHash: pinHash ?? this.pinHash,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      authEmail: authEmail ?? this.authEmail,
      authIsDemo: authIsDemo ?? this.authIsDemo,
      notifyPaymentDue: notifyPaymentDue ?? this.notifyPaymentDue,
      notifyLowCash: notifyLowCash ?? this.notifyLowCash,
      notifyLowStock: notifyLowStock ?? this.notifyLowStock,
      lowCashThresholdMinor:
          lowCashThresholdMinor ?? this.lowCashThresholdMinor,
      lastDirection: lastDirection ?? this.lastDirection,
      activeBranchId: activeBranchId ?? this.activeBranchId,
      activeStaffId: activeStaffId ?? this.activeStaffId,
      activeStaffName: activeStaffName ?? this.activeStaffName,
      activeStaffRole: activeStaffRole ?? this.activeStaffRole,
    );
  }
}

class ParsedEntry {
  const ParsedEntry({
    this.direction,
    this.amountMinor,
    this.partyName,
    this.category,
    this.isCredit = false,
    this.note,
    this.confident = false,
  });

  final Direction? direction;
  final int? amountMinor;
  final String? partyName;
  final String? category;
  final bool isCredit;
  final String? note;
  final bool confident;
}
