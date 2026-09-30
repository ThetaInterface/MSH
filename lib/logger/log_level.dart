enum LogLevel {
    log,
    warning,
    error,
    fatal;

    @override
    String toString() {
        return switch (this) {
            LogLevel.log => "LOG",
            LogLevel.warning => "WARN",
            LogLevel.error => "ERROR",
            LogLevel.fatal => "FATAL"
        };
    }
}