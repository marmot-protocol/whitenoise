import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/src/rust/api/users.dart' show User;

typedef UserSelectionState = ({
  List<User> selectedUsers,
  bool Function(User) isSelected,
  int selectedCount,
});

typedef UserSelectionActions = ({
  void Function(User) toggleUser,
  void Function(List<User>) setUsers,
  void Function() clearSelection,
});

({UserSelectionState state, UserSelectionActions actions}) useUserSelection({
  List<User>? initialUsers,
}) {
  final selectedUsers = useState<List<User>>(
    initialUsers != null ? List<User>.from(initialUsers) : [],
  );

  void toggleUser(User user) {
    final currentList = List<User>.from(selectedUsers.value);
    final index = currentList.indexWhere((u) => u.pubkey == user.pubkey);

    if (index >= 0) {
      currentList.removeAt(index);
    } else {
      currentList.add(user);
    }

    selectedUsers.value = currentList;
  }

  bool isSelected(User user) {
    return selectedUsers.value.any((u) => u.pubkey == user.pubkey);
  }

  void setUsers(List<User> users) {
    selectedUsers.value = users;
  }

  void clearSelection() {
    selectedUsers.value = [];
  }

  return (
    state: (
      selectedUsers: selectedUsers.value,
      isSelected: isSelected,
      selectedCount: selectedUsers.value.length,
    ),
    actions: (
      toggleUser: toggleUser,
      setUsers: setUsers,
      clearSelection: clearSelection,
    ),
  );
}
