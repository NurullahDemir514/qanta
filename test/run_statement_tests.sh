#!/bin/bash

echo "🧪 Running Statement Calculation Tests..."
echo "=========================================="

# Unit tests
echo "📋 Running Unit Tests..."
flutter test test/statement_calculation_test.dart

echo ""
echo "🔗 Running Integration Tests..."
flutter test test/integration/statement_integration_test.dart

echo ""
echo "✅ All tests completed!"
echo "=========================================="
