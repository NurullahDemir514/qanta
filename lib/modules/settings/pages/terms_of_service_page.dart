import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          'Kullanım Şartları',
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
        child: Container(
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: '1. Hizmet Tanımı',
                content: '''Qanta, kişisel finans yönetimi için tasarlanmış bir mobil uygulamadır. Uygulama aşağıdaki hizmetleri sunar:

• Gelir ve gider takibi
• Bütçe yönetimi ve planlama
• Kart ve hesap yönetimi
• Finansal raporlama ve analiz
• Taksit takibi ve yönetimi''',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '2. Kullanım Koşulları',
                content: '''Qanta uygulamasını kullanarak aşağıdaki koşulları kabul etmiş olursunuz:

• Uygulamayı yalnızca yasal amaçlarla kullanacaksınız
• Doğru ve güncel bilgiler sağlayacaksınız
• Hesap güvenliğinizi koruyacaksınız
• Diğer kullanıcıların haklarına saygı göstereceksiniz
• Uygulamanın kötüye kullanımından kaçınacaksınız''',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '3. Kullanıcı Sorumlulukları',
                content: '''Kullanıcı olarak aşağıdaki sorumluluklarınız bulunmaktadır:

• Hesap bilgilerinizi güvenli tutmak
• Şifrenizi kimseyle paylaşmamak
• Finansal verilerinizin doğruluğunu sağlamak
• Uygulama kurallarına uymak
• Güvenlik ihlallerini bildirmek''',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '4. Hizmet Sınırlamaları',
                content: '''Qanta uygulaması aşağıdaki sınırlamalara tabidir:

• Finansal danışmanlık hizmeti sunmaz
• Yatırım önerisi vermez
• Banka işlemleri gerçekleştirmez
• Kredi veya borç verme hizmeti sunmaz
• Vergi danışmanlığı yapmaz''',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '5. Fikri Mülkiyet',
                content: '''Qanta uygulamasının tüm içeriği telif hakkı ile korunmaktadır:

• Uygulama tasarımı ve kodu
• Logo ve marka unsurları
• Metin ve görsel içerikler
• Algoritma ve hesaplama yöntemleri
• Veritabanı yapısı''',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '6. Hizmet Değişiklikleri',
                content: '''Qanta, hizmetlerinde değişiklik yapma hakkını saklı tutar:

• Özellik ekleme veya çıkarma
• Fiyatlandırma değişiklikleri
• Kullanım koşullarını güncelleme
• Hizmet sonlandırma
• Bakım ve güncellemeler''',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '7. Sorumluluk Reddi',
                content: '''Qanta aşağıdaki durumlardan sorumlu değildir:

• Veri kaybı veya bozulması
• Sistem arızaları veya kesintiler
• Üçüncü taraf hizmet sağlayıcıları
• Kullanıcı hatalarından kaynaklanan zararlar
• İnternet bağlantısı sorunları''',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '8. İletişim',
                content: '''Kullanım şartları ile ilgili sorularınız için:

E-posta: support@qanta.app
Web: www.qanta.app
Adres: İstanbul, Türkiye

Bu şartlar son güncellenme tarihi: 20 Ocak 2025''',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
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
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
} 