
class Subject {
  const Subject({
    this.id,
    required this.code,
    required this.name,
    this.instructor,
    required this.colorValue,
  });

  // Firestore document ID
  final String? id;

  final String code;
  final String name;
  final String? instructor;
  final int colorValue;

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'instructor': instructor,
      'colorValue': colorValue,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map, {String? id}) {
    return Subject(
      id: id ?? map['id'] as String?,
      code: map['code'] as String,
      name: map['name'] as String,
      instructor: map['instructor'] as String?,
      colorValue: map['colorValue'] as int,
    );
  }

  Subject copyWith({
    String? id,
    String? code,
    String? name,
    String? instructor,
    int? colorValue,
  }) {
    return Subject(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      instructor: instructor ?? this.instructor,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
