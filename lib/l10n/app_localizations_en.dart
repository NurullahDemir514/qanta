// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Qanta';

  @override
  String get welcome => 'Welcome';

  @override
  String get getStarted => 'Get Started';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Turkish';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Your Name';

  @override
  String get signUp => 'Sign Up';

  @override
  String get forgotPassword => 'I forgot my password, what should I do?';

  @override
  String get budget => 'Budget';

  @override
  String get expenses => 'Expenses';

  @override
  String get income => 'Income';

  @override
  String get investments => 'Investments';

  @override
  String get analytics => 'Analytics';

  @override
  String get balance => 'Balance';

  @override
  String get onboardingDescription =>
      'Your personal finance app. Track expenses, manage cards, monitor stocks, and set budgets.';

  @override
  String get welcomeSubtitle => 'Take control of your finances today!';

  @override
  String get budgetSubtitle => 'Track your spending';

  @override
  String get investmentsSubtitle => 'Grow your wealth';

  @override
  String get analyticsSubtitle => 'Financial insights';

  @override
  String get settingsSubtitle => 'Customize your app';

  @override
  String get appSlogan => 'Manage your money smartly';

  @override
  String greetingHello(String name) {
    return 'Hello, $name!';
  }

  @override
  String get homeMainTitle => 'Ready to reach your financial goals?';

  @override
  String get homeSubtitle => 'Manage your money smartly and plan your future';

  @override
  String get defaultUserName => 'User';

  @override
  String get nameRequired => 'Your name is required';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Please enter a valid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get confirmPasswordRequired => 'Password confirmation is required';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get loginSubtitle => 'Sign in to your account';

  @override
  String get createAccount => 'Create Account';

  @override
  String get registerSubtitle => 'Join Qanta and start managing your money';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get pageNotFoundDescription =>
      'The page you are looking for does not exist.';

  @override
  String get goHome => 'Go Home';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get loginError => 'Login error';

  @override
  String get registerError => 'Registration error';

  @override
  String get emailNotConfirmed =>
      'You need to verify your email address. Please check your email.';

  @override
  String get invalidCredentials =>
      'Invalid email or password. Please try again.';

  @override
  String get tooManyRequests => 'Too many attempts. Please try again later.';

  @override
  String get invalidEmailAddress =>
      'Invalid email address. Please enter a valid email.';

  @override
  String get passwordTooShortError =>
      'Password is too short. Must be at least 6 characters.';

  @override
  String get userAlreadyRegistered =>
      'This email is already registered. Try signing in.';

  @override
  String get signupDisabled =>
      'Registration is currently disabled. Please try again later.';

  @override
  String registrationSuccessful(String name) {
    return 'Registration successful! Welcome $name!';
  }

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get totalPortfolio => 'Total Portfolio';

  @override
  String get allAccounts => 'All your accounts';

  @override
  String get availableBalance => 'Available Balance';

  @override
  String get thisMonthIncome => 'This Month Income';

  @override
  String get thisMonthExpense => 'This Month Expense';

  @override
  String get myCards => 'My Cards';

  @override
  String get manageYourCards => 'Manage your cards';

  @override
  String get seeAll => 'See All';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get thisMonthSummary => 'This Month Summary';

  @override
  String get savings => 'SAVINGS';

  @override
  String get budgetUsed => 'Used';

  @override
  String get remaining => 'Remaining:';

  @override
  String get installment => 'Installment';

  @override
  String get categoryHint => 'coffee, market, fuel...';

  @override
  String get noBudgetDefined => 'No budget defined yet';

  @override
  String get createBudgetDescription =>
      'Create a budget to track your spending limits';

  @override
  String get createBudget => 'Create Budget';

  @override
  String get expenseLimitTracking => 'Expense Limit Tracking';

  @override
  String get manage => 'Manage';

  @override
  String get thisMonthGrowth => 'this month';

  @override
  String get cardHolder => 'CARD HOLDER';

  @override
  String get expiryDate => 'VALID THRU';

  @override
  String get qantaDebit => 'Qanta Debit';

  @override
  String get checkingAccount => 'Checking Account';

  @override
  String get qantaCredit => 'Qanta Credit';

  @override
  String get qantaSavings => 'Qanta Savings';

  @override
  String get goodMorning => 'Good Morning! ☀️';

  @override
  String get goodAfternoon => 'Good Afternoon! 🌤️';

  @override
  String get goodEvening => 'Good Evening!';

  @override
  String get goodNight => 'Good Night! 🌙';

  @override
  String get currency => 'Currency';

  @override
  String get currencyTRY => 'Turkish Lira (₺)';

  @override
  String get currencyUSD => 'US Dollar (\$)';

  @override
  String get currencyEUR => 'Euro (€)';

  @override
  String get currencyGBP => 'British Pound (£)';

  @override
  String get selectCurrency => 'Select Currency';

  @override
  String get selectCurrencyDescription =>
      'Which currency would you like to use?';

  @override
  String get debit => 'Add Debit Card';

  @override
  String get credit => 'Add Credit Card';

  @override
  String get profile => 'Profile';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get preferences => 'Preferences';

  @override
  String get security => 'Security';

  @override
  String get support => 'Support';

  @override
  String get about => 'About';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get privacy => 'Privacy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get version => 'Version';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get changePassword => 'Change Password';

  @override
  String get biometricAuth => 'Biometric Authentication';

  @override
  String get transactions => 'Transactions';

  @override
  String get goals => 'Goals';

  @override
  String get upcomingPayments => 'Upcoming Payments';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get cardInfo => 'Card Information';

  @override
  String get cardType => 'Card Type';

  @override
  String get cardNumber => 'Card Number';

  @override
  String get expiryDateShort => 'Expiry Date';

  @override
  String get status => 'Status';

  @override
  String get active => 'Active';

  @override
  String get balanceInfo => 'Balance Information';

  @override
  String get creditLimit => 'Credit Limit';

  @override
  String get usedLimit => 'Used Limit';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get sendMoney => 'Send Money';

  @override
  String get loadMoney => 'Load Money';

  @override
  String get freezeCard => 'Freeze Card';

  @override
  String get cardSettings => 'Card Settings';

  @override
  String get addNewCard => 'Add New Card';

  @override
  String get addNewCardFeature => 'Add new card feature coming soon!';

  @override
  String get cardManagement => 'Card Management';

  @override
  String get securitySettings => 'Security Settings';

  @override
  String get securitySettingsDesc => 'PIN, limits and security settings';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get notificationSettingsDesc => 'Transaction notifications and alerts';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get transactionHistoryDesc => 'All cards transaction history';

  @override
  String get qantaWallet => 'Qanta Wallet';

  @override
  String get qantaDebitCard => 'Qanta Debit';

  @override
  String get bankTransfer => 'Bank Transfer';

  @override
  String get iban => 'IBAN';

  @override
  String get recommended => 'RECOMMENDED';

  @override
  String get urgent => 'Urgent';

  @override
  String get amount => 'Amount';

  @override
  String get dueDate => 'Due Date';

  @override
  String get setReminder => 'Set Reminder';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get reminderSetup => 'Reminder setup opening...';

  @override
  String get paymentHistoryOpening => 'Payment history opening...';

  @override
  String get sendMoneyOpening => 'Send Money opening...';

  @override
  String get loadMoneyOpening => 'Load Money opening...';

  @override
  String get freezeCardOpening => 'Freeze Card opening...';

  @override
  String get cardSettingsOpening => 'Card Settings opening...';

  @override
  String get securitySettingsOpening => 'Security Settings opening...';

  @override
  String get notificationSettingsOpening => 'Notification Settings opening...';

  @override
  String get transactionHistoryOpening => 'Opening transaction history...';

  @override
  String paymentProcessing(String method) {
    return 'Processing payment with $method...';
  }

  @override
  String get allAccountsTotal => 'Total of all your accounts';

  @override
  String get accountBreakdown => 'Account Breakdown';

  @override
  String get creditCard => 'Credit Card';

  @override
  String get savingsAccount => 'Savings Account';

  @override
  String get cashAccount => 'Cash Account';

  @override
  String get monthlySummary => 'Monthly Summary';

  @override
  String get cashBalance => 'Cash Balance';

  @override
  String get addCashBalance => 'Add Cash Balance';

  @override
  String get enterCashAmount => 'Enter Cash Amount';

  @override
  String get cashAmount => 'Cash Amount';

  @override
  String get addCash => 'Add Cash';

  @override
  String get cancel => 'Cancel';

  @override
  String cashAdded(String amount) {
    return 'Cash balance added: $amount';
  }

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get enterValidAmount => 'Please enter a valid amount';

  @override
  String get cash => 'Cash';

  @override
  String get digitalWallet => 'Digital Wallet';

  @override
  String get all => 'All';

  @override
  String get cashManagement => 'Cash Management';

  @override
  String get addCashHistory => 'Add Cash History';

  @override
  String get addCashHistoryDesc => 'View your cash addition transactions';

  @override
  String get cashLimits => 'Cash Limits';

  @override
  String get cashLimitsDesc => 'Set daily and monthly cash limits';

  @override
  String get debitCardManagement => 'Debit Card Management';

  @override
  String get cardLimits => 'Card Limits';

  @override
  String get cardLimitsDesc => 'Set daily spending and withdrawal limits';

  @override
  String get atmLocations => 'ATM Locations';

  @override
  String get atmLocationsDesc => 'Find nearby ATMs';

  @override
  String get creditCardManagement => 'Credit Card Management';

  @override
  String get creditLimitDesc => 'View your credit limit and request increase';

  @override
  String get installmentOptions => 'Installment Options';

  @override
  String get installmentOptionsDesc => 'Convert your purchases to installments';

  @override
  String get savingsManagement => 'Savings Management';

  @override
  String get savingsGoals => 'Savings Goals';

  @override
  String get savingsGoalsDesc => 'Set and track your savings goals';

  @override
  String get autoSave => 'Auto Save';

  @override
  String get autoSaveDesc => 'Create automatic saving rules';

  @override
  String get opening => 'opening...';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get close => 'Close';

  @override
  String get selectTransactionType =>
      'Select the type of transaction you want to make';

  @override
  String get selectTransactionTypeDesc =>
      'What type of transaction would you like to make?';

  @override
  String expenseSaved(String amount) {
    return 'Expense saved: $amount';
  }

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get enterAmount => 'Enter Amount';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get details => 'Details';

  @override
  String get amountRequired => 'Amount is required';

  @override
  String get enterValidAmountMessage => 'Please enter a valid amount';

  @override
  String get selectCategoryMessage => 'Please select a category';

  @override
  String get selectPaymentMethodMessage => 'Please select a payment method';

  @override
  String get saveExpense => 'Save Expense';

  @override
  String get continueButton => 'Continue';

  @override
  String get lastCheckAndDetails => 'Final review and details';

  @override
  String get summary => 'Summary';

  @override
  String get category => 'Category';

  @override
  String get payment => 'Payment';

  @override
  String get date => 'Date';

  @override
  String get description => 'Description';

  @override
  String get card => 'Card';

  @override
  String get cashPayment => 'Full Payment';

  @override
  String installments(int count) {
    return '$count Installments';
  }

  @override
  String get foodAndDrink => 'Food & Drink';

  @override
  String get transport => 'Transport';

  @override
  String get shopping => 'Shopping';

  @override
  String get entertainment => 'Entertainment';

  @override
  String get bills => 'Bills';

  @override
  String get health => 'Health';

  @override
  String get education => 'Education';

  @override
  String get other => 'Other';

  @override
  String get incomeType => 'Income';

  @override
  String get expenseType => 'Expense';

  @override
  String get transferType => 'Transfer';

  @override
  String get investmentType => 'Investment Type';

  @override
  String get incomeDescription => 'Salary, bonus, sales income';

  @override
  String get expenseDescription => 'Shopping, bills, expenses';

  @override
  String get transferDescription => 'Transfer between accounts';

  @override
  String get investmentDescription => 'Stocks, crypto, gold';

  @override
  String get recurringType => 'Recurring Payments';

  @override
  String get recurringDescription => 'Netflix, bills, subscriptions';

  @override
  String get selectFrequency => 'Select Frequency';

  @override
  String get saveRecurring => 'Save Recurring Payment';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get quarterly => 'Quarterly';

  @override
  String get yearly => 'Yearly';

  @override
  String get weeklyDescription => 'Repeats every week';

  @override
  String get monthlyDescription => 'Repeats every month';

  @override
  String get quarterlyDescription => 'Repeats every 3 months';

  @override
  String get yearlyDescription => 'Repeats every year';

  @override
  String get subscription => 'Subscription';

  @override
  String get utilities => 'Utilities';

  @override
  String get insurance => 'Insurance';

  @override
  String get rent => 'Rent';

  @override
  String get loan => 'Loan';

  @override
  String get subscriptionDescription => 'Netflix, Spotify, YouTube';

  @override
  String get utilitiesDescription => 'Electricity, water, gas';

  @override
  String get insuranceDescription => 'Health, auto, home insurance';

  @override
  String get rentDescription => 'House rent, office rent';

  @override
  String get loanDescription => 'Credit card, installments';

  @override
  String get otherDescription => 'Other recurring payments';

  @override
  String get next => 'Next';

  @override
  String get save => 'Save';

  @override
  String get incomeFormOpening => 'Income form will open';

  @override
  String get transferFormOpening => 'Transfer form will open';

  @override
  String get investmentFormOpening => 'Investment form will open';

  @override
  String get howMuchSpent => 'How much did you spend?';

  @override
  String get whichCategorySpent => 'Which category did you spend in?';

  @override
  String get howDidYouPay => 'How did you pay?';

  @override
  String get saveIncome => 'Save Income';

  @override
  String get food => 'Food';

  @override
  String get foodDescription => 'Restaurant, grocery, coffee';

  @override
  String get transportDescription => 'Taxi, bus, fuel';

  @override
  String get shoppingDescription => 'Clothing, electronics, home';

  @override
  String get billsDescription => 'Electricity, water, internet';

  @override
  String get entertainmentDescription => 'Cinema, concert, games';

  @override
  String get healthDescription => 'Doctor, pharmacy, sports';

  @override
  String get educationDescription => 'Course, books, school';

  @override
  String get travel => 'Travel';

  @override
  String get travelDescription => 'Vacation, flight, hotel';

  @override
  String get howMuchEarned => 'How much did you earn?';

  @override
  String get whichCategoryEarned => 'Which category did you earn in?';

  @override
  String get howDidYouReceive => 'How did you receive it?';

  @override
  String incomeSaved(String amount) {
    return 'Income saved: $amount';
  }

  @override
  String get salary => 'Salary';

  @override
  String get salaryDescription => 'Monthly salary, wage';

  @override
  String get bonus => 'Bonus';

  @override
  String get bonusDescription => 'Bonus, incentive, reward';

  @override
  String get freelance => 'Freelance';

  @override
  String get freelanceDescription => 'Freelance work, project';

  @override
  String get business => 'Business';

  @override
  String get businessDescription => 'Business income, trade';

  @override
  String get rental => 'Rental';

  @override
  String get rentalDescription => 'House rent, car rental';

  @override
  String get gift => 'Gift';

  @override
  String get giftDescription => 'Gift, donation, allowance';

  @override
  String get saveTransfer => 'Save Transfer';

  @override
  String get howMuchInvest => 'How Much Will You Invest?';

  @override
  String get whichInvestmentType => 'Which Investment Type?';

  @override
  String get stocks => 'Stocks';

  @override
  String get stocksDescription => 'Stock market, shares';

  @override
  String get crypto => 'Cryptocurrency';

  @override
  String get cryptoDescription => 'Bitcoin, Ethereum, altcoin';

  @override
  String get gold => 'Gold';

  @override
  String get goldDescription => 'Gold bars, gold coins';

  @override
  String get bonds => 'Bonds';

  @override
  String get bondsDescription => 'Government bonds, corporate bonds';

  @override
  String get funds => 'Funds';

  @override
  String get fundsDescription => 'Mutual funds, pension funds';

  @override
  String get forex => 'Forex';

  @override
  String get forexDescription => 'USD, EUR, GBP';

  @override
  String get realEstate => 'Real Estate';

  @override
  String get realEstateDescription => 'House, land, shop';

  @override
  String get saveInvestment => 'Save Investment';

  @override
  String investmentSaved(String amount) {
    return 'Investment saved: $amount';
  }

  @override
  String get selectInvestmentTypeMessage => 'Please select investment type';

  @override
  String get quantityRequired => 'Quantity required';

  @override
  String get enterValidQuantity => 'Enter a valid quantity';

  @override
  String get rateRequired => 'Rate is required';

  @override
  String get enterValidRate => 'Please enter a valid rate';

  @override
  String get quantity => 'Quantity';

  @override
  String get rate => 'Rate';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get onboardingFeaturesTitle => 'What Can You Do with Qanta?';

  @override
  String get expenseTrackingTitle => 'Expense Tracking';

  @override
  String get expenseTrackingDesc => 'Easily track your daily expenses';

  @override
  String get smartSavingsTitle => 'Smart Savings';

  @override
  String get smartSavingsDesc => 'Save money to reach your goals';

  @override
  String get financialAnalysisTitle => 'Financial Analysis';

  @override
  String get financialAnalysisDesc => 'Analyze your spending habits';

  @override
  String get cardManagementTitle => 'Card Management';

  @override
  String get cardManagementDesc =>
      'Manage credit cards, debit cards and cash accounts';

  @override
  String get stockTrackingTitle => 'Stock Tracking';

  @override
  String get stockTrackingDesc => 'Track your stock portfolio and investments';

  @override
  String get budgetManagementTitle => 'Budget Management';

  @override
  String get budgetManagementDesc =>
      'Set budgets and track your spending limits';

  @override
  String get aiInsightsTitle => 'AI Insights';

  @override
  String get aiInsightsDesc =>
      'Get smart financial recommendations and insights';

  @override
  String get expenseTrackingDescShort =>
      'Record and categorize your daily expenses with detailed tracking';

  @override
  String get cardManagementDescShort =>
      'Manage credit cards, debit cards and cash accounts in one place';

  @override
  String get stockTrackingDescShort =>
      'Monitor your stock portfolio with real-time prices and performance';

  @override
  String get financialAnalysisDescShort =>
      'Analyze spending patterns and financial trends';

  @override
  String get budgetManagementDescShort =>
      'Set monthly budgets and track your spending limits';

  @override
  String get aiInsightsDescShort =>
      'Get personalized financial recommendations and insights';

  @override
  String get languageSelectionTitle => 'Language Selection';

  @override
  String get languageSelectionDesc =>
      'Which language would you like to use the app in?';

  @override
  String get themeSelectionTitle => 'Theme Selection';

  @override
  String get themeSelectionDesc => 'Which theme do you prefer?';

  @override
  String get lightThemeTitle => 'Light Theme';

  @override
  String get lightThemeDesc => 'Classic white theme';

  @override
  String get darkThemeTitle => 'Dark Theme';

  @override
  String get darkThemeDesc => 'Easy on your eyes';

  @override
  String get exitOnboarding => 'Exit';

  @override
  String get exitOnboardingMessage =>
      'Are you sure you want to exit without completing the onboarding?';

  @override
  String get exitCancel => 'Cancel';

  @override
  String get back => 'Back';

  @override
  String get updateCashBalance => 'Update Cash Balance';

  @override
  String get updateCashBalanceDesc => 'Enter your current cash amount';

  @override
  String get updateCashBalanceTitle => 'Update Cash Balance';

  @override
  String get updateCashBalanceMessage => 'Enter your current cash amount:';

  @override
  String get newBalance => 'New Balance';

  @override
  String get update => 'Update';

  @override
  String cashBalanceUpdated(String amount) {
    return 'Cash balance updated to $amount';
  }

  @override
  String get cashAccountLoadError => 'Error loading cash account';

  @override
  String unknownError(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get noCashTransactions => 'No cash transactions yet';

  @override
  String get noCashTransactionsDesc =>
      'Your first cash transaction will appear here';

  @override
  String get balanceUpdated => 'Cash Added';

  @override
  String get walletBalanceUpdated => 'Manual cash addition';

  @override
  String get groceryShopping => 'Grocery Shopping';

  @override
  String get cashPaymentMade => 'Cash payment';

  @override
  String get taxiFare => 'Taxi Fare';

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get cardDetails => 'Card Details';

  @override
  String get time => 'Time';

  @override
  String get transactionType => 'Transaction Type';

  @override
  String get merchant => 'Merchant';

  @override
  String installmentInfo(int current, int total) {
    return '$current/$total Installments';
  }

  @override
  String get availableLimit => 'Available Limit';

  @override
  String get howMuchTransfer => 'How much will you transfer?';

  @override
  String get fromWhichAccount => 'From which account?';

  @override
  String get toWhichAccount => 'To which account?';

  @override
  String get investmentIncome => 'Investment Income';

  @override
  String get investmentIncomeDescription => 'Stocks, funds, rental income';

  @override
  String get silver => 'Silver';

  @override
  String get usd => 'USD';

  @override
  String get eur => 'EUR';

  @override
  String get goldUnit => 'gram';

  @override
  String get silverUnit => 'gram';

  @override
  String get usdUnit => 'unit';

  @override
  String get eurUnit => 'unit';

  @override
  String get silverDescription => 'Silver investment';

  @override
  String get usdDescription => 'US Dollar';

  @override
  String get eurDescription => 'Euro currency';

  @override
  String get selectInvestmentType => 'Select Investment Type';

  @override
  String get investment => 'Investment';

  @override
  String get otherIncome => 'Other Income';

  @override
  String get recurringPayment => 'Recurring Payment';

  @override
  String get saveRecurringPayment => 'Save Recurring Payment';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get noTransactionsDescription =>
      'Tap the + button to add your first transaction';

  @override
  String get noSearchResults => 'No search results found';

  @override
  String noSearchResultsDescription(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get transactionsLoadError => 'Failed to load transactions';

  @override
  String get connectionError => 'Connection problem occurred';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noAccountsAvailable => 'No accounts available';

  @override
  String get debitCard => 'Debit Card';

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get monthlyOverview => 'Monthly Overview';

  @override
  String get totalIncome => 'Total Income';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get netBalance => 'Net Balance';

  @override
  String get categoryBreakdown => 'Category Breakdown';

  @override
  String get spendingTrends => 'Spending Trends';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get last3Months => 'Last 3 Months';

  @override
  String get last6Months => 'Last 6 Months';

  @override
  String get yearToDate => 'Year to Date';

  @override
  String get noDataAvailable => 'No Data Available';

  @override
  String get noTransactionsFound => 'No transactions found';

  @override
  String get averageSpending => 'Average Spending';

  @override
  String get highestSpending => 'Highest Spending';

  @override
  String get lowestSpending => 'Lowest Spending';

  @override
  String get savingsRate => 'Savings Rate';

  @override
  String get smartInsights => 'Smart Insights';

  @override
  String get visualAnalytics => 'Visual Analytics';

  @override
  String get categoryAnalysis => 'Category Analysis';

  @override
  String get financialHealthScore => 'Financial Health Score';

  @override
  String get spendingTrend => 'Spending Trend';

  @override
  String get viewAll => 'View All';

  @override
  String get noDataYet => 'No data to analyze yet';

  @override
  String get addFirstTransaction => 'Add your first expense to get started';

  @override
  String get analyzingData => 'Analyzing your financial data...';

  @override
  String get pleaseWait => 'This may take a few seconds';

  @override
  String get dataLoadError => 'Error loading data';

  @override
  String get excellent => 'Excellent';

  @override
  String get good => 'Good';

  @override
  String get average => 'Average';

  @override
  String get needsImprovement => 'Needs Improvement';

  @override
  String get dailyAverage => 'Daily Average';

  @override
  String get moreCategories => 'more categories';

  @override
  String get netWorth => 'Total Assets';

  @override
  String get welcomeToQanta => 'Welcome to Qanta!';

  @override
  String get startYourFinancialJourney =>
      'Take the first step to start your financial journey';

  @override
  String get addFirstIncome => 'Add First Income';

  @override
  String get addCard => 'Add Card';

  @override
  String get tipTrackYourExpenses =>
      'Track your expenses to reach your financial goals';

  @override
  String get positive => 'Positive';

  @override
  String get negative => 'Negative';

  @override
  String get totalAssets => 'Total Assets';

  @override
  String get totalDebts => 'Total Debts';

  @override
  String get availableCredit => 'Available Credit';

  @override
  String get netAmount => 'Net';

  @override
  String get transactionCount => 'Transactions';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get deletePhoto => 'Delete Photo';

  @override
  String photoUploadError(String error) {
    return 'Error uploading photo: $error';
  }

  @override
  String photoDeleteError(String error) {
    return 'Error deleting photo: $error';
  }

  @override
  String get fileNotFound => 'File not found';

  @override
  String get fileTooLarge => 'File too large (max 5MB)';

  @override
  String get userSessionNotFound => 'User session not found';

  @override
  String get photoDeletedSuccessfully => 'Photo deleted successfully';

  @override
  String get photoUploadedSuccessfully => 'Photo uploaded successfully';

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get selectImageSourceDescription =>
      'Where would you like to select your photo from?';

  @override
  String get uploadingPhoto => 'Uploading photo...';

  @override
  String get deletingPhoto => 'Deleting photo...';

  @override
  String get profilePhoto => 'Profile Photo';

  @override
  String get changeProfilePhoto => 'Change Profile Photo';

  @override
  String get removeProfilePhoto => 'Remove Profile Photo';

  @override
  String get profilePhotoUpdated => 'Profile photo updated';

  @override
  String get profilePhotoRemoved => 'Profile photo removed';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String deleteTransactionConfirm(String description) {
    return 'transaction. Are you sure you want to delete it?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String transactionDeleteError(String error) {
    return 'Error deleting transaction: $error';
  }

  @override
  String get deleteInstallmentTransaction => 'Delete Installment Transaction';

  @override
  String deleteInstallmentTransactionConfirm(String description) {
    return 'Are you sure you want to completely delete the installment transaction $description? This will delete all installments.';
  }

  @override
  String get installmentTransactionDeleted =>
      'Installment transaction deleted, total amount refunded';

  @override
  String installmentTransactionDeleteError(String error) {
    return 'Error deleting installment transaction: $error';
  }

  @override
  String get deleteAll => 'Delete All';

  @override
  String get deleteLimit => 'Delete Limit';

  @override
  String deleteLimitConfirm(String categoryName) {
    return 'Are you sure you want to delete the limit set for $categoryName category?';
  }

  @override
  String get limitDeleted => 'Limit deleted';

  @override
  String get deleteLimitTooltip => 'Delete Limit';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingPastStatements => 'Loading past statements...';

  @override
  String get loadingFutureStatements => 'Loading future statements...';

  @override
  String get loadingCards => 'Error loading cards';

  @override
  String get loadingAccounts => 'Loading accounts';

  @override
  String get loadingStatementInfo => 'Error loading statement information';

  @override
  String get paymentError => 'Error occurred during payment';

  @override
  String get statementMarkError => 'Error marking statement';

  @override
  String get deleteCard => 'Delete Card';

  @override
  String deleteCardConfirm(String cardName) {
    return 'Are you sure you want to delete $cardName card?\n\nThis action cannot be undone.';
  }

  @override
  String get cardDeleted => 'Card deleted successfully';

  @override
  String get cardDeleteError => 'Error deleting card';

  @override
  String transactionAddError(String error) {
    return 'Error adding transaction: $error';
  }

  @override
  String updateError(String error) {
    return 'Error during update: $error';
  }

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get installmentTransactionDeleting =>
      'Deleting installment transaction...';

  @override
  String get installmentTransactionDeletedWithRefund =>
      'Installment transaction deleted, total amount refunded';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get quickNotes => 'Quick Notes';

  @override
  String get quickNotesSubtitle =>
      'Persistent notification for instant note taking';

  @override
  String get quickNotesNotificationEnabled =>
      'Quick notes notification enabled';

  @override
  String get quickNotesNotificationDisabled =>
      'Quick notes notification disabled';

  @override
  String get notificationPermissionRequired =>
      'Notification permission required! Please enable it in settings.';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get account => 'Account';

  @override
  String get now => 'Now';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get expense => 'Expense';

  @override
  String get transfer => 'Transfer';

  @override
  String get today => 'Today';

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String weeksAgo(int count) {
    return '$count weeks ago';
  }

  @override
  String monthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String yearsAgo(int count) {
    return '$count years ago';
  }

  @override
  String get oneMinuteAgo => '1 min ago';

  @override
  String get oneHourAgo => '1 hour ago';

  @override
  String get oneWeekAgo => '1 week ago';

  @override
  String get oneMonthAgo => '1 month ago';

  @override
  String get oneYearAgo => '1 year ago';

  @override
  String get twoDaysAgo => '2 days ago';

  @override
  String get perMonth => '/ month';

  @override
  String get net => 'Net';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get pleaseSelectSourceAccount => 'Please select source account';

  @override
  String get pleaseSelectTargetAccount => 'Please select target account';

  @override
  String get sourceAndTargetSame =>
      'Source and target account cannot be the same';

  @override
  String get accountInfoNotFound =>
      'Account information could not be retrieved';

  @override
  String get accountInfoNotFoundSingle =>
      'Account information could not be retrieved';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get pleaseSelectPaymentMethod => 'Please select a payment method';

  @override
  String get cardsLoadingError => 'Error loading cards';

  @override
  String get noCardsAddedYet => 'No cards added yet';

  @override
  String get transaction => 'Transaction';

  @override
  String get noTransactionsForThisDay => 'No transactions for this day';

  @override
  String get cashWallet => 'Cash Wallet';

  @override
  String get bankName => 'Qanta';

  @override
  String get repeatsEveryWeek => 'Repeats every week';

  @override
  String get repeatsEveryMonth => 'Repeats every month';

  @override
  String get repeatsEveryQuarter => 'Repeats every quarter';

  @override
  String get repeatsEveryYear => 'Repeats every year';

  @override
  String get otherFixedPayments => 'Other fixed payments';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisYear => 'This Year';

  @override
  String get lastYear => 'Last Year';

  @override
  String get custom => 'Custom';

  @override
  String get searchTransactions => 'Search Transactions';

  @override
  String get filterByType => 'Filter by Type';

  @override
  String get filterByPeriod => 'Filter by Period';

  @override
  String get filterByCategory => 'Filter by Category';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get tryDifferentSearch => 'Try a different search';

  @override
  String get noNotesYet => 'No notes yet';

  @override
  String get addExpenseIncomeNotes => 'Add your expense or income notes here';

  @override
  String get justNow => 'Just now';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get textNote => 'Text Note';

  @override
  String get addQuickTextNote => 'Add quick text note';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get takePhotoFromCamera => 'Take photo from camera';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get selectPhotoFromGallery => 'Select photo from gallery';

  @override
  String get photoCaptureError => 'Error capturing photo';

  @override
  String get photoSelectionError => 'Error selecting photo';

  @override
  String get add => 'Add';

  @override
  String get photoNote => 'Photo note';

  @override
  String get photoNoteAdded => 'Photo note added';

  @override
  String get photoNoteAddError => 'Error adding photo note';

  @override
  String get noteAdded => 'Note added';

  @override
  String get noteAddError => 'Error adding note';

  @override
  String get noteDeleted => 'Note deleted';

  @override
  String get noteDeleteError => 'Error deleting note';

  @override
  String get noConvertedNotesYet => 'No notes converted to transactions yet';

  @override
  String get stop => 'Stop';

  @override
  String get send => 'Send';

  @override
  String get processed => 'Processed';

  @override
  String get newest => 'Newest';

  @override
  String get oldest => 'Oldest';

  @override
  String get highestToLowest => 'Highest to Lowest';

  @override
  String get lowestToHighest => 'Lowest to Highest';

  @override
  String get alphabetical => 'A-Z';

  @override
  String get more => 'More';

  @override
  String get less => 'Less';

  @override
  String get cardName => 'Card Name';

  @override
  String get usage => 'Usage';

  @override
  String get lastPayment => 'Last Payment';

  @override
  String get nextPayment => 'Next Payment';

  @override
  String get minimumPayment => 'Minimum Payment';

  @override
  String get totalDebt => 'Total Debt';

  @override
  String get noTransactionsForThisCard => 'No transactions found for this card';

  @override
  String get statementSuccessfullyPaid =>
      'Statement successfully marked as paid';

  @override
  String get bank => 'Bank';

  @override
  String get cardNameRequired => 'Card name is required';

  @override
  String get creditLimitRequired => 'Credit limit is required';

  @override
  String get debt => 'Debt';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get usageRate => 'Usage Rate';

  @override
  String get statementDay => 'Statement Day';

  @override
  String get creditCardInfo => 'Credit Card Info';

  @override
  String get installmentDetailsLoadError =>
      'Installment details could not be loaded';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get passwordMinLengthInfo =>
      'Your password must be at least 6 characters long.';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get wrongCurrentPassword => 'Current password is incorrect';

  @override
  String get passwordTooWeak => 'Password is too weak';

  @override
  String get requiresRecentLogin =>
      'Please log in again to change your password';

  @override
  String get passwordChangeFailed => 'Password change failed';

  @override
  String get ok => 'OK';

  @override
  String get collectedInformation => 'Collected Information';

  @override
  String get collectedInformationContent =>
      'The Qanta application collects the following information to provide you with better service:\n\n• Account information (email, name-surname)\n• Financial transaction data (income, expense, transfer records)\n• Card and account information\n• Budget and category preferences\n• Application usage statistics';

  @override
  String get informationUsage => 'Information Usage';

  @override
  String get informationUsageContent =>
      'The collected information is used for the following purposes:\n\n• Providing personal finance management services\n• Budget tracking and expense analysis\n• Improving application performance\n• Security and fraud prevention\n• Fulfilling legal obligations';

  @override
  String get dataSecurity => 'Data Security';

  @override
  String get dataSecurityContent =>
      'The security of your data is our priority:\n\n• All data is stored encrypted\n• Hosted on secure servers\n• Regular security updates are made\n• Protected against unauthorized access\n• Industry-standard security measures are taken';

  @override
  String get dataSharing => 'Data Sharing';

  @override
  String get dataSharingContent =>
      'Your personal data is not shared with third parties except in the following cases:\n\n• Legal obligations\n• In case of security breaches\n• With your explicit consent\n• Limited sharing with service providers (anonymous)';

  @override
  String get userRights => 'User Rights';

  @override
  String get userRightsContent =>
      'Your rights under GDPR:\n\n• Learning whether your personal data is processed\n• Requesting access to your data\n• Requesting correction of incorrect information\n• Requesting deletion of data\n• Completely closing your account';

  @override
  String get contact => 'Contact';

  @override
  String get contactContent =>
      'For questions about the privacy policy:\n\nEmail: privacy@qanta.app\nAddress: Istanbul, Turkey\n\nThis policy was last updated: January 20, 2025';

  @override
  String get supportAndContact => 'Support & Contact';

  @override
  String get phone => 'Phone';

  @override
  String get liveSupport => 'Live Support';

  @override
  String get liveSupportHours => 'Monday-Friday 09:00-18:00';

  @override
  String get isMyDataSecure => 'Is my data secure?';

  @override
  String get isMyDataSecureAnswer =>
      'Yes, all your data is stored encrypted and hosted on secure servers. We provide industry-standard security using Supabase infrastructure.';

  @override
  String get forgotPasswordAnswer =>
      'You can use the \"Forgot Password\" option on the login screen to send a password reset link to your email address.';

  @override
  String get howToDeleteAccount => 'How can I delete my account?';

  @override
  String get howToDeleteAccountAnswer =>
      'You can log out from the profile page or contact our support team to request complete deletion of your account.';

  @override
  String get isAppFree => 'Is the app free?';

  @override
  String get isAppFreeAnswer =>
      'Yes, Qanta can be used completely free. Premium features may be added in the future, but basic features will always remain free.';

  @override
  String get appInformation => 'App Information';

  @override
  String get lastUpdate => 'Last Update';

  @override
  String get developer => 'Developer';

  @override
  String get platform => 'Platform';

  @override
  String get liveSupportTitle => 'Live Support';

  @override
  String get liveSupportMessage =>
      'Live support service is currently in development. For urgent matters, please contact us via email or phone.';

  @override
  String get serviceDescription => 'Service Description';

  @override
  String get serviceDescriptionContent =>
      'Qanta is a mobile application designed for personal finance management. The application offers the following services:\n\n• Income and expense tracking\n• Budget management and planning\n• Card and account management\n• Financial reporting and analysis\n• Installment tracking and management';

  @override
  String get usageTerms => 'Usage Terms';

  @override
  String get usageTermsContent =>
      'By using the Qanta application, you agree to the following terms:\n\n• You will use the application only for legal purposes\n• You will provide accurate and up-to-date information\n• You will protect your account security\n• You will respect the rights of other users\n• You will avoid misuse of the application';

  @override
  String get userResponsibilities => 'User Responsibilities';

  @override
  String get userResponsibilitiesContent =>
      'As a user, you have the following responsibilities:\n\n• Keeping your account information secure\n• Not sharing your password with anyone\n• Ensuring the accuracy of your financial data\n• Complying with application rules\n• Reporting security breaches';

  @override
  String get serviceLimitations => 'Service Limitations';

  @override
  String get serviceLimitationsContent =>
      'The Qanta application is subject to the following limitations:\n\n• Does not provide financial advisory services\n• Does not give investment advice\n• Does not perform banking transactions\n• Does not provide credit or lending services\n• Does not provide tax advisory services';

  @override
  String get intellectualProperty => 'Intellectual Property';

  @override
  String get intellectualPropertyContent =>
      'All content of the Qanta application is protected by copyright:\n\n• Application design and code\n• Logo and brand elements\n• Text and visual content\n• Algorithms and calculation methods\n• Database structure';

  @override
  String get serviceChanges => 'Service Changes';

  @override
  String get serviceChangesContent =>
      'Qanta reserves the right to make changes to its services:\n\n• Adding or removing features\n• Pricing changes\n• Updating terms of use\n• Service termination\n• Maintenance and updates';

  @override
  String get disclaimer => 'Disclaimer';

  @override
  String get disclaimerContent =>
      'Qanta is not responsible for the following situations:\n\n• Data loss or corruption\n• System failures or interruptions\n• Third-party service providers\n• Damages resulting from user errors\n• Internet connection issues';

  @override
  String get termsContact => 'Contact';

  @override
  String get termsContactContent =>
      'For questions about terms of service:\n\nEmail: support@qanta.app\nWeb: www.qanta.app\nAddress: Istanbul, Turkey\n\nThese terms were last updated: January 20, 2025';

  @override
  String get faq => 'Frequently Asked Questions';

  @override
  String get generalQuestions => 'General Questions';

  @override
  String get accountAndSecurity => 'Account and Security';

  @override
  String get features => 'Features';

  @override
  String get technicalIssues => 'Technical Issues';

  @override
  String get whatIsQanta => 'What is Qanta?';

  @override
  String get whatIsQantaAnswer =>
      'Qanta is a modern mobile application designed for personal finance management. It offers income-expense tracking, budget management, card tracking, and financial analysis features.';

  @override
  String get whichDevicesSupported => 'Which devices can I use it on?';

  @override
  String get whichDevicesSupportedAnswer =>
      'Qanta can be used on Android and iOS devices. It is developed with Flutter technology.';

  @override
  String get howToChangePassword => 'How can I change my password?';

  @override
  String get howToChangePasswordAnswer =>
      'You can use the \"Change Password\" option from the \"Security\" section on the profile page.';

  @override
  String get whichCardTypesSupported => 'Which card types do you support?';

  @override
  String get whichCardTypesSupportedAnswer =>
      'Credit cards, debit cards, and cash accounts are supported. Compatible with all Turkish banks.';

  @override
  String get howDoesInstallmentTrackingWork =>
      'How does installment tracking work?';

  @override
  String get howDoesInstallmentTrackingWorkAnswer =>
      'You can add installment purchases and automatically track your monthly payments. The system sends you reminders.';

  @override
  String get howToUseBudgetManagement => 'How to use budget management?';

  @override
  String get howToUseBudgetManagementAnswer =>
      'You can set monthly limits for categories, track your expenses, and receive alerts when limits are exceeded.';

  @override
  String get whatIsQuickNotesFeature => 'What is the quick notes feature?';

  @override
  String get whatIsQuickNotesFeatureAnswer =>
      'You can quickly take notes with persistent notifications, add photos, and categorize your notes.';

  @override
  String get appCrashingWhatToDo => 'The app is crashing, what should I do?';

  @override
  String get appCrashingWhatToDoAnswer =>
      'First try closing the app completely and reopening it. If the problem persists, restart your device. If it still doesn\'t resolve, contact our support team.';

  @override
  String get dataNotSyncing => 'My data is not syncing';

  @override
  String get dataNotSyncingAnswer =>
      'Check your internet connection and restart the app. If the problem persists, try logging out and logging back in.';

  @override
  String get notificationsNotComing => 'Notifications are not coming';

  @override
  String get notificationsNotComingAnswer =>
      'Make sure notifications are enabled for Qanta in your device settings. Also check notification settings from the profile page.';

  @override
  String get howToContactSupport => 'How can I contact your support team?';

  @override
  String get howToContactSupportAnswer =>
      'You can use the \"Support & Contact\" section from the profile page or send an email to support@qanta.app.';

  @override
  String get haveSuggestionWhereToSend =>
      'I have a suggestion, where can I send it?';

  @override
  String get haveSuggestionWhereToSendAnswer =>
      'You can send your suggestions to support@qanta.app. All feedback is evaluated and used to improve the application.';

  @override
  String get lastMonthChange => 'from last month';

  @override
  String get increase => 'increase';

  @override
  String get decrease => 'decrease';

  @override
  String get noAccountsYet => 'No accounts yet';

  @override
  String get addFirstAccount => 'Add your first account to get started';

  @override
  String get currentDebt => 'Current Debt';

  @override
  String get totalLimit => 'Total Limit';

  @override
  String stockPurchaseInsufficientBalance(String balance) {
    return 'Insufficient balance for stock purchase. Available: $balance';
  }

  @override
  String stockSaleInsufficientQuantity(String quantity) {
    return 'Insufficient stock quantity. Available: $quantity lots';
  }

  @override
  String get searchBanks => 'Search banks...';

  @override
  String get noBanksFound => 'No banks found';

  @override
  String get addCreditCard => 'Add Credit Card';

  @override
  String get cardNameExample => 'E.g: My Work Card, Shopping Card';

  @override
  String get currentDebtOptional => 'Current Debt (Optional)';

  @override
  String get addDebitCard => 'Add Debit Card';

  @override
  String get cardNameExampleDebit => 'E.g: VakıfBank Checking';

  @override
  String get initialBalance => 'Initial Balance';

  @override
  String get day => 'day';

  @override
  String get firstDay => '1st';

  @override
  String get secondDay => '2nd';

  @override
  String get thirdDay => '3rd';

  @override
  String get fourthDay => '4th';

  @override
  String get fifthDay => '5th';

  @override
  String get sixthDay => '6th';

  @override
  String get seventhDay => '7th';

  @override
  String get eighthDay => '8th';

  @override
  String get ninthDay => '9th';

  @override
  String get tenthDay => '10th';

  @override
  String get eleventhDay => '11th';

  @override
  String get twelfthDay => '12th';

  @override
  String get thirteenthDay => '13th';

  @override
  String get fourteenthDay => '14th';

  @override
  String get fifteenthDay => '15th';

  @override
  String get sixteenthDay => '16th';

  @override
  String get seventeenthDay => '17th';

  @override
  String get eighteenthDay => '18th';

  @override
  String get nineteenthDay => '19th';

  @override
  String get twentiethDay => '20th';

  @override
  String get twentyFirstDay => '21st';

  @override
  String get twentySecondDay => '22nd';

  @override
  String get twentyThirdDay => '23rd';

  @override
  String get twentyFourthDay => '24th';

  @override
  String get twentyFifthDay => '25th';

  @override
  String get twentySixthDay => '26th';

  @override
  String get twentySeventhDay => '27th';

  @override
  String get twentyEighthDay => '28th';

  @override
  String get selectCardType => 'Select Card Type';

  @override
  String get addDebitCardDescription =>
      'Add a debit card to track your spending';

  @override
  String get addCreditCardDescription =>
      'Add a credit card to manage your credit';

  @override
  String get searchStocks => 'Search Stocks';

  @override
  String get addStock => 'Add Stock';

  @override
  String get removeStock => 'Remove Stock';

  @override
  String get stockDetails => 'Stock Details';

  @override
  String get stockInfo => 'Stock Information';

  @override
  String get exchange => 'Exchange';

  @override
  String get sector => 'Sector';

  @override
  String get country => 'Country';

  @override
  String get buyStock => 'Buy Stock';

  @override
  String get sellStock => 'Sell Stock';

  @override
  String get buy => 'Buy';

  @override
  String get sell => 'Sell';

  @override
  String get noStocksYet => 'You are not tracking any stocks yet';

  @override
  String get addFirstStock => 'Press + to add stocks';

  @override
  String get stockAdded => 'Stock added to watchlist';

  @override
  String get stockRemoved => 'Stock removed from watchlist';

  @override
  String get confirmRemoveStock =>
      'Are you sure you want to remove this stock from your portfolio?';

  @override
  String get chartComingSoon => 'Chart Coming Soon';

  @override
  String get chartDescription =>
      'Price charts and analysis features are being developed';

  @override
  String get shareStock => 'Share Stock';

  @override
  String get shareFeatureComingSoon => 'Share feature coming soon';

  @override
  String get buyFeatureComingSoon => 'Buy transaction coming soon';

  @override
  String get sellFeatureComingSoon => 'Sell transaction coming soon';

  @override
  String get popularStocks => 'Popular Stocks';

  @override
  String get bistStocks => 'BIST Stocks';

  @override
  String get usStocks => 'US Stocks';

  @override
  String minutesAgoFull(int count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgoFull(int count) {
    return '$count hours ago';
  }

  @override
  String daysAgoFull(int count) {
    return '$count days ago';
  }

  @override
  String get investmentsIncluded => 'Including investments';

  @override
  String get investmentsExcluded => 'Excluding investments';

  @override
  String get addFirstCardDescription =>
      'Go to My Cards page to add your first card';

  @override
  String deleteTransactionConfirmation(String description) {
    return 'Are you sure you want to delete the $description transaction?';
  }

  @override
  String deleteInstallmentConfirmation(String description) {
    return 'Are you sure you want to delete the $description transaction? All installments will be refunded.';
  }

  @override
  String installmentDeleteError(String error) {
    return 'Error deleting installment transaction: $error';
  }

  @override
  String get dueToday => 'Today';

  @override
  String lastDays(int days) {
    return 'Last $days Days';
  }

  @override
  String statementDebt(String amount) {
    return 'Statement Debt: $amount';
  }

  @override
  String get noDebt => 'No debt';

  @override
  String get important => 'Important';

  @override
  String get info => 'Info';

  @override
  String get statementDebtLabel => 'Statement Debt';

  @override
  String debtAmount(String amount) {
    return 'Debt: $amount';
  }

  @override
  String get lastPaymentDate => 'Last Payment Date';

  @override
  String get allNotifications => 'All Notifications';

  @override
  String get pendingNotes => 'Pending';

  @override
  String get addQuickNote => 'Add Quick Note';

  @override
  String get addQuickNoteDescription =>
      'Write your expense or income note. You can add it as a transaction later.';

  @override
  String exampleExpenseNote(String currency) {
    return 'E.g.: Grocery shopping 150$currency';
  }

  @override
  String get addPhotoNote => 'Add Photo Note';

  @override
  String get addPhotoNoteDescription =>
      'Add a description for this photo (optional)';

  @override
  String examplePhotoNote(String currency) {
    return 'E.g.: Receipt - 150$currency';
  }

  @override
  String viewAllNotes(int count) {
    return 'View all notes ($count)';
  }

  @override
  String secondsAgo(int count) {
    return '$count seconds ago';
  }

  @override
  String yesterdayAt(String time) {
    return 'Yesterday at $time';
  }

  @override
  String weekdayAt(String weekday, String time) {
    return '$weekday at $time';
  }

  @override
  String dayMonth(int day, String month) {
    return '$day $month';
  }

  @override
  String dayMonthYear(int day, int month, int year) {
    return '$day/$month/$year';
  }

  @override
  String get januaryShort => 'Jan';

  @override
  String get februaryShort => 'Feb';

  @override
  String get marchShort => 'Mar';

  @override
  String get aprilShort => 'Apr';

  @override
  String get mayShort => 'May';

  @override
  String get juneShort => 'Jun';

  @override
  String get julyShort => 'Jul';

  @override
  String get augustShort => 'Aug';

  @override
  String get septemberShort => 'Sep';

  @override
  String get octoberShort => 'Oct';

  @override
  String get novemberShort => 'Nov';

  @override
  String get decemberShort => 'Dec';

  @override
  String get stocksIncluded => 'Stocks In';

  @override
  String get stocksExcluded => 'Stocks Out';

  @override
  String get stockChip => 'Stock';

  @override
  String get dailyPerformance => 'Daily Performance';

  @override
  String get daily => 'Daily';

  @override
  String get noStocksTracked => 'No stocks tracked yet';

  @override
  String get stockDataLoading => 'Loading stock data...';

  @override
  String get addStocksInstruction => 'Go to Stocks tab to add stocks';

  @override
  String get addStocks => 'Add Stocks';

  @override
  String get noPosition => 'No Position';

  @override
  String get topGainersDescription => 'Stocks with highest gains today';

  @override
  String get marketOpen => 'Market Open';

  @override
  String get marketClosed => 'Market Closed';

  @override
  String get intradayChange => 'Intraday Change';

  @override
  String get previousClose => 'Previous Close';

  @override
  String get loadingStocks => 'Loading stock data...';

  @override
  String get noStockData => 'No stock data available';

  @override
  String get stockSale => 'Stock Sale';

  @override
  String get stockPurchase => 'Stock Purchase';

  @override
  String get stockName => 'Stock Name';

  @override
  String get price => 'Price';

  @override
  String get total => 'Total';

  @override
  String get pieces => 'lot';

  @override
  String totalTransactionsCount(int count) {
    return '$count transactions';
  }

  @override
  String incomeTransactionsCount(int count) {
    return '$count income transactions';
  }

  @override
  String expenseTransactionsCount(int count) {
    return '$count expense transactions';
  }

  @override
  String transferTransactionsCount(int count) {
    return '$count transfer transactions';
  }

  @override
  String stockTransactionsCount(int count) {
    return '$count stock transactions';
  }

  @override
  String get allTime => 'All Time';

  @override
  String get dailyAverageExpense => 'Daily average expense';

  @override
  String get noExpenseTransactions => 'No expense transactions found';

  @override
  String get analyzeYourFinances => 'Analyze your finances';

  @override
  String get statistics => 'Statistics';

  @override
  String get noExpenseRecordsYet => 'No expense records yet';

  @override
  String get transactionHistoryEmpty => 'Transaction history is empty';

  @override
  String get noSpendingInPeriod => 'No spending in selected period';

  @override
  String get spendingCategories => 'Spending Categories';

  @override
  String get noTransactionsInCategory =>
      'No transactions found in this category';

  @override
  String get chart => 'Chart';

  @override
  String get table => 'Table';

  @override
  String get monthlyExpenseAnalysis => 'Monthly Expense Analysis';

  @override
  String get monthlyIncomeAnalysis => 'Monthly Income Analysis';

  @override
  String get monthlyNetBalanceAnalysis => 'Monthly Net Balance Analysis';

  @override
  String noMonthlyData(String title) {
    return 'No Monthly $title Data';
  }

  @override
  String get addFirstTransactionToStart =>
      'Add your first transaction to get started';

  @override
  String get month => 'Month';

  @override
  String get change => 'Change';

  @override
  String get stable => 'Stable';

  @override
  String get stockTrading => 'Stock Trading';

  @override
  String get unknownCategory => 'Unknown Category';

  @override
  String get trackYourStocks => 'Track your stocks';

  @override
  String get chartDevelopmentMessage =>
      'Price charts and analysis features are being developed';

  @override
  String get buyTransactionComingSoon => 'Buy transaction coming soon';

  @override
  String get sellTransactionComingSoon => 'Sell transaction coming soon';

  @override
  String get loadingPopularStocks => 'Loading popular stocks...';

  @override
  String get noStocksFound => 'No stocks found';

  @override
  String get tryDifferentSearchTerm => 'Try a different search term';

  @override
  String get dayHigh => 'Day High';

  @override
  String get dayLow => 'Day Low';

  @override
  String get volume => 'Volume';

  @override
  String get remove => 'Remove';

  @override
  String get errorRemovingStock => 'Error removing stock';

  @override
  String stockRemovedFromPortfolio(String stockName) {
    return '$stockName removed from portfolio';
  }

  @override
  String get stockTransaction => 'Stock Transaction';

  @override
  String get priceRequired => 'Price required';

  @override
  String get enterValidPrice => 'Enter a valid price';

  @override
  String get transactionSummary => 'Transaction Summary';

  @override
  String get subtotal => 'Subtotal';

  @override
  String executeTransaction(String transactionType) {
    return 'Execute $transactionType Transaction';
  }

  @override
  String get unknownStock => 'Unknown Stock';

  @override
  String get selectStock => 'Select Stock';

  @override
  String get selectAccount => 'Select Account';

  @override
  String get pleaseSelectStock => 'Please select a stock';

  @override
  String get pleaseSelectAccount => 'Please select an account';

  @override
  String get noStockSelected => 'No stock selected';

  @override
  String get executePurchase => 'Execute Purchase';

  @override
  String get executeSale => 'Execute Sale';

  @override
  String get noStocksAddedYet => 'No stocks added yet';

  @override
  String get addFirstStockInstruction =>
      'Go to the Stocks screen to add your first stock';

  @override
  String get quantityAndPrice => 'Quantity & Price';

  @override
  String get newBadge => 'NEW';

  @override
  String get commissionRate => 'Commission Rate:';

  @override
  String get commission => 'Commission';

  @override
  String get totalToPay => 'Total to Pay:';

  @override
  String get totalToReceive => 'Total to Receive:';

  @override
  String get noCashAccountFound => 'No Cash Account Found';

  @override
  String get addCashAccountForStockTrading =>
      'You need to add a cash account first to perform stock transactions.';

  @override
  String get currentPrice => 'Current Price';

  @override
  String get currentValue => 'Current Value';

  @override
  String get deleteInstallmentConfirm =>
      'installment transaction. Are you sure you want to delete it completely?';

  @override
  String get deleteInstallmentWarning =>
      'This action will delete all installments and refund paid amounts.';

  @override
  String get errorDeletingTransaction => 'Error deleting transaction';

  @override
  String get deletingInstallmentTransaction =>
      'Deleting installment transaction...';

  @override
  String get errorDeletingInstallmentTransaction =>
      'Error deleting installment transaction';

  @override
  String get cost => 'Cost';

  @override
  String get weightedAverageCost => 'Weighted Average Cost';

  @override
  String get portfolioOverview => 'Portfolio Overview';

  @override
  String get myPortfolio => 'My Portfolio';

  @override
  String get neutral => 'Neutral';

  @override
  String get profit => 'Profit';

  @override
  String get loss => 'Loss';

  @override
  String get filterBy => 'Filter By';

  @override
  String get gainers => 'Rising';

  @override
  String get losers => 'Falling';

  @override
  String get portfolioRatio => 'Weight';

  @override
  String get insufficientBalance => 'Insufficient Balance';

  @override
  String get addMoneyToAccount => 'Add money to your account to buy stocks';

  @override
  String get addMoney => 'Add Money';

  @override
  String get totalValue => 'Total Value';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get totalProfitLoss => 'Total P&L';

  @override
  String get totalReturn => 'Total Return';

  @override
  String get profitLoss => 'Profit/Loss';

  @override
  String get calendar => 'Calendar';

  @override
  String get mondayShort => 'Mon';

  @override
  String get tuesdayShort => 'Tue';

  @override
  String get wednesdayShort => 'Wed';

  @override
  String get thursdayShort => 'Thu';

  @override
  String get fridayShort => 'Fri';

  @override
  String get saturdayShort => 'Sat';

  @override
  String get sundayShort => 'Sun';

  @override
  String get analysisFeaturesInDevelopment =>
      'Analysis features in development';

  @override
  String get value => 'Value';

  @override
  String get returnLabel => 'Return';

  @override
  String get quickNotesTitle => 'Quick Notes';

  @override
  String pendingNotesCount(int count) {
    return '$count pending notes';
  }

  @override
  String get quickAddNote => 'Quick Add Note';

  @override
  String get addNoteHint => 'e.g. 50₺ grocery shopping';

  @override
  String get voiceButton => 'Voice';

  @override
  String get stopButton => 'Stop';

  @override
  String get photoButton => 'Photo';

  @override
  String get addButton => 'Add';

  @override
  String get processedNotes => 'Processed';

  @override
  String get pendingNotesTitle => 'Pending Notes';

  @override
  String get processedNotesTitle => 'Processed Notes';

  @override
  String get noPendingNotes =>
      'No pending notes yet\nAdd notes quickly from the field above';

  @override
  String get noProcessedNotes => 'No notes converted to transactions yet';

  @override
  String get noteStatusPending => 'Pending';

  @override
  String get noteStatusProcessed => 'Processed';

  @override
  String get convertToExpense => 'Expense';

  @override
  String get convertToIncome => 'Income';

  @override
  String get deleteNote => 'Delete';

  @override
  String noteAddedSuccess(String content) {
    return 'Note added: $content';
  }

  @override
  String get noteConvertedSuccess =>
      'Note successfully converted to transaction';

  @override
  String get noteDeletedSuccess => 'Note deleted';

  @override
  String get timeNow => 'Now';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get cutOff => 'Cut-off';

  @override
  String get paid => 'Paid';

  @override
  String get overdue => 'Overdue';

  @override
  String get daysLeft => 'days left';

  @override
  String get noTransactionsInStatement => 'No transactions in this statement';

  @override
  String get loadingStatements => 'Loading statements...';

  @override
  String get loadMore => 'Load More';

  @override
  String get loadingMore => 'Loading...';

  @override
  String get currentStatement => 'Current Statement';

  @override
  String get pastStatements => 'Past Statements';

  @override
  String get futureStatements => 'Future Statements';

  @override
  String get statements => 'Statements';

  @override
  String get garantiBBVA => 'Garanti BBVA';

  @override
  String get isBankasi => 'İş Bankası';

  @override
  String get akbank => 'Akbank';

  @override
  String get ziraatBankasi => 'Ziraat Bankası';

  @override
  String get vakifBank => 'VakıfBank';

  @override
  String get yapiKredi => 'Yapı Kredi';

  @override
  String get kuveytTurk => 'Kuveyt Türk';

  @override
  String get albarakaTurk => 'Albaraka Türk';

  @override
  String get qnbFinansbank => 'QNB Finansbank';

  @override
  String get enpara => 'Enpara.com';

  @override
  String get papara => 'Papara';

  @override
  String get turkiyeFinans => 'Türkiye Finans';

  @override
  String get teb => 'TEB';

  @override
  String get hsbcTurkiye => 'HSBC Türkiye';

  @override
  String get ingTurkiye => 'ING Türkiye';

  @override
  String get denizBank => 'DenizBank';

  @override
  String get anadoluBank => 'AnadoluBank';

  @override
  String get halkBank => 'Halkbank';

  @override
  String get qantaBank => 'Qanta Bank';

  @override
  String get statementOperations => 'Statement Operations';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get downloadPdfSubtitle => 'Download statement as PDF';

  @override
  String get share => 'Share';

  @override
  String get shareSubtitle => 'Share statement';

  @override
  String get markAsUnpaid => 'Mark as Unpaid';

  @override
  String get markAsUnpaidSubtitle => 'Change payment status of this statement';

  @override
  String get statementMarkedAsUnpaid => 'Statement marked as unpaid';

  @override
  String get errorMarkingStatement => 'Error occurred while marking statement';

  @override
  String get pdfExportComingSoon => 'PDF export feature coming soon';

  @override
  String get noStatementsYet => 'No statements yet';

  @override
  String get statementsWillAppearAfterUsage =>
      'Statements will appear here after card usage';

  @override
  String installmentCount(int count) {
    return '$count Installments';
  }

  @override
  String get limitManagement => 'Limit Management';

  @override
  String get pleaseEnterCategoryAndLimit =>
      'Please enter category name and set limit';

  @override
  String get enterValidLimit => 'Enter a valid limit';

  @override
  String get limitSavedSuccessfully => 'Limit saved successfully';

  @override
  String get noLimitsSetYet => 'No limits set yet';

  @override
  String get setMonthlySpendingLimits =>
      'Set monthly spending limits for categories\nto control your budget';

  @override
  String get monthlyLimit => 'Monthly Limit:';

  @override
  String get exceeded => 'Exceeded';

  @override
  String get limitExceeded => 'Limit Exceeded!';

  @override
  String get creditCardLimitInsufficient => 'Credit card limit insufficient';

  @override
  String creditCardLimitInsufficientWithAmount(String amount) {
    return 'Credit card limit insufficient. Remaining limit: $amount';
  }

  @override
  String get creditCardLimitInsufficientTitle =>
      'Credit Card Limit Insufficient';

  @override
  String get creditCardLimitInsufficientMessage =>
      'Your credit card limit is not sufficient for this transaction. Please enter a lower amount or pay off your card debt.';

  @override
  String get debitCardBalanceInsufficientTitle =>
      'Debit Card Balance Insufficient';

  @override
  String get debitCardBalanceInsufficientMessage =>
      'Your debit card balance is not sufficient for this transaction. Please enter a lower amount or deposit money to your card.';

  @override
  String cashBalanceInsufficientWithAmount(String amount) {
    return 'Cash balance insufficient. Current: $amount';
  }

  @override
  String debitCardBalanceInsufficientWithAmount(String amount) {
    return 'Debit card balance insufficient. Current: $amount';
  }

  @override
  String get cashBalanceInsufficientTitle => 'Cash Balance Insufficient';

  @override
  String get cashBalanceInsufficientMessage =>
      'Your cash balance is not sufficient for this transaction. Please enter a lower amount.';

  @override
  String get insufficientBalanceTitle => 'Insufficient Balance';

  @override
  String get spent => 'spent';

  @override
  String get spentAmount => 'Spent:';

  @override
  String get limitAmountHint => '2,000';

  @override
  String get addNewLimit => 'Add New Limit';

  @override
  String get monthlyLimitLabel => 'Monthly Limit';

  @override
  String get limitAmountPlaceholder => '0.00';

  @override
  String get saveLimit => 'Save Limit';

  @override
  String get limit => 'Limit';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get googleSignInError => 'Google sign-in error';

  @override
  String get googleSignUpError => 'Google sign-up error';

  @override
  String get googleSignUpSuccess => 'Successfully signed up with Google!';

  @override
  String get or => 'or';

  @override
  String get addFirstNoteInstruction =>
      'Tap the + button to add your first note';

  @override
  String get addExpenseIncomeNoteInstruction =>
      'Write your expense or income note. You can add it as a transaction later.';

  @override
  String get stockTransactionCannotDelete =>
      'Stock transactions cannot be deleted';

  @override
  String get stockTransactionDeleteWarning =>
      'Instead of deleting, make a sell transaction';

  @override
  String get editCreditCard => 'Edit Credit Card';

  @override
  String get selectBank => 'Select bank';

  @override
  String get pleaseSelectBank => 'Please select a bank';

  @override
  String get cardNameOptional => 'Card Name';

  @override
  String get statementDayLabel => 'Statement Day';

  @override
  String get selectStatementDay => 'Select statement day';

  @override
  String get creditCardUpdatedSuccessfully =>
      'Credit card updated successfully';

  @override
  String updateErrorOccurred(String error) {
    return 'An error occurred during update: $error';
  }

  @override
  String get invalidMonth => 'Invalid month';

  @override
  String get addCardDescription =>
      'Add your first card to start managing your finances';

  @override
  String get budgetManagementDescription =>
      'Track your spending limits and manage your weekly, monthly, and yearly budgets by category';

  @override
  String get dark => 'DARK';

  @override
  String get light => 'LIGHT';

  @override
  String get on => 'ON';

  @override
  String get off => 'OFF';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get bankCard => 'Bank Card';

  @override
  String get noStocksMatchFilter => 'No stocks match the current filter';

  @override
  String get tryDifferentFilter => 'Try selecting a different filter';
}
