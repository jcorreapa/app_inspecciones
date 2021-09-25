import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Custom ValueListenable que se construye en base a dos valores.
class MultiValueListenableBuilder<A, B> extends StatelessWidget {
  const MultiValueListenableBuilder(
    this.first,
    this.second, {
    Key? key,
    required this.builder,
    this.child = const SizedBox.shrink(), //TODO: revisar esto del child
  }) : super(key: key);

  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget child;
  final Widget Function(BuildContext context, A a, B b, Widget child) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (_, a, __) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, __) {
            return builder(context, a, b, child);
          },
        );
      },
    );
  }
}