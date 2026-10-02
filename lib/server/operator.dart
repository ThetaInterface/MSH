class Operator {
    final String name;
    final int level;

    Operator(this.name, this.level);

    factory Operator.fromJson(Map<String, dynamic> json) {
        return Operator(
            json['name'] as String? ?? '',
            json['level'] as int? ?? 0
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'name': name,
            'level': level
        };
    }
}