enum ConfigProperty {
    serverExeFileName,
    javaPath,
    javaArgs,
    autoRestartSeconds,
    customCommandPrefix,
    logRotation,
    logRotationLimit;

    static ConfigProperty? from(String str) {
        return switch (str) {
            'serverExeFileName' => .serverExeFileName,
            'javaPath' => .javaPath,
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
            .javaPath => 'javaPath',
            .javaArgs => 'javaArgs',
            .autoRestartSeconds => 'autoRestartSeconds',
            .customCommandPrefix => 'customCommandPrefix',
            .logRotation => 'logRotation',
            .logRotationLimit => 'logRotationLimit'
        };
    }
}