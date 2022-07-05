import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User _userFromFirebase(User? user){
    //return (user != null) ? user : null;
    return user!;
  }

  Stream<User> get user {
    return _auth.authStateChanges().map(_userFromFirebase);
  }

  Future signInAnon() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      User user = userCredential.user!;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> registerUserWithMailAndPass(String mail, String pass) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: mail, password: pass);
      User user = userCredential.user!;
      if (userCredential.toString().isNotEmpty){
        //_setLogEvent("Registered_successfully", mail, user, pass);
        //showAlertDialog("Registered Successfully!", "Welcome $user", "/welcome");
        //Navigator.pushNamed(context, '/welcome');
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> loginUserWithMailAndPass(String mail, String pass) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: mail, password: pass);
      User user = userCredential.user!;
      if (userCredential.toString().isNotEmpty){
        //_setLogEvent("Registered_successfully", mail, user, pass);
        //showAlertDialog("Registered Successfully!", "Welcome $user", "/welcome");
        //Navigator.pushNamed(context, '/welcome');
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }

  }

}