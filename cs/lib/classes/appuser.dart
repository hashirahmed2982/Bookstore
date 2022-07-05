import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs/classes/book.dart';

class AppUser {
  String email = "";
  String username = "";
  String _password = "";
  String _uid = "";
  List<Book> books = [];

  void getData (FirebaseAuth a) async {
    dynamic data;
    User user = a.currentUser!;
    final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await document.get().then<dynamic>((DocumentSnapshot snapshot) async{
      data = snapshot.data();
      username = data['username'];
      email = data['email'];
      _password = data['password'];
      _uid = data['uid'];
    });
  }

  AppUser(this.email, this.username, this._password, this._uid);
  AppUser.withAuth(FirebaseAuth a) {
    getData(a);
  }

  void printUser () {
    print('$email, $username, $_password, $_uid');
  }

  void addBook () {
    //TODO: Add a book to the books list
  }

  void removeBook() {
    //TODO: Remove a book from the books list (also when quantity is 0)
  }



}