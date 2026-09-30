enum ConfigProperty {
    serverExeFileName,
    javaArgs,
    autoRestartSeconds,
    customCommandPrefix,
    logRotation,
    logRotationLimit;

    static ConfigProperty? from(String str) {
        return switch (str) {
            'serverExeFileName' => .serverExeFileName,
            'javaArgs' => .javaArgs,
            'autoRestartSeconds' => .autoRestartSeconds,
            'customCommandPrefix' => .customCommandPrefix,
            'logRotation' => .logRotation,
            'logRotationLimit' => .logRotationLimit,

            _ => null
        };
    }

    @override
    String toString() {
        return switch (this) {
            .serverExeFileName => 'serverExeFileName',
            .javaArgs => 'javaArgs',
            .autoRestartSeconds => 'autoRestartSeconds',
            .customCommandPrefix => 'customCommandPrefix',
            .logRotation => 'logRotation',
            .logRotationLimit => 'logRotationLimit'
        };
    }
}