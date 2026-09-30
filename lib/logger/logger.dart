import 'dart:io';

import 'package:msh/logger/log_level.dart';
import 'package:msh/utils/file_ext.dart';
import 'package:msh/global.dart' as g;

export 'package:msh/logger/log_level.dart';

class Logger {
    static Future log(String content, LogLevel level) async {
        final logFile = File(g.logFilePath);

        if (await logFile.exists() && g.config.getValue(.logRotation)) {
            final lineCount = (await logFile.readAsLines()).length;

            if (lineCount > g.config.getValue(.logRotationLimit)) {
                await logFile.write('');
            }
        }

        final message = '${DateTime.now()}: [${level.toString()}] $content\n';

        await logFile.write(message, append: true);   
    }
}