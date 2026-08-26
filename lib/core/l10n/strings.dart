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
  String get recordInvoicePayment =>
      isNe ? 'बिलको भुक्तानी लिनुहोस्' : 'Record Payment';
  String get due => isNe ? 'तिर्न बाँकी' : 'Due';

  // Inventory Lite
  String get addItemStock => isNe ? 'नयाँ सामान दर्ता गर्नुहोस्' : 'Add Item';
  String get stockQuantity => isNe ? 'मौज्दात परिमाण' : 'Current Stock';
  String get costPrice => isNe ? 'खरिद दर' : 'Cost Price';
  String get salePrice => isNe ? 'बिक्री दर' : 'Sale Price';
  String get lowStockThreshold =>
      isNe ? 'न्यून मौज्दात सूचना सीमा' : 'Low-Stock Alert Level';
  String get adjustStock => isNe ? 'स्टक मिलाउनुहोस्' : 'Adjust Stock';

  // Guided Reconciliation
  String get reconciliation =>
      isNe ? 'नगद र बैंक हिसाब मिलान' : 'Cash & Bank Reconciliation';
  String get reconcileIntro => isNe
      ? 'तपाईंको हातमा भएको नगद र बैंक ब्यालेन्स गल्लासँग दाँजेर हिसाब मिलाउनुहोस्।'
      : 'Count your physical cash and enter your bank balance to reconcile with Galla.';
  String get countedCash => isNe ? 'हातमा भएको नगद' : 'Counted Physical Cash';
  String get bankBalance => isNe ? 'बैंक ब्यालेन्स' : 'Bank Balance';
  String get systemExpected => isNe ? 'गल्लाको हिसाब' : 'Galla System Total';
  String get discrepancy => isNe ? 'फरक / अन्तर' : 'Discrepancy';
  String get acceptAdjustment =>
      isNe ? 'फरक रकम समायोजन गर्नुहोस्' : 'Create Adjustment Entry';
  String get noDiscrepancy =>
      isNe ? 'हिसाब ठ्याक्कै मिल्यो!' : 'Perfect Match! No discrepancy.';

  // Multi-Branch Support
  String get branches => isNe ? 'शाखाहरू' : 'Branches';
  String get allBranches => isNe ? 'सबै शाखा' : 'All Branches';
  String get addBranch => isNe ? 'नयाँ शाखा थप्नुहोस्' : 'Add Branch';
  String get branchName => isNe ? 'शाखाको नाम' : 'Branch Name';

  // Staff Roles & Multi-User
  String get staffMembers => isNe ? 'कर्मचारीहरू' : 'Staff Members';
  String get addStaff => isNe ? 'कर्मचारी थप्नुहोस्' : 'Add Staff Member';
  String get staffRole => isNe ? 'भूमिका' : 'Role';
  String get ownerRole =>
      isNe ? 'साहुजी / मालिक (सबै पहुँच)' : 'Owner (Full Access)';
  String get staffRoleSimple =>
      isNe ? 'कर्मचारी (इन्ट्री मात्र)' : 'Staff (Entry Only)';
  String get switchStaffMode =>
      isNe ? 'भूमिका बदल्नुहोस्' : 'Switch Role / Mode';

  // Business Health Score & AI Insights
  String get businessHealth =>
      isNe ? 'व्यापार स्वास्थ्य स्कोर' : 'Business Health Score';
  String get healthGrade => isNe ? 'ग्रेड' : 'Grade';
  String get actionableInsights => isNe ? 'उपयोगी सुझावहरू' : 'Key AI Insights';

  // CSV Exports
  String get exportTransactionsCsv =>
      isNe ? 'कारोबारको CSV' : 'Transactions CSV';

  // ── Redesign vocabulary (consistent merchant terms) ─────────────────────────
  String get typeSale => isNe ? 'बिक्री' : 'Sale';
  String get typeExpense => isNe ? 'खर्च' : 'Expense';
  String get creditGiven => isNe ? 'उधारो दिइयो' : 'Credit given';
  String get creditTaken => isNe ? 'उधारो लिइयो' : 'Credit taken';
  String get writeOff => isNe ? 'माफ गरियो' : 'Write-off';
  String get cashAvailable => isNe ? 'हातमा नगद' : 'Cash available';
  String get sales => isNe ? 'बिक्री' : 'Sales';
  String get expenses => isNe ? 'खर्च' : 'Expenses';
  String get toCollect => isNe ? 'असुल बाँकी' : 'To collect';
  String get youWillReceive => isNe ? 'तपाईंले पाउनुहुने' : 'You will receive';
  String get youWillPay => isNe ? 'तपाईंले तिर्नुपर्ने' : 'You will pay';
  String get people => isNe ? 'जना' : 'people';
  String get suppliers => isNe ? 'सप्लायरहरू' : 'suppliers';
  String get addTransaction => isNe ? 'कारोबार थप्नुहोस्' : 'Add transaction';
  String get speak => isNe ? 'बोल्नुहोस्' : 'Speak';
  String get voiceEntry => isNe ? 'बोलेर लेख्नुहोस्' : 'Voice entry';
  String get today => isNe ? 'आज' : 'Today';
  String get thisWeek => isNe ? 'यो हप्ता' : 'This week';
  String get thisMonth => isNe ? 'यो महिना' : 'This month';
  String get custom => isNe ? 'अरू मिति' : 'Custom';
  String get attention => isNe ? 'ध्यान दिनुहोस्' : 'Needs attention';
  String get todaysActivity => isNe ? 'आजको कारोबार' : "Today's activity";
  String get noTxnsTitle =>
      isNe ? 'अझै कुनै कारोबार छैन' : 'No transactions yet';
  String get noTxnsBody => isNe
      ? 'पहिलो बिक्री वा खर्च थप्नुहोस् — आजको हिसाब सुरु हुन्छ।'
      : "Add your first sale or expense to start today's record.";
  String get receivePayment => isNe ? 'भुक्तानी लिनुहोस्' : 'Receive payment';
  String get payNow => isNe ? 'तिर्नुहोस्' : 'Pay';
  String get giveUdhaar => isNe ? 'उधारो दिनुहोस्' : 'Give udhaar';
  String get takeUdhaar => isNe ? 'उधारो लिनुहोस्' : 'Take udhaar';
  String get remindSent => isNe ? 'सम्झना दिइयो' : 'Marked as reminded';
  String get cancelInvoiceAction =>
      isNe ? 'बिल रद्द गर्नुहोस्' : 'Cancel invoice';
  String get invoiceCancelled => isNe ? 'बिल रद्द भयो' : 'Invoice cancelled';
  String get overdue => isNe ? 'म्याद नाघेको' : 'Overdue';
  String get notEnoughDataChart => isNe
      ? 'चार्ट देखाउन पर्याप्त तथ्याङ्क छैन — तलको जम्मा हेर्नुहोस्।'
      : 'Not enough data for a chart yet — see the totals below.';
  String get undo => isNe ? 'फिर्ता' : 'Undo';
  String get entryAdded => isNe ? 'इन्ट्री थपियो' : 'Entry added';
  String get entryRemoved => isNe ? 'इन्ट्री हटाइयो' : 'Entry removed';
  String get removeEntry => isNe ? 'इन्ट्री हटाउनुहोस्' : 'Remove entry';
  String get saveFailed => isNe
      ? 'सेभ गर्न सकिएन — फेरि प्रयास गर्नुहोस्'
      : "Couldn't save — try again";
  String get recordedJustNow => isNe ? 'भर्खरै' : 'just now';

  // ── Profile & language control ──────────────────────────────────────────────
  String get language => isNe ? 'भाषा' : 'Language';
  String get english => isNe ? 'अंग्रेजी' : 'English';
  String get nepali => 'नेपाली';
  String get alerts => isNe ? 'सूचना र सतर्कता' : 'Alerts & reminders';
  String get paymentReminders =>
      isNe ? 'उधारो सम्झना (ग्राहकलाई)' : 'Udhaar payment reminders';
  String get paymentRemindersSub => isNe
      ? 'बाँकी रकम भएका ग्राहकहरूलाई सम्झना दिनुहोस्'
      : 'Remind customers with outstanding balances';
  String get lowCashAlert => isNe ? 'नगद कम भएको सूचना' : 'Low cash alert';
  String get lowCashAlertSub => isNe
      ? 'दैनिक नगद सीमा मुनि झर्दा जानकारी दिनुहोस्'
      : 'Notify when cash on hand falls below your threshold';
  String get lowStockAlert =>
      isNe ? 'मौज्दात कम भएको सूचना' : 'Low stock alerts';
  String get lowStockAlertSub => isNe
      ? 'सामान सीमा मुनि पुग्दा घरको पृष्ठमा देखाउनुहोस्'
      : 'Show restock items on the home screen';
  String get lowCashThresholdLabel =>
      isNe ? 'न्यूनतम नगद सीमा (ऐच्छिक)' : 'Minimum cash threshold (optional)';
  String get profileUpdated => isNe ? 'प्रोफाइल अपडेट भयो' : 'Profile updated';
}
