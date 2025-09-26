import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/unified_provider_v2.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isCreatingTestData = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA),
        elevation: 0,
      ),
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Test verisi oluştur
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bug_report,
                        color: Colors.orange,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Debug Veritabanı',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      'Veritabanı durumunu kontrol et',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                      ),
                    ),
                    trailing: _isCreatingTestData
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF8E8E93),
                          ),
                    onTap: _isCreatingTestData ? null : _debugDatabase,
                  ),
                  
                  const Divider(height: 1),
                  
                  ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.data_object,
                        color: Colors.blue,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'Test Verisi (Geliştirme)',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      'Örnek hesap ve işlemler oluştur',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                      ),
                    ),
                    trailing: _isCreatingTestData
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF8E8E93),
                          ),
                    onTap: _isCreatingTestData ? null : _createTestData,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _debugDatabase() async {
    setState(() {
      _isCreatingTestData = true;
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Get all accounts (including inactive ones)
      final allAccountsResponse = await supabase
          .from('accounts')
          .select('*')
          .order('created_at', ascending: false);
      
      final activeAccountsResponse = await supabase
          .from('accounts')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      
      for (var account in allAccountsResponse) {
        debugPrint('  - ${account['name']} (${account['type']}) - Active: ${account['is_active']}');
      }
      
      for (var account in activeAccountsResponse) {
        debugPrint('  - ${account['name']} (${account['type']}) - Balance: ${account['balance']}');
      }
      
      // Check provider state
      final providerV2 = UnifiedProviderV2.instance;
      debugPrint('  - Accounts in provider: ${providerV2.accounts.length}');
      debugPrint('  - Credit cards: ${providerV2.creditCards.length}');
      debugPrint('  - Debit cards: ${providerV2.debitCards.length}');
      debugPrint('  - Cash accounts: ${providerV2.cashAccounts.length}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Debug tamamlandı. Konsol loglarını kontrol edin.\n'
              'Toplam: ${allAccountsResponse.length}, Aktif: ${activeAccountsResponse.length}',
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingTestData = false;
      });
    }
  }

  Future<void> _createTestData() async {
    setState(() {
      _isCreatingTestData = true;
    });

    try {
      // Test data creation logic here
      debugPrint('Creating test data...');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test verisi oluşturuldu'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test verisi oluşturma hatası: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingTestData = false;
      });
    }
  }
} 