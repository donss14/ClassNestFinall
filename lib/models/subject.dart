class Subject {
  const Subject({
    this.id,
    required this.code,
    required this.name,
    this.instructor,
    required this.colorValue,
  });

  final int? id;
  final String code;
  final String name;
  final String? instructor;
  final int colorValue;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'instructor': instructor,
      'color_value': colorValue,
    };
  }

  factory Subject.fromMap(Map<String, Object?> map) {
    return Subject(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      instructor: map['instructor'] as String?,
      colorValue: map['color_value'] as int,
    );
  }

  Subject copyWith({
    int? id,
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