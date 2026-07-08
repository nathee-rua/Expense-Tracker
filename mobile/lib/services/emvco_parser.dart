class EmvcoParser {
  /// Parses a raw EMVCo PromptPay QR string and extracts the transaction amount and metadata.
  /// Standard PromptPay tags:
  /// Tag 54: Amount (format: 54[length][value], e.g., 5406120.00 for 120.00 THB)
  /// Tag 58: Country Code (usually 5802TH)
  /// Tag 53: Currency Code (usually 5303764 for THB)
  static Map<String, dynamic>? parse(String rawText) {
    final cleanText = rawText.trim();
    if (!cleanText.contains("000201")) {
      return null; // Not a valid EMVCo payload format
    }

    double? amount;
    String? countryCode;
    String? currency;
    String? refId;

    try {
      int index = 0;
      while (index < cleanText.length - 4) {
        final tag = cleanText.substring(index, index + 2);
        final lengthStr = cleanText.substring(index + 2, index + 4);
        final length = int.tryParse(lengthStr) ?? 0;
        
        if (index + 4 + length > cleanText.length) break;
        
        final value = cleanText.substring(index + 4, index + 4 + length);

        if (tag == '54') {
          amount = double.tryParse(value);
        } else if (tag == '58') {
          countryCode = value;
        } else if (tag == '53') {
          currency = value == '764' ? 'THB' : value;
        } else if (tag == '62') {
          // Additional Data Field (frequently contains Ref ID / Invoice number)
          refId = _extractRefIdFromTag62(value);
        } else if (tag == '30' || tag == '29') {
          // Merchant Info - often contains bill payment details
          refId ??= _extractRefIdFromMerchantInfo(value);
        }

        index += 4 + length;
      }
    } catch (e) {
      print("Error parsing EMVCo string: $e");
    }

    if (amount == null) {
      return null;
    }

    return {
      'amount': amount,
      'currency': currency ?? 'THB',
      'country': countryCode ?? 'TH',
      'refId': refId ?? 'PromptPay-Ref',
      'isPromptPay': true
    };
  }

  static String? _extractRefIdFromTag62(String value) {
    try {
      int idx = 0;
      while (idx < value.length - 4) {
        final subTag = value.substring(idx, idx + 2);
        final subLenStr = value.substring(idx + 2, idx + 4);
        final subLen = int.tryParse(subLenStr) ?? 0;
        if (idx + 4 + subLen > value.length) break;

        final subVal = value.substring(idx + 4, idx + 4 + subLen);
        if (subTag == '01' || subTag == '05') {
          return subVal; // Bill Reference or Reference ID
        }
        idx += 4 + subLen;
      }
    } catch (_) {}
    return null;
  }

  static String? _extractRefIdFromMerchantInfo(String value) {
    // Basic heuristics to extract payment reference from merchant structures
    if (value.length > 8) {
      return value.substring(value.length - 8);
    }
    return null;
  }
}
