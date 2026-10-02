enum ConfigProperty {
    serverExeFileName,
    javaPath,
    javaArgs,
    autoRestartSeconds,
    customCommandPrefix,
    logRotation,
    logRotationLimit,
    initializationTimeout;

    static ConfigProperty? from(String str) {
        return switch (str) {
            'serverExeFileName' => .serverExeFileName,
            'javaPath' => .javaPath,
            'javaArgs' => .javaArgs,
            'autoRestartSeconds' => .autoRestartSeconds,
            'customCommandPrefix' => .customCommandPrefix,
            'logRotation' => .logRotation,
            'logRotationLimit' => .logRotationLimit,
            'initializationTimeout' => initializationTimeout,

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
            .logRotationLimit => 'logRotationLimit',
            .initializationTimeout => 'initializationTimeout'
        };
    }
}