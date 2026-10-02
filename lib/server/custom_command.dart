class CustomCommand {
    final String command;
    final List<String> actions;
    final int level;
    final bool autostart;

    CustomCommand(this.command, this.actions, this.level, this.autostart);

    factory CustomCommand.fromJson(Map<String, dynamic> json) {
        return CustomCommand(
            json['command'] as String? ?? '',
            List<String>.from(json['actions']),
            json['level'] as int? ?? 0,
            json['autostart'] as bool? ?? false
        );
    }
}