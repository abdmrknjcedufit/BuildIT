typedef Validator = String? Function(String? value);

String? inputRequired(
  String? value, [
  String message = 'Ovo polje je obavezno.',
]) {
  return (value == null || value.trim().isEmpty) ? message : null;
}

String? emailFormat(String? value, [String message = 'Neispravan format email adrese.']) {
  if (value == null || value.trim().isEmpty) return null;
  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return regex.hasMatch(value) ? null : message;
}

String? password(String? value, [String? message]) {
  if (value == null || value.isEmpty) return null;
  final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');
  return regex.hasMatch(value)
      ? null
      : (message ??
            'Lozinka mora imati najmanje 8 karaktera, jedno veliko slovo, jedan broj i jedan simbol.');
}

String? minLength(String? value, int min, [String? message]) {
  if (value == null) return null;
  return value.length >= min
      ? null
      : (message ?? 'Minimum $min karaktera je potrebno.');
}

String? maxLength(String? value, int max, [String? message]) {
  if (value == null) return null;
  return value.length <= max
      ? null
      : (message ?? 'Maksimum $max karaktera je dozvoljeno.');
}

String formatDate(DateTime? date) {
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

String? phoneValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final trimmedValue = value.trim();
  
  final pattern = RegExp(r'^\+387[0-9]{8,10}$');
  if (!pattern.hasMatch(trimmedValue)) {
    return "Broj telefona mora počinjati sa +387 i imati 8 do 10 cifara bez znakova između (npr. +38761123456)";
  }

  return null;
}

