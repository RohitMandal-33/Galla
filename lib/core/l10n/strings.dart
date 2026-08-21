class S {
  const S(this.locale);
  final String locale;
  bool get isNe => locale == 'ne';

  String get appName => 'Galla';
  String get welcome1Title =>
      isNe ? 'आएको र गएको पैसा लेख्नुहोस्' : 'Record what comes in and goes out';
  String get welcome1Body => isNe
      ? 'तपाईंको खाता जस्तै — बाँकी हामी गर्छौं।'
      : 'Just like your notebook — we will do the rest.';
  String get welcome2Title => isNe ? 'आजको गल्ला' : "Today's Galla";
  String get welcome2Body => isNe
      ? 'कति आयो, कति गयो, अहिले कति नगद छ — एकै नजरमा।'
      : 'See money in, money out, and cash on hand at a glance.';
  String get welcome3Title => isNe ? 'उधारो नबिर्सिनुहोस्' : 'Never lose track of udhaar';
  String get welcome3Body => isNe
      ? 'कसले तिर्नुपर्छ, तपाईंले कसलाई तिर्नुपर्छ — स्पष्ट भाषामा।'
      : 'Who owes you, and who you owe, in plain language.';
  String get continueLabel => isNe ? 'अगाडि बढ्नुहोस्' : 'Continue';
  String get getStarted => isNe ? 'सुरु गर्नुहोस्' : 'Start recording';
  String get skip => isNe ? 'छोड्नुहोस्' : 'Skip';
  String get moneyIn => isNe ? 'पैसा आयो' : 'Money In';
  String get moneyOut => isNe ? 'पैसा गयो' : 'Money Out';
  String get save => isNe ? 'सेभ गर्नुहोस्' : 'Save';
  String get amount => isNe ? 'रकम' : 'Amount';
  String get cashToday => isNe ? 'आजको नगद' : 'Cash today';
  String get youHave => isNe ? 'तपाईंसँग छ' : 'You have';
  String get netToday => isNe ? 'आजको हिसाब' : "Today's net";
  String get inToday => isNe ? 'आयो' : 'In';
  String get outToday => isNe ? 'गयो' : 'Out';
  String get nothingToday => isNe
      ? 'आज केही लेखिएको छैन — पहिलो इन्ट्री थप्नुहोस्'
      : 'Nothing recorded yet today — add your first entry';
  String get addEntry => isNe ? 'इन्ट्री थप्नुहोस्' : 'Add entry';
  String get gallaTab => isNe ? 'गल्ला' : 'Galla';
  String get ledgerTab => isNe ? 'खाता' : 'Ledger';
  String get reportsTab => isNe ? 'रिपोर्ट' : 'Reports';
  String get businessTab => isNe ? 'व्यवसाय' : 'Business';
  String get parties => isNe ? 'मानिसहरू' : 'People';
  String get history => isNe ? 'इतिहास' : 'History';
  String get search => isNe ? 'खोज्नुहोस्' : 'Search';
  String get udhaar => isNe ? 'उधारो' : 'Udhaar';
  String get addToUdhaar => isNe ? 'उधारोमा राख्नुहोस्' : 'Add to udhaar';
  String get partyHint => isNe ? 'नाम (ऐच्छिक)' : 'Name (optional)';
  String get noteHint => isNe ? 'नोट (ऐच्छिक)' : 'Note (optional)';
  String get categoryHint => isNe ? 'किसिम (ऐच्छिक)' : 'Category (optional)';
  String get theyOweYou => isNe ? 'उहाँले तिर्नुपर्छ' : 'They owe you';
  String get youOweThem => isNe ? 'तपाईंले तिर्नुपर्छ' : 'You owe them';
  String get settled => isNe ? 'हिसाब मिलेको' : 'Settled';
  String get emptyParties => isNe
      ? 'कसले तिर्नुपर्छ र तपाईंले कसलाई तिर्नुपर्छ — उधारो बेच्दा वा किन्दा नाम थप्नुहोस्'
      : 'Track who owes you and who you owe — add someone the next time you record a credit sale or purchase';
  String get emptyLedger => isNe
      ? 'अहिलेसम्म कुनै इन्ट्री छैन। पैसा आएपछि वा गएपछि लेख्नुहोस्।'
      : 'No entries yet. Record money as it comes in or goes out.';
  String get reportsIntro => isNe
      ? 'रिपोर्ट आफैं बन्छ — तपाईंले जम्मा गर्नु पर्दैन।'
      : 'Reports are ready from what you already recorded.';
  String get pnl => isNe ? 'नाफा-नोक्सान' : 'Profit & loss';
  String get cashFlow => isNe ? 'नगद बहाव' : 'Cash flow';
  String get thisWeek => isNe ? 'यो हप्ता' : 'This week';
  String get thisMonth => isNe ? 'यो महिना' : 'This month';
  String get thisYear => isNe ? 'यो वर्ष' : 'This year';
  String get whatsLeft => isNe ? 'बाँकी' : "What's left";
  String get noActivity => isNe
      ? 'यो अवधिमा कुनै कारोबार छैन'
      : 'No activity in this period';
  String get sharePdf => isNe ? 'PDF पठाउनुहोस्' : 'Share PDF';
  String get businessName => isNe ? 'व्यवसायको नाम' : 'Business name';
  String get startingBalance => isNe ? 'सुरुको नगद' : 'Starting cash';
  String get correctCash => isNe ? 'नगद मिलाउनुहोस्' : 'Correct cash on hand';
  String get language => isNe ? 'भाषा' : 'Language';
  String get currency => isNe ? 'मुद्रा' : 'Currency';
  String get taxRate => isNe ? 'कर दर (%)' : 'Tax rate (%)';
  String get appLock => isNe ? 'एप लक' : 'App lock';
  String get reminders => isNe ? 'स्मरण' : 'Reminders';
  String get paymentDue => isNe ? 'उधारो स्मरण' : 'Udhaar reminders';
  String get lowCash => isNe ? 'कम नगद' : 'Low cash alert';
  String get exportData => isNe ? 'डेटा निकाल्नुहोस्' : 'Export data';
  String get deleteAll => isNe ? 'सबै मेट्नुहोस्' : 'Delete all data';
  String get unlock => isNe ? 'खोल्नुहोस्' : 'Unlock';
  String get saved => isNe ? 'सेभ भयो' : 'Saved';
  String get repeatLast => isNe ? 'पछिल्लो दोहोर्याउनुहोस्' : 'Repeat last';
  String get speakOrType => isNe
      ? 'भन्नुहोस् वा लेख्नुहोस्: “हरिलाई ५०० उधारो”'
      : 'Speak or type: “sold 500 to Hari on credit”';
  String get photo => isNe ? 'रसिदको फोटो' : 'Receipt photo';
  String get yesterday => isNe ? 'हिजो' : 'Yesterday';
  String get recordPayment => isNe ? 'भुक्तानी लेख्नुहोस्' : 'Record payment';
  String get markSettled => isNe ? 'मिल्यो भनी चिन्ह लगाउनुहोस्' : 'Mark settled';
  String get sendStatement => isNe ? 'हिसाब पठाउनुहोस्' : 'Send statement';
  String get searchHint => isNe ? 'नाम, रकम वा नोट' : 'Name, amount, or note';
  String get nothingMatched => isNe
      ? 'केही मिलेन — हिज्जे जाँच्नुहोस् वा खोज छोटो पार्नुहोस्'
      : 'Nothing matched — check spelling or broaden the search';
  String get cashOnHandLower => isNe
      ? 'नगद सामान्यभन्दा कम छ'
      : 'Cash on hand is lower than usual today';
  String get optionalSetup => isNe
      ? 'ऐच्छिक — पछि पनि मिलाउन सकिन्छ'
      : 'Optional — you can set this later';
  String get setLater => isNe ? 'पछि मिलाउँछु' : 'Set later';
  String get pin => isNe ? 'पिन' : 'PIN';

  // Version 2 Strings
  // Invoicing & Billing
  String get invoices => isNe ? 'बिलहरू / इन्भोइस' : 'Invoices & Billing';
  String get createInvoice => isNe ? 'नयाँ बिल बनाउनुहोस्' : 'Create Invoice';
  String get invoiceNumber => isNe ? 'बिल नं.' : 'Invoice #';
  String get dueDate => isNe ? 'तिर्ने मिति' : 'Due Date';
  String get lineItems => isNe ? 'सामान / विवरण' : 'Items & Services';
  String get addItem => isNe ? 'सामान थप्नुहोस्' : 'Add Item';
  String get itemDescription => isNe ? 'विवरण' : 'Description';
  String get quantity => isNe ? 'परिमाण' : 'Quantity';
  String get unitPrice => isNe ? 'दर' : 'Unit Price';
  String get subtotal => isNe ? 'उप-जम्मा' : 'Subtotal';
  String get tax => isNe ? 'कर (VAT/Tax)' : 'Tax';
  String get total => isNe ? 'कुल जम्मा' : 'Total';
  String get unpaid => isNe ? 'बाँकी' : 'Unpaid';
  String get paid => isNe ? 'चुक्ता' : 'Paid';
  String get partiallyPaid => isNe ? 'आंशिक चुक्ता' : 'Partially Paid';
  String get emptyInvoices => isNe
      ? 'अहिलेसम्म कुनै बिल छैन — पहिलो बिल १ मिनेटमा बनाउनुहोस्'
      : 'No invoices yet — create your first professional bill in under a minute';
  String get recordInvoicePayment => isNe ? 'बिलको भुक्तानी लिनुहोस्' : 'Record Payment';
  String get due => isNe ? 'तिर्न बाँकी' : 'Due';

  // Inventory Lite
  String get inventory => isNe ? 'स्टक / सामान सूची' : 'Inventory Lite';
  String get addItemStock => isNe ? 'नयाँ सामान दर्ता गर्नुहोस्' : 'Add Item';
  String get stockQuantity => isNe ? 'मौज्दात परिमाण' : 'Current Stock';
  String get costPrice => isNe ? 'खरिद दर' : 'Cost Price';
  String get salePrice => isNe ? 'बिक्री दर' : 'Sale Price';
  String get lowStockThreshold => isNe ? 'न्यून मौज्दात सूचना सीमा' : 'Low-Stock Alert Level';
  String get lowStockAlert => isNe ? 'कम मौज्दात' : 'Low Stock';
  String get adjustStock => isNe ? 'स्टक मिलाउनुहोस्' : 'Adjust Stock';
  String get emptyInventory => isNe
      ? 'कुनै सामान दर्ता गरिएको छैन — मौज्दात ट्र्याक गर्न सामान थप्नुहोस्'
      : 'No items in inventory — add products you sell to track stock automatically';
  String get totalInventoryValue => isNe ? 'कुल स्टक मूल्य' : 'Total Stock Value';

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
  String get staffRestrictedNotice => isNe
      ? 'कर्मचारी मोडमा रिपोर्ट र सेटिङ हेर्न साहुजीको पिन चाहिन्छ।'
      : 'Reports & settings are restricted in Staff Mode. Enter Owner PIN to unlock.';

  // Business Health Score & AI Insights
  String get businessHealth => isNe ? 'व्यापार स्वास्थ्य स्कोर' : 'Business Health Score';
  String get healthGrade => isNe ? 'ग्रेड' : 'Grade';
  String get actionableInsights => isNe ? 'उपयोगी सुझावहरू' : 'Key AI Insights';
  String get netMargin => isNe ? 'नाफा दर' : 'Net Margin';
  String get cashStability => isNe ? 'नगद स्थिरता' : 'Cash Flow Stability';
  String get udhaarRecovery => isNe ? 'उधारो असुली' : 'Udhaar Recovery Rate';

  // CSV Exports
  String get exportCsv => isNe ? 'CSV (Excel) निकाल्नुहोस्' : 'Export CSV (Excel)';
  String get exportTransactionsCsv => isNe ? 'कारोबारको CSV' : 'Transactions CSV';
  String get exportInvoicesCsv => isNe ? 'बिलहरूको CSV' : 'Invoices CSV';
}
