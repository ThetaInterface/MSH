import 'package:msh/global.dart' as g;
import 'package:msh/server/server.dart';

void main() async {
    await g.init();

    await Server.init();
}
