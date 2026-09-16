import 'installed_app.dart';

enum AppSortOption {
  name,
  size,
  installDate;

  String get label => switch (this) {
    AppSortOption.name => 'نام',
    AppSortOption.size => 'حجم',
    AppSortOption.installDate => 'تاریخ نصب',
  };

  List<InstalledApp> sort(List<InstalledApp> apps) {
    final List<InstalledApp> sorted = List.of(apps);
    switch (this) {
      case AppSortOption.name:
        sorted.sort(
          (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
        );
      case AppSortOption.size:
        sorted.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      case AppSortOption.installDate:
        sorted.sort((a, b) => b.firstInstallTime.compareTo(a.firstInstallTime));
    }
    return sorted;
  }
}
