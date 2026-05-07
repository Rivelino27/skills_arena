import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabNavState {
  final int currentIndex;
  final List<int> history;

  const TabNavState({this.currentIndex = 0, this.history = const [0]});

  TabNavState copyWith({int? currentIndex, List<int>? history}) {
    return TabNavState(
      currentIndex: currentIndex ?? this.currentIndex,
      history: history ?? this.history,
    );
  }
}

class TabNavNotifier extends StateNotifier<TabNavState> {
  TabNavNotifier() : super(const TabNavState());

  void selectTab(int index) {
    if (index == state.currentIndex) return;
    final history = List<int>.from(state.history);
    if (history.last != index) {
      if (history.contains(index) && index != 0) {
        history.remove(index);
      }
      history.add(index);
      _removeConsecutiveDuplicates(history);
    }
    state = TabNavState(currentIndex: index, history: history);
  }

  bool stepBack() {
    if (state.history.length > 1) {
      final history = List<int>.from(state.history);
      history.removeLast();
      _removeConsecutiveDuplicates(history);
      state = TabNavState(currentIndex: history.last, history: history);
      return true;
    }
    if (state.currentIndex != 0) {
      state = const TabNavState();
      return true;
    }
    return false;
  }

  void reset() {
    state = const TabNavState();
  }

  static void _removeConsecutiveDuplicates(List<int> history) {
    for (int i = history.length - 1; i > 0; i--) {
      if (history[i] == history[i - 1]) {
        history.removeAt(i);
      }
    }
  }
}

final tabNavProvider =
    StateNotifierProvider<TabNavNotifier, TabNavState>((ref) {
  return TabNavNotifier();
});
