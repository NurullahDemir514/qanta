import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gift Card Reward Terms and Conditions Page
/// Tüketiciyi Koruma Kanunu'na uygun bilgilendirme sayfası
class AmazonRewardTermsPage extends StatelessWidget {
  const AmazonRewardTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
        ),
        title: Text(
          'Hediye Kartları',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              'Hediye Kartı Ödül Sistemi',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Şartlar ve Koşullar',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Genel Bilgiler
            _buildSection(
              title: '1. Genel Bilgiler',
              content: '''Hediye Kartı Ödül Sistemi ("Sistem"), Qanta uygulamasını kullanan Türk Play Store kullanıcıları için tasarlanmış bir ödül programıdır. Bu sistem, kullanıcıların uygulama içi aktiviteleri karşılığında puan kazanmalarını ve bu puanları çeşitli hediye kartlarına (Amazon, Paribu Cineverse, D&R, Gratis, vb.) dönüştürmelerini sağlar.

Bu şartlar ve koşullar, Tüketicinin Korunması Hakkında Kanun (6502 sayılı Kanun) ve ilgili mevzuat hükümlerine uygun olarak hazırlanmıştır.''',
              isDark: isDark,
            ),

            // Uygunluk Şartları
            _buildSection(
              title: '2. Uygunluk Şartları',
              content: '''2.1. Bu ödül sisteminden yararlanmak için:
• Türk Play Store'dan Qanta uygulamasını indirmiş olmanız gerekmektedir
• 18 yaşını tamamlamış olmanız gerekmektedir
• Geçerli bir e-posta adresiniz olmalıdır
• Qanta uygulamasında aktif bir hesabınız olmalıdır

2.2. Sistem sadece Türkiye'den indirilen uygulamalarda aktif olup, diğer ülkelerden indirilen uygulamalarda geçerli değildir.

2.3. Qanta, uygunluk şartlarını her zaman kontrol etme ve uygun olmayan kullanıcıları sistemden çıkarma hakkını saklı tutar.''',
              isDark: isDark,
            ),

            // Puan Kazanma Yolları
            _buildSection(
              title: '3. Puan Kazanma Yolları',
              content: '''3.1. Kullanıcılar aşağıdaki yollarla puan kazanabilir:

a) Reklam İzleme:
• Ödüllü reklam izleyerek 50 puan kazanabilirsiniz
• Günlük maksimum reklam izleme sayısı: 10 adet
• Her reklam izleme işlemi için puan kazandığınızda sistem tarafından bildirilirsiniz

b) İşlem Ekleme:
• Harcama veya gelir işlemi ekleyerek 15 puan kazanabilirsiniz
• Günlük maksimum işlem sayısı: 20 adet
• Aynı işlemden sadece bir kez puan kazanabilirsiniz

3.2. Puan kazanma işlemleri anında hesabınıza yansır ve geçmişinizden takip edebilirsiniz.

3.3. Sistem, puan kazanma kurallarını değiştirme hakkını saklı tutar. Değişiklikler önceden bildirilir.''',
              isDark: isDark,
            ),

            // Hediye Kartı Dönüşümü
            _buildSection(
              title: '4. Hediye Kartı Dönüşümü',
              content: '''4.1. Puanlarınızı hediye kartına dönüştürmek için:
• Her hediye kartı sağlayıcısı için minimum puan gereksinimleri farklılık gösterebilir
• Hediye kartı talebinde bulunmak için ilgili sağlayıcının web sitesinde kullanacağınız e-posta adresi veya telefon numarası sağlamanız gerekmektedir
• Hediye kartı talepleri belirli tutarın katları şeklinde olmalıdır (örn: 20.000 puan = 100 TL, 40.000 puan = 200 TL, vb.)

4.2. Hediye kartı talebi süreci:
• Yeterli puanınız olduğunda "Hediye Kartı Al" butonuna tıklayın
• İstediğiniz hediye kartı sağlayıcısını seçin (Amazon, Paribu Cineverse, D&R, Gratis, vb.)
• İlgili sağlayıcının web sitesinde kullanacağınız e-posta adresini veya telefon numarasını girin
• Talep onaylandıktan sonra puanlarınız hesabınızdan düşülür
• Hediye kartı kodu e-posta adresinize veya SMS olarak telefon numaranıza gönderilir
• E-posta/SMS gönderimi 1-3 iş günü içinde tamamlanır

4.3. Hediye kartı kodları ilgili sağlayıcının web sitesinde kullanılabilir (örn: Amazon.com.tr, Paribu Cineverse, D&R, Gratis, vb.).

4.4. Hediye kartı talepleri geri alınamaz ve iade edilemez.

4.5. Her hediye kartı sağlayıcısı için farklı kullanım şartları geçerli olabilir. Lütfen ilgili sağlayıcının kullanım şartlarını kontrol edin.''',
              isDark: isDark,
            ),

            // Günlük Limitler
            _buildSection(
              title: '5. Günlük Limitler',
              content: '''5.1. Puan kazanma işlemleri için günlük limitler bulunmaktadır:

• Reklam İzleme: Günlük maksimum 10 adet (500 puan)
• İşlem Ekleme: Günlük maksimum 20 adet (300 puan)
• Toplam Günlük Maksimum: 800 puan

5.2. Limitler, saat 00:00'da sıfırlanır (Türkiye saati - UTC+3).

5.3. Sistem, limitleri değiştirme hakkını saklı tutar. Değişiklikler önceden bildirilir.''',
              isDark: isDark,
            ),

            // Hediye Kartı Kullanımı
            _buildSection(
              title: '6. Hediye Kartı Kullanımı',
              content: '''6.1. Hediye kartları ilgili sağlayıcının web sitesinde geçerlidir (Amazon.com.tr, Paribu Cineverse, D&R, Gratis, vb.).

6.2. Hediye kartı kodlarınızı güvenli tutun ve başkalarıyla paylaşmayın.

6.3. Hediye kartı kodları genellikle son kullanma tarihi olmadan geçerlidir, ancak her sağlayıcı için farklı kurallar geçerli olabilir.

6.4. Hediye kartı kullanımı ilgili sağlayıcının şartlarına tabidir.

6.5. Qanta, hediye kartlarının kullanımından veya ilgili sağlayıcı tarafından reddedilmesinden sorumlu değildir.

6.6. Her hediye kartı sağlayıcısı için farklı kullanım şartları ve sınırlamalar geçerli olabilir.''',
              isDark: isDark,
            ),

            // Hile ve Kötüye Kullanım
            _buildSection(
              title: '7. Hile ve Kötüye Kullanım',
              content: '''7.1. Aşağıdaki durumlarda hesabınız askıya alınabilir veya kapatılabilir:

• Sahte işlemler oluşturma
• Bot veya otomasyon kullanma
• Sistemi manipüle etme girişimleri
• Başka kullanıcıların hesaplarını kullanma
• Sistemin güvenliğini ihlal etme

7.2. Hile veya kötüye kullanım tespit edilirse:
• Tüm puanlarınız iptal edilir
• Hediye kartı talepleriniz iptal edilir
• Hesabınız kalıcı olarak kapatılır
• Yasal işlem başlatılabilir

7.3. Qanta, hile ve kötüye kullanımı tespit etme ve önleme konusunda her türlü önlemi alma hakkını saklı tutar.''',
              isDark: isDark,
            ),

            // İptal ve İade
            _buildSection(
              title: '8. İptal ve İade',
              content: '''8.1. Hediye kartı talepleri, puanlar hesabınızdan düşüldükten sonra iptal edilemez.

8.2. Puanlar nakit para veya başka bir ödeme yöntemi ile değiştirilemez.

8.3. Hediye kartı kodları e-posta adresinize gönderildikten sonra iade edilemez.

8.4. Teknik bir hata nedeniyle puan kaybı yaşarsanız, destek ekibi ile iletişime geçebilirsiniz.''',
              isDark: isDark,
            ),

            // Değişiklikler ve Sonlandırma
            _buildSection(
              title: '9. Değişiklikler ve Sonlandırma',
              content: '''9.1. Qanta, bu şartları ve koşulları her zaman değiştirme hakkını saklı tutar.

9.2. Önemli değişiklikler, uygulama içi bildirim veya e-posta yoluyla kullanıcılara bildirilir.

9.3. Qanta, ödül sistemini her zaman sonlandırma hakkını saklı tutar.

9.4. Sistem sonlandırılırsa, kullanıcılara yeterli süre tanınır ve birikmiş puanlarını dönüştürme fırsatı verilir.

9.5. Sistem sonlandırıldığında, kullanılmamış puanlar iade edilmez.''',
              isDark: isDark,
            ),

            // Sorumluluk Reddi
            _buildSection(
              title: '10. Sorumluluk Reddi',
              content: '''10.1. Qanta, hediye kartlarının kullanılabilirliğinden veya ilgili sağlayıcı tarafından reddedilmesinden sorumlu değildir.

10.2. Qanta, teknik hatalar, sistem kesintileri veya gecikmelerden kaynaklanan puan kayıplarından sorumlu değildir.

10.3. Qanta, kullanıcı hatalarından (yanlış e-posta adresi, telefon numarası, vb.) kaynaklanan sorunlardan sorumlu değildir.

10.4. Qanta, ilgili sağlayıcıların (Amazon, Paribu Cineverse, D&R, Gratis, vb.) hizmet şartlarına tabi olan hediye kartı kullanımından sorumlu değildir.

10.5. Maksimum sorumluluk, kullanıcının birikmiş puanlarının değeri ile sınırlıdır.

10.6. Qanta, hediye kartı sağlayıcılarının hizmetlerindeki değişikliklerden veya hizmetlerin sonlandırılmasından sorumlu değildir.''',
              isDark: isDark,
            ),

            // Gizlilik
            _buildSection(
              title: '11. Gizlilik',
              content: '''11.1. Toplanan kişisel bilgiler (e-posta adresi, telefon numarası, vb.) sadece hediye kartı gönderimi için kullanılır.

11.2. Kişisel bilgileriniz, Gizlilik Politikamız kapsamında korunur.

11.3. E-posta adresiniz ve telefon numaranız, yalnızca hediye kartı gönderimi için kullanılır ve üçüncü taraflarla paylaşılmaz.

11.4. Hediye kartı sağlayıcılarına (Amazon, Paribu Cineverse, D&R, Gratis, vb.) sadece hediye kartı gönderimi için gerekli bilgiler aktarılır.''',
              isDark: isDark,
            ),

            // İletişim
            _buildSection(
              title: '12. İletişim',
              content: '''12.1. Ödül sistemi ile ilgili sorularınız için:

• E-posta: support@qanta.app
• Uygulama içi destek: Profil > Destek

12.2. Destek ekibi, sorularınıza en geç 3 iş günü içinde yanıt verir.

12.3. Teknik sorunlar için lütfen destek ekibi ile iletişime geçin.''',
              isDark: isDark,
            ),

            // Yasal Uyumluluk
            _buildSection(
              title: '13. Yasal Uyumluluk',
              content: '''13.1. Bu şartlar ve koşullar, Türkiye Cumhuriyeti yasalarına tabidir.

13.2. Tüketicinin Korunması Hakkında Kanun (6502 sayılı Kanun) ve ilgili mevzuat hükümleri geçerlidir.

13.3. Uyuşmazlıklar, İstanbul mahkemelerinde çözülecektir.

13.4. Tüketici hakları saklıdır. Tüketici hakem heyetine başvurabilirsiniz.''',
              isDark: isDark,
            ),

            // Son Güncelleme
            _buildSection(
              title: '14. Son Güncelleme',
              content: '''Bu şartlar ve koşullar son olarak 20 Ocak 2025 tarihinde güncellenmiştir.

Değişiklikler için lütfen bu sayfayı düzenli olarak kontrol edin.''',
              isDark: isDark,
              isLast: true,
            ),

            // Onay Butonu
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : const Color(0xFFE5E5EA),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bu şartları ve koşulları kabul ederek, ödül sistemini kullanmaya başladığınızda yukarıdaki tüm hükümleri kabul etmiş sayılırsınız.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isDark
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.black.withValues(alpha: 0.8),
            height: 1.6,
          ),
        ),
        if (!isLast) const SizedBox(height: 24),
      ],
    );
  }
}
