class S {
  const S(this.locale);
  final String locale;
  bool get isNe => locale == 'ne';

  String get moneyIn => isNe ? 'पैसा आयो' : 'Money In';
  String get moneyOut => isNe ? 'पैसा गयो' : 'Money Out';
  String get save => isNe ? 'सेभ गर्नुहोस्' : 'Save';
  String get amount => isNe ? 'रकम' : 'Amount';
  String get nothingToday => isNe
      ? 'आज केही लेखिएको छैन — पहिलो इन्ट्री थप्नुहोस्'
      : 'Nothing recorded yet today — add your first entry';
  String get addEntry => isNe ? 'इन्ट्री थप्नुहोस्' : 'Add entry';
  String get reportsTab => isNe ? 'रिपोर्ट' : 'Reports';
  String get parties => isNe ? 'मानिसहरू' : 'People';
  String get search => isNe ? 'खोज्नुहोस्' : 'Search';
  String get udhaar => isNe ? 'उधारो' : 'Udhaar';
  String get noteHint => isNe ? 'नोट (ऐच्छिक)' : 'Note (optional)';
  String get theyOweYou => isNe ? 'उहाँले तिर्नुपर्छ' : 'They owe you';
  String get youOweThem => isNe ? 'तपाईंले तिर्नुपर्छ' : 'You owe them';
  String get settled => isNe ? 'हिसाब मिलेको' : 'Settled';
  String get sharePdf => isNe ? 'PDF पठाउनुहोस्' : 'Share PDF';
  String get businessName => isNe ? 'व्यवसायको नाम' : 'Business name';
  String get correctCash => isNe ? 'नगद मिलाउनुहोस्' : 'Correct cash on hand';
  String get currency => isNe ? 'मुद्रा' : 'Currency';
  String get taxRate => isNe ? 'कर दर (%)' : 'Tax rate (%)';
  String get unlock => isNe ? 'खोल्नुहोस्' : 'Unlock';
  String get saved => isNe ? 'सेभ भयो' : 'Saved';
  String get recordPayment => isNe ? 'भुक्तानी लेख्नुहोस्' : 'Record payment';
  String get pin => isNe ? 'पिन' : 'PIN';

  // Version 2 Strings
  // Invoicing & Billing
  String get invoices => isNe ? 'बिलहरू / इन्भोइस' : 'Invoices & Billing';
  String get createInvoice => isNe ? 'नयाँ बिल बनाउनुहोस्' : 'Create Invoice';
  String get invoiceNumber => isNe ? 'बिल नं.' : 'Invoice #';
  String get dueDate => isNe ? 'तिर्ने मिति' : 'Due Date';
  String get lineItems => isNe ? 'सामान / विवरण' : 'Items & Services';
  String get addItem => isNe ? 'सामान थप्नुहोस्' : 'Add Item';
  String get quantity => isNe ? 'परिमाण' : 'Quantity';
  String get unitPrice => isNe ? 'दर' : 'Unit Price';
  String get subtotal => isNe ? 'उप-जम्मा' : 'Subtotal';
  String get tax => isNe ? 'कर (VAT/Tax)' : 'Tax';
  String get total => isNe ? 'कुल जम्मा' : 'Total';
  String get unpaid => isNe ? 'बाँकी' : 'Unpaid';
  String get paid => isNe ? 'चुक्ता' : 'Paid';
  String get partiallyPaid => isNe ? 'आंशिक चुक्ता' : 'Partially Paid';
  String get recordInvoicePayment => isNe ? 'बिलको भुक्तानी लिनुहोस्' : 'Record Payment';
  String get due => isNe ? 'तिर्न बाँकी' : 'Due';

  // Inventory Lite
  String get addItemStock => isNe ? 'नयाँ सामान दर्ता गर्नुहोस्' : 'Add Item';
  String get stockQuantity => isNe ? 'मौज्दात परिमाण' : 'Current Stock';
  String get costPrice => isNe ? 'खरिद दर' : 'Cost Price';
  String get salePrice => isNe ? 'बिक्री दर' : 'Sale Price';
  String get lowStockThreshold => isNe ? 'न्यून मौज्दात सूचना सीमा' : 'Low-Stock Alert Level';
  String get adjustStock => isNe ? 'स्टक मिलाउनुहोस्' : 'Adjust Stock';

  // Guided Reconciliation
  String get reconciliation => isNe ? 'नगद र बैंक हिसाब मिलान' : 'Cash & Bank Reconciliation';
  String get reconcileIntro => isNe
      ? 'तपाईंको हातमा भएको नगद र बैंक ब्यालेन्स गल्लासँग दाँजेर हिसाब मिलाउनुहोस्।'
      : 'Count your physical cash and enter your bank balance to reconcile with Galla.';
  String get countedCash => isNe ? 'हातमा भएको नगद' : 'Counted Physical Cash';
  String get bankBalance => isNe ? 'बैंक ब्यालेन्स' : 'Bank Balance';
  String get systemExpected => isNe ? 'गल्लाको हिसाब' : 'Galla System Total';
  String get discrepancy => isNe ? 'फरक / अन्तर' : 'Discrepancy';
  String get acceptAdjustment => isNe ? 'फरक रकम समायोजन गर्नुहोस्' : 'Create Adjustment Entry';
  String get noDiscrepancy => isNe ? 'हिसाब ठ्याक्कै मिल्यो!' : 'Perfect Match! No discrepancy.';

  // Multi-Branch Support
  String get branches => isNe ? 'शाखाहरू' : 'Branches';
  String get allBranches => isNe ? 'सबै शाखा' : 'All Branches';
  String get addBranch => isNe ? 'नयाँ शाखा थप्नुहोस्' : 'Add Branch';
  String get branchName => isNe ? 'शाखाको नाम' : 'Branch Name';

  // Staff Roles & Multi-User
  String get staffMembers => isNe ? 'कर्मचारीहरू' : 'Staff Members';
  String get addStaff => isNe ? 'कर्मचारी थप्नुहोस्' : 'Add Staff Member';
  String get staffRole => isNe ? 'भूमिका' : 'Role';
  String get ownerRole => isNe ? 'साहुजी / मालिक (सबै पहुँच)' : 'Owner (Full Access)';
  String get staffRoleSimple => isNe ? 'कर्मचारी (इन्ट्री मात्र)' : 'Staff (Entry Only)';
  String get switchStaffMode => isNe ? 'भूमिका बदल्नुहोस्' : 'Switch Role / Mode';

  // Business Health Score & AI Insights
  String get businessHealth => isNe ? 'व्यापार स्वास्थ्य स्कोर' : 'Business Health Score';
  String get healthGrade => isNe ? 'ग्रेड' : 'Grade';
  String get actionableInsights => isNe ? 'उपयोगी सुझावहरू' : 'Key AI Insights';

  // CSV Exports
  String get exportTransactionsCsv => isNe ? 'कारोबारको CSV' : 'Transactions CSV';
}
