import 'package:flutter/material.dart';

class Clock extends StatelessWidget {
  const Clock({
    this.style,
    this.showSeconds = false,
    super.key,
  });

  final TextStyle? style;
  final bool showSeconds;

  Stream<DateTime> _dateTimeStream() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      yield DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _dateTimeStream(),
      builder: (context, snapshot) {
        String hours = snapshot.data?.hour.toString().padLeft(2, "0") ?? "00";
        String minutes =
            snapshot.data?.minute.toString().padLeft(2, "0") ?? "00";
        String seconds =
            snapshot.data?.second.toString().padLeft(2, "0") ?? "00";

        return Text(
          "$hours:$minutes${showSeconds ? ":$seconds" : ""}",
          style: style,
        );
      },
    );
  }
}
