class Validators {
  Validators._();

  static String? subjectCode(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Enter a subject code';
    }

    if (text.length > 20) {
      return 'Subject code is too long';
    }

    return null;
  }

  static String? subjectName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Enter a subject name';
    }

    if (text.length > 100) {
      return 'Subject name is too long';
    }

    return null;
  }

  static String? room(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Enter a room';
    }

    if (text.length > 50) {
      return 'Room name is too long';
    }

    return null;
  }

  static String? timeRange(int startMinutes, int endMinutes) {
    if (startMinutes < 0 || startMinutes >= 1440) {
      return 'Invalid start time';
    }

    if (endMinutes < 0 || endMinutes > 1440) {
      return 'Invalid end time';
    }

    if (endMinutes <= startMinutes) {
      return 'End time must be later than start time';
    }

    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Enter your email';
    }

    if (!text.contains('@') || !text.contains('.')) {
      return 'Enter a valid email';
    }

    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Enter your password';
    }

    if (text.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }
}
