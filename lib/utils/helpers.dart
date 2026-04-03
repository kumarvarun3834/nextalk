import '../auth/auth_service.dart';
import '../models/user_model.dart';

class AppServices {
  static final auth = AuthService();
  static final firestore = FirestoreService();
  // static final storage = StorageService();
  // static final notifications = NotificationService();
}

final fs = AppServices.firestore;
final auth = AppServices.auth;