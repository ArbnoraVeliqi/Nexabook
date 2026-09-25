import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String title, subtitle;
  final Widget? action;
  const PageHeader(this.title, this.subtitle, {super.key, this.action});
  @override
  Widget build(BuildContext c) => Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(c)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(subtitle)
        ])),
        if (action != null) action!
      ]);
}
