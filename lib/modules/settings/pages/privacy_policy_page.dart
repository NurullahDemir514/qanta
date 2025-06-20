import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
          'Gizlilik Politikası',
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
                title: '1. Toplanan Bilgiler',
                content: '''Qanta uygulaması, size daha iyi hizmet verebilmek için aşağıdaki bilgileri toplar:

• Hesap bilgileri (e-posta, ad-soyad)
• Finansal işlem verileri (gelir, gider, transfer kayıtları)
• Kart ve hesap bilgileri
• Bütçe ve kategori tercihleri
• Uygulama kullanım istatistikleri''',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '2. Bilgilerin Kullanımı',
                content: '''Toplanan bilgiler aşağıdaki amaçlarla kullanılır:

• Kişisel finans yönetimi hizmetlerinin sağlanması
• Bütçe takibi ve harcama analizlerinin yapılması
• Uygulama performansının iyileştirilmesi
• Güvenlik ve dolandırıcılık önleme
• Yasal yükümlülüklerin yerine getirilmesi''',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '3. Veri Güvenliği',
                content: '''Verilerinizin güvenliği bizim için önceliktir:

• Tüm veriler şifreli olarak saklanır
• Güvenli sunucularda barındırılır
• Düzenli güvenlik güncellemeleri yapılır
• Yetkisiz erişimlere karşı korunur
• Endüstri standartlarına uygun güvenlik önlemleri alınır''',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '4. Veri Paylaşımı',
                content: '''Kişisel verileriniz aşağıdaki durumlar dışında üçüncü taraflarla paylaşılmaz:

• Yasal zorunluluklar
• Güvenlik ihlalleri durumunda
• Açık rızanızın bulunması
• Hizmet sağlayıcıları ile sınırlı paylaşım (anonim)''',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '5. Kullanıcı Hakları',
                content: '''KVKK kapsamında sahip olduğunuz haklar:

• Kişisel verilerinizin işlenip işlenmediğini öğrenme
• Verilerinize erişim talep etme
• Yanlış bilgilerin düzeltilmesini isteme
• Verilerin silinmesini talep etme
• Hesabınızı tamamen kapatma''',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '6. İletişim',
                content: '''Gizlilik politikası ile ilgili sorularınız için:

E-posta: privacy@qanta.app
Adres: İstanbul, Türkiye

Bu politika son güncellenme tarihi: 20 Ocak 2025''',
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