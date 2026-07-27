import 'reference_item.dart';
import 'reference_item_edit.dart';
import 'reference_page.dart';

abstract interface class ReferenceRepository {
  Future<ReferencePage> fetchPage({required int page, required int pageSize});

  Future<ReferenceItem> fetchById(String id);

  Future<ReferenceItem> save(ReferenceItemEdit edit);
}
