// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Qanta';

  @override
  String get welcome => 'Hoş Geldiniz';

  @override
  String get getStarted => 'Başlayın';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get settings => 'Ayarlar';

  @override
  String get darkMode => 'Karanlık Mod';

  @override
  String get lightMode => 'Açık Mod';

  @override
  String get theme => 'Tema';

  @override
  String get language => 'Dil';

  @override
  String get english => 'İngilizce';

  @override
  String get turkish => 'Türkçe';

  @override
  String get login => 'Giriş Yap';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get fullName => 'Adınız';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get forgotPassword => 'Şifremi unuttum, ne yapmalıyım?';

  @override
  String get budget => 'Bütçe';

  @override
  String get expenses => 'Giderler';

  @override
  String get income => 'Gelir';

  @override
  String get investments => 'Yatırımlar';

  @override
  String get analytics => 'İstatistikler';

  @override
  String get balance => 'Bakiye';

  @override
  String get onboardingDescription =>
      'Qanta ile paranızı daha iyi yönetin. Harcamalarınızı takip edin, bütçe yapın ve akıllı önerilerle birikimlerinizi artırın.';

  @override
  String get welcomeSubtitle => 'Paranızı bugün daha iyi yönetmeye başlayın!';

  @override
  String get budgetSubtitle => 'Harcamalarınızı takip edin';

  @override
  String get investmentsSubtitle => 'Birikimlerinizi artırın';

  @override
  String get analyticsSubtitle => 'Verilerinizi analiz edin';

  @override
  String get settingsSubtitle => 'Uygulamayı kendinize göre ayarlayın';

  @override
  String get appSlogan => 'Paranızı akıllıca yönetin';

  @override
  String greetingHello(String name) {
    return 'Merhaba, $name!';
  }

  @override
  String get homeMainTitle => 'Finansal hedeflerinize ulaşmaya hazır mısınız?';

  @override
  String get homeSubtitle =>
      'Paranızı akıllıca yönetin ve geleceğinizi planlayın';

  @override
  String get defaultUserName => 'Qanta Kullanıcısı';

  @override
  String get nameRequired => 'İsim gerekli';

  @override
  String get emailRequired => 'E-posta gerekli';

  @override
  String get emailInvalid => 'Geçerli bir e-posta girin';

  @override
  String get passwordRequired => 'Şifre gerekli';

  @override
  String get passwordTooShort => 'Şifre çok kısa';

  @override
  String get confirmPasswordRequired => 'Şifre onayı gerekli';

  @override
  String get passwordsDoNotMatch => 'Yeni şifreler eşleşmiyor';

  @override
  String get confirmPassword => 'Şifreyi Onayla';

  @override
  String get loginSubtitle => 'Hesabınıza giriş yapın';

  @override
  String get createAccount => 'Hesap Oluştur';

  @override
  String get registerSubtitle =>
      'Qanta\'ya katılın ve paranızı yönetmeye başlayın';

  @override
  String get pageNotFound => 'Sayfa bulunamadı';

  @override
  String get pageNotFoundDescription => 'Aradığınız sayfa mevcut değil.';

  @override
  String get goHome => 'Ana Sayfaya Git';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı?';

  @override
  String get dontHaveAccount => 'Hesabınız yok mu?';

  @override
  String get loginError => 'Giriş hatası';

  @override
  String get registerError => 'Kayıt hatası';

  @override
  String get emailNotConfirmed =>
      'E-posta adresinizi doğrulamanız gerekiyor. Lütfen e-postanızı kontrol edin.';

  @override
  String get invalidCredentials =>
      'E-posta veya şifre hatalı. Lütfen tekrar deneyin.';

  @override
  String get tooManyRequests =>
      'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';

  @override
  String get invalidEmailAddress =>
      'Geçersiz e-posta adresi. Lütfen doğru bir e-posta girin.';

  @override
  String get passwordTooShortError =>
      'Şifre çok kısa. En az 6 karakter olmalı.';

  @override
  String get userAlreadyRegistered =>
      'Bu e-posta adresi zaten kayıtlı. Giriş yapmayı deneyin.';

  @override
  String get signupDisabled =>
      'Kayıt işlemi şu anda devre dışı. Lütfen daha sonra deneyin.';

  @override
  String registrationSuccessful(String name) {
    return 'Kayıt başarılı! Hoş geldin $name!';
  }

  @override
  String get totalBalance => 'Toplam Bakiye';

  @override
  String get totalPortfolio => 'Toplam Portföy';

  @override
  String get allAccounts => 'Tüm hesaplarınız';

  @override
  String get availableBalance => 'Kullanılabilir Bakiye';

  @override
  String get thisMonthIncome => 'Bu Ay Gelir';

  @override
  String get thisMonthExpense => 'Bu Ay Gider';

  @override
  String get myCards => 'Kartlarım';

  @override
  String get manageYourCards => 'Kartlarınızı yönetin';

  @override
  String get seeAll => 'Tümünü Gör';

  @override
  String get recentTransactions => 'Son İşlemler';

  @override
  String get thisMonthSummary => 'Bu Ay Özeti';

  @override
  String get savings => 'BİRİKİM';

  @override
  String get budgetUsed => 'Kullanıldı';

  @override
  String get remaining => 'kaldı';

  @override
  String get installment => 'Taksit';

  @override
  String get categoryHint => 'kahve, market, benzin...';

  @override
  String get noBudgetDefined => 'Henüz bütçe tanımlanmamış';

  @override
  String get createBudgetDescription =>
      'Harcama limitlerinizi takip etmek için bütçe oluşturun';

  @override
  String get createBudget => 'Bütçe Oluştur';

  @override
  String get expenseLimitTracking => 'Harcama Limit Takibi';

  @override
  String get manage => 'Yönet';

  @override
  String get thisMonthGrowth => 'bu ay';

  @override
  String get cardHolder => 'KART SAHİBİ';

  @override
  String get expiryDate => 'GEÇERLİLİK';

  @override
  String get qantaDebit => 'Qanta Debit';

  @override
  String get checkingAccount => 'Vadesiz Hesap';

  @override
  String get qantaCredit => 'Qanta Credit';

  @override
  String get qantaSavings => 'Qanta Savings';

  @override
  String get goodMorning => 'Günaydın! ☀️';

  @override
  String get goodAfternoon => 'İyi günler! 🌤️';

  @override
  String get goodEvening => 'İyi akşamlar!';

  @override
  String get goodNight => 'İyi geceler! 🌙';

  @override
  String get currency => 'Para Birimi';

  @override
  String get currencyTRY => 'Türk Lirası (₺)';

  @override
  String get currencyUSD => 'Amerikan Doları (\$)';

  @override
  String get currencyEUR => 'Euro (€)';

  @override
  String get currencyGBP => 'İngiliz Sterlini (£)';

  @override
  String get selectCurrency => 'Para Birimi Seçin';

  @override
  String get selectCurrencyDescription =>
      'Hangi para birimini kullanmak istiyorsunuz?';

  @override
  String get debit => 'BANKA';

  @override
  String get credit => 'KREDİ';

  @override
  String get profile => 'Profil';

  @override
  String get personalInfo => 'Kişisel Bilgiler';

  @override
  String get preferences => 'Tercihler';

  @override
  String get security => 'Güvenlik';

  @override
  String get support => 'Destek';

  @override
  String get about => 'Hakkında';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get privacy => 'Gizlilik';

  @override
  String get termsOfService => 'Kullanım Şartları';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get version => 'Versiyon';

  @override
  String get contactSupport => 'Destek İletişim';

  @override
  String get changePassword => 'Şifre Değiştir';

  @override
  String get biometricAuth => 'Biyometrik Kimlik Doğrulama';

  @override
  String get transactions => 'İşlemler';

  @override
  String get goals => 'Hedefler';

  @override
  String get upcomingPayments => 'Yaklaşan Ödemeler';

  @override
  String get comingSoon => 'Yakında geliyor...';

  @override
  String get cardInfo => 'Kart Bilgileri';

  @override
  String get cardType => 'Kart Türü';

  @override
  String get cardNumber => 'Kart Numarası';

  @override
  String get expiryDateShort => 'Son Kullanma';

  @override
  String get status => 'Durum';

  @override
  String get active => 'Aktif';

  @override
  String get balanceInfo => 'Bakiye Bilgileri';

  @override
  String get creditLimit => 'Kredi Limiti';

  @override
  String get usedLimit => 'Kullanılan Limit';

  @override
  String get quickActions => 'Hızlı İşlemler';

  @override
  String get sendMoney => 'Para Gönder';

  @override
  String get loadMoney => 'Para Yükle';

  @override
  String get freezeCard => 'Kartı Dondur';

  @override
  String get cardSettings => 'Kart Ayarları';

  @override
  String get addNewCard => 'Yeni Kart Ekle';

  @override
  String get addNewCardFeature => 'Yeni kart ekleme özelliği yakında geliyor!';

  @override
  String get cardManagement => 'Kart Yönetimi';

  @override
  String get securitySettings => 'Güvenlik Ayarları';

  @override
  String get securitySettingsDesc => 'PIN, limit ve güvenlik ayarları';

  @override
  String get notificationSettings => 'Bildirim Ayarları';

  @override
  String get notificationSettingsDesc => 'İşlem bildirimleri ve uyarılar';

  @override
  String get transactionHistory => 'İşlem Geçmişi';

  @override
  String get transactionHistoryDesc => 'Tüm kartların işlem geçmişi';

  @override
  String get qantaWallet => 'Qanta Cüzdan';

  @override
  String get qantaDebitCard => 'Qanta Debit';

  @override
  String get bankTransfer => 'Banka Transferi';

  @override
  String get iban => 'IBAN';

  @override
  String get recommended => 'ÖNERİLEN';

  @override
  String get urgent => 'ACİL';

  @override
  String get amount => 'Tutar';

  @override
  String get dueDate => 'Son Ödeme';

  @override
  String get setReminder => 'Hatırlatma Kur';

  @override
  String get paymentHistory => 'Ödeme Geçmişi';

  @override
  String get reminderSetup => 'Hatırlatma kurulumu açılıyor...';

  @override
  String get paymentHistoryOpening => 'Ödeme geçmişi açılıyor...';

  @override
  String get sendMoneyOpening => 'Para Gönder açılıyor...';

  @override
  String get loadMoneyOpening => 'Para Yükle açılıyor...';

  @override
  String get freezeCardOpening => 'Kart Dondurma açılıyor...';

  @override
  String get cardSettingsOpening => 'Kart Ayarları açılıyor...';

  @override
  String get securitySettingsOpening => 'Güvenlik Ayarları açılıyor...';

  @override
  String get notificationSettingsOpening => 'Bildirim Ayarları açılıyor...';

  @override
  String get transactionHistoryOpening => 'İşlem geçmişi açılıyor...';

  @override
  String paymentProcessing(String method) {
    return '$method ile ödeme işlemi başlatılıyor...';
  }

  @override
  String get allAccountsTotal => 'Tüm hesaplarınızın toplamı';

  @override
  String get accountBreakdown => 'Hesap Dağılımı';

  @override
  String get creditCard => 'Kredi Kartı';

  @override
  String get savingsAccount => 'Vadeli Hesap';

  @override
  String get cashAccount => 'Nakit Hesap';

  @override
  String get monthlySummary => 'Bu Ay Özeti';

  @override
  String get cashBalance => 'Nakit Bakiye';

  @override
  String get addCashBalance => 'Nakit Bakiye Ekle';

  @override
  String get enterCashAmount => 'Nakit Miktarını Girin';

  @override
  String get cashAmount => 'Nakit Miktarı';

  @override
  String get addCash => 'Nakit Ekle';

  @override
  String get cancel => 'İptal';

  @override
  String cashAdded(String amount) {
    return 'Nakit bakiye eklendi: $amount';
  }

  @override
  String get invalidAmount => 'Geçersiz miktar';

  @override
  String get enterValidAmount => 'Geçerli bir miktar girin';

  @override
  String get cash => 'Nakit';

  @override
  String get digitalWallet => 'Dijital Cüzdan';

  @override
  String get all => 'Tümü';

  @override
  String get cashManagement => 'Nakit Yönetimi';

  @override
  String get addCashHistory => 'Nakit Ekleme Geçmişi';

  @override
  String get addCashHistoryDesc => 'Nakit ekleme işlemlerinizi görüntüleyin';

  @override
  String get cashLimits => 'Nakit Limitleri';

  @override
  String get cashLimitsDesc => 'Günlük ve aylık nakit limitlerini ayarlayın';

  @override
  String get debitCardManagement => 'Banka Kartı Yönetimi';

  @override
  String get cardLimits => 'Kart Limitleri';

  @override
  String get cardLimitsDesc => 'Günlük harcama ve çekim limitlerini ayarlayın';

  @override
  String get atmLocations => 'ATM Konumları';

  @override
  String get atmLocationsDesc => 'Yakınımdaki ATM\'leri bul';

  @override
  String get creditCardManagement => 'Kredi Kartı Yönetimi';

  @override
  String get creditLimitDesc =>
      'Kredi limitinizi görüntüleyin ve artırım talep edin';

  @override
  String get installmentOptions => 'Taksit Seçenekleri';

  @override
  String get installmentOptionsDesc => 'Alışverişlerinizi taksitlendirin';

  @override
  String get savingsManagement => 'Tasarruf Yönetimi';

  @override
  String get savingsGoals => 'Tasarruf Hedefleri';

  @override
  String get savingsGoalsDesc =>
      'Tasarruf hedeflerinizi belirleyin ve takip edin';

  @override
  String get autoSave => 'Otomatik Tasarruf';

  @override
  String get autoSaveDesc => 'Otomatik tasarruf kuralları oluşturun';

  @override
  String get opening => 'açılıyor...';

  @override
  String get addTransaction => 'İşlem Ekle';

  @override
  String get close => 'Kapat';

  @override
  String get selectTransactionType => 'Yapmak istediğiniz işlem türünü seçin';

  @override
  String get selectTransactionTypeDesc =>
      'Hangi türde işlem yapmak istiyorsunuz?';

  @override
  String expenseSaved(String amount) {
    return 'Gider kaydedildi: $amount';
  }

  @override
  String errorOccurred(String error) {
    return 'Hata: $error';
  }

  @override
  String get enterAmount => 'Tutar Girin';

  @override
  String get selectCategory => 'Kategori Seçin';

  @override
  String get paymentMethod => 'Ödeme Yöntemi';

  @override
  String get details => 'Detaylar';

  @override
  String get amountRequired => 'Tutar gerekli';

  @override
  String get enterValidAmountMessage => 'Geçerli bir tutar girin';

  @override
  String get selectCategoryMessage => 'Kategori seçin';

  @override
  String get selectPaymentMethodMessage => 'Ödeme yöntemi seçin';

  @override
  String get saveExpense => 'Gideri Kaydet';

  @override
  String get continueButton => 'Devam Et';

  @override
  String get lastCheckAndDetails => 'Son kontrol ve detaylar';

  @override
  String get summary => 'Özet';

  @override
  String get category => 'Kategori';

  @override
  String get payment => 'Ödeme';

  @override
  String get date => 'Tarih';

  @override
  String get description => 'Açıklama';

  @override
  String get card => 'Kart';

  @override
  String get cashPayment => 'Peşin';

  @override
  String installments(int count) {
    return '$count Taksit';
  }

  @override
  String get foodAndDrink => 'Yemek & İçecek';

  @override
  String get transport => 'Ulaşım';

  @override
  String get shopping => 'Alışveriş';

  @override
  String get entertainment => 'Eğlence';

  @override
  String get bills => 'Faturalar';

  @override
  String get health => 'Sağlık';

  @override
  String get education => 'Eğitim';

  @override
  String get other => 'Diğer';

  @override
  String get incomeType => 'Gelir';

  @override
  String get expenseType => 'Gider';

  @override
  String get transferType => 'Transfer';

  @override
  String get investmentType => 'Yatırım Türü';

  @override
  String get incomeDescription => 'Maaş, bonus, satış geliri';

  @override
  String get expenseDescription => 'Alışveriş, fatura, harcama';

  @override
  String get transferDescription => 'Hesaplar arası transfer';

  @override
  String get investmentDescription => 'Hisse, kripto, altın';

  @override
  String get recurringType => 'Sabit Ödemeler';

  @override
  String get recurringDescription => 'Netflix, fatura, abonelik';

  @override
  String get selectFrequency => 'Sıklık Seçin';

  @override
  String get saveRecurring => 'Sabit Ödemeyi Kaydet';

  @override
  String get weekly => 'Haftalık';

  @override
  String get monthly => 'Aylık';

  @override
  String get quarterly => 'Üç Aylık';

  @override
  String get yearly => 'Yıllık';

  @override
  String get weeklyDescription => 'Her hafta tekrarlanır';

  @override
  String get monthlyDescription => 'Her ay tekrarlanır';

  @override
  String get quarterlyDescription => 'Her 3 ayda bir tekrarlanır';

  @override
  String get yearlyDescription => 'Her yıl tekrarlanır';

  @override
  String get subscription => 'Abonelik';

  @override
  String get utilities => 'Faturalar';

  @override
  String get insurance => 'Sigorta';

  @override
  String get rent => 'Kira';

  @override
  String get loan => 'Kredi';

  @override
  String get subscriptionDescription => 'Netflix, Spotify, YouTube';

  @override
  String get utilitiesDescription => 'Elektrik, su, doğalgaz';

  @override
  String get insuranceDescription => 'Sağlık, kasko, dask';

  @override
  String get rentDescription => 'Ev kirası, ofis kirası';

  @override
  String get loanDescription => 'Kredi kartı, taksit';

  @override
  String get otherDescription => 'Diğer sabit ödemeler';

  @override
  String get next => 'İleri';

  @override
  String get save => 'Kaydet';

  @override
  String get incomeFormOpening => 'Gelir ekleme formu açılacak';

  @override
  String get transferFormOpening => 'Transfer formu açılacak';

  @override
  String get investmentFormOpening => 'Yatırım formu açılacak';

  @override
  String get howMuchSpent => 'Ne kadar harcadınız?';

  @override
  String get whichCategorySpent => 'Hangi kategoride harcama yaptınız?';

  @override
  String get howDidYouPay => 'Nasıl ödeme yaptınız?';

  @override
  String get saveIncome => 'Geliri Kaydet';

  @override
  String get food => 'Yemek';

  @override
  String get foodDescription => 'Restoran, market, kahve';

  @override
  String get transportDescription => 'Taksi, otobüs, yakıt';

  @override
  String get shoppingDescription => 'Giyim, elektronik, ev';

  @override
  String get billsDescription => 'Elektrik, su, internet';

  @override
  String get entertainmentDescription => 'Sinema, konser, oyun';

  @override
  String get healthDescription => 'Doktor, eczane, spor';

  @override
  String get educationDescription => 'Kurs, kitap, okul';

  @override
  String get travel => 'Seyahat';

  @override
  String get travelDescription => 'Tatil, uçak, otel';

  @override
  String get howMuchEarned => 'Ne kadar gelir elde ettiniz?';

  @override
  String get whichCategoryEarned => 'Hangi kategoride gelir elde ettiniz?';

  @override
  String get howDidYouReceive => 'Nasıl aldınız?';

  @override
  String incomeSaved(String amount) {
    return 'Gelir kaydedildi: $amount';
  }

  @override
  String get salary => 'Maaş';

  @override
  String get salaryDescription => 'Aylık maaş, ücret';

  @override
  String get bonus => 'Bonus';

  @override
  String get bonusDescription => 'Prim, ikramiye, bonus';

  @override
  String get freelance => 'Freelance';

  @override
  String get freelanceDescription => 'Serbest çalışma, proje';

  @override
  String get business => 'İş';

  @override
  String get businessDescription => 'İş geliri, ticaret';

  @override
  String get rental => 'Kira';

  @override
  String get rentalDescription => 'Ev kirası, araç kirası';

  @override
  String get gift => 'Hediye';

  @override
  String get giftDescription => 'Hediye, bağış, harçlık';

  @override
  String get saveTransfer => 'Transferi Kaydet';

  @override
  String get howMuchInvest => 'Ne Kadar Yatırım Yapacaksınız?';

  @override
  String get whichInvestmentType => 'Hangi Yatırım Türü?';

  @override
  String get stocks => 'Hisse Senedi';

  @override
  String get stocksDescription => 'Borsa, hisse, pay';

  @override
  String get crypto => 'Kripto Para';

  @override
  String get cryptoDescription => 'Bitcoin, Ethereum, altcoin';

  @override
  String get gold => 'Altın';

  @override
  String get goldDescription => 'Gram altın, çeyrek altın';

  @override
  String get bonds => 'Tahvil';

  @override
  String get bondsDescription => 'Devlet tahvili, özel tahvil';

  @override
  String get funds => 'Fon';

  @override
  String get fundsDescription => 'Yatırım fonu, emeklilik fonu';

  @override
  String get forex => 'Döviz';

  @override
  String get forexDescription => 'USD, EUR, GBP';

  @override
  String get realEstate => 'Gayrimenkul';

  @override
  String get realEstateDescription => 'Ev, arsa, dükkan';

  @override
  String get saveInvestment => 'Yatırımı Kaydet';

  @override
  String investmentSaved(String amount) {
    return 'Yatırım kaydedildi: $amount';
  }

  @override
  String get selectInvestmentTypeMessage => 'Yatırım türü seçin';

  @override
  String get quantityRequired => 'Miktar gerekli';

  @override
  String get enterValidQuantity => 'Geçerli bir miktar girin';

  @override
  String get rateRequired => 'Kur gerekli';

  @override
  String get enterValidRate => 'Geçerli bir kur girin';

  @override
  String get quantity => 'Miktar';

  @override
  String get rate => 'Kur';

  @override
  String get totalAmount => 'Toplam Tutar';

  @override
  String get onboardingFeaturesTitle => 'Qanta ile Neler Yapabilirsiniz?';

  @override
  String get expenseTrackingTitle => 'Harcama Takibi';

  @override
  String get expenseTrackingDesc => 'Günlük harcamalarınızı kolayca takip edin';

  @override
  String get smartSavingsTitle => 'Akıllı Birikim';

  @override
  String get smartSavingsDesc => 'Hedeflerinize ulaşmak için birikim yapın';

  @override
  String get financialAnalysisTitle => 'Finansal Analiz';

  @override
  String get financialAnalysisDesc => 'Harcama alışkanlıklarınızı analiz edin';

  @override
  String get languageSelectionTitle => 'Dil Seçimi';

  @override
  String get languageSelectionDesc =>
      'Uygulamayı hangi dilde kullanmak istiyorsunuz?';

  @override
  String get themeSelectionTitle => 'Tema Seçimi';

  @override
  String get themeSelectionDesc => 'Hangi temayı tercih ediyorsunuz?';

  @override
  String get lightThemeTitle => 'Açık Tema';

  @override
  String get lightThemeDesc => 'Klasik beyaz tema';

  @override
  String get darkThemeTitle => 'Koyu Tema';

  @override
  String get darkThemeDesc => 'Gözlerinizi yormuyor';

  @override
  String get exitOnboarding => 'Çıkış';

  @override
  String get exitOnboardingMessage =>
      'Onboarding\'i tamamlamadan çıkmak istediğinizden emin misiniz?';

  @override
  String get exitCancel => 'İptal';

  @override
  String get back => 'Geri';

  @override
  String get updateCashBalance => 'Nakit Bakiyeyi Güncelle';

  @override
  String get updateCashBalanceDesc =>
      'Cebinizdeki mevcut nakit miktarını girin';

  @override
  String get updateCashBalanceTitle => 'Nakit Bakiyeyi Güncelle';

  @override
  String get updateCashBalanceMessage =>
      'Cebinizdeki mevcut nakit miktarını girin:';

  @override
  String get newBalance => 'Yeni Bakiye';

  @override
  String get update => 'Güncelle';

  @override
  String cashBalanceUpdated(String amount) {
    return 'Nakit bakiye $amount olarak güncellendi';
  }

  @override
  String get cashAccountLoadError => 'Nakit hesabı yüklenirken hata oluştu';

  @override
  String unknownError(String error) {
    return 'Bir hata oluştu: $error';
  }

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get noCashTransactions => 'Henüz nakit işlem yok';

  @override
  String get noCashTransactionsDesc =>
      'İlk nakit işleminizi yaptığınızda burada görünecek';

  @override
  String get balanceUpdated => 'Nakit Eklendi';

  @override
  String get walletBalanceUpdated => 'Nakit güncellendi';

  @override
  String get groceryShopping => 'Market Alışverişi';

  @override
  String get cashPaymentMade => 'Nakit ödeme';

  @override
  String get taxiFare => 'Taksi Ücreti';

  @override
  String get transactionDetails => 'İşlem Detayları';

  @override
  String get cardDetails => 'Kart Bilgileri';

  @override
  String get time => 'Saat';

  @override
  String get transactionType => 'İşlem Türü';

  @override
  String get merchant => 'İşyeri';

  @override
  String get installmentInfo => 'Taksit Bilgisi';

  @override
  String get availableLimit => 'Kullanılabilir Limit';

  @override
  String get howMuchTransfer => 'Ne kadar transfer yapacaksınız?';

  @override
  String get fromWhichAccount => 'Hangi hesaptan?';

  @override
  String get toWhichAccount => 'Hangi hesaba?';

  @override
  String get investmentIncome => 'Yatırım Geliri';

  @override
  String get investmentIncomeDescription => 'Hisse, fon, kira geliri';

  @override
  String get silver => 'Gümüş';

  @override
  String get usd => 'Dolar';

  @override
  String get eur => 'Euro';

  @override
  String get goldUnit => 'gram';

  @override
  String get silverUnit => 'gram';

  @override
  String get usdUnit => 'adet';

  @override
  String get eurUnit => 'adet';

  @override
  String get silverDescription => 'Gümüş yatırımı';

  @override
  String get usdDescription => 'Amerikan Doları';

  @override
  String get eurDescription => 'Euro para birimi';

  @override
  String get selectInvestmentType => 'Yatırım Türü Seçin';

  @override
  String get investment => 'Yatırım';

  @override
  String get otherIncome => 'Diğer Gelir';

  @override
  String get recurringPayment => 'Sabit Ödeme';

  @override
  String get saveRecurringPayment => 'Sabit Ödemeyi Kaydet';

  @override
  String get noTransactionsYet => 'Henüz işlem yok';

  @override
  String get noTransactionsDescription =>
      'İlk işleminizi eklemek için + butonuna dokunun';

  @override
  String get noSearchResults => 'Arama sonucu bulunamadı';

  @override
  String noSearchResultsDescription(String query) {
    return '\"$query\" için sonuç bulunamadı';
  }

  @override
  String get transactionsLoadError => 'İşlemler yüklenemedi';

  @override
  String get connectionError => 'Bağlantı sorunu yaşanıyor';

  @override
  String get tryAgain => 'Tekrar Dene';

  @override
  String get noAccountsAvailable => 'Kullanılabilir hesap yok';

  @override
  String get debitCard => 'Banka Kartı';

  @override
  String get statisticsTitle => 'İstatistikler';

  @override
  String get monthlyOverview => 'Aylık Genel Bakış';

  @override
  String get totalIncome => 'Toplam Gelir';

  @override
  String get totalExpenses => 'Toplam Gider';

  @override
  String get netBalance => 'Net Bakiye';

  @override
  String get categoryBreakdown => 'Kategori Dağılımı';

  @override
  String get spendingTrends => 'Harcama Trendleri';

  @override
  String get thisMonth => 'Bu Ay';

  @override
  String get lastMonth => 'Geçen Ay';

  @override
  String get last3Months => 'Son 3 Ay';

  @override
  String get last6Months => 'Son 6 Ay';

  @override
  String get yearToDate => 'Yıl Başından İtibaren';

  @override
  String get noDataAvailable => 'Veri Mevcut Değil';

  @override
  String get noTransactionsFound => 'Henüz işlem bulunamadı';

  @override
  String get averageSpending => 'Ortalama Harcama';

  @override
  String get highestSpending => 'En Yüksek Harcama';

  @override
  String get lowestSpending => 'En Düşük Harcama';

  @override
  String get savingsRate => 'Tasarruf Oranı';

  @override
  String get smartInsights => 'Akıllı İçgörüler';

  @override
  String get visualAnalytics => 'Görsel Analiz';

  @override
  String get categoryAnalysis => 'Kategori Analizi';

  @override
  String get financialHealthScore => 'Finansal Sağlık Skoru';

  @override
  String get spendingTrend => 'Harcama Trendi';

  @override
  String get viewAll => 'Tümünü Gör';

  @override
  String get noDataYet => 'Henüz analiz edilecek veri yok';

  @override
  String get addFirstTransaction => 'İlk işleminizi ekleyerek başlayın';

  @override
  String get analyzingData => 'Finansal verileriniz analiz ediliyor...';

  @override
  String get pleaseWait => 'Bu işlem birkaç saniye sürebilir';

  @override
  String get dataLoadError => 'Veriler yüklenirken bir hata oluştu';

  @override
  String get excellent => 'Mükemmel';

  @override
  String get good => 'İyi';

  @override
  String get average => 'Orta';

  @override
  String get needsImprovement => 'Geliştirilmeli';

  @override
  String get dailyAverage => 'Günlük Ortalama';

  @override
  String get moreCategories => 'daha fazla kategori';

  @override
  String get netWorth => 'Net Değer';

  @override
  String get positive => 'Pozitif';

  @override
  String get negative => 'Negatif';

  @override
  String get totalAssets => 'Toplam Varlık';

  @override
  String get totalDebts => 'Toplam Borç';

  @override
  String get availableCredit => 'Kullanılabilir Limit';

  @override
  String get netAmount => 'Net';

  @override
  String get transactionCount => 'İşlem';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galeri';

  @override
  String get deletePhoto => 'Fotoğrafı Sil';

  @override
  String photoUploadError(String error) {
    return 'Fotoğraf yüklenirken hata oluştu: $error';
  }

  @override
  String photoDeleteError(String error) {
    return 'Fotoğraf silinirken hata oluştu: $error';
  }

  @override
  String get fileNotFound => 'Dosya bulunamadı';

  @override
  String get fileTooLarge => 'Dosya boyutu çok büyük (max 5MB)';

  @override
  String get userSessionNotFound => 'Kullanıcı oturumu bulunamadı';

  @override
  String get photoDeletedSuccessfully => 'Fotoğraf başarıyla silindi';

  @override
  String get photoUploadedSuccessfully => 'Fotoğraf başarıyla yüklendi';

  @override
  String get selectImageSource => 'Fotoğraf Kaynağı Seçin';

  @override
  String get selectImageSourceDescription =>
      'Fotoğrafınızı nereden seçmek istiyorsunuz?';

  @override
  String get uploadingPhoto => 'Fotoğraf yükleniyor...';

  @override
  String get deletingPhoto => 'Fotoğraf siliniyor...';

  @override
  String get profilePhoto => 'Profil Fotoğrafı';

  @override
  String get changeProfilePhoto => 'Profil Fotoğrafını Değiştir';

  @override
  String get removeProfilePhoto => 'Profil Fotoğrafını Kaldır';

  @override
  String get profilePhotoUpdated => 'Profil fotoğrafı güncellendi';

  @override
  String get profilePhotoRemoved => 'Profil fotoğrafı kaldırıldı';

  @override
  String get deleteTransaction => 'İşlemi Sil';

  @override
  String deleteTransactionConfirm(String description) {
    return '$description işlemini silmek istediğinizden emin misiniz?';
  }

  @override
  String get delete => 'Sil';

  @override
  String get transactionDeleted => 'İşlem silindi';

  @override
  String transactionDeleteError(String error) {
    return 'İşlem silinirken hata oluştu: $error';
  }

  @override
  String get deleteInstallmentTransaction => 'Taksitli İşlemi Sil';

  @override
  String deleteInstallmentTransactionConfirm(String description) {
    return '$description taksitli işlemini tamamen silmek istediğinizden emin misiniz? Bu işlem tüm taksitleri silecektir.';
  }

  @override
  String get installmentTransactionDeleted => 'Taksitli işlem silindi';

  @override
  String installmentTransactionDeleteError(String error) {
    return 'Taksitli işlem silinirken hata oluştu: $error';
  }

  @override
  String get deleteAll => 'Tümünü Sil';

  @override
  String get deleteLimit => 'Limit Sil';

  @override
  String deleteLimitConfirm(String categoryName) {
    return '$categoryName kategorisi için belirlenen limiti silmek istediğinizden emin misiniz?';
  }

  @override
  String get limitDeleted => 'Limit silindi';

  @override
  String get deleteLimitTooltip => 'Limiti Sil';

  @override
  String get error => 'Hata';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get loadingPastStatements => 'Geçmiş ekstreler yükleniyor...';

  @override
  String get loadingFutureStatements => 'Gelecek ekstreler yükleniyor...';

  @override
  String get loadingCards => 'Kartlar yüklenirken hata oluştu';

  @override
  String get loadingAccounts => 'Hesapları yükle';

  @override
  String get loadingStatementInfo => 'Ekstre bilgileri yüklenirken hata oluştu';

  @override
  String get paymentError => 'Ödeme işlemi sırasında hata oluştu';

  @override
  String get statementMarkError => 'Ekstre işaretlenirken hata oluştu';

  @override
  String get deleteCard => 'Kartı Sil';

  @override
  String deleteCardConfirm(String cardName) {
    return '$cardName kartını silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.';
  }

  @override
  String get cardDeleted => 'Kart başarıyla silindi';

  @override
  String get cardDeleteError => 'Kart silinirken hata oluştu';

  @override
  String transactionAddError(String error) {
    return 'İşlem eklenirken hata: $error';
  }

  @override
  String updateError(String error) {
    return 'Güncelleme sırasında hata oluştu: $error';
  }

  @override
  String get deleteFailed => 'Silme işlemi başarısız';

  @override
  String get installmentTransactionDeleting => 'Taksitli işlem siliniyor...';

  @override
  String get installmentTransactionDeletedWithRefund =>
      'Taksitli işlem silindi, toplam tutar iade edildi';

  @override
  String get cancelAction => 'İptal Et';

  @override
  String get quickNotes => 'Hızlı Notlar';

  @override
  String get quickNotesSubtitle => 'Anında not alma için kalıcı bildirim';

  @override
  String get quickNotesNotificationEnabled => 'Hızlı notlar bildirimi açıldı';

  @override
  String get quickNotesNotificationDisabled =>
      'Hızlı notlar bildirimi kapatıldı';

  @override
  String get notificationPermissionRequired =>
      'Bildirim izni gerekli! Lütfen ayarlardan açın.';

  @override
  String get frequentlyAskedQuestions => 'Sık Sorulan Sorular';

  @override
  String get account => 'Hesap';

  @override
  String get now => 'Şimdi';

  @override
  String get yesterday => 'Dün';

  @override
  String get expense => 'Gider';

  @override
  String get transfer => 'Transfer';

  @override
  String get today => 'Bugün';

  @override
  String minutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String hoursAgo(int count) {
    return '$count saat önce';
  }

  @override
  String daysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String weeksAgo(int count) {
    return '$count hafta önce';
  }

  @override
  String monthsAgo(int count) {
    return '$count ay önce';
  }

  @override
  String yearsAgo(int count) {
    return '$count yıl önce';
  }

  @override
  String get oneMinuteAgo => '1 dk önce';

  @override
  String get oneHourAgo => '1 saat önce';

  @override
  String get oneWeekAgo => '1 hafta önce';

  @override
  String get oneMonthAgo => '1 ay önce';

  @override
  String get oneYearAgo => '1 yıl önce';

  @override
  String get twoDaysAgo => '2 gün önce';

  @override
  String get perMonth => '/ay';

  @override
  String get net => 'Net';

  @override
  String get pleaseEnterAmount => 'Lütfen bir tutar girin';

  @override
  String get pleaseEnterValidAmount => 'Geçerli bir tutar girin';

  @override
  String get pleaseSelectSourceAccount => 'Lütfen kaynak hesap seçin';

  @override
  String get pleaseSelectTargetAccount => 'Lütfen hedef hesap seçin';

  @override
  String get sourceAndTargetSame => 'Kaynak ve hedef hesap aynı olamaz';

  @override
  String get accountInfoNotFound => 'Hesap bilgileri alınamadı';

  @override
  String get accountInfoNotFoundSingle => 'Hesap bilgisi alınamadı';

  @override
  String get pleaseSelectCategory => 'Lütfen bir kategori seçin';

  @override
  String get pleaseSelectPaymentMethod => 'Lütfen bir ödeme yöntemi seçin';

  @override
  String get cardsLoadingError => 'Kartlar yüklenirken hata oluştu';

  @override
  String get noCardsAddedYet => 'Henüz kart eklenmemiş';

  @override
  String get transaction => 'İşlem';

  @override
  String get bankName => 'Qanta';

  @override
  String get repeatsEveryWeek => 'Her hafta tekrarlanır';

  @override
  String get repeatsEveryMonth => 'Her ay tekrarlanır';

  @override
  String get repeatsEveryQuarter => 'Her üç ayda tekrarlanır';

  @override
  String get repeatsEveryYear => 'Her yıl tekrarlanır';

  @override
  String get otherFixedPayments => 'Diğer sabit ödemeler';

  @override
  String get thisWeek => 'Bu Hafta';

  @override
  String get thisYear => 'Bu Yıl';

  @override
  String get lastYear => 'Geçen Yıl';

  @override
  String get custom => 'Özel';

  @override
  String get searchTransactions => 'İşlem Ara';

  @override
  String get filterByType => 'Türe Göre Filtrele';

  @override
  String get filterByPeriod => 'Döneme Göre Filtrele';

  @override
  String get filterByCategory => 'Kategoriye Göre Filtrele';

  @override
  String get clearFilters => 'Filtreleri Temizle';

  @override
  String get applyFilters => 'Filtreleri Uygula';

  @override
  String get noResultsFound => 'Sonuç bulunamadı';

  @override
  String get tryDifferentSearch => 'Farklı bir arama deneyin';

  @override
  String get noNotesYet => 'Henüz not yok';

  @override
  String get addExpenseIncomeNotes =>
      'Harcama veya gelir notlarınızı buraya ekleyin';

  @override
  String get justNow => 'Az önce';

  @override
  String get monday => 'Pazartesi';

  @override
  String get tuesday => 'Salı';

  @override
  String get wednesday => 'Çarşamba';

  @override
  String get thursday => 'Perşembe';

  @override
  String get friday => 'Cuma';

  @override
  String get saturday => 'Cumartesi';

  @override
  String get sunday => 'Pazar';

  @override
  String get january => 'Ocak';

  @override
  String get february => 'Şubat';

  @override
  String get march => 'Mart';

  @override
  String get april => 'Nisan';

  @override
  String get may => 'Mayıs';

  @override
  String get june => 'Haziran';

  @override
  String get july => 'Temmuz';

  @override
  String get august => 'Ağustos';

  @override
  String get september => 'Eylül';

  @override
  String get october => 'Ekim';

  @override
  String get november => 'Kasım';

  @override
  String get december => 'Aralık';

  @override
  String get textNote => 'Metin Notu';

  @override
  String get addQuickTextNote => 'Hızlı metin notu ekle';

  @override
  String get takePhoto => 'Fotoğraf Çek';

  @override
  String get takePhotoFromCamera => 'Kameradan fotoğraf çek';

  @override
  String get selectFromGallery => 'Galeriden Seç';

  @override
  String get selectPhotoFromGallery => 'Galeriden fotoğraf seç';

  @override
  String get photoCaptureError => 'Fotoğraf çekilirken hata oluştu';

  @override
  String get photoSelectionError => 'Fotoğraf seçilirken hata oluştu';

  @override
  String get add => 'Ekle';

  @override
  String get photoNote => 'Fotoğraf notu';

  @override
  String get photoNoteAdded => 'Fotoğraf notu eklendi';

  @override
  String get photoNoteAddError => 'Fotoğraf notu eklenirken hata oluştu';

  @override
  String get noteAdded => 'Not eklendi';

  @override
  String get noteAddError => 'Not eklenirken hata oluştu';

  @override
  String get noteDeleted => 'Not silindi';

  @override
  String get noteDeleteError => 'Not silinirken hata oluştu';

  @override
  String get noConvertedNotesYet => 'Henüz işleme dönüştürülen not yok';

  @override
  String get stop => 'Durdur';

  @override
  String get send => 'Gönder';

  @override
  String get processed => 'İşlendi';

  @override
  String get newest => 'En Yeni';

  @override
  String get oldest => 'En Eski';

  @override
  String get highestToLowest => 'Çoktan Aza';

  @override
  String get lowestToHighest => 'Azdan Çoğa';

  @override
  String get alphabetical => 'A-Z';

  @override
  String get more => 'Daha Fazla';

  @override
  String get less => 'Daha Az';

  @override
  String get cardName => 'Kart Adı';

  @override
  String get usage => 'Kullanım';

  @override
  String get lastPayment => 'Son Ödeme';

  @override
  String get nextPayment => 'Sonraki Ödeme';

  @override
  String get minimumPayment => 'Minimum Ödeme';

  @override
  String get totalDebt => 'Toplam Borç';

  @override
  String get noTransactionsForThisCard => 'Bu kart için henüz işlem bulunmuyor';

  @override
  String get statementSuccessfullyPaid =>
      'Ekstre başarıyla ödendi olarak işaretlendi';

  @override
  String get bank => 'Banka';

  @override
  String get cardNameRequired => 'Kart adı gerekli';

  @override
  String get creditLimitRequired => 'Kredi limiti gerekli';

  @override
  String get debt => 'Borç';

  @override
  String get noNotifications => 'Bildirim yok';

  @override
  String get usageRate => 'Kullanım Oranı';

  @override
  String get statementDay => 'Ekstre Günü';

  @override
  String get creditCardInfo => 'Kredi Kartı Bilgileri';

  @override
  String get installmentDetailsLoadError => 'Taksit detayları yüklenemedi';

  @override
  String get tomorrow => 'Yarın';

  @override
  String get currentPassword => 'Mevcut Şifre';

  @override
  String get newPassword => 'Yeni Şifre';

  @override
  String get confirmNewPassword => 'Yeni Şifre (Tekrar)';

  @override
  String get passwordMinLengthInfo =>
      'Şifreniz en az 6 karakter uzunluğunda olmalıdır.';

  @override
  String get passwordMinLength => 'Şifre en az 6 karakter olmalı';

  @override
  String get passwordChangedSuccessfully => 'Şifre başarıyla değiştirildi';

  @override
  String get wrongCurrentPassword => 'Mevcut şifre yanlış';

  @override
  String get passwordTooWeak => 'Şifre çok zayıf';

  @override
  String get requiresRecentLogin =>
      'Şifrenizi değiştirmek için tekrar giriş yapın';

  @override
  String get passwordChangeFailed => 'Şifre değiştirilemedi';

  @override
  String get ok => 'Tamam';

  @override
  String get collectedInformation => 'Toplanan Bilgiler';

  @override
  String get collectedInformationContent =>
      'Qanta uygulaması, size daha iyi hizmet verebilmek için aşağıdaki bilgileri toplar:\n\n• Hesap bilgileri (e-posta, ad-soyad)\n• Finansal işlem verileri (gelir, gider, transfer kayıtları)\n• Kart ve hesap bilgileri\n• Bütçe ve kategori tercihleri\n• Uygulama kullanım istatistikleri';

  @override
  String get informationUsage => 'Bilgilerin Kullanımı';

  @override
  String get informationUsageContent =>
      'Toplanan bilgiler aşağıdaki amaçlarla kullanılır:\n\n• Kişisel finans yönetimi hizmetlerinin sağlanması\n• Bütçe takibi ve harcama analizlerinin yapılması\n• Uygulama performansının iyileştirilmesi\n• Güvenlik ve dolandırıcılık önleme\n• Yasal yükümlülüklerin yerine getirilmesi';

  @override
  String get dataSecurity => 'Veri Güvenliği';

  @override
  String get dataSecurityContent =>
      'Verilerinizin güvenliği bizim için önceliktir:\n\n• Tüm veriler şifreli olarak saklanır\n• Güvenli sunucularda barındırılır\n• Düzenli güvenlik güncellemeleri yapılır\n• Yetkisiz erişimlere karşı korunur\n• Endüstri standartlarına uygun güvenlik önlemleri alınır';

  @override
  String get dataSharing => 'Veri Paylaşımı';

  @override
  String get dataSharingContent =>
      'Kişisel verileriniz aşağıdaki durumlar dışında üçüncü taraflarla paylaşılmaz:\n\n• Yasal zorunluluklar\n• Güvenlik ihlalleri durumunda\n• Açık rızanızın bulunması\n• Hizmet sağlayıcıları ile sınırlı paylaşım (anonim)';

  @override
  String get userRights => 'Kullanıcı Hakları';

  @override
  String get userRightsContent =>
      'KVKK kapsamında sahip olduğunuz haklar:\n\n• Kişisel verilerinizin işlenip işlenmediğini öğrenme\n• Verilerinize erişim talep etme\n• Yanlış bilgilerin düzeltilmesini isteme\n• Verilerin silinmesini talep etme\n• Hesabınızı tamamen kapatma';

  @override
  String get contact => 'İletişim';

  @override
  String get contactContent =>
      'Gizlilik politikası ile ilgili sorularınız için:\n\nE-posta: privacy@qanta.app\nAdres: İstanbul, Türkiye\n\nBu politika son güncellenme tarihi: 20 Ocak 2025';

  @override
  String get supportAndContact => 'Destek & İletişim';

  @override
  String get phone => 'Telefon';

  @override
  String get liveSupport => 'Canlı Destek';

  @override
  String get liveSupportHours => 'Pazartesi-Cuma 09:00-18:00';

  @override
  String get isMyDataSecure => 'Verilerim güvende mi?';

  @override
  String get isMyDataSecureAnswer =>
      'Evet, tüm verileriniz şifreli olarak saklanır ve güvenli sunucularda barındırılır. Supabase altyapısını kullanarak endüstri standartlarında güvenlik sağlıyoruz.';

  @override
  String get forgotPasswordAnswer =>
      'Giriş ekranında \"Şifremi Unuttum\" seçeneğini kullanarak e-posta adresinize şifre sıfırlama bağlantısı gönderebilirsiniz.';

  @override
  String get howToDeleteAccount => 'Hesabımı nasıl silebilirim?';

  @override
  String get howToDeleteAccountAnswer =>
      'Profil sayfasından çıkış yapabilir veya destek ekibimizle iletişime geçerek hesabınızın tamamen silinmesini talep edebilirsiniz.';

  @override
  String get isAppFree => 'Uygulama ücretsiz mi?';

  @override
  String get isAppFreeAnswer =>
      'Evet, Qanta tamamen ücretsiz olarak kullanılabilir. Gelecekte premium özellikler eklenebilir ancak temel özellikler her zaman ücretsiz kalacaktır.';

  @override
  String get appInformation => 'Uygulama Bilgileri';

  @override
  String get lastUpdate => 'Son Güncelleme';

  @override
  String get developer => 'Geliştirici';

  @override
  String get platform => 'Platform';

  @override
  String get liveSupportTitle => 'Canlı Destek';

  @override
  String get liveSupportMessage =>
      'Canlı destek hizmeti şu anda geliştirme aşamasındadır. Acil durumlar için lütfen e-posta veya telefon ile iletişime geçin.';

  @override
  String get serviceDescription => 'Hizmet Tanımı';

  @override
  String get serviceDescriptionContent =>
      'Qanta, kişisel finans yönetimi için tasarlanmış bir mobil uygulamadır. Uygulama aşağıdaki hizmetleri sunar:\n\n• Gelir ve gider takibi\n• Bütçe yönetimi ve planlama\n• Kart ve hesap yönetimi\n• Finansal raporlama ve analiz\n• Taksit takibi ve yönetimi';

  @override
  String get usageTerms => 'Kullanım Koşulları';

  @override
  String get usageTermsContent =>
      'Qanta uygulamasını kullanarak aşağıdaki koşulları kabul etmiş olursunuz:\n\n• Uygulamayı yalnızca yasal amaçlarla kullanacaksınız\n• Doğru ve güncel bilgiler sağlayacaksınız\n• Hesap güvenliğinizi koruyacaksınız\n• Diğer kullanıcıların haklarına saygı göstereceksiniz\n• Uygulamanın kötüye kullanımından kaçınacaksınız';

  @override
  String get userResponsibilities => 'Kullanıcı Sorumlulukları';

  @override
  String get userResponsibilitiesContent =>
      'Kullanıcı olarak aşağıdaki sorumluluklarınız bulunmaktadır:\n\n• Hesap bilgilerinizi güvenli tutmak\n• Şifrenizi kimseyle paylaşmamak\n• Finansal verilerinizin doğruluğunu sağlamak\n• Uygulama kurallarına uymak\n• Güvenlik ihlallerini bildirmek';

  @override
  String get serviceLimitations => 'Hizmet Sınırlamaları';

  @override
  String get serviceLimitationsContent =>
      'Qanta uygulaması aşağıdaki sınırlamalara tabidir:\n\n• Finansal danışmanlık hizmeti sunmaz\n• Yatırım önerisi vermez\n• Banka işlemleri gerçekleştirmez\n• Kredi veya borç verme hizmeti sunmaz\n• Vergi danışmanlığı yapmaz';

  @override
  String get intellectualProperty => 'Fikri Mülkiyet';

  @override
  String get intellectualPropertyContent =>
      'Qanta uygulamasının tüm içeriği telif hakkı ile korunmaktadır:\n\n• Uygulama tasarımı ve kodu\n• Logo ve marka unsurları\n• Metin ve görsel içerikler\n• Algoritma ve hesaplama yöntemleri\n• Veritabanı yapısı';

  @override
  String get serviceChanges => 'Hizmet Değişiklikleri';

  @override
  String get serviceChangesContent =>
      'Qanta, hizmetlerinde değişiklik yapma hakkını saklı tutar:\n\n• Özellik ekleme veya çıkarma\n• Fiyatlandırma değişiklikleri\n• Kullanım koşullarını güncelleme\n• Hizmet sonlandırma\n• Bakım ve güncellemeler';

  @override
  String get disclaimer => 'Sorumluluk Reddi';

  @override
  String get disclaimerContent =>
      'Qanta aşağıdaki durumlardan sorumlu değildir:\n\n• Veri kaybı veya bozulması\n• Sistem arızaları veya kesintiler\n• Üçüncü taraf hizmet sağlayıcıları\n• Kullanıcı hatalarından kaynaklanan zararlar\n• İnternet bağlantısı sorunları';

  @override
  String get termsContact => 'İletişim';

  @override
  String get termsContactContent =>
      'Kullanım şartları ile ilgili sorularınız için:\n\nE-posta: support@qanta.app\nWeb: www.qanta.app\nAdres: İstanbul, Türkiye\n\nBu şartlar son güncellenme tarihi: 20 Ocak 2025';

  @override
  String get faq => 'Sık Sorulan Sorular';

  @override
  String get generalQuestions => 'Genel Sorular';

  @override
  String get accountAndSecurity => 'Hesap ve Güvenlik';

  @override
  String get features => 'Özellikler';

  @override
  String get technicalIssues => 'Teknik Sorunlar';

  @override
  String get whatIsQanta => 'Qanta nedir?';

  @override
  String get whatIsQantaAnswer =>
      'Qanta, kişisel finans yönetimi için tasarlanmış modern bir mobil uygulamadır. Gelir-gider takibi, bütçe yönetimi, kart takibi ve finansal analiz özellikleri sunar.';

  @override
  String get whichDevicesSupported => 'Hangi cihazlarda kullanabilirim?';

  @override
  String get whichDevicesSupportedAnswer =>
      'Qanta, Android ve iOS cihazlarda kullanılabilir. Flutter teknolojisi ile geliştirilmiştir.';

  @override
  String get howToChangePassword => 'Şifremi nasıl değiştiririm?';

  @override
  String get howToChangePasswordAnswer =>
      'Profil sayfasında \"Güvenlik\" bölümünden \"Şifre Değiştir\" seçeneğini kullanabilirsiniz.';

  @override
  String get whichCardTypesSupported =>
      'Hangi kart türlerini destekliyorsunuz?';

  @override
  String get whichCardTypesSupportedAnswer =>
      'Kredi kartları, banka kartları ve nakit hesapları desteklenmektedir. Tüm Türk bankaları ile uyumludur.';

  @override
  String get howDoesInstallmentTrackingWork => 'Taksit takibi nasıl çalışır?';

  @override
  String get howDoesInstallmentTrackingWorkAnswer =>
      'Taksitli alışverişlerinizi ekleyebilir, aylık ödemelerinizi otomatik olarak takip edebilirsiniz. Sistem size hatırlatmalar gönderir.';

  @override
  String get howToUseBudgetManagement => 'Bütçe yönetimi nasıl kullanılır?';

  @override
  String get howToUseBudgetManagementAnswer =>
      'Kategoriler için aylık limitler belirleyebilir, harcamalarınızı takip edebilir ve limit aşımlarında uyarı alabilirsiniz.';

  @override
  String get whatIsQuickNotesFeature => 'Hızlı notlar özelliği nedir?';

  @override
  String get whatIsQuickNotesFeatureAnswer =>
      'Kalıcı bildirim ile hızlıca not alabilir, fotoğraf ekleyebilir ve notlarınızı kategorize edebilirsiniz.';

  @override
  String get appCrashingWhatToDo => 'Uygulama çöküyor, ne yapmalıyım?';

  @override
  String get appCrashingWhatToDoAnswer =>
      'Önce uygulamayı tamamen kapatıp tekrar açmayı deneyin. Sorun devam ederse cihazınızı yeniden başlatın. Hala çözülmezse destek ekibimizle iletişime geçin.';

  @override
  String get dataNotSyncing => 'Verilerim senkronize olmuyor';

  @override
  String get dataNotSyncingAnswer =>
      'İnternet bağlantınızı kontrol edin ve uygulamayı yeniden başlatın. Sorun devam ederse çıkış yapıp tekrar giriş yapmayı deneyin.';

  @override
  String get notificationsNotComing => 'Bildirimler gelmiyor';

  @override
  String get notificationsNotComingAnswer =>
      'Cihaz ayarlarınızdan Qanta için bildirimlerin açık olduğundan emin olun. Profil sayfasından bildirim ayarlarını da kontrol edin.';

  @override
  String get howToContactSupport =>
      'Destek ekibinizle nasıl iletişime geçebilirim?';

  @override
  String get howToContactSupportAnswer =>
      'Profil sayfasından \"Destek & İletişim\" bölümünü kullanabilir veya support@qanta.app adresine e-posta gönderebilirsiniz.';

  @override
  String get haveSuggestionWhereToSend => 'Önerim var, nereye iletebilirim?';

  @override
  String get haveSuggestionWhereToSendAnswer =>
      'Önerilerinizi support@qanta.app adresine gönderebilirsiniz. Tüm geri bildirimler değerlendirilir ve uygulamayı geliştirmek için kullanılır.';

  @override
  String get lastMonthChange => 'Geçen aya göre';

  @override
  String get increase => 'artış';

  @override
  String get decrease => 'azalış';

  @override
  String get noAccountsYet => 'Henüz hesap eklenmemiş';

  @override
  String get addFirstAccount => 'İlk hesabınızı ekleyerek başlayın';

  @override
  String get currentDebt => 'Mevcut Borç';

  @override
  String get totalLimit => 'Toplam Limit';

  @override
  String get cashWallet => 'Nakit Cüzdan';

  @override
  String get searchBanks => 'Banka ara...';

  @override
  String get noBanksFound => 'Banka bulunamadı';

  @override
  String get addCreditCard => 'Kredi Kartı Ekle';

  @override
  String get cardNameExample => 'Örn: VakıfBank Kredi Kartı';

  @override
  String get currentDebtOptional => 'Mevcut Borç (Opsiyonel)';

  @override
  String get addDebitCard => 'Banka Kartı Ekle';

  @override
  String get cardNameExampleDebit => 'Örn: VakıfBank Vadesiz';

  @override
  String get initialBalance => 'Başlangıç Bakiyesi';

  @override
  String get day => 'gün';

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
  String get selectCardType => 'Kart Türü Seçin';

  @override
  String get addDebitCardDescription => 'Vadesiz hesap kartı ekleyin';

  @override
  String get addCreditCardDescription => 'Kredi kartı bilgilerinizi ekleyin';
}
