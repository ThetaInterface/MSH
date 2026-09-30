import 'dart:io';

import 'package:msh/config/config.dart';
import 'package:msh/utils/file_ext.dart';
import 'package:path/path.dart' as path;

final String programPath = Platform.script.toFilePath().endsWith('.dart') ?
    "/home/alpha/temp/server_test/body/" // debug
    : path.dirname(Platform.resolvedExecutable);

final String mshDirectoryPath = path.join(programPath, 'msh');

final String configPath = path.join(mshDirectoryPath, 'config.ini');
final String customCommandsPath = path.join(mshDirectoryPath, 'custom_commands.json');

final String logFilePath = path.join(mshDirectoryPath, 'log.txt');

late final Config currentConfig;

Future init() async {
    Directory mshDir = Directory(mshDirectoryPath);

    if (!await mshDir.exists()) {
        await mshDir.create(recursive: true);
    }


    final configFile = File(configPath);
    final configFileContent = await configFile.readJson();

    if (!await configFile.exists() || configFileContent == null) {
        await configFile.writeJson(
            Config.defaultConfig.map(
                (key, value) => MapEntry(key.toString(), value)
            ), 
            indent: true
        );

        currentConfig = Config(fields: {}).repair();
    } else {
        currentConfig = Config.fromJson(configFileContent).repair();
    }

    await configFile.writeJson(currentConfig.toJson(), indent: true);
}