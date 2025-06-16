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

  /// Email field label
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

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
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

  /// Income tracking
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

  /// Account balance
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// Onboarding screen description text
  ///
  /// In en, this message translates to:
  /// **'Take control of your finances with Qanta. Track expenses, manage budgets, and grow your wealth with smart insights.'**
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

  /// Passwords do not match validation error
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
  /// **'Good Evening! 🌆'**
  String get goodEvening;

  /// Good night greeting
  ///
  /// In en, this message translates to:
  /// **'Good Night! 🌙'**
  String get goodNight;

  /// Currency setting
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

  /// Notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Privacy setting
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// Terms of service
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// App version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Contact support
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// Change password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Biometric authentication
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuth;

  /// Transactions menu item
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

  /// Coming soon placeholder text
  ///
  /// In en, this message translates to:
  /// **'Coming soon...'**
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

  /// Credit limit label
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

  /// Urgent label
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
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

  /// Cash label on cash card
  ///
  /// In en, this message translates to:
  /// **'CASH'**
  String get cash;

  /// Digital wallet label
  ///
  /// In en, this message translates to:
  /// **'Digital Wallet'**
  String get digitalWallet;

  /// All tab label
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

  /// Select transaction type title
  ///
  /// In en, this message translates to:
  /// **'Select Transaction Type'**
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
  /// **'An error occurred. Please try again.'**
  String get errorOccurred;

  /// Enter amount step title
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get enterAmount;

  /// Select category step title
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

  /// Summary title
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// Category label
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

  /// Transport expense category
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// Shopping expense category
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// Entertainment expense category
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainment;

  /// Bills expense category
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// Health expense category
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// Education expense category
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
  /// **'Loan/Installment'**
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

  /// Save button text
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

  /// Food expense category
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

  /// Travel expense category
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

  /// Stocks investment category
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

  /// Quantity required validation message
  ///
  /// In en, this message translates to:
  /// **'Quantity is required'**
  String get quantityRequired;

  /// Enter valid quantity validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid quantity'**
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

  /// Back button text
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
  /// **'Unknown error'**
  String get unknownError;

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

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @installmentInfo.
  ///
  /// In en, this message translates to:
  /// **'Installment Info'**
  String get installmentInfo;

  /// No description provided for @availableLimit.
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

  /// Empty state title when no transactions exist
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
