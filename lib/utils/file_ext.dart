import 'dart:io';
import 'dart:convert';

import 'package:msh/logger/logger.dart';

extension SaveRWExtension on File {
    Future<String?> read() async {
        if (await exists()) {
            return await readAsString();
        } else {
            return null;
        }
    }

    Future write(String content, { bool append = false }) async {
        writeAsString(
            content, 
            mode: append ?
                FileMode.writeOnlyAppend
                : FileMode.writeOnly
        );
    }
}

extension JsonExtenstion on File {
    Future<Map<String, dynamic>?> readJson() async {
        final content = await read();

        if (content == null) {
            return null;
        }

        try {
            return jsonDecode(content);
        } catch (e, stack) {
            Logger.log('while reading json from \'$path\' => $e: $stack', LogLevel.error);

            return null;
        }
    }

    Future writeJson(Map<String, dynamic> json, { bool indent = true }) async {
        try {
            if (indent) {
                await writeAsString(encodeWithIndent(json));
            } else {
                await writeAsString(jsonEncode(json));
            }
        } catch (e, stack) {
            Logger.log('while writing json to \'$path\' => $e: $stack', LogLevel.error);
        }
    }

    String encodeWithIndent(Map<String, dynamic> json) => JsonEncoder.withIndent('    ').convert(json);
}