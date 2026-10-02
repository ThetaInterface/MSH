import 'dart:io';

import 'package:msh/global.dart' as g;
import 'package:msh/server/server.dart';

void main() async {
    setup();

    await g.init();

    do {
        await Server.init();

        if (Server.isInitialized) {
            await Server.maintain();
        }
    } while (Server.isRestarting);

    cleanup();

    exit(0);
}

void setup() {
    stdin.lineMode = false;
    stdin.echoMode = false;

    ProcessSignal.sigint.watch().listen((signal) {
        cleanup();
        exit(2);
    });

    if (!Platform.isWindows) {
        ProcessSignal.sigterm.watch().listen((signal) {
            cleanup();
            exit(15);
        });
    }
}

void cleanup() {
    stdin.lineMode = true;
    stdin.echoMode = true;
}
