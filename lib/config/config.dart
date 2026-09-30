import 'package:msh/config/config_field_type.dart';
import 'package:msh/config/config_property.dart';

export 'package:msh/config/config_property.dart';
export 'package:msh/config/config_field_type.dart';

class Config {
    static const Map<ConfigProperty, dynamic> defaultConfig = {
        .serverExeFileName: 'server.jar',
        .javaPath: 'java',
        .javaArgs: '',
        .autoRestartSeconds: 43200,
        .customCommandPrefix: '.',
        .logRotation: true,
        .logRotationLimit: 1000
    };

    static const Map<ConfigProperty, ConfigFieldType> fieldTypes = {
        .serverExeFileName: .string,
        .javaPath: .string,
        .javaArgs: .string,
        .autoRestartSeconds: .integer,
        .customCommandPrefix: .string,
        .logRotation: .boolean,
        .logRotationLimit: .integer
    };

    final Map<ConfigProperty, dynamic> fields;

    Config({ required this.fields });

    dynamic getValue(ConfigProperty property) {
        if (fields.containsKey(property)) {
            return fields[property];
        } else {
            return defaultConfig[property];
        }
    }

    Config repair() {
        final List<MapEntry<ConfigProperty, dynamic>> entries = fields.entries.toList();

        for (var property in defaultConfig.keys) {
            if (!fields.containsKey(property)) {
                entries.add(MapEntry(property, defaultConfig[property]));
            }
        } 

        return Config(fields: Map.fromEntries(entries));
    }

    factory Config.fromJson(Map<String, dynamic> json) {
        final List<MapEntry<ConfigProperty, dynamic>> entries = [];

        for (var entry in json.entries) {
            final property = ConfigProperty.from(entry.key);

            if (property != null) {
                final value = entry.value;

                if (fieldTypes[property]!.isValid(value)) {
                    entries.add(MapEntry(property, value));
                } else {
                    entries.add(MapEntry(property, defaultConfig[property]!));
                }
            }
        }

        return Config(fields: Map.fromEntries(entries)).repair();
    }

    Map<String, dynamic> toJson() {
        return fields.map((key, value) => MapEntry(key.toString(), value));
    }
}