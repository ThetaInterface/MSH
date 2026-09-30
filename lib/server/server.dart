import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:msh/global.dart' as g;

class Server {
    static late final Process process;

    static bool _isInitialized = false;

    static Future init() async {
        process = await Process.start(
            g.config.getValue(.javaPath),
            (g.config.getValue(.javaArgs) as String)
                .split(' ')
                ..addAll(
                    [
                        '-jar',
                        path.join(g.programPath, g.config.getValue(.serverExeFileName)),
                        'nogui'
                    ]
                )
        );

        final completer = Completer<void>();
        late StreamSubscription<String> initializing;
        
        Timer? timer;

        void onTimeout() async {
            if (!completer.isCompleted) completer.complete();
        }

        timer = Timer(const Duration(seconds: 15), onTimeout);

        initializing = process.stdout
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .listen((line) {
                print(line);

                timer?.cancel();
                timer = Timer(const Duration(seconds: 10), onTimeout);
            }, onDone: () {
                timer?.cancel();

                if (!completer.isCompleted) completer.complete();
            });

        await completer.future;

        await initializing.cancel();
        _isInitialized = true;
    }
}