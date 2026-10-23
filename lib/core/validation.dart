class AppValidators {
  AppValidators._();

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full Name is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters.';
    }
    if (trimmed.length > 60) {
      return 'Name cannot exceed 60 characters.';
    }
    if (!RegExp(r"^[a-zA-Z\s\.\'\-]+$").hasMatch(trimmed)) {
      return 'Name should contain letters and spaces only.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address (e.g. user@example.com).';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Enter a valid 10 to 15-digit phone number.';
    }
    return null;
  }

  static String? validateFoodName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Food name is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Food name must be at least 3 characters.';
    }
    if (trimmed.length > 100) {
      return 'Food name cannot exceed 100 characters.';
    }
    return null;
  }

  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity / Servings is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length > 50) {
      return 'Quantity description is too long (max 50 characters).';
    }
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP code is required.';
    }
    final cleaned = value.trim();
    if (cleaned.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(cleaned)) {
      return 'Enter a valid 6-digit numeric OTP code.';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }
}
