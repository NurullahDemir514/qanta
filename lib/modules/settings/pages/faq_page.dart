import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
        ? const Color(0xFF000000) 
        : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF007AFF),
            size: 20,
          ),
        ),
        title: Text(
          'Gizlilik',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildFAQSection(
              title: 'Genel Sorular',
              items: [
                FAQItem(
                  question: 'Qanta nedir?',
                  answer: 'Qanta, kişisel finans yönetimi için tasarlanmış modern bir mobil uygulamadır. Gelir-gider takibi, bütçe yönetimi, kart takibi ve finansal analiz özellikleri sunar.',
                ),
                FAQItem(
                  question: 'Uygulama ücretsiz mi?',
                  answer: 'Evet, Qanta tamamen ücretsiz olarak kullanılabilir. Gelecekte premium özellikler eklenebilir ancak temel özellikler her zaman ücretsiz kalacaktır.',
                ),
                FAQItem(
                  question: 'Hangi cihazlarda kullanabilirim?',
                  answer: 'Qanta, Android ve iOS cihazlarda kullanılabilir. Flutter teknolojisi ile geliştirilmiştir.',
                ),
              ],
              isDark: isDark,
            ),
            
            const SizedBox(height: 20),
            
            _buildFAQSection(
              title: 'Hesap ve Güvenlik',
              items: [
                FAQItem(
                  question: 'Verilerim güvende mi?',
                  answer: 'Evet, tüm verileriniz şifreli olarak saklanır ve güvenli sunucularda barındırılır. Supabase altyapısını kullanarak endüstri standartlarında güvenlik sağlıyoruz.',
                ),
                FAQItem(
                  question: 'Şifremi unuttum, ne yapmalıyım?',
                  answer: 'Giriş ekranında "Şifremi Unuttum" seçeneğini kullanarak e-posta adresinize şifre sıfırlama bağlantısı gönderebilirsiniz.',
                ),
                FAQItem(
                  question: 'Hesabımı nasıl silebilirim?',
                  answer: 'Profil sayfasından çıkış yapabilir veya destek ekibimizle iletişime geçerek hesabınızın tamamen silinmesini talep edebilirsiniz.',
                ),
                FAQItem(
                  question: 'Şifremi nasıl değiştiririm?',
                  answer: 'Profil sayfasında "Güvenlik" bölümünden "Şifre Değiştir" seçeneğini kullanabilirsiniz.',
                ),
              ],
              isDark: isDark,
            ),
            
            const SizedBox(height: 20),
            
            _buildFAQSection(
              title: 'Özellikler',
              items: [
                FAQItem(
                  question: 'Hangi kart türlerini destekliyorsunuz?',
                  answer: 'Kredi kartları, banka kartları ve nakit hesapları desteklenmektedir. Tüm Türk bankaları ile uyumludur.',
                ),
                FAQItem(
                  question: 'Taksit takibi nasıl çalışır?',
                  answer: 'Taksitli alışverişlerinizi ekleyebilir, aylık ödemelerinizi otomatik olarak takip edebilirsiniz. Sistem size hatırlatmalar gönderir.',
                ),
                FAQItem(
                  question: 'Bütçe yönetimi nasıl kullanılır?',
                  answer: 'Kategoriler için aylık limitler belirleyebilir, harcamalarınızı takip edebilir ve limit aşımlarında uyarı alabilirsiniz.',
                ),
                FAQItem(
                  question: 'Hızlı notlar özelliği nedir?',
                  answer: 'Kalıcı bildirim ile hızlıca not alabilir, fotoğraf ekleyebilir ve notlarınızı kategorize edebilirsiniz.',
                ),
              ],
              isDark: isDark,
            ),
            
            const SizedBox(height: 20),
            
            _buildFAQSection(
              title: 'Teknik Sorunlar',
              items: [
                FAQItem(
                  question: 'Uygulama çöküyor, ne yapmalıyım?',
                  answer: 'Önce uygulamayı tamamen kapatıp tekrar açmayı deneyin. Sorun devam ederse cihazınızı yeniden başlatın. Hala çözülmezse destek ekibimizle iletişime geçin.',
                ),
                FAQItem(
                  question: 'Verilerim senkronize olmuyor',
                  answer: 'İnternet bağlantınızı kontrol edin ve uygulamayı yeniden başlatın. Sorun devam ederse çıkış yapıp tekrar giriş yapmayı deneyin.',
                ),
                FAQItem(
                  question: 'Bildirimler gelmiyor',
                  answer: 'Cihaz ayarlarınızdan Qanta için bildirimlerin açık olduğundan emin olun. Profil sayfasından bildirim ayarlarını da kontrol edin.',
                ),
              ],
              isDark: isDark,
            ),
            
            const SizedBox(height: 20),
            
            _buildFAQSection(
              title: 'İletişim',
              items: [
                FAQItem(
                  question: 'Destek ekibinizle nasıl iletişime geçebilirim?',
                  answer: 'Profil sayfasından "Destek & İletişim" bölümünü kullanabilir veya support@qanta.app adresine e-posta gönderebilirsiniz.',
                ),
                FAQItem(
                  question: 'Önerim var, nereye iletebilirim?',
                  answer: 'Önerilerinizi support@qanta.app adresine gönderebilirsiniz. Tüm geri bildirimler değerlendirilir ve uygulamayı geliştirmek için kullanılır.',
                ),
              ],
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection({
    required String title,
    required List<FAQItem> items,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark 
          ? Border.all(
              color: const Color(0xFF38383A),
              width: 0.5,
            )
          : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            
            return Column(
              children: [
                _buildFAQItem(item, isDark),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: isDark 
                      ? const Color(0xFF38383A)
                      : const Color(0xFFE5E5EA),
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem item, bool isDark) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Text(
        item.question,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      iconColor: const Color(0xFF007AFF),
      collapsedIconColor: const Color(0xFF8E8E93),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            item.answer,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF8E8E93),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
} 