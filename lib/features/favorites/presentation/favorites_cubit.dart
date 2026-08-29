import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/favorites_repository.dart';

class FavoritesCubit extends Cubit<Set<String>> {
  FavoritesCubit(this._repository) : super(_repository.getFavoriteIds());

  final FavoritesRepository _repository;

  bool isFavorite(String toolId) => state.contains(toolId);

  Future<void> toggle(String toolId) async {
    final Set<String> updated = Set<String>.from(state);
    if (!updated.remove(toolId)) {
      updated.add(toolId);
    }
    emit(updated);
    await _repository.saveFavoriteIds(updated);
  }
}
