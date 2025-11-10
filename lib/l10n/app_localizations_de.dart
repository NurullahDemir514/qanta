// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Qanta';

  @override
  String get welcome => 'Willkommen';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get home => 'Startseite';

  @override
  String get settings => 'Einstellungen';

  @override
  String get darkMode => 'Dunkler Modus';

  @override
  String get lightMode => 'Heller Modus';

  @override
  String get theme => 'Design';

  @override
  String get language => 'Sprache';

  @override
  String get english => 'Englisch';

  @override
  String get turkish => 'Türkisch';

  @override
  String get german => 'Deutsch';

  @override
  String get hindi => 'Hindi';

  @override
  String get login => 'Anmelden';

  @override
  String get logout => 'Abmelden';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get fullName => 'Ihr Name';

  @override
  String get signUp => 'Registrieren';

  @override
  String get forgotPassword =>
      'Ich habe mein Passwort vergessen, was soll ich tun?';

  @override
  String get budget => 'Budget';

  @override
  String get expenses => 'Ausgaben';

  @override
  String get income => 'Einnahme';

  @override
  String get investments => 'Investitionen';

  @override
  String get analytics => 'Analyse';

  @override
  String get balance => 'Saldo';

  @override
  String get onboardingDescription =>
      'Ihre persönliche Finanz-App. Verfolgen Sie Ausgaben, verwalten Sie Karten, überwachen Sie Aktien und legen Sie Budgets fest.';

  @override
  String get welcomeSubtitle =>
      'Übernehmen Sie noch heute die Kontrolle über Ihre Finanzen!';

  @override
  String get budgetSubtitle => 'Verfolgen Sie Ihre Ausgaben';

  @override
  String get investmentsSubtitle => 'Vermögen aufbauen';

  @override
  String get analyticsSubtitle => 'Finanzielle Einblicke';

  @override
  String get settingsSubtitle => 'App anpassen';

  @override
  String get appSlogan => 'Verwalten Sie Ihr Geld intelligent';

  @override
  String greetingHello(String name) {
    return 'Hallo, $name!';
  }

  @override
  String get homeMainTitle => 'Bereit, Ihre finanziellen Ziele zu erreichen?';

  @override
  String get homeSubtitle =>
      'Verwalten Sie Ihr Geld intelligent und planen Sie Ihre Zukunft';

  @override
  String get defaultUserName => 'Benutzer';

  @override
  String get nameRequired => 'Bitte geben Sie Ihren Namen ein';

  @override
  String get emailRequired => 'Bitte geben Sie Ihre E-Mail-Adresse ein';

  @override
  String get emailInvalid => 'Bitte geben Sie eine gültige E-Mail-Adresse ein';

  @override
  String get passwordRequired => 'Bitte geben Sie Ihr Passwort ein';

  @override
  String get passwordTooShort =>
      'Das Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get confirmPasswordRequired => 'Bitte bestätigen Sie Ihr Passwort';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get loginSubtitle => 'Bei Ihrem Konto anmelden';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get registerSubtitle =>
      'Treten Sie Qanta bei und beginnen Sie, Ihr Geld zu verwalten';

  @override
  String get pageNotFound => 'Seite nicht gefunden';

  @override
  String get pageNotFoundDescription => 'Die gesuchte Seite existiert nicht.';

  @override
  String get goHome => 'Zur Startseite';

  @override
  String get alreadyHaveAccount => 'Bereits ein Konto vorhanden?';

  @override
  String get dontHaveAccount => 'Noch kein Konto?';

  @override
  String get loginError => 'Anmeldefehler';

  @override
  String get registerError => 'Registrierungsfehler';

  @override
  String get networkError =>
      'Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut';

  @override
  String get emailNotConfirmed =>
      'Sie müssen Ihre E-Mail-Adresse bestätigen. Bitte überprüfen Sie Ihre E-Mails.';

  @override
  String get invalidCredentials =>
      'Ungültige E-Mail-Adresse oder Passwort. Bitte überprüfen Sie Ihre Anmeldedaten und versuchen Sie es erneut.';

  @override
  String get tooManyRequests =>
      'Zu viele Versuche. Bitte warten Sie einige Minuten und versuchen Sie es erneut.';

  @override
  String get invalidEmailAddress =>
      'Ungültige E-Mail-Adresse. Bitte geben Sie eine gültige E-Mail-Adresse ein.';

  @override
  String get passwordTooShortError =>
      'Das Passwort ist zu kurz. Bitte geben Sie ein Passwort mit mindestens 6 Zeichen ein.';

  @override
  String get userAlreadyRegistered =>
      'Diese E-Mail-Adresse ist bereits registriert. Bitte melden Sie sich stattdessen an.';

  @override
  String get signupDisabled =>
      'Die Registrierung ist derzeit nicht verfügbar. Bitte versuchen Sie es später erneut.';

  @override
  String unknownError(String error) {
    return 'Ein Fehler ist aufgetreten: $error';
  }

  @override
  String get noInternetConnection => 'Keine Internetverbindung';

  @override
  String get noInternetDescription =>
      'Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String registrationSuccessful(String name) {
    return 'Registrierung erfolgreich! Willkommen $name!';
  }

  @override
  String get totalBalance => 'Gesamtsaldo';

  @override
  String get totalPortfolio => 'Gesamtportfolio';

  @override
  String get allAccounts => 'Alle Ihre Konten';

  @override
  String availableBalance(Object amount) {
    return 'Verfügbar: $amount';
  }

  @override
  String get thisMonthIncome => 'Einkommen diesen Monat';

  @override
  String get thisMonthExpense => 'Ausgaben diesen Monat';

  @override
  String get myCards => 'Meine Karten';

  @override
  String get manageYourCards => 'Verwalten Sie Ihre Karten';

  @override
  String get seeAll => 'Alle anzeigen';

  @override
  String get recentTransactions => 'Letzte Transaktionen';

  @override
  String get thisMonthSummary => 'Zusammenfassung diesen Monat';

  @override
  String get savings => 'Ersparnisse';

  @override
  String get budgetUsed => 'Verwendet';

  @override
  String get remaining => 'Verbleibend';

  @override
  String get installment => 'Ratenzahlung';

  @override
  String get categoryHint => 'Kaffee, Markt, Kraftstoff...';

  @override
  String get noBudgetDefined => 'Noch kein Budget definiert';

  @override
  String get createBudgetDescription =>
      'Erstellen Sie ein Budget, um Ihre Ausgabengrenzen zu verfolgen';

  @override
  String get createBudget => 'Budget erstellen';

  @override
  String get averageDailySpending => 'Durchschnittliche tägliche Ausgaben';

  @override
  String get spent => 'ausgegeben';

  @override
  String get addExpense => 'Ausgabe hinzufügen';

  @override
  String get expenseLimitTracking => 'Meine Budgets';

  @override
  String get future => 'Zukunft';

  @override
  String get thisMonthGrowth => 'diesen Monat';

  @override
  String get cardHolder => 'KARTENINHABER';

  @override
  String get expiryDate => 'GÜLTIG BIS';

  @override
  String get qantaDebit => 'Qanta Debit';

  @override
  String get checkingAccount => 'Girokonto';

  @override
  String get qantaCredit => 'Qanta Credit';

  @override
  String get qantaSavings => 'Qanta Savings';

  @override
  String get goodMorning => 'Guten Morgen! ☀️';

  @override
  String get goodAfternoon => 'Guten Tag! 🌤️';

  @override
  String get goodEvening => 'Guten Abend!';

  @override
  String get goodNight => 'Gute Nacht! 🌙';

  @override
  String get currency => 'Währung';

  @override
  String get currencyTRY => 'Türkische Lira (₺)';

  @override
  String get currencyUSD => 'US-Dollar (\$)';

  @override
  String get currencyEUR => 'Euro (€)';

  @override
  String get currencyGBP => 'Britisches Pfund (£)';

  @override
  String get selectCurrency => 'Währung auswählen';

  @override
  String get selectCurrencyDescription =>
      'Welche Währung möchten Sie verwenden?';

  @override
  String get debit => 'Debitkarte hinzufügen';

  @override
  String get credit => 'Kreditkarte hinzufügen';

  @override
  String get profile => 'Profil';

  @override
  String get personalInfo => 'Persönliche Informationen';

  @override
  String get preferences => 'Einstellungen';

  @override
  String get security => 'Sicherheit';

  @override
  String get support => 'Support';

  @override
  String get about => 'Über';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get privacy => 'Datenschutz';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get version => 'Version';

  @override
  String get contactSupport => 'Support kontaktieren';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get biometricAuth => 'Biometrische Authentifizierung';

  @override
  String get transactions => 'Transaktionen';

  @override
  String get goals => 'Ziele';

  @override
  String get upcomingPayments => 'Anstehende Zahlungen';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get cardInfo => 'Karteninformationen';

  @override
  String get cardType => 'Kartentyp';

  @override
  String get cardNumber => 'Kartennummer';

  @override
  String get expiryDateShort => 'Ablaufdatum';

  @override
  String get status => 'Status';

  @override
  String get active => 'Aktiv';

  @override
  String get balanceInfo => 'Saldoinformationen';

  @override
  String get creditLimit => 'Kreditlimit';

  @override
  String get usedLimit => 'Verwendetes Limit';

  @override
  String get quickActions => 'Schnellaktionen';

  @override
  String get sendMoney => 'Geld senden';

  @override
  String get loadMoney => 'Geld aufladen';

  @override
  String get freezeCard => 'Karte sperren';

  @override
  String get cardSettings => 'Karteneinstellungen';

  @override
  String get addNewCard => 'Neue Karte hinzufügen';

  @override
  String get addNewCardFeature => 'Neue Kartenfunktion kommt bald!';

  @override
  String get cardManagement => 'Kartenverwaltung';

  @override
  String get securitySettings => 'Sicherheitseinstellungen';

  @override
  String get securitySettingsDesc => 'PIN, Limits und Sicherheitseinstellungen';

  @override
  String get notificationSettings => 'Benachrichtigungseinstellungen';

  @override
  String get notificationSettingsDesc =>
      'Transaktionsbenachrichtigungen und Warnungen';

  @override
  String get transactionHistory => 'Transaktionsverlauf';

  @override
  String get transactionHistoryDesc => 'Transaktionsverlauf aller Karten';

  @override
  String get qantaWallet => 'Qanta Wallet';

  @override
  String get qantaDebitCard => 'Qanta Debit';

  @override
  String get bankTransfer => 'Überweisung';

  @override
  String get iban => 'IBAN';

  @override
  String get recommended => 'EMPFOHLEN';

  @override
  String get urgent => 'Dringend';

  @override
  String get amount => 'Betrag';

  @override
  String get dueDate => 'Fälligkeitsdatum';

  @override
  String get setReminder => 'Erinnerung einrichten';

  @override
  String get paymentHistory => 'Zahlungsverlauf';

  @override
  String get reminderSetup => 'Erinnerungseinrichtung wird geöffnet...';

  @override
  String get paymentHistoryOpening => 'Zahlungsverlauf wird geöffnet...';

  @override
  String get sendMoneyOpening => 'Geld senden wird geöffnet...';

  @override
  String get loadMoneyOpening => 'Geld aufladen wird geöffnet...';

  @override
  String get freezeCardOpening => 'Karte sperren wird geöffnet...';

  @override
  String get cardSettingsOpening => 'Karteneinstellungen werden geöffnet...';

  @override
  String get securitySettingsOpening =>
      'Sicherheitseinstellungen werden geöffnet...';

  @override
  String get notificationSettingsOpening =>
      'Benachrichtigungseinstellungen werden geöffnet...';

  @override
  String get transactionHistoryOpening =>
      'Transaktionsverlauf wird geöffnet...';

  @override
  String paymentProcessing(String method) {
    return 'Zahlung wird verarbeitet mit $method...';
  }

  @override
  String get allAccountsTotal => 'Gesamt aller Ihrer Konten';

  @override
  String get accountBreakdown => 'Kontenaufstellung';

  @override
  String get creditCard => 'Kreditkarte';

  @override
  String get savingsAccount => 'Sparkonto';

  @override
  String get cashAccount => 'Bargeldkonto';

  @override
  String get monthlySummary => 'Monatsübersicht';

  @override
  String get cashBalance => 'Bargeldbestand';

  @override
  String get addCashBalance => 'Bargeldbestand hinzufügen';

  @override
  String get enterCashAmount => 'Bargeldbetrag eingeben';

  @override
  String get cashAmount => 'Bargeldbetrag';

  @override
  String get addCash => 'Bargeld hinzufügen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String cashAdded(String amount) {
    return 'Bargeldbestand hinzugefügt: $amount';
  }

  @override
  String get invalidAmount => 'Bitte geben Sie einen gültigen Betrag ein';

  @override
  String get enterValidAmount => 'Bitte geben Sie einen gültigen Betrag ein';

  @override
  String get cash => 'Bargeld';

  @override
  String get digitalWallet => 'Digitale Geldbörse';

  @override
  String get all => 'Alle';

  @override
  String get cashManagement => 'Bargeldverwaltung';

  @override
  String get addCashHistory => 'Bargeld-Hinzufügungsverlauf';

  @override
  String get addCashHistoryDesc =>
      'Sehen Sie Ihre Bargeld-Hinzufügungstransaktionen';

  @override
  String get cashLimits => 'Bargeldlimits';

  @override
  String get cashLimitsDesc =>
      'Tägliche und monatliche Bargeldlimits festlegen';

  @override
  String get debitCardManagement => 'Debitkarten-Verwaltung';

  @override
  String get cardLimits => 'Kartenlimits';

  @override
  String get cardLimitsDesc =>
      'Tägliche Ausgaben- und Abhebungslimits festlegen';

  @override
  String get atmLocations => 'Geldautomaten-Standorte';

  @override
  String get atmLocationsDesc => 'Geldautomaten in der Nähe finden';

  @override
  String get creditCardManagement => 'Kreditkarten-Verwaltung';

  @override
  String get creditLimitDesc =>
      'Sehen Sie Ihr Kreditlimit und fordern Sie eine Erhöhung an';

  @override
  String get installmentOptions => 'Ratenzahlungsoptionen';

  @override
  String get singlePayment => 'Einmalzahlung';

  @override
  String get howManyInstallments => 'Wie viele Raten?';

  @override
  String get installmentOptionsDesc =>
      'Wandeln Sie Ihre Käufe in Ratenzahlungen um';

  @override
  String get savingsManagement => 'Sparverwaltung';

  @override
  String get savingsGoals => 'Sparziele';

  @override
  String get savingsGoalsDesc => 'Setzen und verfolgen Sie Ihre Sparziele';

  @override
  String get autoSave => 'Automatisches Sparen';

  @override
  String get autoSaveDesc => 'Erstellen Sie automatische Sparregeln';

  @override
  String get opening => 'wird geöffnet...';

  @override
  String get addTransaction => 'Transaktion hinzufügen';

  @override
  String get close => 'Schließen';

  @override
  String get selectTransactionType => 'Transaktionstyp auswählen';

  @override
  String get selectTransactionTypeDesc =>
      'Welche Art von Transaktion möchten Sie durchführen?';

  @override
  String expenseSaved(String amount) {
    return 'Ausgabe gespeichert: $amount';
  }

  @override
  String get errorOccurred => 'Ein Fehler ist aufgetreten';

  @override
  String get enterAmount => 'Betrag eingeben';

  @override
  String get selectCategory => 'Kategorie auswählen';

  @override
  String get paymentMethod => 'Zahlungsmethode';

  @override
  String get details => 'Details';

  @override
  String get amountRequired => 'Betrag ist erforderlich';

  @override
  String get enterValidAmountMessage =>
      'Bitte geben Sie einen gültigen Betrag ein';

  @override
  String get selectCategoryMessage => 'Bitte wählen Sie eine Kategorie aus';

  @override
  String get selectPaymentMethodMessage =>
      'Bitte wählen Sie eine Zahlungsmethode aus';

  @override
  String get saveExpense => 'Ausgabe speichern';

  @override
  String get continueButton => 'Weiter';

  @override
  String get lastCheckAndDetails => 'Finale Überprüfung und Details';

  @override
  String get summary => 'Zusammenfassung';

  @override
  String get category => 'Kategorie';

  @override
  String get payment => 'Zahlung';

  @override
  String get date => 'Datum';

  @override
  String get description => 'Beschreibung';

  @override
  String get card => 'Karte';

  @override
  String get cashPayment => 'Vollzahlung';

  @override
  String installments(int count) {
    return '$count Raten';
  }

  @override
  String get foodAndDrink => 'Essen & Trinken';

  @override
  String get transport => 'Transport';

  @override
  String get shopping => 'Einkaufen';

  @override
  String get entertainment => 'Unterhaltung';

  @override
  String get bills => 'Rechnungen';

  @override
  String get health => 'Gesundheit';

  @override
  String get education => 'Bildung';

  @override
  String get other => 'Sonstiges';

  @override
  String get incomeType => 'Einkommen';

  @override
  String get expenseType => 'Ausgabe';

  @override
  String get transferType => 'Überweisung';

  @override
  String get investmentType => 'Investitionstyp';

  @override
  String get incomeDescription => 'Gehalt, Bonus, Verkaufseinkommen';

  @override
  String get expenseDescription => 'Einkaufen, Rechnungen, Ausgaben';

  @override
  String get transferDescription => 'Überweisung zwischen Konten';

  @override
  String get investmentDescription => 'Aktien, Krypto, Gold';

  @override
  String get recurringType => 'Wiederkehrende Zahlungen';

  @override
  String get recurringDescription => 'Netflix, Rechnungen, Abonnements';

  @override
  String get selectFrequency => 'Häufigkeit auswählen';

  @override
  String get saveRecurring => 'Wiederkehrende Zahlung speichern';

  @override
  String get weekly => 'Wöchentlich';

  @override
  String get monthly => 'Monatlich';

  @override
  String get quarterly => 'Vierteljährlich';

  @override
  String get yearly => 'Jährlich';

  @override
  String get weeklyDescription => 'Wiederholt sich jede Woche';

  @override
  String get monthlyDescription => 'Wiederholt sich jeden Monat';

  @override
  String get quarterlyDescription => 'Wiederholt sich alle 3 Monate';

  @override
  String get yearlyDescription => 'Wiederholt sich jedes Jahr';

  @override
  String get subscription => 'Abonnement';

  @override
  String get thisIsSubscription => 'Dies ist ein Abonnement';

  @override
  String get utilities => 'Versorgungsunternehmen';

  @override
  String get insurance => 'Versicherung';

  @override
  String get rent => 'Miete';

  @override
  String get loan => 'Kredit';

  @override
  String get subscriptionDescription => 'Netflix, Spotify, YouTube';

  @override
  String get utilitiesDescription => 'Strom, Wasser, Gas';

  @override
  String get insuranceDescription => 'Gesundheits-, Auto-, Hausratversicherung';

  @override
  String get rentDescription => 'Wohnungsmiete, Büromiete';

  @override
  String get loanDescription => 'Kreditkarte, Ratenzahlungen';

  @override
  String get otherDescription => 'Andere wiederkehrende Zahlungen';

  @override
  String get next => 'Weiter';

  @override
  String get save => 'Speichern';

  @override
  String get automatic => 'Automatisch';

  @override
  String get createdAutomatically => 'Automatisch erstellt (Abonnement)';

  @override
  String get automaticPaymentCreated => 'Automatische Zahlung erstellt';

  @override
  String automaticPaymentsCreated(int count) {
    return '$count automatische Zahlungen erstellt';
  }

  @override
  String get incomeFormOpening => 'Einkommensformular wird geöffnet';

  @override
  String get transferFormOpening => 'Überweisungsformular wird geöffnet';

  @override
  String get investmentFormOpening => 'Investitionsformular wird geöffnet';

  @override
  String get howMuchSpent => 'Wie viel haben Sie ausgegeben?';

  @override
  String get whichCategorySpent => 'In welcher Kategorie haben Sie ausgegeben?';

  @override
  String get howDidYouPay => 'Wie haben Sie bezahlt?';

  @override
  String get saveIncome => 'Einkommen speichern';

  @override
  String get food => 'Essen';

  @override
  String get foodDescription => 'Restaurant, Lebensmittel, Kaffee';

  @override
  String get transportDescription => 'Taxi, Bus, Kraftstoff';

  @override
  String get shoppingDescription => 'Kleidung, Elektronik, Haushalt';

  @override
  String get billsDescription => 'Strom, Wasser, Internet';

  @override
  String get entertainmentDescription => 'Kino, Konzert, Spiele';

  @override
  String get healthDescription => 'Arzt, Apotheke, Sport';

  @override
  String get educationDescription => 'Kurs, Bücher, Schule';

  @override
  String get travel => 'Reisen';

  @override
  String get travelDescription => 'Urlaub, Flug, Hotel';

  @override
  String get howMuchEarned => 'Wie viel haben Sie verdient?';

  @override
  String get whichCategoryEarned => 'In welcher Kategorie haben Sie verdient?';

  @override
  String get howDidYouReceive => 'Wie haben Sie es erhalten?';

  @override
  String incomeSaved(String amount) {
    return 'Einkommen gespeichert: $amount';
  }

  @override
  String get salary => 'Gehalt';

  @override
  String get salaryDescription => 'Monatsgehalt, Lohn';

  @override
  String get bonus => 'Bonus';

  @override
  String get bonusDescription => 'Bonus, Anreiz, Belohnung';

  @override
  String get freelance => 'Freiberuflich';

  @override
  String get freelanceDescription => 'Freiberufliche Arbeit, Projekt';

  @override
  String get business => 'Geschäft';

  @override
  String get businessDescription => 'Geschäftseinkommen, Handel';

  @override
  String get rental => 'Vermietung';

  @override
  String get rentalDescription => 'Wohnungsmiete, Autovermietung';

  @override
  String get gift => 'Geschenk';

  @override
  String get giftDescription => 'Geschenk, Spende, Taschengeld';

  @override
  String get saveTransfer => 'Überweisung speichern';

  @override
  String get howMuchInvest => 'Wie viel werden Sie investieren?';

  @override
  String get whichInvestmentType => 'Welcher Investitionstyp?';

  @override
  String get stocks => 'Aktien';

  @override
  String get stocksDescription => 'Börse, Aktien';

  @override
  String get crypto => 'Kryptowährung';

  @override
  String get cryptoDescription => 'Bitcoin, Ethereum, Altcoin';

  @override
  String get gold => 'Gold';

  @override
  String get goldDescription => 'Goldbarren, Goldmünzen';

  @override
  String get bonds => 'Anleihen';

  @override
  String get bondsDescription => 'Staatsanleihen, Unternehmensanleihen';

  @override
  String get funds => 'Fonds';

  @override
  String get fundsDescription => 'Investmentfonds, Pensionsfonds';

  @override
  String get forex => 'Devisen';

  @override
  String get forexDescription => 'USD, EUR, GBP';

  @override
  String get realEstate => 'Immobilien';

  @override
  String get realEstateDescription => 'Haus, Land, Geschäft';

  @override
  String get saveInvestment => 'Investition speichern';

  @override
  String investmentSaved(String amount) {
    return 'Investition gespeichert: $amount';
  }

  @override
  String get selectInvestmentTypeMessage =>
      'Bitte wählen Sie einen Investitionstyp aus';

  @override
  String get quantityRequired => 'Menge erforderlich';

  @override
  String get enterValidQuantity => 'Geben Sie eine gültige Menge ein';

  @override
  String get rateRequired => 'Kurs ist erforderlich';

  @override
  String get enterValidRate => 'Bitte geben Sie einen gültigen Kurs ein';

  @override
  String get quantity => 'Menge';

  @override
  String get rate => 'Kurs';

  @override
  String get totalAmount => 'Gesamtbetrag';

  @override
  String get onboardingFeaturesTitle => 'Was können Sie mit Qanta tun?';

  @override
  String get expenseTrackingTitle => 'Ausgabenverfolgung';

  @override
  String get expenseTrackingDesc =>
      'Verfolgen Sie Ihre täglichen Ausgaben einfach';

  @override
  String get smartSavingsTitle => 'Intelligentes Sparen';

  @override
  String get smartSavingsDesc => 'Sparen Sie Geld, um Ihre Ziele zu erreichen';

  @override
  String get financialAnalysisTitle => 'Finanzanalyse';

  @override
  String get financialAnalysisDesc => 'Analysieren Sie Ihre Ausgewohnheiten';

  @override
  String get cardManagementTitle => 'Kartenverwaltung';

  @override
  String get cardManagementDesc =>
      'Verwalten Sie Kreditkarten, Debitkarten und Bargeldkonten';

  @override
  String get stockTrackingTitle => 'Aktienverfolgung';

  @override
  String get stockTrackingDesc =>
      'Verfolgen Sie Ihr Aktienportfolio und Ihre Investitionen';

  @override
  String get budgetManagementTitle => 'Budgetverwaltung';

  @override
  String get budgetManagementDesc =>
      'Legen Sie Budgets fest und verfolgen Sie Ihre Ausgabengrenzen';

  @override
  String get aiInsightsTitle => 'KI-Einblicke';

  @override
  String get aiInsightsDesc =>
      'Erhalten Sie intelligente Finanzempfehlungen und Einblicke';

  @override
  String get expenseTrackingDescShort =>
      'Erfassen und kategorisieren Sie Ihre täglichen Ausgaben mit detaillierter Verfolgung';

  @override
  String get cardManagementDescShort =>
      'Verwalten Sie Kreditkarten, Debitkarten und Bargeldkonten an einem Ort';

  @override
  String get stockTrackingDescShort =>
      'Überwachen Sie Ihr Aktienportfolio mit Echtzeitpreisen und Performance';

  @override
  String get financialAnalysisDescShort =>
      'Analysieren Sie Ausgabemuster und Finanztrends';

  @override
  String get budgetManagementDescShort =>
      'Legen Sie monatliche Budgets fest und verfolgen Sie Ihre Ausgabengrenzen';

  @override
  String get aiInsightsDescShort =>
      'Erhalten Sie personalisierte Finanzempfehlungen und Einblicke';

  @override
  String get languageSelectionTitle => 'Sprachauswahl';

  @override
  String get languageSelectionDesc =>
      'In welcher Sprache möchten Sie die App verwenden?';

  @override
  String get themeSelectionTitle => 'Designauswahl';

  @override
  String get themeSelectionDesc => 'Welches Design bevorzugen Sie?';

  @override
  String get lightThemeTitle => 'Helles Design';

  @override
  String get lightThemeDesc => 'Klassisches weißes Design';

  @override
  String get darkThemeTitle => 'Dunkles Design';

  @override
  String get darkThemeDesc => 'Schonend für die Augen';

  @override
  String get exitOnboarding => 'Beenden';

  @override
  String get exitOnboardingMessage =>
      'Sind Sie sicher, dass Sie ohne Abschluss der Einrichtung beenden möchten?';

  @override
  String get exitCancel => 'Abbrechen';

  @override
  String get back => 'Zurück';

  @override
  String get updateCashBalance => 'Aktualisieren Sie Ihr Bargeldguthaben';

  @override
  String get updateCashBalanceDesc =>
      'Geben Sie Ihren aktuellen Bargeldbetrag ein';

  @override
  String get updateCashBalanceTitle => 'Bargeldbestand aktualisieren';

  @override
  String get updateCashBalanceMessage =>
      'Geben Sie Ihren aktuellen Bargeldbetrag ein:';

  @override
  String get newBalance => 'Neuer Bestand';

  @override
  String get update => 'Aktualisieren';

  @override
  String cashBalanceUpdated(String amount) {
    return 'Bargeldbestand auf $amount aktualisiert';
  }

  @override
  String get cashAccountLoadError => 'Fehler beim Laden des Bargeldkontos';

  @override
  String get retry => 'Wiederholen';

  @override
  String get noCashTransactions => 'Noch keine Bargeldtransaktionen';

  @override
  String get noCashTransactionsDesc =>
      'Ihre erste Bargeldtransaktion wird hier angezeigt';

  @override
  String get balanceUpdated => 'Bargeld hinzugefügt';

  @override
  String get updateBalance => 'Bestand aktualisieren';

  @override
  String get walletBalanceUpdated => 'Manuelle Bargeldzuführung';

  @override
  String get groceryShopping => 'Lebensmitteleinkauf';

  @override
  String get cashPaymentMade => 'Bargeldzahlung';

  @override
  String get taxiFare => 'Taxifahrt';

  @override
  String get transactionDetails => 'Transaktionsdetails';

  @override
  String get cardDetails => 'Kartendetails';

  @override
  String get time => 'Zeit';

  @override
  String get transactionType => 'Transaktionstyp';

  @override
  String get merchant => 'Händler';

  @override
  String installmentInfo(int current, int total) {
    return '$current/$total Raten';
  }

  @override
  String get availableLimit => 'Verfügbares Limit';

  @override
  String get howMuchTransfer => 'Wie viel werden Sie überweisen?';

  @override
  String get fromWhichAccount => 'Von welchem Konto?';

  @override
  String get toWhichAccount => 'Auf welches Konto?';

  @override
  String get investmentIncome => 'Investitionseinkommen';

  @override
  String get investmentIncomeDescription => 'Aktien, Fonds, Mieteinnahmen';

  @override
  String get silver => 'Silber';

  @override
  String get usd => 'USD';

  @override
  String get eur => 'EUR';

  @override
  String get goldUnit => 'Gramm';

  @override
  String get silverUnit => 'Gramm';

  @override
  String get usdUnit => 'Einheit';

  @override
  String get eurUnit => 'Einheit';

  @override
  String get silverDescription => 'Silberinvestition';

  @override
  String get usdDescription => 'US-Dollar';

  @override
  String get eurDescription => 'Euro-Währung';

  @override
  String get selectInvestmentType => 'Investitionstyp auswählen';

  @override
  String get investment => 'Investition';

  @override
  String get otherIncome => 'Sonstiges Einkommen';

  @override
  String get recurringPayment => 'Wiederkehrende Zahlung';

  @override
  String get saveRecurringPayment => 'Wiederkehrende Zahlung speichern';

  @override
  String get noTransactionsYet => 'Noch keine Transaktionen';

  @override
  String get noTransactionsDescription =>
      'Tippen Sie auf die + Schaltfläche, um Ihre erste Transaktion hinzuzufügen';

  @override
  String get noSearchResults => 'Keine Suchergebnisse gefunden';

  @override
  String noSearchResultsDescription(String query) {
    return 'Keine Ergebnisse für \"$query\" gefunden';
  }

  @override
  String get transactionsLoadError => 'Fehler beim Laden der Transaktionen';

  @override
  String get connectionError => 'Verbindungsproblem aufgetreten';

  @override
  String get noAccountsAvailable => 'Keine Konten verfügbar';

  @override
  String get debitCard => 'Debitkarte';

  @override
  String get statisticsTitle => 'Statistiken';

  @override
  String get monthlyOverview => 'Monatsübersicht';

  @override
  String get totalIncome => 'Gesamteinkommen';

  @override
  String get totalExpenses => 'Gesamtausgaben';

  @override
  String get netBalance => 'Nettosaldo';

  @override
  String get categoryBreakdown => 'Kategorieaufteilung';

  @override
  String get spendingTrends => 'Ausgabentrends';

  @override
  String get thisMonth => 'Dieser Monat';

  @override
  String get lastMonth => 'Letzter Monat';

  @override
  String get last3Months => 'Letzte 3 Monate';

  @override
  String get last6Months => 'Letzte 6 Monate';

  @override
  String get yearToDate => 'Jahr bis heute';

  @override
  String get noDataAvailable => 'Keine Daten verfügbar';

  @override
  String get noTransactionsFound => 'Keine Transaktionen gefunden';

  @override
  String get averageSpending => 'Durchschnittliche Ausgaben';

  @override
  String get highestSpending => 'Höchste Ausgaben';

  @override
  String get lowestSpending => 'Niedrigste Ausgaben';

  @override
  String get savingsRate => 'Sparquote';

  @override
  String get smartInsights => 'Intelligente Einblicke';

  @override
  String get visualAnalytics => 'Visuelle Analyse';

  @override
  String get categoryAnalysis => 'Kategorieanalyse';

  @override
  String get financialHealthScore => 'Finanzgesundheitswert';

  @override
  String get spendingTrend => 'Ausgabentrend';

  @override
  String get viewAll => 'Alle anzeigen';

  @override
  String get noDataYet => 'Noch keine Daten zum Analysieren';

  @override
  String get addFirstTransaction =>
      'Fügen Sie Ihre erste Ausgabe hinzu, um zu beginnen';

  @override
  String get analyzingData => 'Ihre Finanzdaten werden analysiert...';

  @override
  String get pleaseWait => 'Dies kann einige Sekunden dauern';

  @override
  String get dataLoadError => 'Fehler beim Laden der Daten';

  @override
  String get excellent => 'Ausgezeichnet';

  @override
  String get good => 'Gut';

  @override
  String get average => 'Durchschnittlich';

  @override
  String get needsImprovement => 'Verbesserungsbedürftig';

  @override
  String get dailyAverage => 'Täglicher Durchschnitt';

  @override
  String get moreCategories => 'weitere Kategorien';

  @override
  String get netWorth => 'Gesamtvermögen';

  @override
  String get welcomeToQanta => 'Willkommen bei Qanta!';

  @override
  String get startYourFinancialJourney =>
      'Machen Sie den ersten Schritt, um Ihre finanzielle Reise zu beginnen';

  @override
  String get addFirstIncome => 'Erstes Einkommen hinzufügen';

  @override
  String get addCard => 'Karte hinzufügen';

  @override
  String get tipTrackYourExpenses =>
      'Verfolgen Sie Ihre Ausgaben, um Ihre finanziellen Ziele zu erreichen';

  @override
  String get positive => 'Positiv';

  @override
  String get negative => 'Negativ';

  @override
  String get totalAssets => 'Gesamtvermögen';

  @override
  String get totalDebts => 'Gesamtschulden';

  @override
  String get availableCredit => 'Verfügbares Guthaben';

  @override
  String get netAmount => 'Nettobetrag';

  @override
  String get transactionCount => 'Transaktionen';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galerie';

  @override
  String get deletePhoto => 'Foto löschen';

  @override
  String photoUploadError(String error) {
    return 'Fehler beim Hochladen des Fotos: $error';
  }

  @override
  String photoDeleteError(String error) {
    return 'Fehler beim Löschen des Fotos: $error';
  }

  @override
  String get fileNotFound => 'Datei nicht gefunden';

  @override
  String get fileTooLarge => 'Datei zu groß (max. 5MB)';

  @override
  String get userSessionNotFound => 'Benutzersitzung nicht gefunden';

  @override
  String get photoDeletedSuccessfully => 'Foto erfolgreich gelöscht';

  @override
  String get photoUploadedSuccessfully => 'Foto erfolgreich hochgeladen';

  @override
  String get selectImageSource => 'Bildquelle auswählen';

  @override
  String get selectImageSourceDescription =>
      'Wo möchten Sie Ihr Foto auswählen?';

  @override
  String get uploadingPhoto => 'Foto wird hochgeladen...';

  @override
  String get deletingPhoto => 'Foto wird gelöscht...';

  @override
  String get profilePhoto => 'Profilfoto';

  @override
  String get changeProfilePhoto => 'Profilfoto ändern';

  @override
  String get removeProfilePhoto => 'Profilfoto entfernen';

  @override
  String get profilePhotoUpdated => 'Profilfoto aktualisiert';

  @override
  String get profilePhotoRemoved => 'Profilfoto entfernt';

  @override
  String get deleteTransaction => 'Transaktion löschen';

  @override
  String deleteTransactionConfirm(String description) {
    return 'Transaktion. Sind Sie sicher, dass Sie sie löschen möchten?';
  }

  @override
  String get delete => 'Löschen';

  @override
  String get transactionDeleted => 'Transaktion gelöscht';

  @override
  String transactionDeleteError(String error) {
    return 'Fehler beim Löschen der Transaktion: $error';
  }

  @override
  String get deleteInstallmentTransaction => 'Ratenzahlungstransaktion löschen';

  @override
  String deleteInstallmentTransactionConfirm(String description) {
    return 'Sind Sie sicher, dass Sie die Ratenzahlung $description vollständig löschen möchten? Dies löscht alle Raten.';
  }

  @override
  String get installmentTransactionDeleted =>
      'Ratenzahlung gelöscht, Gesamtbetrag erstattet';

  @override
  String installmentTransactionDeleteError(String error) {
    return 'Fehler beim Löschen der Ratenzahlung: $error';
  }

  @override
  String get deleteAll => 'Alle löschen';

  @override
  String get deleteLimit => 'Limit löschen';

  @override
  String deleteLimitConfirm(String categoryName) {
    return 'Sind Sie sicher, dass Sie das für die Kategorie $categoryName gesetzte Limit löschen möchten?';
  }

  @override
  String get limitDeleted => 'Limit gelöscht';

  @override
  String get deleteLimitTooltip => 'Limit löschen';

  @override
  String get error => 'Fehler';

  @override
  String get loading => 'Wird geladen...';

  @override
  String get loadingPastStatements =>
      'Vergangene Kontoauszüge werden geladen...';

  @override
  String get loadingFutureStatements =>
      'Zukünftige Kontoauszüge werden geladen...';

  @override
  String get loadingCards => 'Fehler beim Laden der Karten';

  @override
  String get loadingAccounts => 'Konten werden geladen';

  @override
  String get loadingStatementInfo =>
      'Fehler beim Laden der Kontoauszugsinformationen';

  @override
  String get paymentError => 'Fehler während der Zahlung aufgetreten';

  @override
  String get statementMarkError => 'Fehler beim Markieren des Kontoauszugs';

  @override
  String get deleteCard => 'Karte löschen';

  @override
  String deleteCardConfirm(String cardName) {
    return 'Sind Sie sicher, dass Sie die Karte $cardName löschen möchten?\n\nDiese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get cardDeleted => 'Karte erfolgreich gelöscht';

  @override
  String get cardDeleteError => 'Fehler beim Löschen der Karte';

  @override
  String transactionAddError(String error) {
    return 'Fehler beim Hinzufügen der Transaktion: $error';
  }

  @override
  String updateError(String error) {
    return 'Fehler während der Aktualisierung: $error';
  }

  @override
  String get deleteFailed => 'Löschen fehlgeschlagen';

  @override
  String get installmentTransactionDeleting => 'Ratenzahlung wird gelöscht...';

  @override
  String get installmentTransactionDeletedWithRefund =>
      'Ratenzahlung gelöscht, Gesamtbetrag erstattet';

  @override
  String get cancelAction => 'Abbrechen';

  @override
  String get notificationPermissionRequired =>
      'Benachrichtigungsberechtigung erforderlich! Bitte aktivieren Sie sie in den Einstellungen.';

  @override
  String get enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get subscriptionNotificationPermissionMessage =>
      'Möchten Sie automatische Benachrichtigungen für Abonnementzahlungen erhalten? Benachrichtigungen erinnern Sie daran, wann Zahlungen erfolgt sind und an bevorstehende Zahlungstermine.';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get enable => 'Aktivieren';

  @override
  String get frequentlyAskedQuestions => 'Häufig gestellte Fragen';

  @override
  String get account => 'Konto';

  @override
  String get now => 'Jetzt';

  @override
  String get yesterday => 'Gestern';

  @override
  String get expense => 'Ausgabe';

  @override
  String get transfer => 'Überweisung';

  @override
  String get today => 'Heute';

  @override
  String minutesAgo(int count) {
    return 'vor $count Minuten';
  }

  @override
  String hoursAgo(int count) {
    return 'vor $count Stunden';
  }

  @override
  String daysAgo(int count) {
    return 'vor $count T';
  }

  @override
  String weeksAgo(int count) {
    return 'vor $count Wochen';
  }

  @override
  String monthsAgo(int count) {
    return 'vor $count Monaten';
  }

  @override
  String yearsAgo(int count) {
    return 'vor $count Jahren';
  }

  @override
  String get oneMinuteAgo => 'vor 1 Min';

  @override
  String get oneHourAgo => 'vor 1 Std';

  @override
  String get oneWeekAgo => 'vor 1 Woche';

  @override
  String get oneMonthAgo => 'vor 1 Monat';

  @override
  String get oneYearAgo => 'vor 1 Jahr';

  @override
  String get twoDaysAgo => 'vor 2 Tagen';

  @override
  String get perMonth => '/ Monat';

  @override
  String get perDay => '/Tag';

  @override
  String get net => 'Netto';

  @override
  String get pleaseEnterAmount => 'Bitte geben Sie einen Betrag ein';

  @override
  String get pleaseEnterValidAmount =>
      'Bitte geben Sie einen gültigen Betrag ein';

  @override
  String get pleaseSelectSourceAccount => 'Bitte wählen Sie das Quellkonto aus';

  @override
  String get pleaseSelectTargetAccount => 'Bitte wählen Sie das Zielkonto aus';

  @override
  String get sourceAndTargetSame =>
      'Quell- und Zielkonto dürfen nicht dasselbe sein';

  @override
  String get accountInfoNotFound =>
      'Kontoinformationen konnten nicht abgerufen werden';

  @override
  String get accountInfoNotFoundSingle =>
      'Kontoinformationen konnten nicht abgerufen werden';

  @override
  String get pleaseSelectCategory => 'Bitte wählen Sie eine Kategorie aus';

  @override
  String get pleaseSelectPaymentMethod =>
      'Bitte wählen Sie eine Zahlungsmethode aus';

  @override
  String get cardsLoadingError => 'Fehler beim Laden der Karten';

  @override
  String get noCardsAddedYet => 'Noch keine Karten hinzugefügt';

  @override
  String get transaction => 'Transaktion';

  @override
  String get noTransactionsForThisDay => 'Keine Transaktionen für diesen Tag';

  @override
  String get cashWallet => 'Bargeldbörse';

  @override
  String get bankName => 'Qanta';

  @override
  String get repeatsEveryWeek => 'Wiederholt sich jede Woche';

  @override
  String get repeatsEveryMonth => 'Wiederholt sich jeden Monat';

  @override
  String get repeatsEveryQuarter => 'Wiederholt sich jedes Quartal';

  @override
  String get repeatsEveryYear => 'Wiederholt sich jedes Jahr';

  @override
  String get otherFixedPayments => 'Sonstige feste Zahlungen';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get thisYear => 'Dieses Jahr';

  @override
  String get lastYear => 'Letztes Jahr';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get searchTransactions => 'Transaktionen suchen';

  @override
  String get filterByType => 'Nach Typ filtern';

  @override
  String get filterByPeriod => 'Nach Zeitraum filtern';

  @override
  String get filterByCategory => 'Nach Kategorie filtern';

  @override
  String get clearFilters => 'Filter löschen';

  @override
  String get applyFilters => 'Filter anwenden';

  @override
  String get noResultsFound => 'Keine Ergebnisse gefunden';

  @override
  String get tryDifferentSearch => 'Versuchen Sie eine andere Suche';

  @override
  String get noNotesYet => 'Noch keine Notizen';

  @override
  String get addExpenseIncomeNotes =>
      'Fügen Sie hier Ihre Ausgaben- oder Einkommensnotizen hinzu';

  @override
  String get justNow => 'Gerade eben';

  @override
  String get monday => 'Montag';

  @override
  String get tuesday => 'Dienstag';

  @override
  String get wednesday => 'Mittwoch';

  @override
  String get thursday => 'Donnerstag';

  @override
  String get friday => 'Freitag';

  @override
  String get saturday => 'Samstag';

  @override
  String get sunday => 'Sonntag';

  @override
  String get january => 'Januar';

  @override
  String get february => 'Februar';

  @override
  String get march => 'März';

  @override
  String get april => 'April';

  @override
  String get may => 'Mai';

  @override
  String get june => 'Juni';

  @override
  String get july => 'Juli';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'Oktober';

  @override
  String get november => 'November';

  @override
  String get december => 'Dezember';

  @override
  String get textNote => 'Textnotiz';

  @override
  String get addQuickTextNote => 'Schnelle Textnotiz hinzufügen';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get takePhotoFromCamera => 'Foto mit Kamera aufnehmen';

  @override
  String get selectFromGallery => 'Aus Galerie auswählen';

  @override
  String get selectPhotoFromGallery => 'Foto aus Galerie auswählen';

  @override
  String get photoCaptureError => 'Fehler beim Aufnehmen des Fotos';

  @override
  String get photoSelectionError => 'Fehler beim Auswählen des Fotos';

  @override
  String get add => 'Hinzufügen';

  @override
  String get photoNote => 'Fotonotiz';

  @override
  String get photoNoteAdded => 'Fotonotiz hinzugefügt';

  @override
  String get photoNoteAddError => 'Fehler beim Hinzufügen der Fotonotiz';

  @override
  String get noteAdded => 'Notiz hinzugefügt';

  @override
  String get noteAddError => 'Fehler beim Hinzufügen der Notiz';

  @override
  String get noteDeleted => 'Notiz gelöscht';

  @override
  String get noteDeleteError => 'Fehler beim Löschen der Notiz';

  @override
  String get noConvertedNotesYet =>
      'Noch keine Notizen in Transaktionen umgewandelt';

  @override
  String get stop => 'Stoppen';

  @override
  String get send => 'Senden';

  @override
  String get processed => 'Verarbeitet';

  @override
  String get newest => 'Neueste';

  @override
  String get oldest => 'Älteste';

  @override
  String get highestToLowest => 'Höchste bis Niedrigste';

  @override
  String get lowestToHighest => 'Niedrigste bis Höchste';

  @override
  String get alphabetical => 'A-Z';

  @override
  String get more => 'Mehr';

  @override
  String get less => 'Weniger';

  @override
  String get cardName => 'Kartenname';

  @override
  String get usage => 'Nutzung';

  @override
  String get lastPayment => 'Letzte Zahlung';

  @override
  String get nextPayment => 'Nächste';

  @override
  String get minimumPayment => 'Mindestzahlung';

  @override
  String get totalDebt => 'Gesamtschulden';

  @override
  String get creditCardDebt => 'Kreditkartenschulden';

  @override
  String cardCount(int count) {
    return '$count Karten';
  }

  @override
  String get noTransactionsForThisCard =>
      'Keine Transaktionen für diese Karte gefunden';

  @override
  String get statementSuccessfullyPaid =>
      'Kontoauszug erfolgreich als bezahlt markiert';

  @override
  String get bank => 'Bank';

  @override
  String get cardNameRequired => 'Kartenname ist erforderlich';

  @override
  String get creditLimitRequired => 'Kreditlimit ist erforderlich';

  @override
  String get debt => 'Schulden';

  @override
  String get noNotifications => 'Keine Benachrichtigungen';

  @override
  String get usageRate => 'Nutzungsrate';

  @override
  String get statementDay => 'Auszugstag';

  @override
  String get creditCardInfo => 'Kreditkarteninformationen';

  @override
  String get installmentDetailsLoadError =>
      'Ratenzahlungsdetails konnten nicht geladen werden';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get passwordMinLengthInfo =>
      'Ihr Passwort muss mindestens 6 Zeichen lang sein.';

  @override
  String get passwordMinLength =>
      'Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get passwordChangedSuccessfully => 'Passwort erfolgreich geändert';

  @override
  String get wrongCurrentPassword => 'Aktuelles Passwort ist falsch';

  @override
  String get passwordTooWeak => 'Passwort ist zu schwach';

  @override
  String get requiresRecentLogin =>
      'Bitte melden Sie sich erneut an, um Ihr Passwort zu ändern';

  @override
  String get passwordChangeFailed => 'Passwortänderung fehlgeschlagen';

  @override
  String get ok => 'OK';

  @override
  String get collectedInformation => 'Gesammelte Informationen';

  @override
  String get collectedInformationContent =>
      'Die Qanta-Anwendung sammelt die folgenden Informationen, um Ihnen einen besseren Service zu bieten:\n\n• Kontoinformationen (E-Mail, Name-Nachname)\n• Finanztransaktionsdaten (Einkommen, Ausgaben, Überweisungsdatensätze)\n• Karten- und Kontoinformationen\n• Budget- und Kategoriepräferenzen\n• Anwendungsnutzungsstatistiken';

  @override
  String get informationUsage => 'Nutzung der Informationen';

  @override
  String get informationUsageContent =>
      'Die gesammelten Informationen werden für folgende Zwecke verwendet:\n\n• Bereitstellung von persönlichen Finanzmanagementdiensten\n• Budgetverfolgung und Ausgabenanalyse\n• Verbesserung der Anwendungsleistung\n• Sicherheit und Betrugsprävention\n• Erfüllung gesetzlicher Verpflichtungen';

  @override
  String get dataSecurity => 'Datensicherheit';

  @override
  String get dataSecurityContent =>
      'Die Sicherheit Ihrer Daten hat für uns Priorität:\n\n• Alle Daten werden verschlüsselt gespeichert\n• Gehostet auf sicheren Servern\n• Regelmäßige Sicherheitsupdates werden durchgeführt\n• Geschützt vor unbefugtem Zugriff\n• Branchenübliche Sicherheitsmaßnahmen werden ergriffen';

  @override
  String get dataSharing => 'Datenweitergabe';

  @override
  String get dataSharingContent =>
      'Ihre persönlichen Daten werden außer in folgenden Fällen nicht an Dritte weitergegeben:\n\n• Gesetzliche Verpflichtungen\n• Bei Sicherheitsverletzungen\n• Mit Ihrer ausdrücklichen Zustimmung\n• Begrenzte Weitergabe an Dienstleister (anonym)';

  @override
  String get userRights => 'Benutzerrechte';

  @override
  String get userRightsContent =>
      'Ihre Rechte nach DSGVO:\n\n• Erfahren, ob Ihre persönlichen Daten verarbeitet werden\n• Zugriff auf Ihre Daten anfordern\n• Korrektur falscher Informationen anfordern\n• Löschung von Daten anfordern\n• Ihr Konto vollständig schließen';

  @override
  String get contact => 'Kontakt';

  @override
  String get contactContent =>
      'Bei Fragen zur Datenschutzrichtlinie:\n\nE-Mail: privacy@qanta.app\nAdresse: Istanbul, Türkei\n\nDiese Richtlinie wurde zuletzt aktualisiert: 20. Januar 2025';

  @override
  String get supportAndContact => 'Support & Kontakt';

  @override
  String get phone => 'Telefon';

  @override
  String get liveSupport => 'Live-Support';

  @override
  String get liveSupportHours => 'Montag-Freitag 09:00-18:00';

  @override
  String get isMyDataSecure => 'Sind meine Daten sicher?';

  @override
  String get isMyDataSecureAnswer =>
      'Ja, alle Ihre Daten werden verschlüsselt gespeichert und auf sicheren Servern gehostet. Wir bieten branchenübliche Sicherheit mit Supabase-Infrastruktur.';

  @override
  String get forgotPasswordAnswer =>
      'Sie können die Option \"Passwort vergessen\" auf dem Anmeldebildschirm verwenden, um einen Link zum Zurücksetzen des Passworts an Ihre E-Mail-Adresse zu senden.';

  @override
  String get howToDeleteAccount => 'Wie kann ich mein Konto löschen?';

  @override
  String get howToDeleteAccountAnswer =>
      'Sie können sich auf der Profilseite abmelden oder unser Support-Team kontaktieren, um die vollständige Löschung Ihres Kontos anzufordern.';

  @override
  String get isAppFree => 'Ist die App kostenlos?';

  @override
  String get isAppFreeAnswer =>
      'Ja, Qanta kann vollständig kostenlos verwendet werden. Premium-Funktionen können in Zukunft hinzugefügt werden, aber grundlegende Funktionen bleiben immer kostenlos.';

  @override
  String get appInformation => 'App-Informationen';

  @override
  String get lastUpdate => 'Letzte Aktualisierung';

  @override
  String get developer => 'Entwickler';

  @override
  String get platform => 'Plattform';

  @override
  String get liveSupportTitle => 'Live-Support';

  @override
  String get liveSupportMessage =>
      'Der Live-Support-Service befindet sich derzeit in der Entwicklung. Für dringende Angelegenheiten kontaktieren Sie uns bitte per E-Mail oder Telefon.';

  @override
  String get serviceDescription => 'Servicebeschreibung';

  @override
  String get serviceDescriptionContent =>
      'Qanta ist eine mobile Anwendung für die persönliche Finanzverwaltung. Die Anwendung bietet die folgenden Dienstleistungen:\n\n• Einnahmen- und Ausgabenverfolgung\n• Budgetverwaltung und -planung\n• Karten- und Kontoverwaltung\n• Finanzberichterstattung und -analyse\n• Ratenzahlungsverfolgung und -verwaltung';

  @override
  String get usageTerms => 'Nutzungsbedingungen';

  @override
  String get usageTermsContent =>
      'Durch die Nutzung der Qanta-Anwendung stimmen Sie den folgenden Bedingungen zu:\n\n• Sie verwenden die Anwendung nur für rechtmäßige Zwecke\n• Sie geben genaue und aktuelle Informationen an\n• Sie schützen Ihre Kontosicherheit\n• Sie respektieren die Rechte anderer Benutzer\n• Sie vermeiden den Missbrauch der Anwendung';

  @override
  String get userResponsibilities => 'Benutzerverantwortlichkeiten';

  @override
  String get userResponsibilitiesContent =>
      'Als Benutzer haben Sie folgende Verantwortlichkeiten:\n\n• Sicherung Ihrer Kontoinformationen\n• Nicht-Weitergabe Ihres Passworts an Dritte\n• Gewährleistung der Genauigkeit Ihrer Finanzdaten\n• Einhaltung der Anwendungsregeln\n• Meldung von Sicherheitsverletzungen';

  @override
  String get serviceLimitations => 'Serviceeinschränkungen';

  @override
  String get serviceLimitationsContent =>
      'Die Qanta-Anwendung unterliegt folgenden Einschränkungen:\n\n• Bietet keine Finanzberatungsdienste\n• Gibt keine Anlageberatung\n• Führt keine Banktransaktionen durch\n• Bietet keine Kredit- oder Kreditdienstleistungen\n• Bietet keine Steuerberatung';

  @override
  String get intellectualProperty => 'Geistiges Eigentum';

  @override
  String get intellectualPropertyContent =>
      'Alle Inhalte der Qanta-Anwendung sind urheberrechtlich geschützt:\n\n• Anwendungsdesign und Code\n• Logo und Markenelemente\n• Text- und visuelle Inhalte\n• Algorithmen und Berechnungsmethoden\n• Datenbankstruktur';

  @override
  String get serviceChanges => 'Serviceänderungen';

  @override
  String get serviceChangesContent =>
      'Qanta behält sich das Recht vor, Änderungen an seinen Diensten vorzunehmen:\n\n• Hinzufügen oder Entfernen von Funktionen\n• Preisänderungen\n• Aktualisierung der Nutzungsbedingungen\n• Dienstbeendigung\n• Wartung und Updates';

  @override
  String get disclaimer => 'Haftungsausschluss';

  @override
  String get disclaimerContent =>
      'Qanta ist nicht verantwortlich für folgende Situationen:\n\n• Datenverlust oder -beschädigung\n• Systemausfälle oder -unterbrechungen\n• Drittanbieter\n• Schäden durch Benutzerfehler\n• Internetverbindungsprobleme';

  @override
  String get termsContact => 'Kontakt';

  @override
  String get termsContactContent =>
      'Bei Fragen zu den Nutzungsbedingungen:\n\nE-Mail: support@qanta.app\nWeb: www.qanta.app\nAdresse: Istanbul, Türkei\n\nDiese Bedingungen wurden zuletzt aktualisiert: 20. Januar 2025';

  @override
  String get faq => 'Häufig gestellte Fragen';

  @override
  String get generalQuestions => 'Allgemeine Fragen';

  @override
  String get accountAndSecurity => 'Konto und Sicherheit';

  @override
  String get features => 'Funktionen';

  @override
  String get technicalIssues => 'Technische Probleme';

  @override
  String get whatIsQanta => 'Was ist Qanta?';

  @override
  String get whatIsQantaAnswer =>
      'Qanta ist eine moderne mobile Anwendung zur persönlichen Finanzverwaltung. Sie bietet Einnahmen-Ausgaben-Verfolgung, Budgetverwaltung, Kartenverfolgung und Finanzanalysefunktionen.';

  @override
  String get whichDevicesSupported =>
      'Auf welchen Geräten kann ich es verwenden?';

  @override
  String get whichDevicesSupportedAnswer =>
      'Qanta kann auf Android- und iOS-Geräten verwendet werden. Es wurde mit Flutter-Technologie entwickelt.';

  @override
  String get howToChangePassword => 'Wie kann ich mein Passwort ändern?';

  @override
  String get howToChangePasswordAnswer =>
      'Sie können die Option \"Passwort ändern\" im Bereich \"Sicherheit\" auf der Profilseite verwenden.';

  @override
  String get whichCardTypesSupported => 'Welche Kartentypen unterstützen Sie?';

  @override
  String get whichCardTypesSupportedAnswer =>
      'Kreditkarten, Debitkarten und Bargeldkonten werden unterstützt. Kompatibel mit allen türkischen Banken.';

  @override
  String get howDoesInstallmentTrackingWork =>
      'Wie funktioniert die Ratenzahlungsverfolgung?';

  @override
  String get howDoesInstallmentTrackingWorkAnswer =>
      'Sie können Ratenkäufe hinzufügen und Ihre monatlichen Zahlungen automatisch verfolgen. Das System sendet Ihnen Erinnerungen.';

  @override
  String get howToUseBudgetManagement =>
      'Wie verwende ich die Budgetverwaltung?';

  @override
  String get howToUseBudgetManagementAnswer =>
      'Sie können monatliche Limits für Kategorien festlegen, Ihre Ausgaben verfolgen und Warnungen erhalten, wenn Limits überschritten werden.';

  @override
  String get appCrashingWhatToDo => 'Die App stürzt ab, was soll ich tun?';

  @override
  String get appCrashingWhatToDoAnswer =>
      'Versuchen Sie zuerst, die App vollständig zu schließen und erneut zu öffnen. Wenn das Problem weiterhin besteht, starten Sie Ihr Gerät neu. Wenn es immer noch nicht behoben ist, kontaktieren Sie unser Support-Team.';

  @override
  String get dataNotSyncing => 'Meine Daten werden nicht synchronisiert';

  @override
  String get dataNotSyncingAnswer =>
      'Überprüfen Sie Ihre Internetverbindung und starten Sie die App neu. Wenn das Problem weiterhin besteht, versuchen Sie, sich ab- und wieder anzumelden.';

  @override
  String get notificationsNotComing => 'Benachrichtigungen kommen nicht an';

  @override
  String get notificationsNotComingAnswer =>
      'Stellen Sie sicher, dass Benachrichtigungen für Qanta in Ihren Geräteeinstellungen aktiviert sind. Überprüfen Sie auch die Benachrichtigungseinstellungen auf der Profilseite.';

  @override
  String get howToContactSupport =>
      'Wie kann ich Ihr Support-Team kontaktieren?';

  @override
  String get howToContactSupportAnswer =>
      'Sie können den Bereich \"Support & Kontakt\" auf der Profilseite verwenden oder eine E-Mail an support@qanta.app senden.';

  @override
  String get haveSuggestionWhereToSend =>
      'Ich habe einen Vorschlag, wohin kann ich ihn senden?';

  @override
  String get haveSuggestionWhereToSendAnswer =>
      'Sie können Ihre Vorschläge an support@qanta.app senden. Alle Rückmeldungen werden bewertet und zur Verbesserung der Anwendung verwendet.';

  @override
  String get lastMonthChange => 'im Vergleich zum Vormonat';

  @override
  String get increase => 'Anstieg';

  @override
  String get decrease => 'Rückgang';

  @override
  String get noAccountsYet => 'Noch keine Konten';

  @override
  String get addFirstAccount =>
      'Fügen Sie Ihr erstes Konto hinzu, um zu beginnen';

  @override
  String get currentDebt => 'Aktuelle Schulden';

  @override
  String get totalLimit => 'Gesamtlimit';

  @override
  String stockPurchaseInsufficientBalance(String balance) {
    return 'Unzureichender Saldo für Aktienkauf. Verfügbar: $balance';
  }

  @override
  String stockSaleInsufficientQuantity(String quantity) {
    return 'Unzureichende Aktienmenge. Verfügbar: $quantity Lose';
  }

  @override
  String get searchBanks => 'Banken suchen...';

  @override
  String get noBanksFound => 'Keine Banken gefunden';

  @override
  String get addCreditCard => 'Kreditkarte hinzufügen';

  @override
  String get cardNameExample => 'z.B.: Meine Arbeitskarte, Einkaufskarte';

  @override
  String get currentDebtOptional => 'Aktuelle Schulden (Optional)';

  @override
  String get addDebitCard => 'Debitkarte hinzufügen';

  @override
  String get cardNameExampleDebit => 'Z.B.: VakıfBank Girokonto';

  @override
  String get initialBalance => 'Anfangssaldo';

  @override
  String get day => 'Tag';

  @override
  String get firstDay => '1.';

  @override
  String get secondDay => '2.';

  @override
  String get thirdDay => '3.';

  @override
  String get fourthDay => '4.';

  @override
  String get fifthDay => '5.';

  @override
  String get sixthDay => '6.';

  @override
  String get seventhDay => '7.';

  @override
  String get eighthDay => '8.';

  @override
  String get ninthDay => '9.';

  @override
  String get tenthDay => '10.';

  @override
  String get eleventhDay => '11.';

  @override
  String get twelfthDay => '12.';

  @override
  String get thirteenthDay => '13.';

  @override
  String get fourteenthDay => '14.';

  @override
  String get fifteenthDay => '15.';

  @override
  String get sixteenthDay => '16.';

  @override
  String get seventeenthDay => '17.';

  @override
  String get eighteenthDay => '18.';

  @override
  String get nineteenthDay => '19.';

  @override
  String get twentiethDay => '20.';

  @override
  String get twentyFirstDay => '21.';

  @override
  String get twentySecondDay => '22.';

  @override
  String get twentyThirdDay => '23.';

  @override
  String get twentyFourthDay => '24.';

  @override
  String get twentyFifthDay => '25.';

  @override
  String get twentySixthDay => '26.';

  @override
  String get twentySeventhDay => '27.';

  @override
  String get twentyEighthDay => '28.';

  @override
  String get selectCardType => 'Kartentyp auswählen';

  @override
  String get addDebitCardDescription =>
      'Fügen Sie eine Debitkarte hinzu, um Ihre Ausgaben zu verfolgen';

  @override
  String get addCreditCardDescription =>
      'Fügen Sie eine Kreditkarte hinzu, um Ihr Kreditlimit zu verwalten';

  @override
  String get searchStocks => 'Aktien suchen';

  @override
  String get addStock => 'Aktie hinzufügen';

  @override
  String get removeStock => 'Aktie entfernen';

  @override
  String get stockDetails => 'Aktiendetails';

  @override
  String get positionSummary => 'Positionsübersicht';

  @override
  String get averagePrice => 'Ø Preis';

  @override
  String get avg => 'Ø';

  @override
  String get stockInfo => 'Aktieninformationen';

  @override
  String get exchange => 'Börse';

  @override
  String get sector => 'Sektor';

  @override
  String get country => 'Land';

  @override
  String get buyStock => 'Aktie kaufen';

  @override
  String get sellStock => 'Aktie verkaufen';

  @override
  String get buy => 'Kaufen';

  @override
  String get sell => 'Verkaufen';

  @override
  String get noStocksYet => 'Sie verfolgen noch keine Aktien';

  @override
  String get addFirstStock => 'Drücken Sie +, um Aktien hinzuzufügen';

  @override
  String get stockAdded => 'Aktie zur Beobachtungsliste hinzugefügt';

  @override
  String get stockRemoved => 'Aktie aus Beobachtungsliste entfernt';

  @override
  String confirmRemoveStock(String stockName) {
    return 'Sind Sie sicher, dass Sie $stockName aus der Beobachtungsliste entfernen möchten?';
  }

  @override
  String get chartComingSoon => 'Chart kommt bald';

  @override
  String get chartDescription =>
      'Preisdiagramme und Analysefunktionen werden entwickelt';

  @override
  String get shareStock => 'Aktie teilen';

  @override
  String get shareFeatureComingSoon => 'Teilen-Funktion kommt bald';

  @override
  String get buyFeatureComingSoon => 'Kauf-Transaktion kommt bald';

  @override
  String get sellFeatureComingSoon => 'Verkauf-Transaktion kommt bald';

  @override
  String get popularStocks => 'Beliebte Aktien';

  @override
  String get bistStocks => 'BIST Aktien';

  @override
  String get usStocks => 'US-Aktien';

  @override
  String minutesAgoFull(int count) {
    return 'vor $count Minuten';
  }

  @override
  String hoursAgoFull(int count) {
    return 'vor $count Stunden';
  }

  @override
  String daysAgoFull(int count) {
    return 'vor $count Tagen';
  }

  @override
  String get investmentsIncluded => 'Inklusive Investitionen';

  @override
  String get investmentsExcluded => 'Exklusive Investitionen';

  @override
  String get addFirstCardDescription =>
      'Gehen Sie zur Seite \"Meine Karten\", um Ihre erste Karte hinzuzufügen';

  @override
  String get firstCardRewardMessage =>
      'Add your first card and earn 250 points!';

  @override
  String get firstBudgetRewardMessage =>
      'Create your first budget and earn 250 points!';

  @override
  String get firstStockPurchaseRewardMessage =>
      'Make your first stock purchase and earn 250 points!';

  @override
  String get firstSubscriptionRewardMessage =>
      'Add your first subscription and earn 250 points!';

  @override
  String deleteTransactionConfirmation(String description) {
    return 'Sind Sie sicher, dass Sie die Transaktion $description löschen möchten?';
  }

  @override
  String deleteInstallmentConfirmation(String description) {
    return 'Sind Sie sicher, dass Sie die Transaktion $description löschen möchten? Alle Raten werden erstattet.';
  }

  @override
  String installmentDeleteError(String error) {
    return 'Fehler beim Löschen der Ratenzahlung: $error';
  }

  @override
  String get dueToday => 'Heute';

  @override
  String lastDays(int days) {
    return 'Letzte $days Tage';
  }

  @override
  String statementDebt(String amount) {
    return 'Auszugsschulden: $amount';
  }

  @override
  String get noDebt => 'Keine Schulden';

  @override
  String get important => 'Wichtig';

  @override
  String get info => 'Info';

  @override
  String get statementDebtLabel => 'Auszugsschulden';

  @override
  String debtAmount(String amount) {
    return 'Schulden: $amount';
  }

  @override
  String get lastPaymentDate => 'Letztes Zahlungsdatum';

  @override
  String get allNotifications => 'Alle Benachrichtigungen';

  @override
  String exampleExpenseNote(String currency) {
    return 'Z.B.: Lebensmitteleinkauf 150$currency';
  }

  @override
  String get addPhotoNote => 'Fotonotiz hinzufügen';

  @override
  String get addPhotoNoteDescription =>
      'Fügen Sie eine Beschreibung für dieses Foto hinzu (optional)';

  @override
  String examplePhotoNote(String currency) {
    return 'Z.B.: Quittung - 150$currency';
  }

  @override
  String viewAllNotes(int count) {
    return 'Alle Notizen anzeigen ($count)';
  }

  @override
  String secondsAgo(int count) {
    return 'vor $count Sekunden';
  }

  @override
  String yesterdayAt(String time) {
    return 'Gestern um $time';
  }

  @override
  String weekdayAt(String weekday, String time) {
    return '$weekday um $time';
  }

  @override
  String dayMonth(int day, String month) {
    return '$day $month';
  }

  @override
  String dayMonthYear(int day, int month, int year) {
    return '$day.$month.$year';
  }

  @override
  String get januaryShort => 'Jan';

  @override
  String get februaryShort => 'Feb';

  @override
  String get marchShort => 'Mär';

  @override
  String get aprilShort => 'Apr';

  @override
  String get mayShort => 'Mai';

  @override
  String get juneShort => 'Jun';

  @override
  String get julyShort => 'Jul';

  @override
  String get augustShort => 'Aug';

  @override
  String get septemberShort => 'Sep';

  @override
  String get octoberShort => 'Okt';

  @override
  String get novemberShort => 'Nov';

  @override
  String get decemberShort => 'Dez';

  @override
  String get stocksIncluded => 'Aktien eingeschlossen';

  @override
  String get stocksExcluded => 'Aktien ausgeschlossen';

  @override
  String get stockChip => 'Aktie';

  @override
  String get dailyPerformance => 'Tagesperformance';

  @override
  String get daily => 'Täglich';

  @override
  String get noStocksTracked => 'Noch keine Aktien verfolgt';

  @override
  String get stockDataLoading => 'Aktiendaten werden geladen...';

  @override
  String get addStocksInstruction =>
      'Gehen Sie zum Aktien-Tab, um Aktien hinzuzufügen';

  @override
  String get addStocks => 'Aktien hinzufügen';

  @override
  String get noPosition => 'Keine Position';

  @override
  String get topGainersDescription => 'Aktien mit den höchsten Gewinnen heute';

  @override
  String get marketOpen => 'Börse geöffnet';

  @override
  String get marketClosed => 'Börse geschlossen';

  @override
  String get intradayChange => 'Intraday-Änderung';

  @override
  String get previousClose => 'Vorheriger Schlusskurs';

  @override
  String get loadingStocks => 'Aktiendaten werden geladen...';

  @override
  String get noStockData => 'Keine Aktiendaten verfügbar';

  @override
  String get stockSale => 'Aktienverkauf';

  @override
  String get stockPurchase => 'Aktienkauf';

  @override
  String get stockName => 'Aktienname';

  @override
  String get price => 'Preis';

  @override
  String get total => 'Gesamt';

  @override
  String get pieces => 'Los';

  @override
  String get piecesPlural => 'Lose';

  @override
  String totalTransactionsCount(int count) {
    return '$count Transaktionen';
  }

  @override
  String incomeTransactionsCount(int count) {
    return '$count Einkommenstransaktionen';
  }

  @override
  String expenseTransactionsCount(int count) {
    return '$count Ausgabentransaktionen';
  }

  @override
  String transferTransactionsCount(int count) {
    return '$count Überweisungstransaktionen';
  }

  @override
  String stockTransactionsCount(int count) {
    return '$count Aktientransaktionen';
  }

  @override
  String get allTime => 'Gesamt';

  @override
  String get dailyAverageExpense => 'Durchschnittliche tägliche Ausgaben';

  @override
  String get noExpenseTransactions => 'Keine Ausgabentransaktionen gefunden';

  @override
  String get analyzeYourFinances => 'Analysieren Sie Ihre Finanzen';

  @override
  String get statistics => 'Statistiken';

  @override
  String get noExpenseRecordsYet => 'Noch keine Ausgabenaufzeichnungen';

  @override
  String get transactionHistoryEmpty => 'Transaktionsverlauf ist leer';

  @override
  String get noSpendingInPeriod => 'Keine Ausgaben im ausgewählten Zeitraum';

  @override
  String get spendingCategories => 'Ausgabenkategorien';

  @override
  String get noTransactionsInCategory =>
      'Keine Transaktionen in dieser Kategorie gefunden';

  @override
  String get chart => 'Diagramm';

  @override
  String get table => 'Tabelle';

  @override
  String get monthlyExpenseAnalysis => 'Monatliche Ausgabenanalyse';

  @override
  String get monthlyIncomeAnalysis => 'Monatliche Einkommensanalyse';

  @override
  String get monthlyNetBalanceAnalysis => 'Monatliche Nettosaldoanalyse';

  @override
  String noMonthlyData(String title) {
    return 'Keine monatlichen $title Daten';
  }

  @override
  String get addFirstTransactionToStart =>
      'Fügen Sie Ihre erste Transaktion hinzu, um zu beginnen';

  @override
  String get month => 'Monat';

  @override
  String get change => 'Änderung';

  @override
  String get stable => 'Stabil';

  @override
  String get stockTrading => 'Aktienhandel';

  @override
  String get unknownCategory => 'Unbekannte Kategorie';

  @override
  String get trackYourStocks => 'Verfolgen Sie Ihre Aktien';

  @override
  String get chartDevelopmentMessage =>
      'Preisdiagramme und Analysefunktionen werden entwickelt';

  @override
  String get buyTransactionComingSoon => 'Kauf-Transaktion kommt bald';

  @override
  String get sellTransactionComingSoon => 'Verkauf-Transaktion kommt bald';

  @override
  String get loadingPopularStocks => 'Beliebte Aktien werden geladen...';

  @override
  String get noStocksFound => 'Keine Aktien gefunden';

  @override
  String get tryDifferentSearchTerm =>
      'Versuchen Sie einen anderen Suchbegriff';

  @override
  String get dayHigh => 'Tageshoch';

  @override
  String get dayLow => 'Tagestief';

  @override
  String get volume => 'Volumen';

  @override
  String get remove => 'Entfernen';

  @override
  String get removeFromWatchlist => 'Aus Beobachtungsliste entfernen';

  @override
  String get errorRemovingStock => 'Fehler beim Entfernen der Aktie';

  @override
  String stockRemovedFromPortfolio(String stockName) {
    return '$stockName aus Portfolio entfernt';
  }

  @override
  String get cannotRemoveStock => 'Kann nicht entfernt werden';

  @override
  String cannotRemoveStockWithPosition(String stockName) {
    return 'Sie haben eine aktive Position in $stockName. Bitte verkaufen Sie alle Anteile, bevor Sie sie aus der Beobachtungsliste entfernen.';
  }

  @override
  String get stockTransaction => 'Aktientransaktion';

  @override
  String get priceRequired => 'Preis erforderlich';

  @override
  String get enterValidPrice => 'Geben Sie einen gültigen Preis ein';

  @override
  String get transactionSummary => 'Transaktionsübersicht';

  @override
  String get subtotal => 'Zwischensumme';

  @override
  String executeTransaction(String transactionType) {
    return '$transactionType-Transaktion ausführen';
  }

  @override
  String get unknownStock => 'Unbekannte Aktie';

  @override
  String get selectStock => 'Aktie auswählen';

  @override
  String get selectAccount => 'Zahlungskonto auswählen';

  @override
  String get pleaseSelectStock => 'Bitte wählen Sie eine Aktie aus';

  @override
  String get pleaseSelectAccount => 'Bitte wählen Sie ein Konto aus';

  @override
  String get noStockSelected => 'Keine Aktie ausgewählt';

  @override
  String get executePurchase => 'Kauf ausführen';

  @override
  String get executeSale => 'Verkauf ausführen';

  @override
  String get noStocksAddedYet => 'Noch keine Aktien hinzugefügt';

  @override
  String get addFirstStockInstruction =>
      'Gehen Sie zum Aktienbildschirm, um Ihre erste Aktie hinzuzufügen';

  @override
  String get quantityAndPrice => 'Menge & Preis';

  @override
  String get newBadge => 'NEU';

  @override
  String get commissionRate => 'Provisionssatz:';

  @override
  String get commission => 'Provision';

  @override
  String get totalToPay => 'Zu zahlender Betrag:';

  @override
  String get totalToReceive => 'Zu erhaltender Betrag:';

  @override
  String get noCashAccountFound => 'Kein Bargeldkonto gefunden';

  @override
  String get addCashAccountForStockTrading =>
      'Sie müssen zuerst ein Bargeldkonto hinzufügen, um Aktientransaktionen durchzuführen.';

  @override
  String get currentPrice => 'Aktueller Preis';

  @override
  String get currentValue => 'Aktueller Wert';

  @override
  String get deleteInstallmentConfirm =>
      'Ratenzahlungstransaktion. Sind Sie sicher, dass Sie sie vollständig löschen möchten?';

  @override
  String get deleteInstallmentWarning =>
      'Diese Aktion löscht alle Raten und erstattet gezahlte Beträge.';

  @override
  String get errorDeletingTransaction => 'Fehler beim Löschen der Transaktion';

  @override
  String get deletingInstallmentTransaction =>
      'Ratenzahlungstransaktion wird gelöscht...';

  @override
  String get errorDeletingInstallmentTransaction =>
      'Fehler beim Löschen der Ratenzahlungstransaktion';

  @override
  String get cost => 'Kosten';

  @override
  String get weightedAverageCost => 'Gewichtete Durchschnittskosten';

  @override
  String get portfolioOverview => 'Portfolio-Übersicht';

  @override
  String get myPortfolio => 'Mein Portfolio';

  @override
  String get neutral => 'Neutral';

  @override
  String get profit => 'Gewinn';

  @override
  String get loss => 'Verlust';

  @override
  String get filterBy => 'Filtern nach';

  @override
  String get gainers => 'Steigend';

  @override
  String get losers => 'Fallend';

  @override
  String get portfolioRatio => 'Gewichtung';

  @override
  String get insufficientBalance => 'Unzureichendes Guthaben';

  @override
  String get addMoneyToAccount =>
      'Fügen Sie Geld zu Ihrem Konto hinzu, um Aktien zu kaufen';

  @override
  String get addMoney => 'Geld hinzufügen';

  @override
  String get addBankAccount => 'Bankkonto hinzufügen';

  @override
  String get noBankAccountCashZero =>
      'Ihr Bargeldguthaben ist null und Sie haben kein Bankkonto';

  @override
  String get updateCashOrAddBank =>
      'Aktualisieren Sie Ihr Bargeldguthaben oder fügen Sie ein Bankkonto hinzu';

  @override
  String get totalValue => 'Gesamtwert';

  @override
  String get totalCost => 'Gesamtkosten';

  @override
  String get totalProfitLoss => 'Gesamt G&V';

  @override
  String get totalReturn => 'Gesamtrendite';

  @override
  String get profitLoss => 'Gewinn/Verlust';

  @override
  String get calendar => 'Kalender';

  @override
  String get mondayShort => 'Mo';

  @override
  String get tuesdayShort => 'Di';

  @override
  String get wednesdayShort => 'Mi';

  @override
  String get thursdayShort => 'Do';

  @override
  String get fridayShort => 'Fr';

  @override
  String get saturdayShort => 'Sa';

  @override
  String get sundayShort => 'So';

  @override
  String get analysisFeaturesInDevelopment =>
      'Analysefunktionen in Entwicklung';

  @override
  String get value => 'Wert';

  @override
  String get returnLabel => 'Rendite';

  @override
  String get quickAddNote => 'Schnell Notiz hinzufügen';

  @override
  String get addNoteHint => 'z.B. 50€ Lebensmitteleinkauf';

  @override
  String get voiceButton => 'Sprache';

  @override
  String get stopButton => 'Stopp';

  @override
  String get photoButton => 'Foto';

  @override
  String get addButton => 'Hinzufügen';

  @override
  String get pendingNotes => 'Ausstehend';

  @override
  String get processedNotes => 'Verarbeitet';

  @override
  String get pendingNotesTitle => 'Ausstehende Notizen';

  @override
  String get processedNotesTitle => 'Verarbeitete Notizen';

  @override
  String get noPendingNotes =>
      'Noch keine ausstehenden Notizen\nFügen Sie Notizen schnell aus dem Feld oben hinzu';

  @override
  String get noProcessedNotes =>
      'Noch keine Notizen in Transaktionen umgewandelt';

  @override
  String get noteStatusPending => 'Ausstehend';

  @override
  String get noteStatusProcessed => 'Verarbeitet';

  @override
  String get convertToExpense => 'Ausgabe';

  @override
  String get convertToIncome => 'Einnahme';

  @override
  String get deleteNote => 'Löschen';

  @override
  String noteAddedSuccess(String content) {
    return 'Notiz hinzugefügt: $content';
  }

  @override
  String get noteConvertedSuccess =>
      'Notiz erfolgreich in Transaktion umgewandelt';

  @override
  String get noteDeletedSuccess => 'Notiz gelöscht';

  @override
  String get timeNow => 'Jetzt';

  @override
  String timeMinutesAgo(int minutes) {
    return 'vor $minutes Min';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'vor $hours Std';
  }

  @override
  String timeDaysAgo(int days) {
    return 'vor $days Tagen';
  }

  @override
  String get cutOff => 'Fälligkeit';

  @override
  String get paid => 'Bezahlt';

  @override
  String get overdue => 'Überfällig';

  @override
  String get daysLeft => 'Tage verbleibend';

  @override
  String get noTransactionsInStatement =>
      'Keine Transaktionen in diesem Kontoauszug';

  @override
  String get loadingStatements => 'Kontoauszüge werden geladen...';

  @override
  String get loadMore => 'Mehr laden';

  @override
  String get loadingMore => 'Wird geladen...';

  @override
  String get currentStatement => 'Aktueller Kontoauszug';

  @override
  String get pastStatements => 'Vergangene Kontoauszüge';

  @override
  String get futureStatements => 'Zukünftige Kontoauszüge';

  @override
  String get statements => 'Kontoauszüge';

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
  String get statementOperations => 'Kontoauszugsoperationen';

  @override
  String get downloadPdf => 'PDF herunterladen';

  @override
  String get downloadPdfSubtitle => 'Kontoauszug als PDF herunterladen';

  @override
  String get share => 'Teilen';

  @override
  String get shareSubtitle => 'Kontoauszug teilen';

  @override
  String get markAsUnpaid => 'Als unbezahlt markieren';

  @override
  String get markAsUnpaidSubtitle =>
      'Zahlungsstatus dieses Kontoauszugs ändern';

  @override
  String get statementMarkedAsUnpaid => 'Kontoauszug als unbezahlt markiert';

  @override
  String get errorMarkingStatement => 'Fehler beim Markieren des Kontoauszugs';

  @override
  String get pdfExportComingSoon => 'PDF-Export-Funktion kommt bald';

  @override
  String get noStatementsYet => 'Noch keine Kontoauszüge';

  @override
  String get statementsWillAppearAfterUsage =>
      'Kontoauszüge erscheinen hier nach Kartennutzung';

  @override
  String installmentCount(int count) {
    return '$count Raten';
  }

  @override
  String get limitManagement => 'Limitverwaltung';

  @override
  String get pleaseEnterCategoryAndLimit =>
      'Bitte geben Sie den Kategorienamen ein und setzen Sie das Limit';

  @override
  String get enterValidLimit => 'Geben Sie ein gültiges Limit ein';

  @override
  String get limitSavedSuccessfully => 'Limit erfolgreich gespeichert';

  @override
  String get noLimitsSetYet => 'Noch keine Limits gesetzt';

  @override
  String get setMonthlySpendingLimits =>
      'Setzen Sie monatliche Ausgabenlimits für Kategorien,\num Ihr Budget zu kontrollieren';

  @override
  String get monthlyLimit => 'Monatliches Limit:';

  @override
  String get exceeded => 'Überschritten';

  @override
  String get limitExceeded => 'Limit überschritten!';

  @override
  String get creditCardLimitInsufficient => 'Kreditkartenlimit unzureichend';

  @override
  String creditCardLimitInsufficientWithAmount(String amount) {
    return 'Kreditkartenlimit unzureichend. Verbleibendes Limit: $amount';
  }

  @override
  String get creditCardLimitInsufficientTitle =>
      'Kreditkartenlimit unzureichend';

  @override
  String get creditCardLimitInsufficientMessage =>
      'Ihr Kreditkartenlimit reicht für diese Transaktion nicht aus. Bitte geben Sie einen niedrigeren Betrag ein oder begleichen Sie Ihre Kartenschulden.';

  @override
  String get debitCardBalanceInsufficientTitle =>
      'Debitkartenguthaben unzureichend';

  @override
  String get debitCardBalanceInsufficientMessage =>
      'Ihr Debitkartenguthaben reicht für diese Transaktion nicht aus. Bitte geben Sie einen niedrigeren Betrag ein oder zahlen Sie Geld auf Ihre Karte ein.';

  @override
  String cashBalanceInsufficientWithAmount(String amount) {
    return 'Bargeldguthaben unzureichend. Aktuell: $amount';
  }

  @override
  String debitCardBalanceInsufficientWithAmount(String amount) {
    return 'Debitkartenguthaben unzureichend. Aktuell: $amount';
  }

  @override
  String get cashBalanceInsufficientTitle => 'Bargeldguthaben unzureichend';

  @override
  String get cashBalanceInsufficientMessage =>
      'Ihr Bargeldguthaben reicht für diese Transaktion nicht aus. Bitte geben Sie einen niedrigeren Betrag ein.';

  @override
  String get insufficientBalanceTitle => 'Unzureichendes Guthaben';

  @override
  String get spentAmount => 'Ausgegeben:';

  @override
  String get limitAmountHint => '2.000';

  @override
  String get addNewLimit => 'Neues Limit hinzufügen';

  @override
  String get monthlyLimitLabel => 'Monatliches Limit';

  @override
  String get limitAmountPlaceholder => '0,00';

  @override
  String get startDate => 'Startdatum';

  @override
  String get selectStartDate => 'Startdatum auswählen';

  @override
  String get startDateHint => 'Budget-Startdatum';

  @override
  String get limitDuration => 'Limitdauer';

  @override
  String get oneTime => 'Einmalig';

  @override
  String get recurring => 'Wiederkehrend';

  @override
  String limitWillRenew(String period) {
    return 'Dieses Limit wird automatisch $period erneuert';
  }

  @override
  String get limitOneTime => 'Dieses Limit wird einmalig erstellt';

  @override
  String get saveLimit => 'Limit speichern';

  @override
  String get limit => 'Limit';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get signUpWithGoogle => 'Mit Google registrieren';

  @override
  String get googleSignInError => 'Google-Anmeldefehler';

  @override
  String get googleSignUpError => 'Google-Registrierungsfehler';

  @override
  String get googleSignUpSuccess => 'Erfolgreich mit Google registriert!';

  @override
  String get or => 'oder';

  @override
  String get addFirstNoteInstruction =>
      'Tippen Sie auf die + Schaltfläche, um Ihre erste Notiz hinzuzufügen';

  @override
  String get addExpenseIncomeNoteInstruction =>
      'Schreiben Sie Ihre Ausgaben- oder Einnahmennotiz. Sie können sie später als Transaktion hinzufügen.';

  @override
  String get stockTransactionCannotDelete =>
      'Aktientransaktionen können nicht gelöscht werden';

  @override
  String get stockTransactionDeleteWarning =>
      'Erstellen Sie stattdessen eine Verkaufstransaktion';

  @override
  String get editCreditCard => 'Kreditkarte bearbeiten';

  @override
  String get selectBank => 'Bank auswählen';

  @override
  String get pleaseSelectBank => 'Bitte wählen Sie eine Bank aus';

  @override
  String get cardNameOptional => 'Kartenname';

  @override
  String get statementDayLabel => 'Auszugstag';

  @override
  String get selectStatementDay => 'Auszugstag auswählen';

  @override
  String get creditCardUpdatedSuccessfully =>
      'Kreditkarte erfolgreich aktualisiert';

  @override
  String updateErrorOccurred(String error) {
    return 'Ein Fehler ist beim Aktualisieren aufgetreten: $error';
  }

  @override
  String get invalidMonth => 'Ungültiger Monat';

  @override
  String get addCardDescription =>
      'Fügen Sie Ihre erste Karte hinzu, um mit der Verwaltung Ihrer Finanzen zu beginnen';

  @override
  String get budgetManagementDescription =>
      'Verfolgen Sie Ihre Ausgabenlimits und verwalten Sie Ihre wöchentlichen, monatlichen und jährlichen Budgets nach Kategorie';

  @override
  String get dark => 'DUNKEL';

  @override
  String get light => 'HELL';

  @override
  String get on => 'EIN';

  @override
  String get off => 'AUS';

  @override
  String get last7Days => 'Letzte 7 Tage';

  @override
  String get last30Days => 'Letzte 30 Tage';

  @override
  String get bankCard => 'Bankkarte';

  @override
  String get noStocksMatchFilter =>
      'Keine Aktien entsprechen dem aktuellen Filter';

  @override
  String get tryDifferentFilter =>
      'Versuchen Sie, einen anderen Filter auszuwählen';

  @override
  String get lunchBreak => 'Mittagspause';

  @override
  String get lunchBreakMessage =>
      'Die Hälfte des Tages ist vorbei, überprüfen Sie die heutigen Ausgaben';

  @override
  String get eveningCheck => 'Abendliche Überprüfung';

  @override
  String get eveningCheckMessage =>
      'Vergessen Sie nicht, die heutigen Ausgaben zu erfassen';

  @override
  String get dayEnd => 'Tagesende';

  @override
  String get dayEndMessage =>
      'Notieren Sie die heutigen Einnahmen und Ausgaben';

  @override
  String get qantaReminders => 'Qanta Erinnerungen';

  @override
  String get reminderChannelDescription =>
      'Erinnerungen für Ausgaben und Einnahmen';

  @override
  String budgetExceededWarning(String amount) {
    return 'Diese Ausgabe überschreitet Ihr Budgetlimit um $amount€';
  }

  @override
  String budgetExceededWarningTotal(String amount) {
    return 'Diese Ausgabe überschreitet Ihr Budgetlimit um $amount€';
  }

  @override
  String get budgetNearLimitWarning =>
      'Diese Ausgabe überschreitet 80% Ihres Budgetlimits';

  @override
  String get exampleMarketShopping => 'z.B. Lebensmitteleinkauf';

  @override
  String get exampleSalary => 'z.B. Gehalt';

  @override
  String get accountInfoError =>
      'Kontoinformationen konnten nicht abgerufen werden';

  @override
  String transactionError(String error) {
    return 'Fehler beim Hinzufügen der Transaktion: $error';
  }

  @override
  String get limitDeleteError => 'Limit konnte nicht gelöscht werden';

  @override
  String get installment_summary => 'Ratenzahlungen';

  @override
  String get manage => 'Verwalten';

  @override
  String get overallBudget => 'Gesamtbudget';

  @override
  String get categoryDistribution => 'Kategorieverteilung';

  @override
  String get spendingStatus => 'Ausgabenstatus';

  @override
  String get duplicateBudgetWarning => 'Bestehendes Budget';

  @override
  String get duplicateBudgetMessage =>
      'Für diese Kategorie existiert bereits ein Budget im gleichen Zeitraum. Verwenden Sie die Budgetverwaltungsseite, um das bestehende Budget zu bearbeiten.';

  @override
  String get categories => 'Kategorien';

  @override
  String get overBudget => 'Über Budget';

  @override
  String budgetExceededBy(Object amount) {
    return 'Sie haben Ihr Budget um $amount überschritten';
  }

  @override
  String get days => 'Tage';

  @override
  String get weeks => 'Wochen';

  @override
  String get months => 'Monate';

  @override
  String get years => 'Jahre';

  @override
  String get weeklyTrend => 'Wöchentlicher Trend';

  @override
  String get weeklyTrendExplanation =>
      'Zeigt das Ausgabenmuster der letzten 7 Tage. Höhere Ausgaben an Wochenenden und niedrigere an Montagen sind normal.';

  @override
  String get dailyLimit => 'Tageslimit';

  @override
  String get fastSpendingExplanation =>
      'Sie geben mehr als 15% Ihres täglichen Budgets aus. Es wird empfohlen, vorsichtiger zu sein.';

  @override
  String get normalSpendingExplanation =>
      'Sie geben zwischen 8-15% Ihres täglichen Budgets aus. Das ist eine gesunde Ausgabenrate.';

  @override
  String get slowSpendingExplanation =>
      'Sie geben weniger als 8% Ihres täglichen Budgets aus. Sie sparen!';

  @override
  String get defaultSpendingExplanation =>
      'Dieser Betrag ist Ihr Gesamtbudget dividiert durch die verbleibenden Tage.';

  @override
  String get cardLimitReached => 'Kartenlimit erreicht';

  @override
  String get cardLimitReachedMessage =>
      'Sie können in der kostenlosen Version bis zu 3 Karten hinzufügen';

  @override
  String get cardLimitExceeded => 'Kartenlimit';

  @override
  String cardLimitExceededMessage(int totalCards, int deleteCount) {
    return 'Sie haben $totalCards Karten (vom Premium-Plan)\n\nKostenlose Benutzer können max. 3 Karten verwenden. Bitte löschen Sie $deleteCount Karten oder upgraden Sie auf Premium.';
  }

  @override
  String get upgradeToPremium => 'Auf Premium upgraden';

  @override
  String get premiumOfferTitle => 'Qanta Premium';

  @override
  String get premiumOfferSubtitle => 'Alle Funktionen freischalten';

  @override
  String get freeVersion => 'Kostenlos';

  @override
  String get premiumVersion => 'Premium';

  @override
  String get featureCardLimit => 'Kartenlimit';

  @override
  String get featureCardLimitFree => '3 Karten';

  @override
  String get featureCardLimitPremium => 'Unbegrenzt';

  @override
  String get featureStockLimit => 'Stock Limit';

  @override
  String get featureStockLimitFree => '3 Aktien';

  @override
  String get featureStockLimitPremium => 'Unbegrenzt';

  @override
  String get stockLimitReached => 'Aktienlimit erreicht';

  @override
  String get stockLimitReachedMessage =>
      'Sie können in der kostenlosen Version bis zu 3 Aktien hinzufügen';

  @override
  String get featureAILimit => 'KI-Nutzungslimit';

  @override
  String get featureAILimitFree => '10/Tag';

  @override
  String get featureAILimitPremium => '75/Tag';

  @override
  String get featureAds => 'Werbung';

  @override
  String get featureAdsFree => 'Ja';

  @override
  String get featureAdsPremium => 'Nein';

  @override
  String get featureSupport => 'Support';

  @override
  String get featureSupportFree => 'Community';

  @override
  String get featureSupportPremium => 'Priorität';

  @override
  String get featureUpdates => 'Updates';

  @override
  String get featureUpdatesFree => 'Standard';

  @override
  String get featureUpdatesPremium => 'Früher Zugang';

  @override
  String get getQantaPremium => 'Qanta Premium erhalten';

  @override
  String get continueWithFree => 'Mit kostenloser Version fortfahren';

  @override
  String get premiumBenefitsTitle => 'Premium-Vorteile';

  @override
  String get upgradeToPremiumBanner => 'Auf Premium upgraden';

  @override
  String get premiumBannerSubtitle =>
      'Werbung entfernen, unbegrenzte Funktionen';

  @override
  String get discover => 'Entdecken';

  @override
  String get premiumStatus => 'Premium';

  @override
  String get premiumActive => 'Premium aktiv';

  @override
  String get premiumActiveDescription =>
      'Unbegrenzte Funktionen, werbefreie Erfahrung';

  @override
  String get manageSubscription => 'Abonnement verwalten';

  @override
  String get manageSubscriptionDescription =>
      'Abonnementeinstellungen in Google Play bearbeiten';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get restorePurchasesDescription =>
      'Premium wiederherstellen, wenn Sie zuvor gekauft haben';

  @override
  String get checkingPurchases => 'Wird geprüft...';

  @override
  String get premiumRestored => 'Premium wiederhergestellt!';

  @override
  String get noActivePremium => 'Kein aktives Premium-Abonnement gefunden';

  @override
  String get playStoreError => 'Google Play Store konnte nicht geöffnet werden';

  @override
  String get upgradeNow => 'Upgraden';

  @override
  String get quickAddHint => 'z.B.: 50€ Kaffee | 15 Äpfel zu 180€ verkauft';

  @override
  String get quickAddTransaction => 'Transaktion schnell hinzufügen';

  @override
  String get confirmAndSave => 'Bestätigen und speichern';

  @override
  String stockSymbolQuantity(String symbol, int quantity) {
    return '$quantity Anteile von $symbol';
  }

  @override
  String get buyOrSell => 'Kaufen oder Verkaufen?';

  @override
  String get priceNotSpecified => 'Preis nicht angegeben';

  @override
  String get pleaseEnterPrice =>
      'Bitte geben Sie den Preis ein.\nBeispiel: \"15 Äpfel zu 180€ verkauft\"';

  @override
  String get goBack => 'Zurück';

  @override
  String get summaryHint => 'Bestätigen oder abbrechen Sie die Zusammenfassung';

  @override
  String aiChatWelcome(String name) {
    return 'Hallo $name!\nWie kann ich Ihnen helfen? Möchten Sie eine Ausgabe oder Einnahme hinzufügen?';
  }

  @override
  String get aiChatError =>
      'Entschuldigung, ein Fehler ist aufgetreten. Möchten Sie es erneut versuchen?';

  @override
  String get aiImageAnalysisError =>
      'Beim Analysieren des Bildes ist ein Fehler aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String get aiCategoryCreationError =>
      'Beim Erstellen der Kategorie ist ein Fehler aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String get watchAdBonus => 'Werbung ansehen (+5 Bonus)';

  @override
  String get adLoading => 'Werbung wird geladen...';

  @override
  String get aiChatTransactionSuccess => 'Transaktion erfolgreich erfasst.';

  @override
  String get aiChatTransactionFailed =>
      'Beim Hinzufügen der Transaktion ist ein Fehler aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String get aiChatThemeFailed =>
      'Theme konnte nicht geändert werden. Bitte versuchen Sie es erneut.';

  @override
  String get aiChatDeleteConfirmTitle => 'Massenlöschung bestätigen';

  @override
  String get aiChatDeleteButton => 'Löschen';

  @override
  String get aiChatDeleteProcessing =>
      'Transaktionen werden gelöscht, bitte warten...';

  @override
  String aiChatDeleteSuccess(String message, int count, int duration) {
    return 'Löschung abgeschlossen! $count Transaktionen erfolgreich gelöscht.';
  }

  @override
  String get aiChatDeleteFailed =>
      '❌ Löschung fehlgeschlagen.\n\nBitte versuchen Sie es erneut oder überprüfen Sie Ihre Internetverbindung.';

  @override
  String get aiChatConfirmButton => 'Bestätigen';

  @override
  String get aiChatCancelButton => 'Abbrechen';

  @override
  String get aiChatPendingApproval =>
      'Bitte bestätigen Sie die Transaktion oben...';

  @override
  String get aiChatSendPlaceholder => 'Nachricht eingeben... (z.B. 50€ Kaffee)';

  @override
  String get aiChatToday => 'Heutige';

  @override
  String get aiChatYesterday => 'Gestrige';

  @override
  String aiChatLastNDays(int days) {
    return 'Letzte $days Tage';
  }

  @override
  String get aiChatAllTransactions => 'alle Transaktionen';

  @override
  String get aiChatExpenses => 'Ausgaben';

  @override
  String get aiChatIncome => 'Einnahmen';

  @override
  String aiChatDeleteWarning(String timeText, String typeText) {
    return 'Sie sind dabei, $timeText $typeText zu löschen. Diese Aktion kann nicht rückgängig gemacht werden. Sind Sie sicher?';
  }

  @override
  String get aiChatDailyUsage => 'Tägliche Nutzung';

  @override
  String get aiChatAssistant => 'Ihr Finanzassistent';

  @override
  String get clearChatHistory => 'Verlauf löschen';

  @override
  String get clearChatHistoryConfirmation =>
      'Der gesamte Chatverlauf wird gelöscht. Sind Sie sicher?';

  @override
  String get chatHistoryCleared => 'Chatverlauf gelöscht';

  @override
  String get clear => 'Löschen';

  @override
  String aiChatDailyLimitReached(int limit) {
    return 'Sie haben Ihr tägliches KI-Limit erreicht ($limit Nachrichten/Tag). Versuchen Sie es morgen erneut.';
  }

  @override
  String get aiChatTransactionCancelled => 'In Ordnung, abgebrochen 👍';

  @override
  String get confirmTransactions => 'Transaktionen bestätigen';

  @override
  String get transactionsSelected => 'Transaktionen ausgewählt';

  @override
  String get noTransactionsSelected =>
      'Bitte wählen Sie mindestens eine Transaktion aus';

  @override
  String get transactionsSaved => 'Transaktionen gespeichert';

  @override
  String get errorSavingTransactions =>
      'Fehler beim Speichern der Transaktionen. Bitte versuchen Sie es erneut.';

  @override
  String get saveSelected => 'Ausgewählte speichern';

  @override
  String budgetCreated(Object category, Object period, Object limit) {
    return 'Budget erstellt! $period Limit von $limit für $category gesetzt. 💰';
  }

  @override
  String budgetUpdated(Object category, Object limit) {
    return 'Budget aktualisiert! Neues Limit für $category: $limit 📊';
  }

  @override
  String budgetDeleted(Object category) {
    return 'Budget gelöscht. $category Budget wird nicht mehr verfolgt. ✅';
  }

  @override
  String get budgetCreateFailed =>
      'Budget konnte nicht erstellt werden. Bitte versuchen Sie es erneut. ❌';

  @override
  String get budgetUpdateFailed =>
      'Budget konnte nicht aktualisiert werden. Bitte versuchen Sie es erneut. ❌';

  @override
  String get budgetDeleteFailed =>
      'Budget konnte nicht gelöscht werden. Bitte versuchen Sie es erneut. ❌';

  @override
  String get quickActionAddExpense => 'Ausgabe hinzufügen';

  @override
  String get quickActionAddIncome => 'Einnahme hinzufügen';

  @override
  String get quickActionAnalyzeInvoice => 'Rechnung analysieren';

  @override
  String get quickActionCreateBudget => 'Budget erstellen';

  @override
  String get quickActionAddAccount => 'Konto hinzufügen';

  @override
  String get quickActionViewTransactions => 'Meine Transaktionen anzeigen';

  @override
  String get planFree => 'Kostenlos';

  @override
  String get planPremium => 'Premium';

  @override
  String get planPremiumPlus => 'Premium Plus';

  @override
  String get mostPopular => 'Beliebteste';

  @override
  String get perYear => '/Jahr';

  @override
  String savePercentage(int percentage) {
    return '$percentage% sparen';
  }

  @override
  String get featureAILimitPremiumPlus => '250/Tag';

  @override
  String get planFreeDescription => 'Perfekt zum Einstieg';

  @override
  String get planPremiumDescription => 'Für den täglichen Gebrauch';

  @override
  String get planPremiumPlusDescription => 'Für Power-User';

  @override
  String get choosePlan => 'Plan auswählen';

  @override
  String get currentPlan => 'Aktueller Plan';

  @override
  String get unlockAllFeatures => 'Alle Funktionen freischalten';

  @override
  String get welcomeCampaign => 'Willkommensaktion!';

  @override
  String monthlyPremiumOnly(String price) {
    return 'Monatliches Premium nur $price';
  }

  @override
  String percentDiscount(String percent) {
    return '$percent% RABATT';
  }

  @override
  String daysRemaining(int days) {
    return '$days Tage';
  }

  @override
  String get comparePlans => 'Pläne vergleichen';

  @override
  String get featurePrioritySupport => 'Prioritätssupport';

  @override
  String get featureEarlyAccess => 'Früher Zugang';

  @override
  String featureAIMessagesPerDay(String count) {
    return '$count Anfragen/Monat';
  }

  @override
  String get featureUnlimitedCards => 'Unbegrenzte Karten';

  @override
  String featureLimitedCards(String count) {
    return 'Bis zu $count Karten';
  }

  @override
  String get featureUnlimitedStocks => 'Unbegrenzte Aktienverfolgung';

  @override
  String featureLimitedStocks(String count) {
    return 'Bis zu $count Aktien';
  }

  @override
  String get featureWithAds => 'Enthält Werbung';

  @override
  String get featureNoAds => 'Werbefreie Erfahrung';

  @override
  String get featureBasicSupport => 'Basis-Support';

  @override
  String get feature247Support => '24/7 Prioritätssupport';

  @override
  String get featureEarlyAccessDescription =>
      'Früher Zugang zu neuen Funktionen';

  @override
  String featurePointsMultiplier(String multiplier) {
    return '${multiplier}x Punkte-Multiplikator';
  }

  @override
  String get skip => 'Überspringen';

  @override
  String get premiumWelcomeTitle => 'Willkommen bei Premium!';

  @override
  String get premiumWelcomeSubtitle =>
      'Vielen Dank für das Upgrade. Sie haben jetzt Zugriff auf alle Premium-Funktionen.';

  @override
  String get premiumFeaturesTitle => 'Ihre Premium-Funktionen';

  @override
  String get premiumFeatureAI => 'Unbegrenzte KI-Insights';

  @override
  String get premiumFeatureReports => 'Erweiterte Berichte & Analysen';

  @override
  String get premiumFeatureCards => 'Unbegrenzte Karten & Konten';

  @override
  String get premiumFeatureStocks => 'Unbegrenzte Aktienverfolgung';

  @override
  String get premiumFeatureNoAds => 'Werbefreie Erfahrung';

  @override
  String get premiumReadyTitle => 'Sie sind bereit!';

  @override
  String get premiumReadySubtitle =>
      'Beginnen Sie Ihre Premium-Reise und übernehmen Sie die Kontrolle über Ihre Finanzen.';

  @override
  String get totalSavings => 'Gesamtersparnisse';

  @override
  String get myGoals => 'Meine Ziele';

  @override
  String get noSavingsGoals => 'Noch keine Sparziele';

  @override
  String get createFirstGoal =>
      'Erstellen Sie Ihr erstes Sparziel und beginnen Sie, Ihre finanzielle Zukunft aufzubauen!';

  @override
  String get createGoal => 'Ziel erstellen';

  @override
  String get createSavingsGoal => 'Sparziel erstellen';

  @override
  String get goalName => 'Zielname';

  @override
  String get enterGoalName => 'Zielname eingeben';

  @override
  String get pleaseEnterGoalName => 'Bitte geben Sie einen Zielnamen ein';

  @override
  String get targetAmount => 'Zielbetrag';

  @override
  String get currentAmount => 'Aktueller Betrag';

  @override
  String get current => 'Aktuell';

  @override
  String get target => 'Ziel';

  @override
  String get targetDate => 'Zieldatum';

  @override
  String get selectDate => 'Datum auswählen';

  @override
  String get selectColor => 'Farbe auswählen';

  @override
  String get optional => 'Optional';

  @override
  String get goalCreatedSuccessfully => 'Ziel erfolgreich erstellt!';

  @override
  String get archived => 'Archiviert';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get goalInfoFailed =>
      'Zielinformationen konnten nicht geladen werden. Bitte aktualisieren Sie die Seite.';

  @override
  String get goalNotFound => 'Ziel nicht gefunden';

  @override
  String get savingsCompleted => 'Ersparnisse abgeschlossen';

  @override
  String get addSavings => 'Ersparnisse hinzufügen';

  @override
  String get withdraw => 'Abheben';

  @override
  String get withdrawMoney => 'Geld abheben';

  @override
  String get editGoal => 'Ziel bearbeiten';

  @override
  String get unarchive => 'Archivierung aufheben';

  @override
  String get activate => 'Aktivieren';

  @override
  String get archive => 'Archivieren';

  @override
  String get activateGoal => 'Ziel aktivieren';

  @override
  String get restartGoal => 'Ziel neu starten';

  @override
  String get archiveGoal => 'Archivieren';

  @override
  String get deleteGoal => 'Ziel löschen';

  @override
  String get progress => 'Fortschritt';

  @override
  String get remainingDays => 'Verbleibende Tage';

  @override
  String get monthlyTarget => 'Monatliches Ziel';

  @override
  String get noTransactionsHint =>
      'Sie können die Schaltflächen oben verwenden,\num Ihre erste Transaktion zu tätigen';

  @override
  String get savingsAdded => 'Ersparnisse hinzugefügt';

  @override
  String get moneyWithdrawn => 'Geld abgehoben';

  @override
  String get invalidGoal => 'Ungültiges Ziel';

  @override
  String get goalArchived => 'Ziel archiviert';

  @override
  String get goalActivated => 'Ziel aktiviert';

  @override
  String get goalReactivated => 'Ziel reaktiviert';

  @override
  String get markAsCompleted => 'Als abgeschlossen markieren';

  @override
  String get completedButton => 'Abgeschlossen';

  @override
  String goalCompletedImpact(String percent) {
    return '$percent% des Ziels abgeschlossen';
  }

  @override
  String get archiveGoalDialogTitle => 'Ziel archivieren?';

  @override
  String get archiveGoalDialogContent =>
      'Das Ziel wird archiviert. Sie können es später aus dem Archiv abrufen.';

  @override
  String get unarchiveGoalDialogTitle => 'Archivierung aufheben?';

  @override
  String get unarchiveGoalDialogContent =>
      'Das Ziel wird aus dem Archiv entfernt und zu Ihren aktiven Zielen hinzugefügt.';

  @override
  String get activateGoalDialogTitle => 'Ziel aktivieren?';

  @override
  String get activateGoalDialogContent =>
      'Das abgeschlossene Ziel wird reaktiviert und Sie können daran weiterarbeiten.';

  @override
  String get completeGoalDialogTitle => '🎉 Glückwunsch!';

  @override
  String get completeGoalDialogContent =>
      'Sie haben Ihr Ziel erreicht! Möchten Sie es als abgeschlossen markieren?';

  @override
  String get deleteGoalDialogTitle => 'Ziel löschen?';

  @override
  String get deleteGoalDialogContent =>
      'Diese Aktion kann nicht rückgängig gemacht werden. Das Ziel und der gesamte Transaktionsverlauf werden gelöscht.';

  @override
  String get goalCompletedSuccess =>
      '🎉 Großartig! Sie haben Ihr Ziel erreicht!';

  @override
  String get transactionFailed => 'Transaktion fehlgeschlagen';

  @override
  String get addSavingsTitle => 'Ersparnisse hinzufügen';

  @override
  String get withdrawTitle => 'Geld abheben';

  @override
  String get savingsDeposited => 'Geld eingezahlt!';

  @override
  String get savingsWithdrawn => 'Geld abgehoben!';

  @override
  String get depositNoteHint => 'z.B. Gehaltssparplan';

  @override
  String get withdrawNoteHint => 'z.B. Notfallbedarf';

  @override
  String savingsGoalImpactDeposit(String percentage) {
    return '$percentage% des Ziels abgeschlossen';
  }

  @override
  String savingsGoalImpactWithdraw(String percentage) {
    return 'Um $percentage% vom Ziel verringert';
  }

  @override
  String get editSavingsGoal => 'Ersparnisse bearbeiten';

  @override
  String get savingsName => 'Sparname';

  @override
  String get enterGoalNameHint => 'Zielname eingeben';

  @override
  String get pleaseEnterGoalNameError => 'Bitte geben Sie einen Zielnamen ein';

  @override
  String get selectDateHint => 'Datum auswählen';

  @override
  String get color => 'Farbe';

  @override
  String get milestone25Title => 'Guter Start!';

  @override
  String get milestone50Title => 'Auf halbem Weg!';

  @override
  String get milestone75Title => 'Fast geschafft!';

  @override
  String get milestone100Title => 'Ersparnisse abgeschlossen!';

  @override
  String get milestoneDefaultTitle => 'Glückwunsch!';

  @override
  String get milestone25Message =>
      'Sie haben 25% Ihres Ziels erreicht! Weiter so!';

  @override
  String get milestone50Message =>
      'Sie haben die Hälfte Ihres Ziels erreicht! Großer Fortschritt!';

  @override
  String get milestone75Message =>
      'Sie haben 75% Ihres Ziels erreicht! Endspurt!';

  @override
  String get milestone100Message =>
      'Sie haben Ihr Ziel erreicht! Großartige Leistung!';

  @override
  String get milestoneDefaultMessage =>
      'Sie sind einen Schritt näher an Ihrem Ziel!';

  @override
  String get optionalField => '(Optional)';

  @override
  String get daysUnit => 'Tage';

  @override
  String get monthsUnit => 'Mon.';

  @override
  String get yearsUnit => 'Jahr';

  @override
  String get timeRemaining => 'verbleibend';

  @override
  String get aiUsageLimit => 'KI-Nutzungslimit';

  @override
  String remainingCount(int count) {
    return '$count verbleibend';
  }

  @override
  String get messages => 'Nachrichten';

  @override
  String get watchAdBonusInfo =>
      'Sehen Sie sich eine Werbung an, um +5 zusätzliche Nutzungsrechte zu verdienen';

  @override
  String maxBonusRemaining(int count) {
    return 'Sie können pro Tag bis zu $count weiteren Bonus verdienen';
  }

  @override
  String get unlimitedAIWithPremium => 'Unbegrenzte KI-Nutzung mit Premium';

  @override
  String get adLoadingWait => 'Werbung wird geladen, bitte warten...';

  @override
  String get dailyUsage => 'Tägliche Nutzung';

  @override
  String get rights => 'Rechte';

  @override
  String get watchAdBonusShort => 'Werbung ansehen (+5)';

  @override
  String get adLoadError => 'Beim Laden der Werbung ist ein Fehler aufgetreten';

  @override
  String get noDescription => 'Keine Beschreibung';

  @override
  String get insufficientBalanceDetail =>
      'Dieses Konto hat nicht genug Guthaben';

  @override
  String get insufficientSavings => 'Unzureichende Ersparnisse';

  @override
  String insufficientSavingsDetail(Object amount) {
    return 'Verfügbar zum Abheben von diesem Ziel: $amount';
  }

  @override
  String get availableBalanceLabel => 'Verfügbares Guthaben';

  @override
  String get maxAmount => 'Max';

  @override
  String get amountMustBeGreaterThanZero => 'Betrag muss größer als 0 sein';

  @override
  String get amountExceedsBalance =>
      'Betrag überschreitet verfügbares Guthaben';

  @override
  String get amountExceedsSavings =>
      'Betrag überschreitet verfügbare Ersparnisse';

  @override
  String get amountExceedsGoalRemaining =>
      'Betrag überschreitet verbleibendes Ziel';

  @override
  String get goalCompletedTitle => 'Ziel erreicht! 🎉';

  @override
  String goalCompletedMessage(Object goalName) {
    return 'Glückwunsch! Sie haben $goalName erreicht!';
  }

  @override
  String goalCompletedStats(Object amount, Object days) {
    return '$amount in $days Tagen gespart';
  }

  @override
  String get keepActive => 'Aktiv bleiben';

  @override
  String get createNewGoal => 'Neues Ziel';

  @override
  String get goalArchivedSuccess => 'Ziel archiviert';

  @override
  String get budgetAndSubscriptions => 'Budget und Abonnements';

  @override
  String get budgets => 'Budgets';

  @override
  String get subscriptions => 'Abonnements';

  @override
  String get subscriptionDetails => 'Abonnementdetails';

  @override
  String get subscriptionSchedule => 'Zeitplan';

  @override
  String get paymentAccount => 'Zahlungskonto';

  @override
  String get subscriptionName => 'Abonnementname';

  @override
  String get frequency => 'Häufigkeit';

  @override
  String get endDate => 'Enddatum';

  @override
  String get endDateOptional => 'Enddatum (Optional)';

  @override
  String get reviewSubscription => 'Abonnement überprüfen';

  @override
  String get noSubscriptionsYet => 'Noch keine Abonnements';

  @override
  String get addFirstSubscriptionDescription =>
      'Fügen Sie Abonnements wie Netflix, Spotify hinzu, um sie automatisch zu verfolgen';

  @override
  String get addSubscription => 'Abonnement hinzufügen';

  @override
  String get requiredField => 'Dieses Feld ist erforderlich';

  @override
  String get deleteSubscription => 'Abonnement löschen';

  @override
  String deleteSubscriptionConfirm(String subscriptionName) {
    return 'Sind Sie sicher, dass Sie das Abonnement $subscriptionName löschen möchten?';
  }

  @override
  String get subscriptionDeleted => 'Abonnement erfolgreich gelöscht';

  @override
  String get activeSubscriptions => 'Aktive Abonnements';

  @override
  String inactiveSubscriptions(int count) {
    return 'Inaktive Abonnements';
  }

  @override
  String inactiveSubscriptionsWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Inaktive Abonnements ($count)',
      zero: 'Inaktive Abonnements',
    );
    return '$_temp0';
  }

  @override
  String get inactive => 'Inaktiv';

  @override
  String get monthlyTotal => 'Monatliche Gesamtsumme';

  @override
  String get yearlyPrefix => 'Jährlich:';

  @override
  String get subscriptionAdded => 'Abonnement erfolgreich hinzugefügt';

  @override
  String get subscriptionExample => 'z.B.: Netflix Premium';

  @override
  String get available => 'Verfügbar';

  @override
  String get tutorialTitle => 'Transaktion schnell hinzufügen';

  @override
  String get tutorialDescription =>
      'Tippen Sie auf die Schaltfläche in der unteren Ecke, um Ausgaben, Einkommen oder Überweisungen hinzuzufügen.';

  @override
  String get tutorialNext => 'Weiter';

  @override
  String get tutorialPrevious => 'Zurück';

  @override
  String get tutorialSkip => 'Überspringen';

  @override
  String get tutorialGotIt => 'Verstanden!';

  @override
  String get tutorialBalanceOverviewTitle => 'Gesamtvermögen';

  @override
  String get tutorialBalanceOverviewDescription =>
      'Hier können Sie den Gesamtsaldo aller Ihrer Konten, Karten und Investitionen sehen.';

  @override
  String get tutorialRecentTransactionsTitle => 'Letzte Transaktionen';

  @override
  String get tutorialRecentTransactionsDescription =>
      'Alle Ihre Transaktionen werden hier angezeigt. Lang drücken, um Transaktionen zu bearbeiten oder zu löschen.';

  @override
  String get tutorialAIChatTitle => 'KI-Assistent';

  @override
  String get tutorialAIChatDescription =>
      'Chatten Sie natürlich mit dem KI-Assistenten, um Transaktionen hinzuzufügen, finanzielle Zusammenfassungen zu erhalten, Analysen durchzuführen, Transaktionen in großen Mengen zu löschen und finanzielle Fragen zu stellen. Sie haben einen leistungsstarken finanziellen Assistenten!';

  @override
  String get tutorialCardsTitle => 'Kartenverwaltung';

  @override
  String get tutorialCardsDescription =>
      'Hier können Sie Ihre Karten anzeigen, neue Karten hinzufügen und Ihre Kontostandinformationen verfolgen.';

  @override
  String get tutorialBottomNavigationTitle => 'Navigations-Tabs';

  @override
  String get tutorialBottomNavigationDescription =>
      'Verwenden Sie die Tabs unten, um zwischen Startseite, Transaktionen, Karten, Analysen, Kalender und Aktien-Seiten zu navigieren.';

  @override
  String get tutorialBudgetTitle => 'Budgetverwaltung';

  @override
  String get tutorialBudgetDescription =>
      'Verfolgen Sie Ihre monatlichen Ausgaben, legen Sie Budgets fest und überwachen Sie Ihre Ausgabenlimits.';

  @override
  String get tutorialProfileTitle => 'Profil';

  @override
  String get tutorialProfileDescription =>
      'Tippen Sie auf Ihr Profilfoto, um auf Einstellungen, Premium-Funktionen und Ihre persönlichen Informationen zuzugreifen.';

  @override
  String get incomeExpenseFlow => 'Income & Expense Flow';

  @override
  String get spendingIntensity => 'Spending Intensity';

  @override
  String get budgetSpendingDistribution => 'Budget & Spending Distribution';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get spending => 'Spending';

  @override
  String get compare => 'Compare';

  @override
  String get filter => 'Filter';

  @override
  String get apply => 'Apply';

  @override
  String get incomeExpenseComparison => 'Income & Expense Comparison';

  @override
  String get referralCodeTitle => 'Enter Referral Code';

  @override
  String get referralCodeDescription =>
      'Enter a referral code to earn bonus points! You and your friend will both receive 500 points.';

  @override
  String get referralCode => 'Referral Code';

  @override
  String get referralCodeRequired => 'Referral code is required';

  @override
  String get referralCodeInvalidLength => 'Referral code must be 8 characters';

  @override
  String get referralCodeSubmit => 'Apply Code';

  @override
  String get referralCodeSkip => 'Skip for now';

  @override
  String get referralCodeSuccess => 'Referral code applied!';

  @override
  String get referralCodeSuccessMessage =>
      'You and your friend have received bonus points!';

  @override
  String get referralCodeInvalid => 'Invalid referral code';

  @override
  String get referralCodeError => 'Error processing referral code';
}
