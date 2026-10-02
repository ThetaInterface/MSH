import 'dart:io';

extension StdoutExtension on Stdout {
    void clearScreen() {
        write('\x1B[2J\x1B[0;0H');
    }
}