import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../shared/models/amazon_gift_card_model.dart';
import '../../../shared/models/gift_card_provider_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

/// Amazon Gift Card History Page
/// Shows list of all gift cards received by user
class AmazonGiftCardHistoryPage extends StatefulWidget {
  const AmazonGiftCardHistoryPage({super.key});

  @override
  State<AmazonGiftCardHistoryPage> createState() =>
      _AmazonGiftCardHistoryPageState();
}

class _AmazonGiftCardHistoryPageState
    extends State<AmazonGiftCardHistoryPage> {
  List<AmazonGiftCard> _giftCards = [];
  Map<String, String> _giftCardProviders = {}; // Map gift card ID to provider
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _giftCardSubscription;
  Set<String> _shownNotifications = {}; // Track which gift cards we've already shown notifications for
  bool _showPending = true; // Toggle: true = pending, false = completed

  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  @override
  void dispose() {
    _giftCardSubscription?.cancel();
    super.dispose();
  }

  void _setupListener() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Listen to real-time updates
    _giftCardSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('amazon_gift_cards')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _giftCards = snapshot.docs
            .map((doc) => AmazonGiftCard.fromQueryDocument(
                  doc as QueryDocumentSnapshot<Map<String, dynamic>>,
                ))
            .toList();
        
        // Extract provider information from Firestore
        _giftCardProviders = {};
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final provider = data['provider'] as String?;
          if (provider != null && provider.trim().isNotEmpty) {
            _giftCardProviders[doc.id] = provider.trim();
          } else {
            // If provider is missing, check admin_requests for backward compatibility
            // This is a fallback for old gift cards that don't have provider in the document
            // Note: This is async and might not work in real-time, but it's better than showing wrong provider
            debugPrint('⚠️ Gift card ${doc.id} missing provider field, defaulting to amazon');
            _giftCardProviders[doc.id] = 'amazon'; // Default fallback
          }
        }
        
        _isLoading = false;
      });

      // Check if any gift card status changed to 'sent' and show notification
      _checkForNewSentCards(snapshot);
    });
  }

  void _checkForNewSentCards(QuerySnapshot snapshot) {
    // Only track newly sent cards (not on initial load)
    if (_isLoading) return;
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String?;
      final giftCardId = doc.id;

      // If status is 'sent' and we haven't tracked this card yet
      if (status == 'sent' && !_shownNotifications.contains(giftCardId)) {
        // Mark as shown (no snackbar notification)
        _shownNotifications.add(giftCardId);
      }
    }
  }


  void _openProviderWebsite(String? providerId) async {
    String url;
    switch (providerId) {
      case 'paribu':
        url = 'https://www.paribucineverse.com';
        break;
      case 'dnr':
        url = 'https://www.dr.com.tr';
        break;
      case 'gratis':
        url = 'https://www.gratis.com.tr';
        break;
      case 'amazon':
      default:
        url = 'https://www.amazon.com.tr';
        break;
    }
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppPageScaffold(
      title: 'Hediye Kartlarım',
      onRefresh: () async {
        // Refresh is handled by the stream listener
      },
      body: _isLoading
          ? const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          : Builder(
              builder: (context) {
                // Separate gift cards by status
                final pendingCards = _giftCards.where((card) => 
                  card.status == GiftCardStatus.pending
                ).toList();
                
                final completedCards = _giftCards.where((card) => 
                  card.status == GiftCardStatus.sent || 
                  card.status == GiftCardStatus.redeemed
                ).toList();
                
                // Get current list based on toggle
                final currentCards = _showPending ? pendingCards : completedCards;
                
                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Toggle Switch
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0xFFE5E5EA),
                          width: 1,
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildToggleButton(
                                context,
                                'İşlemlerdeki',
                                _showPending,
                                pendingCards.length,
                                () {
                                  setState(() {
                                    _showPending = true;
                                  });
                                },
                                isDark,
                              ),
                            ),
                            Container(
                              width: 1,
                              color: isDark
                                  ? const Color(0xFF38383A)
                                  : const Color(0xFFE5E5EA),
                            ),
                            Expanded(
                              child: _buildToggleButton(
                                context,
                                'Alınanlar',
                                !_showPending,
                                completedCards.length,
                                () {
                                  setState(() {
                                    _showPending = false;
                                  });
                                },
                                isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Cards List
                    if (currentCards.isNotEmpty)
                      ...currentCards.map((giftCard) => _buildGiftCardItem(context, giftCard, isDark))
                    else
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.card_giftcard_outlined,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _showPending
                                    ? 'İşlemlerdeki hediye kartı yok'
                                    : 'Henüz hediye kartı almadınız',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _showPending
                                    ? 'Tüm hediye kartlarınız işlenmiş'
                                    : 'Hediye kartı talep ettiğinizde burada görünecek',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ]),
                );
              },
            ),
    );
  }


  Widget _buildToggleButton(
    BuildContext context,
    String label,
    bool isSelected,
    int count,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7))
              : Colors.transparent,
          borderRadius: BorderRadius.zero, // No radius for active toggle background
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftCardItem(
    BuildContext context,
    AmazonGiftCard giftCard,
    bool isDark,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'tr_TR');
    // Get provider information from map (extracted from Firestore)
    final providerId = _giftCardProviders[giftCard.id] ?? 'amazon';
    final providerConfig = GiftCardProviderConfig.getProviderById(providerId);
    final providerName = providerConfig?.name ?? 'Amazon';

    // Get provider color for card styling
    final providerColor = providerConfig?.primaryColor ?? const Color(0xFFFF9900);
    final providerAccentColor = providerConfig?.accentColor ?? const Color(0xFFFF7700);
    
    final statusText = giftCard.status == GiftCardStatus.sent
        ? 'Gönderildi'
        : giftCard.status == GiftCardStatus.redeemed
            ? 'Kullanıldı'
            : giftCard.status == GiftCardStatus.pending
                ? 'Hazırlanıyor'
                : 'İşleniyor';
    
    // Status colors with provider color accent
    final statusColor = giftCard.status == GiftCardStatus.sent
        ? providerColor.withValues(alpha: 0.8)
        : giftCard.status == GiftCardStatus.redeemed
            ? Colors.blue
            : providerColor;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF38383A)
              : const Color(0xFFE5E5EA),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Amount and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0).format(giftCard.amount),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (providerConfig?.primaryColor ?? const Color(0xFFFF9900)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (providerConfig?.primaryColor ?? const Color(0xFFFF9900)).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            providerName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: providerConfig?.primaryColor ?? const Color(0xFFFF9900),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(giftCard.sentAt != null ? giftCard.sentAt! : giftCard.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: giftCard.status == GiftCardStatus.redeemed
                        ? Colors.blue.shade700
                        : statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email Information
          if (giftCard.status == GiftCardStatus.sent || giftCard.status == GiftCardStatus.redeemed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          giftCard.recipientEmail,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 16,
                    color: providerColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hediye kartınız hazırlanıyor. En kısa sürede email\'inize gönderilecek.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Action Button (only for sent cards)
          if (giftCard.status == GiftCardStatus.sent) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openProviderWebsite(providerId),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text('${providerName}\'a Git'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: (providerConfig?.primaryColor ?? const Color(0xFFFF9900)).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

