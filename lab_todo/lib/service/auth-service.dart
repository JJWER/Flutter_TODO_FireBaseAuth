import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  Future<String> reqistration({
    required String email,
    required String password,
    required String confirm,
  }) async {
    // ตรวจสอบรหัสผ่าน
    if (password != confirm) {
      return 'Passwords do not match';
    }

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> signin({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    } catch (e) {
      return e.toString();
    }
  }
}
