import 'package:flutter/widgets.dart';

class KeepAlivePage extends StatefulWidget {
  final Widget child;
  final Key? storageKey; // optional, falls du’s später brauchen willst

  const KeepAlivePage({super.key, required this.child, this.storageKey});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin<KeepAlivePage> {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // wichtig für KeepAlive!
    // Kein PageStorage() mehr -> kein bucket nötig.
    // Optional: mit KeyedSubtree den storageKey an den Subtree hängen
    return widget.storageKey == null
        ? widget.child
        : KeyedSubtree(key: widget.storageKey, child: widget.child);
  }
}
