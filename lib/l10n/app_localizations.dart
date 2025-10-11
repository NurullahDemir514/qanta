import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Qanta'**
  String get appTitle;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Get started button text
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Light mode setting
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Turkish language option
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Email
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get fullName;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Forgot password
  ///
  /// In en, this message translates to:
  /// **'I forgot my password, what should I do?'**
  String get forgotPassword;

  /// Budget feature
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// Expenses tracking
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// Income label
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// Investment portfolio
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get investments;

  /// Financial analytics
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Balance
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// Onboarding screen description text
  ///
  /// In en, this message translates to:
  /// **'Your personal finance app. Track expenses, manage cards, monitor stocks, and set budgets.'**
  String get onboardingDescription;

  /// Welcome subtitle on home screen
  ///
  /// In en, this message translates to:
  /// **'Take control of your finances today!'**
  String get welcomeSubtitle;

  /// Budget card subtitle
  ///
  /// In en, this message translates to:
  /// **'Track your spending'**
  String get budgetSubtitle;

  /// Investments card subtitle
  ///
  /// In en, this message translates to:
  /// **'Grow your wealth'**
  String get investmentsSubtitle;

  /// Analytics card subtitle
  ///
  /// In en, this message translates to:
  /// **'Financial insights'**
  String get analyticsSubtitle;

  /// Settings card subtitle
  ///
  /// In en, this message translates to:
  /// **'Customize your app'**
  String get settingsSubtitle;

  /// App slogan on splash screen
  ///
  /// In en, this message translates to:
  /// **'Manage your money smartly'**
  String get appSlogan;

  /// Personalized greeting with user name
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String greetingHello(String name);

  /// Main title on home screen
  ///
  /// In en, this message translates to:
  /// **'Ready to reach your financial goals?'**
  String get homeMainTitle;

  /// Subtitle on home screen
  ///
  /// In en, this message translates to:
  /// **'Manage your money smartly and plan your future'**
  String get homeSubtitle;

  /// Default name when user name is not available
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUserName;

  /// Name field validation error
  ///
  /// In en, this message translates to:
  /// **'Your name is required'**
  String get nameRequired;

  /// Email field validation error
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Invalid email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get emailInvalid;

  /// Password field validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Password too short validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Confirm password field validation error
  ///
  /// In en, this message translates to:
  /// **'Password confirmation is required'**
  String get confirmPasswordRequired;

  /// Passwords do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Login page subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get loginSubtitle;

  /// Create account title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Register page subtitle
  ///
  /// In en, this message translates to:
  /// **'Join Qanta and start managing your money'**
  String get registerSubtitle;

  /// 404 error page title
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// 404 error page description
  ///
  /// In en, this message translates to:
  /// **'The page you are looking for does not exist.'**
  String get pageNotFoundDescription;

  /// Go to home page button
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// Already have account text
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Don't have account text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Login error prefix
  ///
  /// In en, this message translates to:
  /// **'Login error'**
  String get loginError;

  /// Register error prefix
  ///
  /// In en, this message translates to:
  /// **'Registration error'**
  String get registerError;

  /// Email not confirmed error
  ///
  /// In en, this message translates to:
  /// **'You need to verify your email address. Please check your email.'**
  String get emailNotConfirmed;

  /// Invalid credentials error
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please try again.'**
  String get invalidCredentials;

  /// Too many requests error
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get tooManyRequests;

  /// Invalid email address error
  ///
  /// In en, this message translates to:
  /// **'Invalid email address. Please enter a valid email.'**
  String get invalidEmailAddress;

  /// Password too short error message
  ///
  /// In en, this message translates to:
  /// **'Password is too short. Must be at least 6 characters.'**
  String get passwordTooShortError;

  /// User already registered error
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try signing in.'**
  String get userAlreadyRegistered;

  /// Signup disabled error
  ///
  /// In en, this message translates to:
  /// **'Registration is currently disabled. Please try again later.'**
  String get signupDisabled;

  /// Registration successful message
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Welcome {name}!'**
  String registrationSuccessful(String name);

  /// Total balance label
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// Total portfolio label
  ///
  /// In en, this message translates to:
  /// **'Total Portfolio'**
  String get totalPortfolio;

  /// All accounts subtitle
  ///
  /// In en, this message translates to:
  /// **'All your accounts'**
  String get allAccounts;

  /// Available balance label
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// This month income label
  ///
  /// In en, this message translates to:
  /// **'This Month Income'**
  String get thisMonthIncome;

  /// This month expense label
  ///
  /// In en, this message translates to:
  /// **'This Month Expense'**
  String get thisMonthExpense;

  /// My cards section title
  ///
  /// In en, this message translates to:
  /// **'My Cards'**
  String get myCards;

  /// Manage your cards subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your cards'**
  String get manageYourCards;

  /// See all button text
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// Recent transactions section title
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// This month summary section title
  ///
  /// In en, this message translates to:
  /// **'This Month Summary'**
  String get thisMonthSummary;

  /// Savings card type
  ///
  /// In en, this message translates to:
  /// **'SAVINGS'**
  String get savings;

  /// Budget used label
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get budgetUsed;

  /// Remaining amount label
  ///
  /// In en, this message translates to:
  /// **'Remaining:'**
  String get remaining;

  /// Installment word
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get installment;

  /// Category input hint text
  ///
  /// In en, this message translates to:
  /// **'coffee, market, fuel...'**
  String get categoryHint;

  /// No budget defined message
  ///
  /// In en, this message translates to:
  /// **'No budget defined yet'**
  String get noBudgetDefined;

  /// Create budget description
  ///
  /// In en, this message translates to:
  /// **'Create a budget to track your spending limits'**
  String get createBudgetDescription;

  /// Create budget button text
  ///
  /// In en, this message translates to:
  /// **'Create Budget'**
  String get createBudget;

  /// Expense limit tracking title
  ///
  /// In en, this message translates to:
  /// **'Expense Limit Tracking'**
  String get expenseLimitTracking;

  /// Manage button text
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// This month growth indicator
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get thisMonthGrowth;

  /// Card holder label on credit card
  ///
  /// In en, this message translates to:
  /// **'CARD HOLDER'**
  String get cardHolder;

  /// Expiry date label on credit card
  ///
  /// In en, this message translates to:
  /// **'VALID THRU'**
  String get expiryDate;

  /// Qanta debit card name
  ///
  /// In en, this message translates to:
  /// **'Qanta Debit'**
  String get qantaDebit;

  /// Checking account type
  ///
  /// In en, this message translates to:
  /// **'Checking Account'**
  String get checkingAccount;

  /// Qanta credit card name
  ///
  /// In en, this message translates to:
  /// **'Qanta Credit'**
  String get qantaCredit;

  /// Qanta savings card name
  ///
  /// In en, this message translates to:
  /// **'Qanta Savings'**
  String get qantaSavings;

  /// Good morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good Morning! ☀️'**
  String get goodMorning;

  /// Good afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon! 🌤️'**
  String get goodAfternoon;

  /// Good evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good Evening!'**
  String get goodEvening;

  /// Good night greeting
  ///
  /// In en, this message translates to:
  /// **'Good Night! 🌙'**
  String get goodNight;

  /// Stock currency label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Turkish Lira currency option
  ///
  /// In en, this message translates to:
  /// **'Turkish Lira (₺)'**
  String get currencyTRY;

  /// US Dollar currency option
  ///
  /// In en, this message translates to:
  /// **'US Dollar (\$)'**
  String get currencyUSD;

  /// Euro currency option
  ///
  /// In en, this message translates to:
  /// **'Euro (€)'**
  String get currencyEUR;

  /// British Pound currency option
  ///
  /// In en, this message translates to:
  /// **'British Pound (£)'**
  String get currencyGBP;

  /// Select currency title
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// Select currency description
  ///
  /// In en, this message translates to:
  /// **'Which currency would you like to use?'**
  String get selectCurrencyDescription;

  /// Debit card type
  ///
  /// In en, this message translates to:
  /// **'DEBIT'**
  String get debit;

  /// Credit card type
  ///
  /// In en, this message translates to:
  /// **'CREDIT'**
  String get credit;

  /// Profile page title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Personal information section
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// Preferences section
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// Security section
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Support section
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// About section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Edit profile button
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Privacy setting
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// Terms of Service
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Contact support
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// Change Password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Biometric authentication
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuth;

  /// Transaction count label
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// Goals menu item
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// Upcoming payments section title
  ///
  /// In en, this message translates to:
  /// **'Upcoming Payments'**
  String get upcomingPayments;

  /// Coming soon title
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Card information section title
  ///
  /// In en, this message translates to:
  /// **'Card Information'**
  String get cardInfo;

  /// Card type label
  ///
  /// In en, this message translates to:
  /// **'Card Type'**
  String get cardType;

  /// Card number label
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// Short expiry date label
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDateShort;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Active status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Balance information section title
  ///
  /// In en, this message translates to:
  /// **'Balance Information'**
  String get balanceInfo;

  /// Credit Limit
  ///
  /// In en, this message translates to:
  /// **'Credit Limit'**
  String get creditLimit;

  /// Used limit label
  ///
  /// In en, this message translates to:
  /// **'Used Limit'**
  String get usedLimit;

  /// Quick actions section title
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Send money action
  ///
  /// In en, this message translates to:
  /// **'Send Money'**
  String get sendMoney;

  /// Load money action
  ///
  /// In en, this message translates to:
  /// **'Load Money'**
  String get loadMoney;

  /// Freeze card action
  ///
  /// In en, this message translates to:
  /// **'Freeze Card'**
  String get freezeCard;

  /// Card settings action
  ///
  /// In en, this message translates to:
  /// **'Card Settings'**
  String get cardSettings;

  /// Add new card button
  ///
  /// In en, this message translates to:
  /// **'Add New Card'**
  String get addNewCard;

  /// Add new card feature coming soon message
  ///
  /// In en, this message translates to:
  /// **'Add new card feature coming soon!'**
  String get addNewCardFeature;

  /// Card management section title
  ///
  /// In en, this message translates to:
  /// **'Card Management'**
  String get cardManagement;

  /// Security settings option
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// Security settings description
  ///
  /// In en, this message translates to:
  /// **'PIN, limits and security settings'**
  String get securitySettingsDesc;

  /// Notification settings option
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Notification settings description
  ///
  /// In en, this message translates to:
  /// **'Transaction notifications and alerts'**
  String get notificationSettingsDesc;

  /// Transaction history option
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// Transaction history description
  ///
  /// In en, this message translates to:
  /// **'All cards transaction history'**
  String get transactionHistoryDesc;

  /// Qanta wallet payment method
  ///
  /// In en, this message translates to:
  /// **'Qanta Wallet'**
  String get qantaWallet;

  /// Qanta debit card payment method
  ///
  /// In en, this message translates to:
  /// **'Qanta Debit'**
  String get qantaDebitCard;

  /// Bank transfer payment method
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// IBAN label
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get iban;

  /// Recommended label
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get recommended;

  /// Urgent priority level
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// Amount label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Due date label
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// Set reminder action
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get setReminder;

  /// Payment history action
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// Reminder setup opening message
  ///
  /// In en, this message translates to:
  /// **'Reminder setup opening...'**
  String get reminderSetup;

  /// Payment history opening message
  ///
  /// In en, this message translates to:
  /// **'Payment history opening...'**
  String get paymentHistoryOpening;

  /// Send money opening message
  ///
  /// In en, this message translates to:
  /// **'Send Money opening...'**
  String get sendMoneyOpening;

  /// Load money opening message
  ///
  /// In en, this message translates to:
  /// **'Load Money opening...'**
  String get loadMoneyOpening;

  /// Freeze card opening message
  ///
  /// In en, this message translates to:
  /// **'Freeze Card opening...'**
  String get freezeCardOpening;

  /// Card settings opening message
  ///
  /// In en, this message translates to:
  /// **'Card Settings opening...'**
  String get cardSettingsOpening;

  /// Security settings opening message
  ///
  /// In en, this message translates to:
  /// **'Security Settings opening...'**
  String get securitySettingsOpening;

  /// Notification settings opening message
  ///
  /// In en, this message translates to:
  /// **'Notification Settings opening...'**
  String get notificationSettingsOpening;

  /// Transaction history opening message
  ///
  /// In en, this message translates to:
  /// **'Opening transaction history...'**
  String get transactionHistoryOpening;

  /// Payment processing message
  ///
  /// In en, this message translates to:
  /// **'Processing payment with {method}...'**
  String paymentProcessing(String method);

  /// All accounts total subtitle
  ///
  /// In en, this message translates to:
  /// **'Total of all your accounts'**
  String get allAccountsTotal;

  /// Account breakdown section title
  ///
  /// In en, this message translates to:
  /// **'Account Breakdown'**
  String get accountBreakdown;

  /// Credit card account type
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// Savings account type
  ///
  /// In en, this message translates to:
  /// **'Savings Account'**
  String get savingsAccount;

  /// Cash account type
  ///
  /// In en, this message translates to:
  /// **'Cash Account'**
  String get cashAccount;

  /// Monthly summary section title
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get monthlySummary;

  /// Cash balance label
  ///
  /// In en, this message translates to:
  /// **'Cash Balance'**
  String get cashBalance;

  /// Add cash balance button
  ///
  /// In en, this message translates to:
  /// **'Add Cash Balance'**
  String get addCashBalance;

  /// Enter cash amount dialog title
  ///
  /// In en, this message translates to:
  /// **'Enter Cash Amount'**
  String get enterCashAmount;

  /// Cash amount field label
  ///
  /// In en, this message translates to:
  /// **'Cash Amount'**
  String get cashAmount;

  /// Add cash button
  ///
  /// In en, this message translates to:
  /// **'Add Cash'**
  String get addCash;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Cash added success message
  ///
  /// In en, this message translates to:
  /// **'Cash balance added: {amount}'**
  String cashAdded(String amount);

  /// Invalid amount error
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// Enter valid amount validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get enterValidAmount;

  /// Cash account type
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// Digital wallet label
  ///
  /// In en, this message translates to:
  /// **'Digital Wallet'**
  String get digitalWallet;

  /// All option
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Cash management section title
  ///
  /// In en, this message translates to:
  /// **'Cash Management'**
  String get cashManagement;

  /// Add cash history option
  ///
  /// In en, this message translates to:
  /// **'Add Cash History'**
  String get addCashHistory;

  /// Add cash history description
  ///
  /// In en, this message translates to:
  /// **'View your cash addition transactions'**
  String get addCashHistoryDesc;

  /// Cash limits option
  ///
  /// In en, this message translates to:
  /// **'Cash Limits'**
  String get cashLimits;

  /// Cash limits description
  ///
  /// In en, this message translates to:
  /// **'Set daily and monthly cash limits'**
  String get cashLimitsDesc;

  /// Debit card management section title
  ///
  /// In en, this message translates to:
  /// **'Debit Card Management'**
  String get debitCardManagement;

  /// Card limits option
  ///
  /// In en, this message translates to:
  /// **'Card Limits'**
  String get cardLimits;

  /// Card limits description
  ///
  /// In en, this message translates to:
  /// **'Set daily spending and withdrawal limits'**
  String get cardLimitsDesc;

  /// ATM locations option
  ///
  /// In en, this message translates to:
  /// **'ATM Locations'**
  String get atmLocations;

  /// ATM locations description
  ///
  /// In en, this message translates to:
  /// **'Find nearby ATMs'**
  String get atmLocationsDesc;

  /// Credit card management section title
  ///
  /// In en, this message translates to:
  /// **'Credit Card Management'**
  String get creditCardManagement;

  /// Credit limit description
  ///
  /// In en, this message translates to:
  /// **'View your credit limit and request increase'**
  String get creditLimitDesc;

  /// Installment options title
  ///
  /// In en, this message translates to:
  /// **'Installment Options'**
  String get installmentOptions;

  /// Installment options description
  ///
  /// In en, this message translates to:
  /// **'Convert your purchases to installments'**
  String get installmentOptionsDesc;

  /// Savings management section title
  ///
  /// In en, this message translates to:
  /// **'Savings Management'**
  String get savingsManagement;

  /// Savings goals option
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get savingsGoals;

  /// Savings goals description
  ///
  /// In en, this message translates to:
  /// **'Set and track your savings goals'**
  String get savingsGoalsDesc;

  /// Auto save option
  ///
  /// In en, this message translates to:
  /// **'Auto Save'**
  String get autoSave;

  /// Auto save description
  ///
  /// In en, this message translates to:
  /// **'Create automatic saving rules'**
  String get autoSaveDesc;

  /// Opening message
  ///
  /// In en, this message translates to:
  /// **'opening...'**
  String get opening;

  /// Add transaction button text
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Select transaction type message
  ///
  /// In en, this message translates to:
  /// **'Select the type of transaction you want to make'**
  String get selectTransactionType;

  /// Select transaction type description
  ///
  /// In en, this message translates to:
  /// **'What type of transaction would you like to make?'**
  String get selectTransactionTypeDesc;

  /// Expense saved success message
  ///
  /// In en, this message translates to:
  /// **'Expense saved: {amount}'**
  String expenseSaved(String amount);

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// Enter amount step title
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get enterAmount;

  /// Select category label
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// Payment method step title
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// Details step title
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Amount required validation message
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// Enter valid amount validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get enterValidAmountMessage;

  /// Select category validation message
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get selectCategoryMessage;

  /// Select payment method validation message
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get selectPaymentMethodMessage;

  /// Save expense button text
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get saveExpense;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Last check and details description
  ///
  /// In en, this message translates to:
  /// **'Final review and details'**
  String get lastCheckAndDetails;

  /// Summary step
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// Category placeholder
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Payment label
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// Date label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Description field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Card payment method
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// Cash payment (no installments)
  ///
  /// In en, this message translates to:
  /// **'Full Payment'**
  String get cashPayment;

  /// Installments count
  ///
  /// In en, this message translates to:
  /// **'{count} Installments'**
  String installments(int count);

  /// Food and drink category
  ///
  /// In en, this message translates to:
  /// **'Food & Drink'**
  String get foodAndDrink;

  /// Transport category
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// Shopping category
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// Entertainment category
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainment;

  /// Bills category
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// Health category
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// Education category
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// Other category
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Income transaction type
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeType;

  /// Expense transaction type
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseType;

  /// Transfer transaction type
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferType;

  /// Investment type label
  ///
  /// In en, this message translates to:
  /// **'Investment Type'**
  String get investmentType;

  /// Income transaction description
  ///
  /// In en, this message translates to:
  /// **'Salary, bonus, sales income'**
  String get incomeDescription;

  /// Expense transaction description
  ///
  /// In en, this message translates to:
  /// **'Shopping, bills, expenses'**
  String get expenseDescription;

  /// Transfer transaction description
  ///
  /// In en, this message translates to:
  /// **'Transfer between accounts'**
  String get transferDescription;

  /// Investment transaction description
  ///
  /// In en, this message translates to:
  /// **'Stocks, crypto, gold'**
  String get investmentDescription;

  /// Recurring transaction type
  ///
  /// In en, this message translates to:
  /// **'Recurring Payments'**
  String get recurringType;

  /// Recurring transaction description
  ///
  /// In en, this message translates to:
  /// **'Netflix, bills, subscriptions'**
  String get recurringDescription;

  /// Select frequency title
  ///
  /// In en, this message translates to:
  /// **'Select Frequency'**
  String get selectFrequency;

  /// Save recurring payment button text
  ///
  /// In en, this message translates to:
  /// **'Save Recurring Payment'**
  String get saveRecurring;

  /// Weekly frequency
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// Monthly frequency
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// Quarterly frequency
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get quarterly;

  /// Yearly frequency
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// Weekly frequency description
  ///
  /// In en, this message translates to:
  /// **'Repeats every week'**
  String get weeklyDescription;

  /// Monthly frequency description
  ///
  /// In en, this message translates to:
  /// **'Repeats every month'**
  String get monthlyDescription;

  /// Quarterly frequency description
  ///
  /// In en, this message translates to:
  /// **'Repeats every 3 months'**
  String get quarterlyDescription;

  /// Yearly frequency description
  ///
  /// In en, this message translates to:
  /// **'Repeats every year'**
  String get yearlyDescription;

  /// Subscription category
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// Utilities category
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get utilities;

  /// Insurance category
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// Rent category
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// Loan category
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get loan;

  /// Subscription category description
  ///
  /// In en, this message translates to:
  /// **'Netflix, Spotify, YouTube'**
  String get subscriptionDescription;

  /// Utilities category description
  ///
  /// In en, this message translates to:
  /// **'Electricity, water, gas'**
  String get utilitiesDescription;

  /// Insurance category description
  ///
  /// In en, this message translates to:
  /// **'Health, auto, home insurance'**
  String get insuranceDescription;

  /// Rent category description
  ///
  /// In en, this message translates to:
  /// **'House rent, office rent'**
  String get rentDescription;

  /// Loan category description
  ///
  /// In en, this message translates to:
  /// **'Credit card, installments'**
  String get loanDescription;

  /// Other recurring category description
  ///
  /// In en, this message translates to:
  /// **'Other recurring payments'**
  String get otherDescription;

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Income form opening message
  ///
  /// In en, this message translates to:
  /// **'Income form will open'**
  String get incomeFormOpening;

  /// Transfer form opening message
  ///
  /// In en, this message translates to:
  /// **'Transfer form will open'**
  String get transferFormOpening;

  /// Investment form opening message
  ///
  /// In en, this message translates to:
  /// **'Investment form will open'**
  String get investmentFormOpening;

  /// How much did you spend question
  ///
  /// In en, this message translates to:
  /// **'How much did you spend?'**
  String get howMuchSpent;

  /// Which category did you spend in question
  ///
  /// In en, this message translates to:
  /// **'Which category did you spend in?'**
  String get whichCategorySpent;

  /// How did you pay question
  ///
  /// In en, this message translates to:
  /// **'How did you pay?'**
  String get howDidYouPay;

  /// Save income button text
  ///
  /// In en, this message translates to:
  /// **'Save Income'**
  String get saveIncome;

  /// Food category
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// Food expense category description
  ///
  /// In en, this message translates to:
  /// **'Restaurant, grocery, coffee'**
  String get foodDescription;

  /// Transport expense category description
  ///
  /// In en, this message translates to:
  /// **'Taxi, bus, fuel'**
  String get transportDescription;

  /// Shopping expense category description
  ///
  /// In en, this message translates to:
  /// **'Clothing, electronics, home'**
  String get shoppingDescription;

  /// Bills expense category description
  ///
  /// In en, this message translates to:
  /// **'Electricity, water, internet'**
  String get billsDescription;

  /// Entertainment expense category description
  ///
  /// In en, this message translates to:
  /// **'Cinema, concert, games'**
  String get entertainmentDescription;

  /// Health expense category description
  ///
  /// In en, this message translates to:
  /// **'Doctor, pharmacy, sports'**
  String get healthDescription;

  /// Education expense category description
  ///
  /// In en, this message translates to:
  /// **'Course, books, school'**
  String get educationDescription;

  /// Travel category
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// Travel expense category description
  ///
  /// In en, this message translates to:
  /// **'Vacation, flight, hotel'**
  String get travelDescription;

  /// How much did you earn question
  ///
  /// In en, this message translates to:
  /// **'How much did you earn?'**
  String get howMuchEarned;

  /// Which category did you earn in question
  ///
  /// In en, this message translates to:
  /// **'Which category did you earn in?'**
  String get whichCategoryEarned;

  /// How did you receive payment question
  ///
  /// In en, this message translates to:
  /// **'How did you receive it?'**
  String get howDidYouReceive;

  /// Income saved success message
  ///
  /// In en, this message translates to:
  /// **'Income saved: {amount}'**
  String incomeSaved(String amount);

  /// Salary income category
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// Salary income category description
  ///
  /// In en, this message translates to:
  /// **'Monthly salary, wage'**
  String get salaryDescription;

  /// Bonus income category
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get bonus;

  /// Bonus income category description
  ///
  /// In en, this message translates to:
  /// **'Bonus, incentive, reward'**
  String get bonusDescription;

  /// Freelance income category
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get freelance;

  /// Freelance income category description
  ///
  /// In en, this message translates to:
  /// **'Freelance work, project'**
  String get freelanceDescription;

  /// Business income category
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// Business income category description
  ///
  /// In en, this message translates to:
  /// **'Business income, trade'**
  String get businessDescription;

  /// Rental income category
  ///
  /// In en, this message translates to:
  /// **'Rental'**
  String get rental;

  /// Rental income category description
  ///
  /// In en, this message translates to:
  /// **'House rent, car rental'**
  String get rentalDescription;

  /// Gift income category
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get gift;

  /// Gift income category description
  ///
  /// In en, this message translates to:
  /// **'Gift, donation, allowance'**
  String get giftDescription;

  /// Save transfer button text
  ///
  /// In en, this message translates to:
  /// **'Save Transfer'**
  String get saveTransfer;

  /// How much to invest question
  ///
  /// In en, this message translates to:
  /// **'How Much Will You Invest?'**
  String get howMuchInvest;

  /// Which investment type question
  ///
  /// In en, this message translates to:
  /// **'Which Investment Type?'**
  String get whichInvestmentType;

  /// Stocks tab label
  ///
  /// In en, this message translates to:
  /// **'Stocks'**
  String get stocks;

  /// Stocks investment category description
  ///
  /// In en, this message translates to:
  /// **'Stock market, shares'**
  String get stocksDescription;

  /// Crypto investment category
  ///
  /// In en, this message translates to:
  /// **'Cryptocurrency'**
  String get crypto;

  /// Crypto investment category description
  ///
  /// In en, this message translates to:
  /// **'Bitcoin, Ethereum, altcoin'**
  String get cryptoDescription;

  /// Gold investment category
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// Gold investment category description
  ///
  /// In en, this message translates to:
  /// **'Gold bars, gold coins'**
  String get goldDescription;

  /// Bonds investment category
  ///
  /// In en, this message translates to:
  /// **'Bonds'**
  String get bonds;

  /// Bonds investment category description
  ///
  /// In en, this message translates to:
  /// **'Government bonds, corporate bonds'**
  String get bondsDescription;

  /// Funds investment category
  ///
  /// In en, this message translates to:
  /// **'Funds'**
  String get funds;

  /// Funds investment category description
  ///
  /// In en, this message translates to:
  /// **'Mutual funds, pension funds'**
  String get fundsDescription;

  /// Forex investment category
  ///
  /// In en, this message translates to:
  /// **'Forex'**
  String get forex;

  /// Forex investment category description
  ///
  /// In en, this message translates to:
  /// **'USD, EUR, GBP'**
  String get forexDescription;

  /// Real estate investment category
  ///
  /// In en, this message translates to:
  /// **'Real Estate'**
  String get realEstate;

  /// Real estate investment category description
  ///
  /// In en, this message translates to:
  /// **'House, land, shop'**
  String get realEstateDescription;

  /// Save investment button
  ///
  /// In en, this message translates to:
  /// **'Save Investment'**
  String get saveInvestment;

  /// Investment saved success message
  ///
  /// In en, this message translates to:
  /// **'Investment saved: {amount}'**
  String investmentSaved(String amount);

  /// Select investment type validation message
  ///
  /// In en, this message translates to:
  /// **'Please select investment type'**
  String get selectInvestmentTypeMessage;

  /// Quantity required error
  ///
  /// In en, this message translates to:
  /// **'Quantity required'**
  String get quantityRequired;

  /// Enter valid quantity error
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity'**
  String get enterValidQuantity;

  /// Rate required validation message
  ///
  /// In en, this message translates to:
  /// **'Rate is required'**
  String get rateRequired;

  /// Enter valid rate validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid rate'**
  String get enterValidRate;

  /// Quantity label
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Rate label
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// Total amount label
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// Onboarding features page title
  ///
  /// In en, this message translates to:
  /// **'What Can You Do with Qanta?'**
  String get onboardingFeaturesTitle;

  /// Expense tracking feature title
  ///
  /// In en, this message translates to:
  /// **'Expense Tracking'**
  String get expenseTrackingTitle;

  /// Expense tracking feature description
  ///
  /// In en, this message translates to:
  /// **'Easily track your daily expenses'**
  String get expenseTrackingDesc;

  /// Smart savings feature title
  ///
  /// In en, this message translates to:
  /// **'Smart Savings'**
  String get smartSavingsTitle;

  /// Smart savings feature description
  ///
  /// In en, this message translates to:
  /// **'Save money to reach your goals'**
  String get smartSavingsDesc;

  /// Financial analysis feature title
  ///
  /// In en, this message translates to:
  /// **'Financial Analysis'**
  String get financialAnalysisTitle;

  /// Financial analysis feature description
  ///
  /// In en, this message translates to:
  /// **'Analyze your spending habits'**
  String get financialAnalysisDesc;

  /// Card management feature title
  ///
  /// In en, this message translates to:
  /// **'Card Management'**
  String get cardManagementTitle;

  /// Card management feature description
  ///
  /// In en, this message translates to:
  /// **'Manage credit cards, debit cards and cash accounts'**
  String get cardManagementDesc;

  /// Stock tracking feature title
  ///
  /// In en, this message translates to:
  /// **'Stock Tracking'**
  String get stockTrackingTitle;

  /// Stock tracking feature description
  ///
  /// In en, this message translates to:
  /// **'Track your stock portfolio and investments'**
  String get stockTrackingDesc;

  /// Budget management feature title
  ///
  /// In en, this message translates to:
  /// **'Budget Management'**
  String get budgetManagementTitle;

  /// Budget management feature description
  ///
  /// In en, this message translates to:
  /// **'Set budgets and track your spending limits'**
  String get budgetManagementDesc;

  /// AI insights feature title
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get aiInsightsTitle;

  /// AI insights feature description
  ///
  /// In en, this message translates to:
  /// **'Get smart financial recommendations and insights'**
  String get aiInsightsDesc;

  /// Short expense tracking description
  ///
  /// In en, this message translates to:
  /// **'Record and categorize your daily expenses with detailed tracking'**
  String get expenseTrackingDescShort;

  /// Short card management description
  ///
  /// In en, this message translates to:
  /// **'Manage credit cards, debit cards and cash accounts in one place'**
  String get cardManagementDescShort;

  /// Short stock tracking description
  ///
  /// In en, this message translates to:
  /// **'Monitor your stock portfolio with real-time prices and performance'**
  String get stockTrackingDescShort;

  /// Short financial analysis description
  ///
  /// In en, this message translates to:
  /// **'Analyze spending patterns and financial trends'**
  String get financialAnalysisDescShort;

  /// Short budget management description
  ///
  /// In en, this message translates to:
  /// **'Set monthly budgets and track your spending limits'**
  String get budgetManagementDescShort;

  /// Short AI insights description
  ///
  /// In en, this message translates to:
  /// **'Get personalized financial recommendations and insights'**
  String get aiInsightsDescShort;

  /// Language selection page title
  ///
  /// In en, this message translates to:
  /// **'Language Selection'**
  String get languageSelectionTitle;

  /// Language selection page description
  ///
  /// In en, this message translates to:
  /// **'Which language would you like to use the app in?'**
  String get languageSelectionDesc;

  /// Theme selection page title
  ///
  /// In en, this message translates to:
  /// **'Theme Selection'**
  String get themeSelectionTitle;

  /// Theme selection page description
  ///
  /// In en, this message translates to:
  /// **'Which theme do you prefer?'**
  String get themeSelectionDesc;

  /// Light theme option title
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightThemeTitle;

  /// Light theme option description
  ///
  /// In en, this message translates to:
  /// **'Classic white theme'**
  String get lightThemeDesc;

  /// Dark theme option title
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkThemeTitle;

  /// Dark theme option description
  ///
  /// In en, this message translates to:
  /// **'Easy on your eyes'**
  String get darkThemeDesc;

  /// Exit onboarding dialog title
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitOnboarding;

  /// Exit onboarding dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit without completing the onboarding?'**
  String get exitOnboardingMessage;

  /// Cancel exit dialog button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get exitCancel;

  /// Back button tooltip
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Update cash balance button text
  ///
  /// In en, this message translates to:
  /// **'Update Cash Balance'**
  String get updateCashBalance;

  /// Update cash balance description
  ///
  /// In en, this message translates to:
  /// **'Enter your current cash amount'**
  String get updateCashBalanceDesc;

  /// Update cash balance dialog title
  ///
  /// In en, this message translates to:
  /// **'Update Cash Balance'**
  String get updateCashBalanceTitle;

  /// Update cash balance dialog message
  ///
  /// In en, this message translates to:
  /// **'Enter your current cash amount:'**
  String get updateCashBalanceMessage;

  /// New balance input label
  ///
  /// In en, this message translates to:
  /// **'New Balance'**
  String get newBalance;

  /// Update button text
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Cash balance updated success message
  ///
  /// In en, this message translates to:
  /// **'Cash balance updated to {amount}'**
  String cashBalanceUpdated(String amount);

  /// Cash account load error message
  ///
  /// In en, this message translates to:
  /// **'Error loading cash account'**
  String get cashAccountLoadError;

  /// Unknown error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String unknownError(String error);

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No cash transactions message
  ///
  /// In en, this message translates to:
  /// **'No cash transactions yet'**
  String get noCashTransactions;

  /// No cash transactions description
  ///
  /// In en, this message translates to:
  /// **'Your first cash transaction will appear here'**
  String get noCashTransactionsDesc;

  /// Title for cash balance increase transaction
  ///
  /// In en, this message translates to:
  /// **'Cash Added'**
  String get balanceUpdated;

  /// Subtitle for manual cash addition
  ///
  /// In en, this message translates to:
  /// **'Manual cash addition'**
  String get walletBalanceUpdated;

  /// Grocery shopping transaction title
  ///
  /// In en, this message translates to:
  /// **'Grocery Shopping'**
  String get groceryShopping;

  /// Cash payment transaction subtitle
  ///
  /// In en, this message translates to:
  /// **'Cash payment'**
  String get cashPaymentMade;

  /// Taxi fare transaction title
  ///
  /// In en, this message translates to:
  /// **'Taxi Fare'**
  String get taxiFare;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @cardDetails.
  ///
  /// In en, this message translates to:
  /// **'Card Details'**
  String get cardDetails;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Transaction type label
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// Installment info format
  ///
  /// In en, this message translates to:
  /// **'{current}/{total} Installments'**
  String installmentInfo(int current, int total);

  /// Available credit limit label
  ///
  /// In en, this message translates to:
  /// **'Available Limit'**
  String get availableLimit;

  /// How much transfer question
  ///
  /// In en, this message translates to:
  /// **'How much will you transfer?'**
  String get howMuchTransfer;

  /// From which account question
  ///
  /// In en, this message translates to:
  /// **'From which account?'**
  String get fromWhichAccount;

  /// To which account question
  ///
  /// In en, this message translates to:
  /// **'To which account?'**
  String get toWhichAccount;

  /// Investment income category
  ///
  /// In en, this message translates to:
  /// **'Investment Income'**
  String get investmentIncome;

  /// Investment income category description
  ///
  /// In en, this message translates to:
  /// **'Stocks, funds, rental income'**
  String get investmentIncomeDescription;

  /// Silver investment type
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silver;

  /// USD investment type
  ///
  /// In en, this message translates to:
  /// **'USD'**
  String get usd;

  /// EUR investment type
  ///
  /// In en, this message translates to:
  /// **'EUR'**
  String get eur;

  /// Gold unit
  ///
  /// In en, this message translates to:
  /// **'gram'**
  String get goldUnit;

  /// Silver unit
  ///
  /// In en, this message translates to:
  /// **'gram'**
  String get silverUnit;

  /// USD unit
  ///
  /// In en, this message translates to:
  /// **'unit'**
  String get usdUnit;

  /// EUR unit
  ///
  /// In en, this message translates to:
  /// **'unit'**
  String get eurUnit;

  /// Silver investment description
  ///
  /// In en, this message translates to:
  /// **'Silver investment'**
  String get silverDescription;

  /// USD investment description
  ///
  /// In en, this message translates to:
  /// **'US Dollar'**
  String get usdDescription;

  /// EUR investment description
  ///
  /// In en, this message translates to:
  /// **'Euro currency'**
  String get eurDescription;

  /// Select investment type title
  ///
  /// In en, this message translates to:
  /// **'Select Investment Type'**
  String get selectInvestmentType;

  /// Investment category
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get investment;

  /// Other income category
  ///
  /// In en, this message translates to:
  /// **'Other Income'**
  String get otherIncome;

  /// Recurring payment title
  ///
  /// In en, this message translates to:
  /// **'Recurring Payment'**
  String get recurringPayment;

  /// Save recurring payment button
  ///
  /// In en, this message translates to:
  /// **'Save Recurring Payment'**
  String get saveRecurringPayment;

  /// No transactions message
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// Empty state description when no transactions exist
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add your first transaction'**
  String get noTransactionsDescription;

  /// Empty state title when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No search results found'**
  String get noSearchResults;

  /// Empty state description when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String noSearchResultsDescription(String query);

  /// Error state title when transactions fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load transactions'**
  String get transactionsLoadError;

  /// Error state description for connection issues
  ///
  /// In en, this message translates to:
  /// **'Connection problem occurred'**
  String get connectionError;

  /// Try again button text
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No accounts available message
  ///
  /// In en, this message translates to:
  /// **'No accounts available'**
  String get noAccountsAvailable;

  /// Debit card account type
  ///
  /// In en, this message translates to:
  /// **'Debit Card'**
  String get debitCard;

  /// Statistics page title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTitle;

  /// Monthly overview section title
  ///
  /// In en, this message translates to:
  /// **'Monthly Overview'**
  String get monthlyOverview;

  /// Total income label
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// Total expenses label
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// Net balance full label
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalance;

  /// Category breakdown section title
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdown;

  /// Spending trends section title
  ///
  /// In en, this message translates to:
  /// **'Spending Trends'**
  String get spendingTrends;

  /// This month
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// Last month
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// Last 3 months
  ///
  /// In en, this message translates to:
  /// **'Last 3 Months'**
  String get last3Months;

  /// Last 6 months label
  ///
  /// In en, this message translates to:
  /// **'Last 6 Months'**
  String get last6Months;

  /// Year to date label
  ///
  /// In en, this message translates to:
  /// **'Year to Date'**
  String get yearToDate;

  /// No data available message
  ///
  /// In en, this message translates to:
  /// **'No Data Available'**
  String get noDataAvailable;

  /// No transactions found message
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// Average spending label
  ///
  /// In en, this message translates to:
  /// **'Average Spending'**
  String get averageSpending;

  /// Highest spending label
  ///
  /// In en, this message translates to:
  /// **'Highest Spending'**
  String get highestSpending;

  /// Lowest spending label
  ///
  /// In en, this message translates to:
  /// **'Lowest Spending'**
  String get lowestSpending;

  /// Savings rate label
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get savingsRate;

  /// No description provided for @smartInsights.
  ///
  /// In en, this message translates to:
  /// **'Smart Insights'**
  String get smartInsights;

  /// No description provided for @visualAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Visual Analytics'**
  String get visualAnalytics;

  /// No description provided for @categoryAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Category Analysis'**
  String get categoryAnalysis;

  /// No description provided for @financialHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Financial Health Score'**
  String get financialHealthScore;

  /// No description provided for @spendingTrend.
  ///
  /// In en, this message translates to:
  /// **'Spending Trend'**
  String get spendingTrend;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data to analyze yet'**
  String get noDataYet;

  /// Add first transaction message
  ///
  /// In en, this message translates to:
  /// **'Add your first expense to get started'**
  String get addFirstTransaction;

  /// No description provided for @analyzingData.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your financial data...'**
  String get analyzingData;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'This may take a few seconds'**
  String get pleaseWait;

  /// No description provided for @dataLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get dataLoadError;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @needsImprovement.
  ///
  /// In en, this message translates to:
  /// **'Needs Improvement'**
  String get needsImprovement;

  /// No description provided for @dailyAverage.
  ///
  /// In en, this message translates to:
  /// **'Daily Average'**
  String get dailyAverage;

  /// More categories text
  ///
  /// In en, this message translates to:
  /// **'more categories'**
  String get moreCategories;

  /// No description provided for @netWorth.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get netWorth;

  /// No description provided for @positive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get positive;

  /// No description provided for @negative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get negative;

  /// No description provided for @totalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get totalAssets;

  /// No description provided for @totalDebts.
  ///
  /// In en, this message translates to:
  /// **'Total Debts'**
  String get totalDebts;

  /// Available Credit
  ///
  /// In en, this message translates to:
  /// **'Available Credit'**
  String get availableCredit;

  /// No description provided for @netAmount.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get netAmount;

  /// No description provided for @transactionCount.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionCount;

  /// Camera option for image picker
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Gallery option for image picker
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Delete photo option
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get deletePhoto;

  /// Photo upload error message
  ///
  /// In en, this message translates to:
  /// **'Error uploading photo: {error}'**
  String photoUploadError(String error);

  /// Photo delete error message
  ///
  /// In en, this message translates to:
  /// **'Error deleting photo: {error}'**
  String photoDeleteError(String error);

  /// File not found error
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFound;

  /// File too large error message
  ///
  /// In en, this message translates to:
  /// **'File too large (max 5MB)'**
  String get fileTooLarge;

  /// User session not found error
  ///
  /// In en, this message translates to:
  /// **'User session not found'**
  String get userSessionNotFound;

  /// Photo deleted successfully message
  ///
  /// In en, this message translates to:
  /// **'Photo deleted successfully'**
  String get photoDeletedSuccessfully;

  /// Photo uploaded successfully message
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded successfully'**
  String get photoUploadedSuccessfully;

  /// Select image source dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// Select image source dialog description
  ///
  /// In en, this message translates to:
  /// **'Where would you like to select your photo from?'**
  String get selectImageSourceDescription;

  /// Photo uploading loading message
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get uploadingPhoto;

  /// Photo deleting loading message
  ///
  /// In en, this message translates to:
  /// **'Deleting photo...'**
  String get deletingPhoto;

  /// Profile photo label
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhoto;

  /// Change profile photo button
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get changeProfilePhoto;

  /// Remove profile photo button
  ///
  /// In en, this message translates to:
  /// **'Remove Profile Photo'**
  String get removeProfilePhoto;

  /// Profile photo updated message
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// Profile photo removed message
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed'**
  String get profilePhotoRemoved;

  /// Delete transaction action sheet title
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// Delete transaction confirmation message
  ///
  /// In en, this message translates to:
  /// **'transaction. Are you sure you want to delete it?'**
  String deleteTransactionConfirm(String description);

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Transaction deleted message
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// Transaction delete error message
  ///
  /// In en, this message translates to:
  /// **'Error deleting transaction: {error}'**
  String transactionDeleteError(String error);

  /// Delete installment transaction action sheet title
  ///
  /// In en, this message translates to:
  /// **'Delete Installment Transaction'**
  String get deleteInstallmentTransaction;

  /// Delete installment transaction confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to completely delete the installment transaction {description}? This will delete all installments.'**
  String deleteInstallmentTransactionConfirm(String description);

  /// Installment transaction deleted success message
  ///
  /// In en, this message translates to:
  /// **'Installment transaction deleted, total amount refunded'**
  String get installmentTransactionDeleted;

  /// Installment transaction delete error message
  ///
  /// In en, this message translates to:
  /// **'Error deleting installment transaction: {error}'**
  String installmentTransactionDeleteError(String error);

  /// Delete all button text
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// Delete limit dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Limit'**
  String get deleteLimit;

  /// Delete limit confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the limit set for {categoryName} category?'**
  String deleteLimitConfirm(String categoryName);

  /// Limit deleted success message
  ///
  /// In en, this message translates to:
  /// **'Limit deleted'**
  String get limitDeleted;

  /// Delete limit tooltip
  ///
  /// In en, this message translates to:
  /// **'Delete Limit'**
  String get deleteLimitTooltip;

  /// Error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Loading past statements message
  ///
  /// In en, this message translates to:
  /// **'Loading past statements...'**
  String get loadingPastStatements;

  /// Loading future statements message
  ///
  /// In en, this message translates to:
  /// **'Loading future statements...'**
  String get loadingFutureStatements;

  /// Loading cards error message
  ///
  /// In en, this message translates to:
  /// **'Error loading cards'**
  String get loadingCards;

  /// Loading accounts message
  ///
  /// In en, this message translates to:
  /// **'Loading accounts'**
  String get loadingAccounts;

  /// Loading statement info error message
  ///
  /// In en, this message translates to:
  /// **'Error loading statement information'**
  String get loadingStatementInfo;

  /// Payment error message
  ///
  /// In en, this message translates to:
  /// **'Error occurred during payment'**
  String get paymentError;

  /// Statement mark error message
  ///
  /// In en, this message translates to:
  /// **'Error marking statement'**
  String get statementMarkError;

  /// Delete card dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Card'**
  String get deleteCard;

  /// Delete card confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {cardName} card?\n\nThis action cannot be undone.'**
  String deleteCardConfirm(String cardName);

  /// Card deleted success message
  ///
  /// In en, this message translates to:
  /// **'Card deleted successfully'**
  String get cardDeleted;

  /// Card delete error message
  ///
  /// In en, this message translates to:
  /// **'Error deleting card'**
  String get cardDeleteError;

  /// Transaction add error message
  ///
  /// In en, this message translates to:
  /// **'Error adding transaction: {error}'**
  String transactionAddError(String error);

  /// Update error message
  ///
  /// In en, this message translates to:
  /// **'Error during update: {error}'**
  String updateError(String error);

  /// Delete failed message
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// Installment transaction deleting message
  ///
  /// In en, this message translates to:
  /// **'Deleting installment transaction...'**
  String get installmentTransactionDeleting;

  /// Installment transaction deleted with refund message
  ///
  /// In en, this message translates to:
  /// **'Installment transaction deleted, total amount refunded'**
  String get installmentTransactionDeletedWithRefund;

  /// Cancel action button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// Quick notes title
  ///
  /// In en, this message translates to:
  /// **'Quick Notes'**
  String get quickNotes;

  /// Quick notes feature subtitle
  ///
  /// In en, this message translates to:
  /// **'Persistent notification for instant note taking'**
  String get quickNotesSubtitle;

  /// Quick notes notification enabled message
  ///
  /// In en, this message translates to:
  /// **'Quick notes notification enabled'**
  String get quickNotesNotificationEnabled;

  /// Quick notes notification disabled message
  ///
  /// In en, this message translates to:
  /// **'Quick notes notification disabled'**
  String get quickNotesNotificationDisabled;

  /// Notification permission required message
  ///
  /// In en, this message translates to:
  /// **'Notification permission required! Please enable it in settings.'**
  String get notificationPermissionRequired;

  /// Frequently Asked Questions
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// Account type fallback
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Now time reference
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// Yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Expense label
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// Transfer transaction type
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// Today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Minutes ago text
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(int count);

  /// Hours ago text
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// Days ago
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// Weeks ago text
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String weeksAgo(int count);

  /// Months ago text
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String monthsAgo(int count);

  /// Years ago text
  ///
  /// In en, this message translates to:
  /// **'{count} years ago'**
  String yearsAgo(int count);

  /// One minute ago text
  ///
  /// In en, this message translates to:
  /// **'1 min ago'**
  String get oneMinuteAgo;

  /// One hour ago text
  ///
  /// In en, this message translates to:
  /// **'1 hour ago'**
  String get oneHourAgo;

  /// One week ago text
  ///
  /// In en, this message translates to:
  /// **'1 week ago'**
  String get oneWeekAgo;

  /// One month ago text
  ///
  /// In en, this message translates to:
  /// **'1 month ago'**
  String get oneMonthAgo;

  /// One year ago text
  ///
  /// In en, this message translates to:
  /// **'1 year ago'**
  String get oneYearAgo;

  /// Two days ago text
  ///
  /// In en, this message translates to:
  /// **'2 days ago'**
  String get twoDaysAgo;

  /// Per month suffix
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonth;

  /// Net balance label
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// Please enter amount error
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// Please enter valid amount error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// Please select source account error
  ///
  /// In en, this message translates to:
  /// **'Please select source account'**
  String get pleaseSelectSourceAccount;

  /// Please select target account error
  ///
  /// In en, this message translates to:
  /// **'Please select target account'**
  String get pleaseSelectTargetAccount;

  /// Source and target account same error
  ///
  /// In en, this message translates to:
  /// **'Source and target account cannot be the same'**
  String get sourceAndTargetSame;

  /// Account info not found error
  ///
  /// In en, this message translates to:
  /// **'Account information could not be retrieved'**
  String get accountInfoNotFound;

  /// Account information could not be retrieved (single)
  ///
  /// In en, this message translates to:
  /// **'Account information could not be retrieved'**
  String get accountInfoNotFoundSingle;

  /// Please select a category
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// Please select a payment method
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get pleaseSelectPaymentMethod;

  /// Cards loading error
  ///
  /// In en, this message translates to:
  /// **'Error loading cards'**
  String get cardsLoadingError;

  /// Message when no cards are added yet
  ///
  /// In en, this message translates to:
  /// **'No cards added yet'**
  String get noCardsAddedYet;

  /// Transaction generic term
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transaction;

  /// Bank name
  ///
  /// In en, this message translates to:
  /// **'Qanta'**
  String get bankName;

  /// Repeats every week
  ///
  /// In en, this message translates to:
  /// **'Repeats every week'**
  String get repeatsEveryWeek;

  /// Repeats every month
  ///
  /// In en, this message translates to:
  /// **'Repeats every month'**
  String get repeatsEveryMonth;

  /// Repeats every quarter
  ///
  /// In en, this message translates to:
  /// **'Repeats every quarter'**
  String get repeatsEveryQuarter;

  /// Repeats every year
  ///
  /// In en, this message translates to:
  /// **'Repeats every year'**
  String get repeatsEveryYear;

  /// Other fixed payments
  ///
  /// In en, this message translates to:
  /// **'Other fixed payments'**
  String get otherFixedPayments;

  /// This week time period
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// This year time period
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// Last year
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get lastYear;

  /// Custom period
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// Search transactions placeholder
  ///
  /// In en, this message translates to:
  /// **'Search Transactions'**
  String get searchTransactions;

  /// Filter by type
  ///
  /// In en, this message translates to:
  /// **'Filter by Type'**
  String get filterByType;

  /// Filter by period
  ///
  /// In en, this message translates to:
  /// **'Filter by Period'**
  String get filterByPeriod;

  /// Filter by category
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get filterByCategory;

  /// Clear filters
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// Apply filters
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No results found
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// Try different search
  ///
  /// In en, this message translates to:
  /// **'Try a different search'**
  String get tryDifferentSearch;

  /// No notes yet
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// Add expense or income notes description
  ///
  /// In en, this message translates to:
  /// **'Add your expense or income notes here'**
  String get addExpenseIncomeNotes;

  /// Just now
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Monday
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// Tuesday
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// Wednesday
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// Thursday
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// Friday
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// Saturday
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// Sunday
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// January
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// February
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// March
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// April
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// May
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// June
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// July
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// August
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// September
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// October
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// November
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// December
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// Text note option
  ///
  /// In en, this message translates to:
  /// **'Text Note'**
  String get textNote;

  /// Add quick text note description
  ///
  /// In en, this message translates to:
  /// **'Add quick text note'**
  String get addQuickTextNote;

  /// Take photo option
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Take photo from camera description
  ///
  /// In en, this message translates to:
  /// **'Take photo from camera'**
  String get takePhotoFromCamera;

  /// Select from gallery option
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectFromGallery;

  /// Select photo from gallery description
  ///
  /// In en, this message translates to:
  /// **'Select photo from gallery'**
  String get selectPhotoFromGallery;

  /// Photo capture error message
  ///
  /// In en, this message translates to:
  /// **'Error capturing photo'**
  String get photoCaptureError;

  /// Photo selection error message
  ///
  /// In en, this message translates to:
  /// **'Error selecting photo'**
  String get photoSelectionError;

  /// Add
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Photo note default text
  ///
  /// In en, this message translates to:
  /// **'Photo note'**
  String get photoNote;

  /// Photo note added success message
  ///
  /// In en, this message translates to:
  /// **'Photo note added'**
  String get photoNoteAdded;

  /// Photo note add error message
  ///
  /// In en, this message translates to:
  /// **'Error adding photo note'**
  String get photoNoteAddError;

  /// Note added success message
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get noteAdded;

  /// Note add error message
  ///
  /// In en, this message translates to:
  /// **'Error adding note'**
  String get noteAddError;

  /// Note deleted success message
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeleted;

  /// Note delete error message
  ///
  /// In en, this message translates to:
  /// **'Error deleting note'**
  String get noteDeleteError;

  /// No notes converted to transactions yet
  ///
  /// In en, this message translates to:
  /// **'No notes converted to transactions yet'**
  String get noConvertedNotesYet;

  /// Stop
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Send
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Processed
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get processed;

  /// Newest
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// Oldest
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// Highest to Lowest
  ///
  /// In en, this message translates to:
  /// **'Highest to Lowest'**
  String get highestToLowest;

  /// Lowest to Highest
  ///
  /// In en, this message translates to:
  /// **'Lowest to Highest'**
  String get lowestToHighest;

  /// Alphabetical
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get alphabetical;

  /// More
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// Less
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// Card name label
  ///
  /// In en, this message translates to:
  /// **'Card Name'**
  String get cardName;

  /// Usage percentage label
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get usage;

  /// Last payment date label
  ///
  /// In en, this message translates to:
  /// **'Last Payment'**
  String get lastPayment;

  /// Next Payment
  ///
  /// In en, this message translates to:
  /// **'Next Payment'**
  String get nextPayment;

  /// Minimum Payment
  ///
  /// In en, this message translates to:
  /// **'Minimum Payment'**
  String get minimumPayment;

  /// Total Debt
  ///
  /// In en, this message translates to:
  /// **'Total Debt'**
  String get totalDebt;

  /// No transactions found for this card
  ///
  /// In en, this message translates to:
  /// **'No transactions found for this card'**
  String get noTransactionsForThisCard;

  /// Statement successfully marked as paid
  ///
  /// In en, this message translates to:
  /// **'Statement successfully marked as paid'**
  String get statementSuccessfullyPaid;

  /// Bank
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// Card name is required
  ///
  /// In en, this message translates to:
  /// **'Card name is required'**
  String get cardNameRequired;

  /// Credit limit is required
  ///
  /// In en, this message translates to:
  /// **'Credit limit is required'**
  String get creditLimitRequired;

  /// Debt amount label
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debt;

  /// No notifications
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// Usage Rate
  ///
  /// In en, this message translates to:
  /// **'Usage Rate'**
  String get usageRate;

  /// Statement Day
  ///
  /// In en, this message translates to:
  /// **'Statement Day'**
  String get statementDay;

  /// Credit Card Info
  ///
  /// In en, this message translates to:
  /// **'Credit Card Info'**
  String get creditCardInfo;

  /// Installment details could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Installment details could not be loaded'**
  String get installmentDetailsLoadError;

  /// Tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Current Password
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// New Password
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Confirm New Password
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// Your password must be at least 6 characters long.
  ///
  /// In en, this message translates to:
  /// **'Your password must be at least 6 characters long.'**
  String get passwordMinLengthInfo;

  /// Password must be at least 6 characters
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Password changed successfully
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// Current password is incorrect
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get wrongCurrentPassword;

  /// Password is too weak
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get passwordTooWeak;

  /// Please log in again to change your password
  ///
  /// In en, this message translates to:
  /// **'Please log in again to change your password'**
  String get requiresRecentLogin;

  /// Password change failed
  ///
  /// In en, this message translates to:
  /// **'Password change failed'**
  String get passwordChangeFailed;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Collected Information
  ///
  /// In en, this message translates to:
  /// **'Collected Information'**
  String get collectedInformation;

  /// Collected Information Content
  ///
  /// In en, this message translates to:
  /// **'The Qanta application collects the following information to provide you with better service:\n\n• Account information (email, name-surname)\n• Financial transaction data (income, expense, transfer records)\n• Card and account information\n• Budget and category preferences\n• Application usage statistics'**
  String get collectedInformationContent;

  /// Information Usage
  ///
  /// In en, this message translates to:
  /// **'Information Usage'**
  String get informationUsage;

  /// Information Usage Content
  ///
  /// In en, this message translates to:
  /// **'The collected information is used for the following purposes:\n\n• Providing personal finance management services\n• Budget tracking and expense analysis\n• Improving application performance\n• Security and fraud prevention\n• Fulfilling legal obligations'**
  String get informationUsageContent;

  /// Data Security
  ///
  /// In en, this message translates to:
  /// **'Data Security'**
  String get dataSecurity;

  /// Data Security Content
  ///
  /// In en, this message translates to:
  /// **'The security of your data is our priority:\n\n• All data is stored encrypted\n• Hosted on secure servers\n• Regular security updates are made\n• Protected against unauthorized access\n• Industry-standard security measures are taken'**
  String get dataSecurityContent;

  /// Data Sharing
  ///
  /// In en, this message translates to:
  /// **'Data Sharing'**
  String get dataSharing;

  /// Data Sharing Content
  ///
  /// In en, this message translates to:
  /// **'Your personal data is not shared with third parties except in the following cases:\n\n• Legal obligations\n• In case of security breaches\n• With your explicit consent\n• Limited sharing with service providers (anonymous)'**
  String get dataSharingContent;

  /// User Rights
  ///
  /// In en, this message translates to:
  /// **'User Rights'**
  String get userRights;

  /// User Rights Content
  ///
  /// In en, this message translates to:
  /// **'Your rights under GDPR:\n\n• Learning whether your personal data is processed\n• Requesting access to your data\n• Requesting correction of incorrect information\n• Requesting deletion of data\n• Completely closing your account'**
  String get userRightsContent;

  /// Contact
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// Contact Content
  ///
  /// In en, this message translates to:
  /// **'For questions about the privacy policy:\n\nEmail: privacy@qanta.app\nAddress: Istanbul, Turkey\n\nThis policy was last updated: January 20, 2025'**
  String get contactContent;

  /// Support & Contact
  ///
  /// In en, this message translates to:
  /// **'Support & Contact'**
  String get supportAndContact;

  /// Phone
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Live Support
  ///
  /// In en, this message translates to:
  /// **'Live Support'**
  String get liveSupport;

  /// Live Support Hours
  ///
  /// In en, this message translates to:
  /// **'Monday-Friday 09:00-18:00'**
  String get liveSupportHours;

  /// Is my data secure?
  ///
  /// In en, this message translates to:
  /// **'Is my data secure?'**
  String get isMyDataSecure;

  /// Is my data secure answer
  ///
  /// In en, this message translates to:
  /// **'Yes, all your data is stored encrypted and hosted on secure servers. We provide industry-standard security using Supabase infrastructure.'**
  String get isMyDataSecureAnswer;

  /// Forgot password answer
  ///
  /// In en, this message translates to:
  /// **'You can use the \"Forgot Password\" option on the login screen to send a password reset link to your email address.'**
  String get forgotPasswordAnswer;

  /// How to delete account
  ///
  /// In en, this message translates to:
  /// **'How can I delete my account?'**
  String get howToDeleteAccount;

  /// How to delete account answer
  ///
  /// In en, this message translates to:
  /// **'You can log out from the profile page or contact our support team to request complete deletion of your account.'**
  String get howToDeleteAccountAnswer;

  /// Is app free?
  ///
  /// In en, this message translates to:
  /// **'Is the app free?'**
  String get isAppFree;

  /// Is app free answer
  ///
  /// In en, this message translates to:
  /// **'Yes, Qanta can be used completely free. Premium features may be added in the future, but basic features will always remain free.'**
  String get isAppFreeAnswer;

  /// App Information
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInformation;

  /// Last update label
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastUpdate;

  /// Developer
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// Platform
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// Live Support Title
  ///
  /// In en, this message translates to:
  /// **'Live Support'**
  String get liveSupportTitle;

  /// Live Support Message
  ///
  /// In en, this message translates to:
  /// **'Live support service is currently in development. For urgent matters, please contact us via email or phone.'**
  String get liveSupportMessage;

  /// Service Description
  ///
  /// In en, this message translates to:
  /// **'Service Description'**
  String get serviceDescription;

  /// Service Description Content
  ///
  /// In en, this message translates to:
  /// **'Qanta is a mobile application designed for personal finance management. The application offers the following services:\n\n• Income and expense tracking\n• Budget management and planning\n• Card and account management\n• Financial reporting and analysis\n• Installment tracking and management'**
  String get serviceDescriptionContent;

  /// Usage Terms
  ///
  /// In en, this message translates to:
  /// **'Usage Terms'**
  String get usageTerms;

  /// Usage Terms Content
  ///
  /// In en, this message translates to:
  /// **'By using the Qanta application, you agree to the following terms:\n\n• You will use the application only for legal purposes\n• You will provide accurate and up-to-date information\n• You will protect your account security\n• You will respect the rights of other users\n• You will avoid misuse of the application'**
  String get usageTermsContent;

  /// User Responsibilities
  ///
  /// In en, this message translates to:
  /// **'User Responsibilities'**
  String get userResponsibilities;

  /// User Responsibilities Content
  ///
  /// In en, this message translates to:
  /// **'As a user, you have the following responsibilities:\n\n• Keeping your account information secure\n• Not sharing your password with anyone\n• Ensuring the accuracy of your financial data\n• Complying with application rules\n• Reporting security breaches'**
  String get userResponsibilitiesContent;

  /// Service Limitations
  ///
  /// In en, this message translates to:
  /// **'Service Limitations'**
  String get serviceLimitations;

  /// Service Limitations Content
  ///
  /// In en, this message translates to:
  /// **'The Qanta application is subject to the following limitations:\n\n• Does not provide financial advisory services\n• Does not give investment advice\n• Does not perform banking transactions\n• Does not provide credit or lending services\n• Does not provide tax advisory services'**
  String get serviceLimitationsContent;

  /// Intellectual Property
  ///
  /// In en, this message translates to:
  /// **'Intellectual Property'**
  String get intellectualProperty;

  /// Intellectual Property Content
  ///
  /// In en, this message translates to:
  /// **'All content of the Qanta application is protected by copyright:\n\n• Application design and code\n• Logo and brand elements\n• Text and visual content\n• Algorithms and calculation methods\n• Database structure'**
  String get intellectualPropertyContent;

  /// Service Changes
  ///
  /// In en, this message translates to:
  /// **'Service Changes'**
  String get serviceChanges;

  /// Service Changes Content
  ///
  /// In en, this message translates to:
  /// **'Qanta reserves the right to make changes to its services:\n\n• Adding or removing features\n• Pricing changes\n• Updating terms of use\n• Service termination\n• Maintenance and updates'**
  String get serviceChangesContent;

  /// Disclaimer
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get disclaimer;

  /// Disclaimer Content
  ///
  /// In en, this message translates to:
  /// **'Qanta is not responsible for the following situations:\n\n• Data loss or corruption\n• System failures or interruptions\n• Third-party service providers\n• Damages resulting from user errors\n• Internet connection issues'**
  String get disclaimerContent;

  /// Terms Contact
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get termsContact;

  /// Terms Contact Content
  ///
  /// In en, this message translates to:
  /// **'For questions about terms of service:\n\nEmail: support@qanta.app\nWeb: www.qanta.app\nAddress: Istanbul, Turkey\n\nThese terms were last updated: January 20, 2025'**
  String get termsContactContent;

  /// FAQ
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faq;

  /// General Questions
  ///
  /// In en, this message translates to:
  /// **'General Questions'**
  String get generalQuestions;

  /// Account and Security
  ///
  /// In en, this message translates to:
  /// **'Account and Security'**
  String get accountAndSecurity;

  /// Features
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// Technical Issues
  ///
  /// In en, this message translates to:
  /// **'Technical Issues'**
  String get technicalIssues;

  /// What is Qanta?
  ///
  /// In en, this message translates to:
  /// **'What is Qanta?'**
  String get whatIsQanta;

  /// What is Qanta answer
  ///
  /// In en, this message translates to:
  /// **'Qanta is a modern mobile application designed for personal finance management. It offers income-expense tracking, budget management, card tracking, and financial analysis features.'**
  String get whatIsQantaAnswer;

  /// Which devices are supported?
  ///
  /// In en, this message translates to:
  /// **'Which devices can I use it on?'**
  String get whichDevicesSupported;

  /// Which devices supported answer
  ///
  /// In en, this message translates to:
  /// **'Qanta can be used on Android and iOS devices. It is developed with Flutter technology.'**
  String get whichDevicesSupportedAnswer;

  /// How to change password
  ///
  /// In en, this message translates to:
  /// **'How can I change my password?'**
  String get howToChangePassword;

  /// How to change password answer
  ///
  /// In en, this message translates to:
  /// **'You can use the \"Change Password\" option from the \"Security\" section on the profile page.'**
  String get howToChangePasswordAnswer;

  /// Which card types are supported?
  ///
  /// In en, this message translates to:
  /// **'Which card types do you support?'**
  String get whichCardTypesSupported;

  /// Which card types supported answer
  ///
  /// In en, this message translates to:
  /// **'Credit cards, debit cards, and cash accounts are supported. Compatible with all Turkish banks.'**
  String get whichCardTypesSupportedAnswer;

  /// How does installment tracking work?
  ///
  /// In en, this message translates to:
  /// **'How does installment tracking work?'**
  String get howDoesInstallmentTrackingWork;

  /// How does installment tracking work answer
  ///
  /// In en, this message translates to:
  /// **'You can add installment purchases and automatically track your monthly payments. The system sends you reminders.'**
  String get howDoesInstallmentTrackingWorkAnswer;

  /// How to use budget management?
  ///
  /// In en, this message translates to:
  /// **'How to use budget management?'**
  String get howToUseBudgetManagement;

  /// How to use budget management answer
  ///
  /// In en, this message translates to:
  /// **'You can set monthly limits for categories, track your expenses, and receive alerts when limits are exceeded.'**
  String get howToUseBudgetManagementAnswer;

  /// What is quick notes feature?
  ///
  /// In en, this message translates to:
  /// **'What is the quick notes feature?'**
  String get whatIsQuickNotesFeature;

  /// What is quick notes feature answer
  ///
  /// In en, this message translates to:
  /// **'You can quickly take notes with persistent notifications, add photos, and categorize your notes.'**
  String get whatIsQuickNotesFeatureAnswer;

  /// App is crashing, what should I do?
  ///
  /// In en, this message translates to:
  /// **'The app is crashing, what should I do?'**
  String get appCrashingWhatToDo;

  /// App crashing what to do answer
  ///
  /// In en, this message translates to:
  /// **'First try closing the app completely and reopening it. If the problem persists, restart your device. If it still doesn\'t resolve, contact our support team.'**
  String get appCrashingWhatToDoAnswer;

  /// Data not syncing
  ///
  /// In en, this message translates to:
  /// **'My data is not syncing'**
  String get dataNotSyncing;

  /// Data not syncing answer
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and restart the app. If the problem persists, try logging out and logging back in.'**
  String get dataNotSyncingAnswer;

  /// Notifications not coming
  ///
  /// In en, this message translates to:
  /// **'Notifications are not coming'**
  String get notificationsNotComing;

  /// Notifications not coming answer
  ///
  /// In en, this message translates to:
  /// **'Make sure notifications are enabled for Qanta in your device settings. Also check notification settings from the profile page.'**
  String get notificationsNotComingAnswer;

  /// How to contact support
  ///
  /// In en, this message translates to:
  /// **'How can I contact your support team?'**
  String get howToContactSupport;

  /// How to contact support answer
  ///
  /// In en, this message translates to:
  /// **'You can use the \"Support & Contact\" section from the profile page or send an email to support@qanta.app.'**
  String get howToContactSupportAnswer;

  /// Have suggestion, where to send
  ///
  /// In en, this message translates to:
  /// **'I have a suggestion, where can I send it?'**
  String get haveSuggestionWhereToSend;

  /// Have suggestion where to send answer
  ///
  /// In en, this message translates to:
  /// **'You can send your suggestions to support@qanta.app. All feedback is evaluated and used to improve the application.'**
  String get haveSuggestionWhereToSendAnswer;

  /// Last month change
  ///
  /// In en, this message translates to:
  /// **'from last month'**
  String get lastMonthChange;

  /// Increase
  ///
  /// In en, this message translates to:
  /// **'increase'**
  String get increase;

  /// Decrease
  ///
  /// In en, this message translates to:
  /// **'decrease'**
  String get decrease;

  /// No accounts yet
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get noAccountsYet;

  /// Add first account to get started
  ///
  /// In en, this message translates to:
  /// **'Add your first account to get started'**
  String get addFirstAccount;

  /// Current Debt
  ///
  /// In en, this message translates to:
  /// **'Current Debt'**
  String get currentDebt;

  /// Total Limit
  ///
  /// In en, this message translates to:
  /// **'Total Limit'**
  String get totalLimit;

  /// Cash Wallet
  ///
  /// In en, this message translates to:
  /// **'Cash Wallet'**
  String get cashWallet;

  /// Search banks
  ///
  /// In en, this message translates to:
  /// **'Search banks...'**
  String get searchBanks;

  /// No banks found
  ///
  /// In en, this message translates to:
  /// **'No banks found'**
  String get noBanksFound;

  /// Add Credit Card
  ///
  /// In en, this message translates to:
  /// **'Add Credit Card'**
  String get addCreditCard;

  /// Card name example
  ///
  /// In en, this message translates to:
  /// **'E.g: VakıfBank Credit Card'**
  String get cardNameExample;

  /// Current Debt (Optional)
  ///
  /// In en, this message translates to:
  /// **'Current Debt (Optional)'**
  String get currentDebtOptional;

  /// Add Debit Card
  ///
  /// In en, this message translates to:
  /// **'Add Debit Card'**
  String get addDebitCard;

  /// Debit card name example
  ///
  /// In en, this message translates to:
  /// **'E.g: VakıfBank Checking'**
  String get cardNameExampleDebit;

  /// Initial Balance
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get initialBalance;

  /// day
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// 1st
  ///
  /// In en, this message translates to:
  /// **'1st'**
  String get firstDay;

  /// 2nd
  ///
  /// In en, this message translates to:
  /// **'2nd'**
  String get secondDay;

  /// 3rd
  ///
  /// In en, this message translates to:
  /// **'3rd'**
  String get thirdDay;

  /// 4th
  ///
  /// In en, this message translates to:
  /// **'4th'**
  String get fourthDay;

  /// 5th
  ///
  /// In en, this message translates to:
  /// **'5th'**
  String get fifthDay;

  /// 6th
  ///
  /// In en, this message translates to:
  /// **'6th'**
  String get sixthDay;

  /// 7th
  ///
  /// In en, this message translates to:
  /// **'7th'**
  String get seventhDay;

  /// 8th
  ///
  /// In en, this message translates to:
  /// **'8th'**
  String get eighthDay;

  /// 9th
  ///
  /// In en, this message translates to:
  /// **'9th'**
  String get ninthDay;

  /// 10th
  ///
  /// In en, this message translates to:
  /// **'10th'**
  String get tenthDay;

  /// 11th
  ///
  /// In en, this message translates to:
  /// **'11th'**
  String get eleventhDay;

  /// 12th
  ///
  /// In en, this message translates to:
  /// **'12th'**
  String get twelfthDay;

  /// 13th
  ///
  /// In en, this message translates to:
  /// **'13th'**
  String get thirteenthDay;

  /// 14th
  ///
  /// In en, this message translates to:
  /// **'14th'**
  String get fourteenthDay;

  /// 15th
  ///
  /// In en, this message translates to:
  /// **'15th'**
  String get fifteenthDay;

  /// 16th
  ///
  /// In en, this message translates to:
  /// **'16th'**
  String get sixteenthDay;

  /// 17th
  ///
  /// In en, this message translates to:
  /// **'17th'**
  String get seventeenthDay;

  /// 18th
  ///
  /// In en, this message translates to:
  /// **'18th'**
  String get eighteenthDay;

  /// 19th
  ///
  /// In en, this message translates to:
  /// **'19th'**
  String get nineteenthDay;

  /// 20th
  ///
  /// In en, this message translates to:
  /// **'20th'**
  String get twentiethDay;

  /// 21st
  ///
  /// In en, this message translates to:
  /// **'21st'**
  String get twentyFirstDay;

  /// 22nd
  ///
  /// In en, this message translates to:
  /// **'22nd'**
  String get twentySecondDay;

  /// 23rd
  ///
  /// In en, this message translates to:
  /// **'23rd'**
  String get twentyThirdDay;

  /// 24th
  ///
  /// In en, this message translates to:
  /// **'24th'**
  String get twentyFourthDay;

  /// 25th
  ///
  /// In en, this message translates to:
  /// **'25th'**
  String get twentyFifthDay;

  /// 26th
  ///
  /// In en, this message translates to:
  /// **'26th'**
  String get twentySixthDay;

  /// 27th
  ///
  /// In en, this message translates to:
  /// **'27th'**
  String get twentySeventhDay;

  /// 28th
  ///
  /// In en, this message translates to:
  /// **'28th'**
  String get twentyEighthDay;

  /// Select Card Type
  ///
  /// In en, this message translates to:
  /// **'Select Card Type'**
  String get selectCardType;

  /// Add checking account card
  ///
  /// In en, this message translates to:
  /// **'Add checking account card'**
  String get addDebitCardDescription;

  /// Add your credit card information
  ///
  /// In en, this message translates to:
  /// **'Add your credit card information'**
  String get addCreditCardDescription;

  /// Search stocks button
  ///
  /// In en, this message translates to:
  /// **'Search Stocks'**
  String get searchStocks;

  /// Add stock button
  ///
  /// In en, this message translates to:
  /// **'Add Stock'**
  String get addStock;

  /// Remove stock button
  ///
  /// In en, this message translates to:
  /// **'Remove Stock'**
  String get removeStock;

  /// Stock details title
  ///
  /// In en, this message translates to:
  /// **'Stock Details'**
  String get stockDetails;

  /// Stock information section title
  ///
  /// In en, this message translates to:
  /// **'Stock Information'**
  String get stockInfo;

  /// Stock exchange label
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get exchange;

  /// Stock sector label
  ///
  /// In en, this message translates to:
  /// **'Sector'**
  String get sector;

  /// Stock country label
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// Buy stock button
  ///
  /// In en, this message translates to:
  /// **'Buy Stock'**
  String get buyStock;

  /// Sell stock button
  ///
  /// In en, this message translates to:
  /// **'Sell Stock'**
  String get sellStock;

  /// Buy action
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// Sell action
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No stocks being tracked
  ///
  /// In en, this message translates to:
  /// **'You are not tracking any stocks yet'**
  String get noStocksYet;

  /// Add first stock instruction
  ///
  /// In en, this message translates to:
  /// **'Press + to add stocks'**
  String get addFirstStock;

  /// Stock added to watchlist
  ///
  /// In en, this message translates to:
  /// **'Stock added to watchlist'**
  String get stockAdded;

  /// Stock removed from watchlist
  ///
  /// In en, this message translates to:
  /// **'Stock removed from watchlist'**
  String get stockRemoved;

  /// Confirm stock removal message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this stock from your portfolio?'**
  String get confirmRemoveStock;

  /// Chart coming soon message
  ///
  /// In en, this message translates to:
  /// **'Chart Coming Soon'**
  String get chartComingSoon;

  /// Chart development message
  ///
  /// In en, this message translates to:
  /// **'Price charts and analysis features are being developed'**
  String get chartDescription;

  /// Share stock action
  ///
  /// In en, this message translates to:
  /// **'Share Stock'**
  String get shareStock;

  /// Share feature coming soon message
  ///
  /// In en, this message translates to:
  /// **'Share feature coming soon'**
  String get shareFeatureComingSoon;

  /// Buy feature coming soon
  ///
  /// In en, this message translates to:
  /// **'Buy transaction coming soon'**
  String get buyFeatureComingSoon;

  /// Sell feature coming soon
  ///
  /// In en, this message translates to:
  /// **'Sell transaction coming soon'**
  String get sellFeatureComingSoon;

  /// Popular stocks section
  ///
  /// In en, this message translates to:
  /// **'Popular Stocks'**
  String get popularStocks;

  /// BIST stocks section
  ///
  /// In en, this message translates to:
  /// **'BIST Stocks'**
  String get bistStocks;

  /// US stocks section
  ///
  /// In en, this message translates to:
  /// **'US Stocks'**
  String get usStocks;

  /// Minutes ago full text
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgoFull(int count);

  /// Hours ago full text
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgoFull(int count);

  /// Days ago full text
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgoFull(int count);

  /// Toggle text for including investments in net worth
  ///
  /// In en, this message translates to:
  /// **'Including investments'**
  String get investmentsIncluded;

  /// Toggle text for excluding investments from net worth
  ///
  /// In en, this message translates to:
  /// **'Excluding investments'**
  String get investmentsExcluded;

  /// Description for adding first card
  ///
  /// In en, this message translates to:
  /// **'Go to My Cards page to add your first card'**
  String get addFirstCardDescription;

  /// Delete transaction confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the {description} transaction?'**
  String deleteTransactionConfirmation(String description);

  /// Delete installment transaction confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the {description} transaction? All installments will be refunded.'**
  String deleteInstallmentConfirmation(String description);

  /// Installment transaction delete error message
  ///
  /// In en, this message translates to:
  /// **'Error deleting installment transaction: {error}'**
  String installmentDeleteError(String error);

  /// Due today text
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dueToday;

  /// Last X days text
  ///
  /// In en, this message translates to:
  /// **'Last {days} Days'**
  String lastDays(int days);

  /// Statement debt text
  ///
  /// In en, this message translates to:
  /// **'Statement Debt: {amount}'**
  String statementDebt(String amount);

  /// No debt text
  ///
  /// In en, this message translates to:
  /// **'No debt'**
  String get noDebt;

  /// Important priority level
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get important;

  /// Info priority level
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// Statement debt label
  ///
  /// In en, this message translates to:
  /// **'Statement Debt'**
  String get statementDebtLabel;

  /// Debt amount text
  ///
  /// In en, this message translates to:
  /// **'Debt: {amount}'**
  String debtAmount(String amount);

  /// Last payment date label
  ///
  /// In en, this message translates to:
  /// **'Last Payment Date'**
  String get lastPaymentDate;

  /// All notifications title
  ///
  /// In en, this message translates to:
  /// **'All Notifications'**
  String get allNotifications;

  /// Pending notes tab
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingNotes;

  /// Add quick note title
  ///
  /// In en, this message translates to:
  /// **'Add Quick Note'**
  String get addQuickNote;

  /// Add quick note description
  ///
  /// In en, this message translates to:
  /// **'Write your expense or income note. You can add it as a transaction later.'**
  String get addQuickNoteDescription;

  /// Example expense note with currency
  ///
  /// In en, this message translates to:
  /// **'E.g.: Grocery shopping 150{currency}'**
  String exampleExpenseNote(String currency);

  /// Add photo note title
  ///
  /// In en, this message translates to:
  /// **'Add Photo Note'**
  String get addPhotoNote;

  /// Add photo note description
  ///
  /// In en, this message translates to:
  /// **'Add a description for this photo (optional)'**
  String get addPhotoNoteDescription;

  /// Example photo note with currency
  ///
  /// In en, this message translates to:
  /// **'E.g.: Receipt - 150{currency}'**
  String examplePhotoNote(String currency);

  /// View all notes button
  ///
  /// In en, this message translates to:
  /// **'View all notes ({count})'**
  String viewAllNotes(int count);

  /// Seconds ago text
  ///
  /// In en, this message translates to:
  /// **'{count} seconds ago'**
  String secondsAgo(int count);

  /// Yesterday at time text
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {time}'**
  String yesterdayAt(String time);

  /// Weekday at time text
  ///
  /// In en, this message translates to:
  /// **'{weekday} at {time}'**
  String weekdayAt(String weekday, String time);

  /// Day and month text
  ///
  /// In en, this message translates to:
  /// **'{day} {month}'**
  String dayMonth(int day, String month);

  /// Day/month/year text
  ///
  /// In en, this message translates to:
  /// **'{day}/{month}/{year}'**
  String dayMonthYear(int day, int month, int year);

  /// January short
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get januaryShort;

  /// February short
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get februaryShort;

  /// March short
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get marchShort;

  /// April short
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get aprilShort;

  /// May short
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get mayShort;

  /// June short
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get juneShort;

  /// July short
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get julyShort;

  /// August short
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get augustShort;

  /// September short
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get septemberShort;

  /// October short
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get octoberShort;

  /// November short
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get novemberShort;

  /// December short
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get decemberShort;

  /// Stocks included toggle text
  ///
  /// In en, this message translates to:
  /// **'Stocks In'**
  String get stocksIncluded;

  /// Stocks excluded toggle text
  ///
  /// In en, this message translates to:
  /// **'Stocks Out'**
  String get stocksExcluded;

  /// Stock transaction chip label
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stockChip;

  /// Daily performance section title
  ///
  /// In en, this message translates to:
  /// **'Daily Performance'**
  String get dailyPerformance;

  /// Daily label for stock performance
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// Message when user has no stocks tracked
  ///
  /// In en, this message translates to:
  /// **'No stocks tracked yet'**
  String get noStocksTracked;

  /// Message when stock data is loading
  ///
  /// In en, this message translates to:
  /// **'Loading stock data...'**
  String get stockDataLoading;

  /// Instruction to add stocks
  ///
  /// In en, this message translates to:
  /// **'Go to Stocks tab to add stocks'**
  String get addStocksInstruction;

  /// Add stocks button text
  ///
  /// In en, this message translates to:
  /// **'Add Stocks'**
  String get addStocks;

  /// Message when there is no stock position
  ///
  /// In en, this message translates to:
  /// **'No Position'**
  String get noPosition;

  /// Top gainers section description
  ///
  /// In en, this message translates to:
  /// **'Stocks with highest gains today'**
  String get topGainersDescription;

  /// Market is open status
  ///
  /// In en, this message translates to:
  /// **'Market Open'**
  String get marketOpen;

  /// Market is closed status
  ///
  /// In en, this message translates to:
  /// **'Market Closed'**
  String get marketClosed;

  /// Intraday change label
  ///
  /// In en, this message translates to:
  /// **'Intraday Change'**
  String get intradayChange;

  /// Previous close price label
  ///
  /// In en, this message translates to:
  /// **'Previous Close'**
  String get previousClose;

  /// Loading stocks data message
  ///
  /// In en, this message translates to:
  /// **'Loading stock data...'**
  String get loadingStocks;

  /// No stock data available message
  ///
  /// In en, this message translates to:
  /// **'No stock data available'**
  String get noStockData;

  /// Stock sale title
  ///
  /// In en, this message translates to:
  /// **'Stock Sale'**
  String get stockSale;

  /// Stock purchase title
  ///
  /// In en, this message translates to:
  /// **'Stock Purchase'**
  String get stockPurchase;

  /// Stock name label
  ///
  /// In en, this message translates to:
  /// **'Stock Name'**
  String get stockName;

  /// Price label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Pieces unit
  ///
  /// In en, this message translates to:
  /// **'pieces'**
  String get pieces;

  /// Total transactions count
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String totalTransactionsCount(int count);

  /// Income transactions count
  ///
  /// In en, this message translates to:
  /// **'{count} income transactions'**
  String incomeTransactionsCount(int count);

  /// Expense transactions count
  ///
  /// In en, this message translates to:
  /// **'{count} expense transactions'**
  String expenseTransactionsCount(int count);

  /// Transfer transactions count
  ///
  /// In en, this message translates to:
  /// **'{count} transfer transactions'**
  String transferTransactionsCount(int count);

  /// Stock transactions count
  ///
  /// In en, this message translates to:
  /// **'{count} stock transactions'**
  String stockTransactionsCount(int count);

  /// All time period
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// Daily average expense label
  ///
  /// In en, this message translates to:
  /// **'Daily average expense'**
  String get dailyAverageExpense;

  /// No expense transactions found message
  ///
  /// In en, this message translates to:
  /// **'No expense transactions found'**
  String get noExpenseTransactions;

  /// Analyze your finances subtitle
  ///
  /// In en, this message translates to:
  /// **'Analyze your finances'**
  String get analyzeYourFinances;

  /// Statistics page title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No expense records message
  ///
  /// In en, this message translates to:
  /// **'No expense records yet'**
  String get noExpenseRecordsYet;

  /// Empty transaction history message
  ///
  /// In en, this message translates to:
  /// **'Transaction history is empty'**
  String get transactionHistoryEmpty;

  /// No spending in selected period
  ///
  /// In en, this message translates to:
  /// **'No spending in selected period'**
  String get noSpendingInPeriod;

  /// Spending categories section title
  ///
  /// In en, this message translates to:
  /// **'Spending Categories'**
  String get spendingCategories;

  /// No transactions in category message
  ///
  /// In en, this message translates to:
  /// **'No transactions found in this category'**
  String get noTransactionsInCategory;

  /// Chart view
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get chart;

  /// Table view
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// Monthly expense analysis title
  ///
  /// In en, this message translates to:
  /// **'Monthly Expense Analysis'**
  String get monthlyExpenseAnalysis;

  /// Monthly income analysis title
  ///
  /// In en, this message translates to:
  /// **'Monthly Income Analysis'**
  String get monthlyIncomeAnalysis;

  /// Monthly net balance analysis title
  ///
  /// In en, this message translates to:
  /// **'Monthly Net Balance Analysis'**
  String get monthlyNetBalanceAnalysis;

  /// No monthly data message
  ///
  /// In en, this message translates to:
  /// **'No Monthly {title} Data'**
  String noMonthlyData(String title);

  /// Add first transaction to start message
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction to get started'**
  String get addFirstTransactionToStart;

  /// Month column header
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// Change column header
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// Stable change indicator
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stable;

  /// Stock trading category name
  ///
  /// In en, this message translates to:
  /// **'Stock Trading'**
  String get stockTrading;

  /// Unknown category
  ///
  /// In en, this message translates to:
  /// **'Unknown Category'**
  String get unknownCategory;

  /// Stocks screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Track your stocks'**
  String get trackYourStocks;

  /// Chart development message
  ///
  /// In en, this message translates to:
  /// **'Price charts and analysis features are being developed'**
  String get chartDevelopmentMessage;

  /// Buy transaction coming soon message
  ///
  /// In en, this message translates to:
  /// **'Buy transaction coming soon'**
  String get buyTransactionComingSoon;

  /// Sell transaction coming soon message
  ///
  /// In en, this message translates to:
  /// **'Sell transaction coming soon'**
  String get sellTransactionComingSoon;

  /// Loading popular stocks message
  ///
  /// In en, this message translates to:
  /// **'Loading popular stocks...'**
  String get loadingPopularStocks;

  /// No stocks found message
  ///
  /// In en, this message translates to:
  /// **'No stocks found'**
  String get noStocksFound;

  /// Try different search term message
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchTerm;

  /// Day high label
  ///
  /// In en, this message translates to:
  /// **'Day High'**
  String get dayHigh;

  /// Day low label
  ///
  /// In en, this message translates to:
  /// **'Day Low'**
  String get dayLow;

  /// Volume label
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// Remove button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Error removing stock message
  ///
  /// In en, this message translates to:
  /// **'Error removing stock'**
  String get errorRemovingStock;

  /// Stock removed from portfolio message
  ///
  /// In en, this message translates to:
  /// **'{stockName} removed from portfolio'**
  String stockRemovedFromPortfolio(String stockName);

  /// Stock transaction title
  ///
  /// In en, this message translates to:
  /// **'Stock Transaction'**
  String get stockTransaction;

  /// Price required error
  ///
  /// In en, this message translates to:
  /// **'Price required'**
  String get priceRequired;

  /// Enter valid price error
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get enterValidPrice;

  /// Transaction summary title
  ///
  /// In en, this message translates to:
  /// **'Transaction Summary'**
  String get transactionSummary;

  /// Subtotal label
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// Execute transaction button
  ///
  /// In en, this message translates to:
  /// **'Execute {transactionType} Transaction'**
  String executeTransaction(String transactionType);

  /// Unknown stock fallback
  ///
  /// In en, this message translates to:
  /// **'Unknown Stock'**
  String get unknownStock;

  /// Select stock step
  ///
  /// In en, this message translates to:
  /// **'Select Stock'**
  String get selectStock;

  /// Select account step
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get selectAccount;

  /// Please select stock message
  ///
  /// In en, this message translates to:
  /// **'Please select a stock'**
  String get pleaseSelectStock;

  /// Please select account message
  ///
  /// In en, this message translates to:
  /// **'Please select an account'**
  String get pleaseSelectAccount;

  /// No stock selected message
  ///
  /// In en, this message translates to:
  /// **'No stock selected'**
  String get noStockSelected;

  /// Execute purchase button
  ///
  /// In en, this message translates to:
  /// **'Execute Purchase'**
  String get executePurchase;

  /// Execute sale button
  ///
  /// In en, this message translates to:
  /// **'Execute Sale'**
  String get executeSale;

  /// No stocks added yet message
  ///
  /// In en, this message translates to:
  /// **'No stocks added yet'**
  String get noStocksAddedYet;

  /// Add first stock instruction
  ///
  /// In en, this message translates to:
  /// **'Go to the Stocks screen to add your first stock'**
  String get addFirstStockInstruction;

  /// Quantity and price step
  ///
  /// In en, this message translates to:
  /// **'Quantity & Price'**
  String get quantityAndPrice;

  /// New badge
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// Commission rate label
  ///
  /// In en, this message translates to:
  /// **'Commission Rate:'**
  String get commissionRate;

  /// Commission label
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get commission;

  /// Total to pay label
  ///
  /// In en, this message translates to:
  /// **'Total to Pay:'**
  String get totalToPay;

  /// Total to receive label
  ///
  /// In en, this message translates to:
  /// **'Total to Receive:'**
  String get totalToReceive;

  /// No cash account found message
  ///
  /// In en, this message translates to:
  /// **'No Cash Account Found'**
  String get noCashAccountFound;

  /// Add cash account for stock trading message
  ///
  /// In en, this message translates to:
  /// **'You need to add a cash account first to perform stock transactions.'**
  String get addCashAccountForStockTrading;

  /// Current price label
  ///
  /// In en, this message translates to:
  /// **'Current Price'**
  String get currentPrice;

  /// Current value label (cost + profit/loss)
  ///
  /// In en, this message translates to:
  /// **'Current Value'**
  String get currentValue;

  /// No description provided for @deleteInstallmentConfirm.
  ///
  /// In en, this message translates to:
  /// **'installment transaction. Are you sure you want to delete it completely?'**
  String get deleteInstallmentConfirm;

  /// No description provided for @deleteInstallmentWarning.
  ///
  /// In en, this message translates to:
  /// **'This action will delete all installments and refund paid amounts.'**
  String get deleteInstallmentWarning;

  /// No description provided for @errorDeletingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Error deleting transaction'**
  String get errorDeletingTransaction;

  /// No description provided for @deletingInstallmentTransaction.
  ///
  /// In en, this message translates to:
  /// **'Deleting installment transaction...'**
  String get deletingInstallmentTransaction;

  /// No description provided for @errorDeletingInstallmentTransaction.
  ///
  /// In en, this message translates to:
  /// **'Error deleting installment transaction'**
  String get errorDeletingInstallmentTransaction;

  /// Cost label
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// Weighted average cost label
  ///
  /// In en, this message translates to:
  /// **'Weighted Average Cost'**
  String get weightedAverageCost;

  /// Portfolio overview title
  ///
  /// In en, this message translates to:
  /// **'Portfolio Overview'**
  String get portfolioOverview;

  /// Total portfolio value
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValue;

  /// Total portfolio cost
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// Total profit/loss
  ///
  /// In en, this message translates to:
  /// **'Total P&L'**
  String get totalProfitLoss;

  /// Total return percentage
  ///
  /// In en, this message translates to:
  /// **'Total Return'**
  String get totalReturn;

  /// Profit/Loss label
  ///
  /// In en, this message translates to:
  /// **'Profit/Loss'**
  String get profitLoss;

  /// Calendar page title
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Monday short
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mondayShort;

  /// Tuesday short
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesdayShort;

  /// Wednesday short
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesdayShort;

  /// Thursday short
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursdayShort;

  /// Friday short
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fridayShort;

  /// Saturday short
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturdayShort;

  /// Sunday short
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sundayShort;

  /// Analysis features development message
  ///
  /// In en, this message translates to:
  /// **'Analysis features in development'**
  String get analysisFeaturesInDevelopment;

  /// Value label
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// Return label
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnLabel;

  /// Quick notes page title
  ///
  /// In en, this message translates to:
  /// **'Quick Notes'**
  String get quickNotesTitle;

  /// Pending notes count
  ///
  /// In en, this message translates to:
  /// **'{count} pending notes'**
  String pendingNotesCount(int count);

  /// Quick add note section title
  ///
  /// In en, this message translates to:
  /// **'Quick Add Note'**
  String get quickAddNote;

  /// Add note input hint
  ///
  /// In en, this message translates to:
  /// **'e.g. 50₺ grocery shopping'**
  String get addNoteHint;

  /// Voice recording button
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceButton;

  /// Stop recording button
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// Photo capture button
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoButton;

  /// Add note button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// Processed notes tab
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get processedNotes;

  /// Pending notes section title
  ///
  /// In en, this message translates to:
  /// **'Pending Notes'**
  String get pendingNotesTitle;

  /// Processed notes section title
  ///
  /// In en, this message translates to:
  /// **'Processed Notes'**
  String get processedNotesTitle;

  /// Empty state for pending notes
  ///
  /// In en, this message translates to:
  /// **'No pending notes yet\nAdd notes quickly from the field above'**
  String get noPendingNotes;

  /// Empty state for processed notes
  ///
  /// In en, this message translates to:
  /// **'No notes converted to transactions yet'**
  String get noProcessedNotes;

  /// Note status pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get noteStatusPending;

  /// Note status processed
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get noteStatusProcessed;

  /// Convert to expense button
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get convertToExpense;

  /// Convert to income button
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get convertToIncome;

  /// Delete note button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteNote;

  /// Note added success message
  ///
  /// In en, this message translates to:
  /// **'Note added: {content}'**
  String noteAddedSuccess(String content);

  /// Note converted success message
  ///
  /// In en, this message translates to:
  /// **'Note successfully converted to transaction'**
  String get noteConvertedSuccess;

  /// Note deleted success message
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeletedSuccess;

  /// Time now
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get timeNow;

  /// Time minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String timeMinutesAgo(int minutes);

  /// Time hours ago
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String timeHoursAgo(int hours);

  /// Time days ago
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String timeDaysAgo(int days);

  /// Cut-off date label
  ///
  /// In en, this message translates to:
  /// **'Cut-off'**
  String get cutOff;

  /// Payment status - paid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// Payment status - overdue
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// Days left until due date
  ///
  /// In en, this message translates to:
  /// **'days left'**
  String get daysLeft;

  /// No transactions in statement message
  ///
  /// In en, this message translates to:
  /// **'No transactions in this statement'**
  String get noTransactionsInStatement;

  /// Loading statements message
  ///
  /// In en, this message translates to:
  /// **'Loading statements...'**
  String get loadingStatements;

  /// Load more button text
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// Loading more items message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingMore;

  /// Current statement section header
  ///
  /// In en, this message translates to:
  /// **'Current Statement'**
  String get currentStatement;

  /// Past statements section header
  ///
  /// In en, this message translates to:
  /// **'Past Statements'**
  String get pastStatements;

  /// Future statements section header
  ///
  /// In en, this message translates to:
  /// **'Future Statements'**
  String get futureStatements;

  /// Statements page title
  ///
  /// In en, this message translates to:
  /// **'Statements'**
  String get statements;

  /// Garanti BBVA bank name
  ///
  /// In en, this message translates to:
  /// **'Garanti BBVA'**
  String get garantiBBVA;

  /// İş Bankası bank name
  ///
  /// In en, this message translates to:
  /// **'İş Bankası'**
  String get isBankasi;

  /// Akbank bank name
  ///
  /// In en, this message translates to:
  /// **'Akbank'**
  String get akbank;

  /// Ziraat Bankası bank name
  ///
  /// In en, this message translates to:
  /// **'Ziraat Bankası'**
  String get ziraatBankasi;

  /// VakıfBank bank name
  ///
  /// In en, this message translates to:
  /// **'VakıfBank'**
  String get vakifBank;

  /// Yapı Kredi bank name
  ///
  /// In en, this message translates to:
  /// **'Yapı Kredi'**
  String get yapiKredi;

  /// Kuveyt Türk bank name
  ///
  /// In en, this message translates to:
  /// **'Kuveyt Türk'**
  String get kuveytTurk;

  /// Albaraka Türk bank name
  ///
  /// In en, this message translates to:
  /// **'Albaraka Türk'**
  String get albarakaTurk;

  /// QNB Finansbank bank name
  ///
  /// In en, this message translates to:
  /// **'QNB Finansbank'**
  String get qnbFinansbank;

  /// Enpara.com bank name
  ///
  /// In en, this message translates to:
  /// **'Enpara.com'**
  String get enpara;

  /// Papara bank name
  ///
  /// In en, this message translates to:
  /// **'Papara'**
  String get papara;

  /// Türkiye Finans bank name
  ///
  /// In en, this message translates to:
  /// **'Türkiye Finans'**
  String get turkiyeFinans;

  /// TEB bank name
  ///
  /// In en, this message translates to:
  /// **'TEB'**
  String get teb;

  /// HSBC Türkiye bank name
  ///
  /// In en, this message translates to:
  /// **'HSBC Türkiye'**
  String get hsbcTurkiye;

  /// ING Türkiye bank name
  ///
  /// In en, this message translates to:
  /// **'ING Türkiye'**
  String get ingTurkiye;

  /// DenizBank bank name
  ///
  /// In en, this message translates to:
  /// **'DenizBank'**
  String get denizBank;

  /// AnadoluBank bank name
  ///
  /// In en, this message translates to:
  /// **'AnadoluBank'**
  String get anadoluBank;

  /// Halkbank bank name
  ///
  /// In en, this message translates to:
  /// **'Halkbank'**
  String get halkBank;

  /// Qanta Bank fallback name
  ///
  /// In en, this message translates to:
  /// **'Qanta Bank'**
  String get qantaBank;

  /// Statement operations modal title
  ///
  /// In en, this message translates to:
  /// **'Statement Operations'**
  String get statementOperations;

  /// Download PDF action
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// Download PDF action subtitle
  ///
  /// In en, this message translates to:
  /// **'Download statement as PDF'**
  String get downloadPdfSubtitle;

  /// Share action
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Share action subtitle
  ///
  /// In en, this message translates to:
  /// **'Share statement'**
  String get shareSubtitle;

  /// Mark as unpaid action
  ///
  /// In en, this message translates to:
  /// **'Mark as Unpaid'**
  String get markAsUnpaid;

  /// Mark as unpaid action subtitle
  ///
  /// In en, this message translates to:
  /// **'Change payment status of this statement'**
  String get markAsUnpaidSubtitle;

  /// Statement marked as unpaid success message
  ///
  /// In en, this message translates to:
  /// **'Statement marked as unpaid'**
  String get statementMarkedAsUnpaid;

  /// Error marking statement message
  ///
  /// In en, this message translates to:
  /// **'Error occurred while marking statement'**
  String get errorMarkingStatement;

  /// PDF export coming soon message
  ///
  /// In en, this message translates to:
  /// **'PDF export feature coming soon'**
  String get pdfExportComingSoon;

  /// No statements yet message
  ///
  /// In en, this message translates to:
  /// **'No statements yet'**
  String get noStatementsYet;

  /// Statements will appear after card usage message
  ///
  /// In en, this message translates to:
  /// **'Statements will appear here after card usage'**
  String get statementsWillAppearAfterUsage;

  /// Installment count format
  ///
  /// In en, this message translates to:
  /// **'{count} Installments'**
  String installmentCount(int count);

  /// Limit management page title
  ///
  /// In en, this message translates to:
  /// **'Limit Management'**
  String get limitManagement;

  /// Error message when category or limit is missing
  ///
  /// In en, this message translates to:
  /// **'Please enter category name and set limit'**
  String get pleaseEnterCategoryAndLimit;

  /// Error message for invalid limit
  ///
  /// In en, this message translates to:
  /// **'Enter a valid limit'**
  String get enterValidLimit;

  /// Success message when limit is saved
  ///
  /// In en, this message translates to:
  /// **'Limit saved successfully'**
  String get limitSavedSuccessfully;

  /// Empty state message when no limits are set
  ///
  /// In en, this message translates to:
  /// **'No limits set yet'**
  String get noLimitsSetYet;

  /// Empty state description for setting limits
  ///
  /// In en, this message translates to:
  /// **'Set monthly spending limits for categories\nto control your budget'**
  String get setMonthlySpendingLimits;

  /// Monthly limit label
  ///
  /// In en, this message translates to:
  /// **'Monthly Limit:'**
  String get monthlyLimit;

  /// Exceeded status badge
  ///
  /// In en, this message translates to:
  /// **'Exceeded'**
  String get exceeded;

  /// Limit exceeded message
  ///
  /// In en, this message translates to:
  /// **'Limit Exceeded!'**
  String get limitExceeded;

  /// Spent percentage suffix
  ///
  /// In en, this message translates to:
  /// **'spent'**
  String get spent;

  /// Spent amount label
  ///
  /// In en, this message translates to:
  /// **'Spent:'**
  String get spentAmount;

  /// Hint text for limit amount input
  ///
  /// In en, this message translates to:
  /// **'2,000'**
  String get limitAmountHint;

  /// Add new limit bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Add New Limit'**
  String get addNewLimit;

  /// Monthly limit label
  ///
  /// In en, this message translates to:
  /// **'Monthly Limit'**
  String get monthlyLimitLabel;

  /// Placeholder for limit amount input
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get limitAmountPlaceholder;

  /// Save limit button text
  ///
  /// In en, this message translates to:
  /// **'Save Limit'**
  String get saveLimit;

  /// Limit label
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limit;

  /// Google sign-in button text
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// Google sign-up button text
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpWithGoogle;

  /// Google sign-in error message
  ///
  /// In en, this message translates to:
  /// **'Google sign-in error'**
  String get googleSignInError;

  /// Google sign-up error message
  ///
  /// In en, this message translates to:
  /// **'Google sign-up error'**
  String get googleSignUpError;

  /// Google sign-up success message
  ///
  /// In en, this message translates to:
  /// **'Successfully signed up with Google!'**
  String get googleSignUpSuccess;

  /// Or separator text
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
