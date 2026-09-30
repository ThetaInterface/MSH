enum ConfigFieldType {
    string,
    integer,
    boolean;

    bool isValid(dynamic value) {
        return switch (this) {
            .string => value is String,
            .integer => value is int,
            .boolean => value is bool
        };
    }
}