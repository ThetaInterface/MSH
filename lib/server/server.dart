import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

import 'package:msh/global.dart' as g;

import 'package:msh/logger/logger.dart';
import 'package:msh/utils/stdout_ext.dart';
import 'package:msh/utils/file_ext.dart';
import 'package:msh/server/task.dart';
import 'package:msh/server/operator.dart';
import 'package:msh/server/custom_command.dart';

export 'package:msh/server/task.dart';
export 'package:msh/server/operator.dart';
export 'package:msh/server/custom_command.dart';

class Server {
    static late Process _process;
    static late Stream<String> _serverStdout;
    static late Completer _serverExit;

    static Stream<List<int>>? _stdinBroadcast;
    static Completer? _stdinCompleter;

    static final List<String> _stdoutLines = [];
    static final _userInput = StringBuffer();

    static final List<(Task, List<String>)> _heavyTaskPull = [];
    static final List<(Task, List<String>)> _lightTaskPull = [];
    static Task? _runningTask;

    static bool _isInitialized = false;
    static bool _isRestarting = false;

    static int _uptime = 0;


    static bool get isInitialized => _isInitialized;
    static bool get isRestarting => _isRestarting; 

    static void _cleanup() {
        _uptime = 0;

        _isRestarting = false;
        _isInitialized = false;

        _runningTask = null;
        _heavyTaskPull.removeRange(0, _heavyTaskPull.length);
        _lightTaskPull.removeRange(0, _heavyTaskPull.length);
        _stdoutLines.removeRange(0, _stdoutLines.length);
        _userInput.clear();

        _stdinCompleter = null;
    }

    static Future init() async {
        _cleanup();

        _process = await Process.start(
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

        _process.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) async => await Logger.log('Error while initializing server -> $line', .error));

        _serverStdout = _process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .asBroadcastStream();

        bool err = false;
        final completer = Completer<void>();
        late final StreamSubscription<String> initializing;

        Timer? timer;

        void onTimeout() async {
            if (!completer.isCompleted) completer.complete();
        }

        timer = Timer(const Duration(seconds: 10), onTimeout);

        initializing = _serverStdout.listen((line) {
            _printLine(line);

            timer?.cancel();
            timer = Timer(const Duration(seconds: 10), onTimeout);
        }, onDone: () async {
            await Logger.log('Unexpected java process termination. See minecraft server logs.', LogLevel.fatal);
            
            err = true;
        }, onError: (e) async {
            await Logger.log('Unexpected java process termination -> $e', .fatal);

            err = true;
        });

        await completer.future;
        await initializing.cancel();

        if (!err) {
            _isInitialized = true;

            _printLine(_serverThreadMessage('Initialized.'));

            final customCommands = await _getCustomCommands();

            for (var command in customCommands.where((e) => e.autostart)) {
                for (var action in command.actions) {
                    _process.stdin.writeln(action);

                    await Future.delayed(const Duration(milliseconds: 100));
                }
            }
        }
    }

    static Future maintain() async {
        if (_isInitialized) {
            _serverExit = Completer<void>();

            final customCommandPrefix = g.config.getValue(.customCommandPrefix) as String;

            final maintain = _serverStdout.listen((line) {
                _printLine(line);

                if (line.contains('[Not Secure] <')) {
                    final messageContent = line.split('>').last.trim();
                    final playerName = line.split('>').first.split('<').last.trim();

                    if (messageContent.startsWith(customCommandPrefix)) {
                        _processCommand(messageContent, customCommandPrefix, playerName);
                    }
                }
            });

            _inputHandler();
            _autoRestartHandler();

            await _serverExit.future;
            await maintain.cancel();
        }
    }

    static Future stop() async {
        if (_isInitialized) {
            final stoping = _serverStdout.listen((line) => stdout.writeln(line));

            _process.stdin.writeln('stop');

            await _process.exitCode;
            await stoping.cancel();

            _serverExit.complete();
            _stdinCompleter?.complete();

            _isInitialized = false;
            _runningTask = null;
        }
    }

    static void _inputHandler() async {
        _stdinBroadcast ??= stdin.asBroadcastStream();
        _stdinCompleter ??= Completer<void>();

        final customCommandPrefix = g.config.getValue(.customCommandPrefix) as String;

        final sub = _stdinBroadcast?.listen((List<int> bytes) {
            String char = utf8.decode(bytes);

            if (bytes.length == 1 && (bytes.first == 8 || bytes.first == 127)) {
                if (_userInput.isNotEmpty) {
                    stdout.write('\b \b');

                    final oldWord = _userInput.toString();

                    _userInput.clear();
                    _userInput.write(oldWord.substring(0, oldWord.length - 1));
                }

                return;
            }

            if (char == '\n' || char == '\r') {
                final currentWord = _userInput.toString().trim();

                _userInput.clear();
                _printLine(currentWord);

                if (currentWord.startsWith(customCommandPrefix)) {
                    _processCommand(currentWord, customCommandPrefix, 'admin', admin: true);
                } else {
                    _process.stdin.writeln(currentWord);
                }

                return;
            } else {
                stdout.write(char);
                _userInput.write(char);
            }
        });

        await _stdinCompleter?.future;
        await sub?.cancel();

        _userInput.clear();
    }

    static void _autoRestartHandler() async {
        final timeToRestart = g.config.getValue(.autoRestartSeconds) as int;

        while (!_serverExit.isCompleted) {
            await Future.delayed(const Duration(seconds: 1));

            _uptime += 1;

            final toRestart = timeToRestart - _uptime;
            if (toRestart == 1800 || toRestart == 900 || toRestart == 300 || toRestart == 60 || (toRestart <= 10 && toRestart > 0)) {
                _process.stdin.writeln(_restartAfterMessage(_secondsToFormatTime(toRestart)));
            }

            if (toRestart == 0) {
                _process.stdin.writeln('/title @a actionbar {"text":"Перезагрузка!","color":"red","bold":true}');

                _addHeavyTask((.restart, []));
            }
        }
    }

    static String _secondsToFormatTime(int seconds) {
        final hours = (seconds / 3600).truncate();
        final minutes = (seconds % 3600 / 60).truncate();
        final newSeconds = seconds % 60;

        return ((hours > 0 ? '${_numberToTime(hours)}:' : '00:') +
            (minutes > 0 ? '${_numberToTime(minutes)}:' : '00:') + 
            (newSeconds > 0 ? _numberToTime(newSeconds) : '00')).trim();
    }

    static String _numberToTime(int number) {
        if (number < 10) {
            return '0$number';
        } else {
            return number.toString();
        }
    }

    static void _heavyProcessor() async {
        while (_heavyTaskPull.isNotEmpty && !_serverExit.isCompleted) {
            if (_runningTask == null) {
                final nextTask = _heavyTaskPull.first;

                _printLine(_serverThreadMessage('Running heavy task -> ${nextTask.toString()}'));

                if (nextTask.$1 == .stop) {
                    _runningTask = .stop;

                    stop();
                } else if (nextTask.$1 == .restart) {
                    _runningTask = .restart;

                    _isRestarting = true;
                    stop();
                }

                _heavyTaskPull.remove(nextTask);
            }

            await Future.delayed(const Duration(milliseconds: 100));
        }
    }

    static void _lightProcessor() async {
        while (_lightTaskPull.isNotEmpty && !_serverExit.isCompleted) {
            final nextTask = _lightTaskPull.first;

            _printLine(_serverThreadMessage('Running light task -> ${nextTask.toString()}'));

            if (nextTask.$1 == Task.ttr) {
                final restartSeconds = g.config.getValue(.autoRestartSeconds);
                final toRestart = _secondsToFormatTime(restartSeconds - _uptime);

                _process.stdin.writeln(_restartAfterMessage(toRestart));
                _printLine(_serverThreadMessage('Restart in $toRestart'));
            }

            _lightTaskPull.remove(nextTask);

            await Future.delayed(const Duration(milliseconds: 100));
        }
    }

    static void _addHeavyTask((Task, List<String>) task) {
        _heavyTaskPull.add(task);

        _heavyProcessor();
    }

    static void _addLightTask((Task, List<String>) task) {
        _lightTaskPull.add(task);

        _lightProcessor();
    }

    static void _processCommand(String command, String commandPrefix, String playerName, { bool admin = false }) async {
        final parts = command.split(' ');
        final mainPart = parts.first.replaceFirst(RegExp(commandPrefix), '');

        final task = Task.from(mainPart);

        if (task != null) {
            if (!admin) {
                if (!await _doPlayerHaveRights(playerName, task.adminLevel())) {
                    return;
                }
            }

            if (task.isHeavy()) {
                _addHeavyTask((task, parts..removeAt(0)));
            } else {
                _addLightTask((task, parts..removeAt(0)));
            }
        } else {
            final customCommands = await _getCustomCommands();

            if (customCommands.any((e) => e.command == mainPart)) {
                final customCommand = customCommands.firstWhere((e) => e.command == mainPart);

                if (!admin) {
                    if (!await _doPlayerHaveRights(playerName, customCommand.level)) {
                        return;
                    }
                }

                for (var action in customCommand.actions) {
                    _process.stdin.writeln(action);

                    await Future.delayed(const Duration(milliseconds: 100));
                }
            }
        }
    }

    static Future<bool> _doPlayerHaveRights(String playerName, int level) async {
        if (level > 0) {
            final opsFile = File(g.opsFilePath);
            final content = await opsFile.read();

            if (content != null) {
                try {
                    final List<dynamic> opsJson = jsonDecode(content);

                    final ops = opsJson.map((e) => Operator.fromJson(Map<String, dynamic>.from(e))).toList();
                    final op = ops.firstWhere((o) => o.name == playerName);

                    if (op.level < level) {
                        return false;
                    }
                } on StateError catch (_) {
                    return false;
                } 
                catch (e, stack) {
                    await Logger.log('Unable to decode ops list -> $e: $stack', LogLevel.error);

                    return false;
                }

            } else {
                return false;
            }
        }

        return true;
    }

    static Future<List<CustomCommand>> _getCustomCommands() async {
        final customCommandsFile = File(g.customCommandsPath);

        final content = await customCommandsFile.read();

        if (content != null) {
            try {
                final List<dynamic> list = jsonDecode(content);

                return list.map((e) => CustomCommand.fromJson(e as Map<String, dynamic>)).toList();
            } catch (e, stack) {
                await Logger.log('Unable to decode custom commands file -> $e: $stack', LogLevel.error);

                return [];
            }
        } else { 
            return [];
        }
    }

    static void _printLine(String line) {
        stdout.clearScreen();

        if (_stdoutLines.length >= 150) {
            _stdoutLines.removeAt(0);
        }

        _stdoutLines.add(line);

        _stdoutLines.forEach(stdout.writeln);
        stdout.write(_userInput.toString());
    }

    static String _serverThreadMessage(String message) {
        return '[${DateFormat('HH:mm:ss').format(DateTime.now())}] [Server thread/INFO]: $message';
    }

    static String _restartAfterMessage(String after) {
        return '/title @a actionbar {"text":"Перезагрузка через: ","color":"gray","extra":[{"text":"$after","color":"red","bold":true}]}';
    }
}