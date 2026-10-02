enum Task {
    stop,
    restart,
    ttr;

    bool isHeavy() {
        switch (this) {
            case stop:
            case restart:
                return true;

            case _:
                return false;
        }
    }

    int adminLevel() {
        switch (this) {
            case stop:
            case restart:
                return 4;
            
            case _:
                return 0;
        }
    }

    static Task? from(String str) {
        return switch (str) {
            'stop' => .stop,
            'restart' => .restart,
            'ttr' => .ttr,

            _ => null
        };
    }
}