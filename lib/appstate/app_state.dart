//change notifier class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_correct/models/courses_models.dart';
import 'package:course_correct/models/tutor_model.dart';
import 'package:course_correct/models/user_model.dart';
import 'package:course_correct/pages/landing_page.dart';
import 'package:course_correct/pages/login_page.dart';
import 'package:course_correct/pages/student_homepage.dart';
import 'package:course_correct/pages/tutors_homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool animationcomplete = false;

  //variable to store the current user
  User? user;
  UserModel? userProfile;
  //variable to store the current theme
  ThemeData _theme = ThemeData.light();
  //getter to get the current theme
  ThemeData get theme => _theme;
  //function to change the theme

  //course related variables
  String? courseName;
  CoursesModel? course;

  void changeTheme() {
    if (_theme == ThemeData.light()) {
      _theme = ThemeData.dark();
    } else {
      _theme = ThemeData.light();
    }
    notifyListeners();
  }

  Future<void> initialization() async {
    setUser(FirebaseAuth.instance.currentUser);
    setUserProfile(await readUserProfileFromFirestore());
  }
  
  //user related functions
  void setUser(User? user) {
    this.user = user;
    notifyListeners();
  }

  void logoutUser(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pop(context);
    // go to login page
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  void registerTutorOnFirestore(TutorModel tutor) {
    FirebaseFirestore.instance
        .collection('tutors')
        .doc(user!.uid)
        .set(tutor.toFirestore());
  }

  Future<TutorModel?> getTutor() async {
    final tutorRef = FirebaseFirestore.instance
        .collection('tutors')
        .doc(user!.uid)
        .withConverter(
            fromFirestore: TutorModel.fromFirestore,
            toFirestore: (TutorModel tutor, _) => tutor.toFirestore());
    final tutorSnap = await tutorRef.get();
    final tutor = tutorSnap.data();
    return tutor;
  }

  //function to get all tutors
  Future<List<TutorModel>> getAllTutors() async {
    final tutorsRef = FirebaseFirestore.instance
        .collection('tutors')
        .withConverter(
          fromFirestore: (snapshot, _) => TutorModel.fromFirestore(
              snapshot.data()! as DocumentSnapshot<Map<String, dynamic>>, _),
          toFirestore: (tutor, _) => tutor.toFirestore(),
        );
    final tutorsSnap = await tutorsRef.get();
    final tutors = tutorsSnap.docs.map((doc) => doc.data()).toList();
    return tutors;
  }

  void usertoFirebase(bool isTutor) {
    FirebaseFirestore.instance.collection('users').doc(user!.uid).set({});
  }

  // Future<void> addStudentToFirestore(String uid, String name) async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user != null){
  //   await FirebaseFirestore.instance.collection('users').doc(uid).set({
  //     'email': user.email,
  //     'name': name,
  //     'created_at': FieldValue.serverTimestamp(),
  //     'role': 'student',
  //   });
  // }
  // }

  Future<void> loginSequence(
      String email, String password, BuildContext context) async {
    try {
       ScaffoldMessenger.of(context).showSnackBar( SnackBar(
          content: Row(
        children: [
          Text(
            'Logging you in',
            style: defaultTextStyle.copyWith(color: Colors.white),
          ),
          const Spacer(),
          const CircularProgressIndicator()
        ],
      )));
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        setUser(user);
        userProfile = await readUserProfileFromFirestore();
        notifyListeners();
        if (userProfile!.role == 'tutor') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const TutorHomepage()));
        } else if (userProfile!.role == 'student') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const StudentHomepage()));
        } else {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => LandingPage()));
        }
      }
    } catch (e) {
      snackBarMessage(e.toString(), context);
    }
  }

  Future<UserModel?> readUserProfileFromFirestore() async {
    user = FirebaseAuth.instance.currentUser;
    String userUid = user!.uid;
    if (user != null) {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .withConverter(
            fromFirestore: (snapshot, _) =>
                UserModel.fromFirestore(snapshot, _),
            toFirestore: (user, _) => user.toFirestore(),
          );
      final userSnap = await userRef.get();
      final user = userSnap.data();
      return user;
    } else {
      return null;
    }
  }

  Future<void> registerSequence(
      String email, String password, String name, BuildContext context) async {
    try {
       ScaffoldMessenger.of(context).showSnackBar( SnackBar(
          content: Row(
        children: [
          Text(
            'Registering',
            style: defaultTextStyle.copyWith(color: Colors.white),
          ),
          const Spacer(),
          const CircularProgressIndicator()
        ],
      )));
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'name': name,
          'created_at': FieldValue.serverTimestamp(),
        });
        setUser(user);
        userProfile = UserModel(name: name);
        notifyListeners();
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LandingPage()));
      }
    } catch (e) {
      snackBarMessage(e.toString(), context);
    }
  }

  void setUserProfile(UserModel? userProfile) {
    this.userProfile = userProfile;
    notifyListeners();
  }

  //COURSE RELATED FUNCTIONS
  void setCourseName(String courseName) {
    this.courseName = courseName;
    notifyListeners();
  }

  snackBarMessage(String text, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
    ));
  }
}
