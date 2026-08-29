import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/recent_tools_repository.dart';

class RecentToolsCubit extends Cubit<List<String>> {
  RecentToolsCubit(this._repository) : super(_repository.getRecentIds());

  final RecentToolsRepository _repository;

  Future<void> recordUsed(String toolId) async {
    final List<String> updated = List<String>.from(state)..remove(toolId);
    updated.insert(0, toolId);
    if (updated.length > RecentToolsRepository.maxItems) {
      updated.removeRange(RecentToolsRepository.maxItems, updated.length);
    }
    emit(updated);
    await _repository.saveRecentIds(updated);
  }
}
