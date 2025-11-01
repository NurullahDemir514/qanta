# 🚨 KART LİMİTİ GÜVENLİK AÇIĞI

## ❌ SORUN

**Free kullanıcılar sınırsız kart ekleyebiliyor!**

### Mevcut Durum:
```dart
// PremiumService'de limit kontrolü VAR:
bool canAddCard(int currentCardCount) {
  if (isPremium) return true;
  return currentCardCount < 3; // Free: max 3 kart
}

// Ama Firestore rules'da KORUMA YOK:
match /accounts/{accountId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  // ❌ Kart sayısı kontrolü YOK!
}
```

### Sömürü Senaryosu:
```dart
// Kullanıcı client-side kontrolünü atlayıp direkt Firebase'e yazabilir:
for (int i = 0; i < 100; i++) {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('accounts')
      .add({
        'type': 'credit_card',
        'name': 'Kart $i',
        'balance': 0,
        // ... diğer fieldlar
      });
}
// 🎉 Free kullanıcı 100 kart ekledi!
```

---

## ✅ ÇÖZÜM

### Yaklaşım 1: Backend Cloud Function (ÖNERİLEN)
Kart oluşturmayı backend'e taşı, limitlPremium status kontrolünü orada yap.

```javascript
// functions/handlers/createCard.js
async function createCard(request) {
  const userId = request.auth.uid;
  const {type, name, balance, ...} = request.data;
  
  // Premium status kontrolü
  const userTier = await getUserTier(userId);
  
  // Mevcut kart sayısını al
  const accountsSnapshot = await db.collection('users')
      .doc(userId)
      .collection('accounts')
      .where('type', 'in', ['credit_card', 'debit_card'])
      .get();
  
  const currentCardCount = accountsSnapshot.size;
  
  // Limit kontrolü
  if (userTier === 'free' && currentCardCount >= 3) {
    throw new HttpsError(
        'resource-exhausted',
        'Free kullanıcılar maksimum 3 kart ekleyebilir. Premium\'a yükselt!',
    );
  }
  
  // Kartı oluştur
  await db.collection('users')
      .doc(userId)
      .collection('accounts')
      .add({
        user_id: userId,
        type: type,
        name: name,
        balance: balance,
        is_active: true,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
  
  return {success: true};
}
```

### Yaklaşım 2: Firestore Rules (KARMAŞIK)
Rules'da mevcut kart sayısını kontrol et (performans kaybı var).

```javascript
match /accounts/{accountId} {
  function canCreateCard() {
    let userId = request.auth.uid;
    let userData = get(/databases/$(database)/documents/users/$(userId)).data;
    let isPremium = userData.isPremium == true || userData.isPremiumPlus == true;
    
    if (isPremium) {
      return true; // Premium sınırsız
    }
    
    // Free kullanıcı için kart sayısını say
    let existingCards = existingData(/databases/$(database)/documents/users/$(userId)/accounts)
        .where('type', 'in', ['credit_card', 'debit_card'])
        .size();
    
    return existingCards < 3;
  }
  
  allow create: if canCreateCard();
  allow read, update, delete: if request.auth.uid == userId;
}
```

**SORUN:** Firestore rules'da `existingData()` yok, bu yaklaşım çalışmaz!

---

## 🎯 ÖNERİLEN ÇÖZÜM: Backend Cloud Function

### Adımlar:
1. ✅ `createCard` Cloud Function oluştur
2. ✅ `UnifiedProviderV2.createAccount()` metodunu backend'i çağıracak şekilde güncelle
3. ✅ Firestore rules'ı sıkılaştır (sadece backend yazabilir)
4. ✅ Hisse limiti için de aynı yaklaşım (free: max 3 hisse)

---

## 📊 MEVCUT LİMİTLER

| Özellik | Free | Premium | Premium Plus |
|---------|------|---------|--------------|
| Kart (Debit + Credit) | 3 | Sınırsız | Sınırsız |
| Hisse | 3 | Sınırsız | Sınırsız |
| AI (Günlük/Aylık) | 10/gün | 1500/ay | 3000/ay |
| Tasarruf Hedefi | 3 | Sınırsız | Sınırsız |
| Reklamlar | Var | Yok | Yok |

---

## ⚠️ ACİLİYET

**Orta Aciliyet:** 
- Premium field'ları kadar kritik değil (gelir kaybı direkt değil)
- Ama kullanıcı deneyimi ve sistem performansı için önemli
- Bazı kullanıcılar 100+ kart ekleyerek sistemi yavaşlatabilir

**Önerilen Aksiyon:**
1. Önce premium field güvenliği (✅ TAMAMLANDI)
2. Sonra kart/hisse limitleri (⏳ BU)
3. Sonra tasarruf hedefi limitleri

