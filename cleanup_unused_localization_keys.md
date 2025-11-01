# Kullanılmayan Localization Keys Temizliği

## Bulunan 44 Kullanılmayan Key

Bu key'ler kod tabanında hiçbir yerde kullanılmıyor. Temizlenmeleri gerekiyor.

### Önerilen Yaklaşım

1. **AI Chat Key'leri** (3 adet) - AI chat refactor sırasında kullanımdan kaldırılmış
   - aiChatLastNDays
   - aiChatDeleteWarning  
   - aiChatDailyLimitReached

2. **Eski Hata Mesajları** (8 adet)
   - signUpError
   - unknownError (3 farklı versiyonu var!)
   - paymentProcessing
   - transactionAddError
   - installmentTransactionDeleteError
   - transactionError

3. **Eski Başarı Mesajları** (4 adet)
   - cashAdded
   - expenseSaved
   - incomeSaved
   - investmentSaved
   - automaticPaymentsCreated

4. **Zaman Format Key'leri** (9 adet) - Muhtemelen yeni bir format sistemine geçildi
   - minutesAgo, hoursAgo, secondsAgo
   - minutesAgoFull, hoursAgoFull, daysAgoFull
   - yesterdayAt, weekdayAt
   - timeMinutesAgo, timeHoursAgo, timeDaysAgo
   - dayMonth, dayMonthYear

5. **Note/Transaction Key'leri** (4 adet)
   - exampleExpenseNote
   - examplePhotoNote
   - viewAllNotes
   - noteAddedSuccess

6. **Transaction Count Key'leri** (5 adet)
   - totalTransactionsCount
   - incomeTransactionsCount
   - expenseTransactionsCount
   - transferTransactionsCount
   - stockTransactionsCount

7. **Diğer** (11 adet)
   - noSearchResultsDescription
   - lastDays
   - debtAmount
   - noMonthlyData
   - cannotRemoveStockWithPosition
   - monthlyPremiumOnly
   - percentDiscount
   - goalCompletedImpact

## Notlar

- `unknownError` key'i 3 farklı versiyonla tanımlı (tekrar eden key'ler)
- Bazı key'ler muhtemelen eski UI'dan kalmış
- Temizlik yapıldıktan sonra `flutter gen-l10n` çalıştırılmalı

