// // File: test/fake_widget_ref.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// /// Riverpod の WidgetRef のシグネチャに合わせたテスト用 FakeWidgetRef の実装例です。
// class FakeWidgetRef implements WidgetRef {
//   final ProviderContainer container;
//   FakeWidgetRef(this.container);
//
//   @override
//   T read<T>(ProviderListenable<T> provider) => container.read(provider);
//
//   @override
//   T watch<T>(ProviderListenable<T> provider) => container.read(provider);
//
//   // refresh のパラメータ型は Refreshable<T> である必要があります。
//   @override
//   T refresh<T>(Refreshable<T> provider) => container.refresh(provider);
//
//   // invalidate と exists では、provider を ProviderBase<Object?> にキャストして渡します。
//   @override
//   void invalidate(ProviderOrFamily provider) =>
//       container.invalidate(provider as ProviderBase<Object?>);
//
//   @override
//   bool exists(ProviderOrFamily provider) =>
//       container.exists(provider as ProviderBase<Object?>);
//
//   @override
//   ProviderSubscription<T> listen<T>(
//       ProviderListenable<T> provider,
//       void Function(T? previous, T next) listener, {
//         bool fireImmediately = false,
//         void Function(Object, StackTrace)? onError,
//       }) {
//     return container.listen(
//       provider,
//       listener,
//       fireImmediately: fireImmediately,
//       onError: onError,
//     );
//   }
//
//   @override
//   ProviderSubscription<T> listenManual<T>(
//       ProviderListenable<T> provider,
//       void Function(T? previous, T next) listener, {
//         bool fireImmediately = false,
//         void Function(Object, StackTrace)? onError,
//       }) {
//     return container.listen(
//       provider,
//       listener,
//       fireImmediately: fireImmediately,
//       onError: onError,
//     );
//   }
//
//   @override
//   bool get mounted => true;
//
//   @override
//   BuildContext get context => throw UnimplementedError();
// }
