import 'reference_item.dart';

final class ReferencePage {
  const ReferencePage({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  final List<ReferenceItem> items;
  final int page;
  final bool hasMore;
}
