import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intern_test/add_photo.dart';
import 'package:intern_test/photo_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import 'login_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  bool showSpinner = false;

  @override
  void initState() {
    super.initState();
  }

  Future verify() async {
    setState(() {
      showSpinner = true;
    });
    FirebaseUser user = await _auth.currentUser();
    await user.reload();
    setState(() {
      showSpinner = false;
    });
    if (user.isEmailVerified) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddPhotoPage()),
      );
    } else {
      showDialogBox(context, user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.black,
          title: Text(
            'PicToShare',
            style: GoogleFonts.raleway(
              textStyle: TextStyle(fontSize: 35),
            ),
          ),
          actions: [
            FlatButton(
              child: Text(
                'Sign Out',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                _auth.signOut();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (Route<dynamic> route) => false);
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white,
          child: Icon(
            Icons.add,
            color: Colors.black,
          ),
          onPressed: () async {
            await verify();
          },
        ),
        body: Column(
          children: [
            PhotosPage(),
          ],
        ),
      ),
    );
  }
}

void showDialogBox(BuildContext context, FirebaseUser user) {
  var popup = AlertDialog(
    content: SingleChildScrollView(
      child: Column(
        children: [
          Text(
            'Please verify your email id ${user.email} by clicking on the link sent to your email id.',
            style: TextStyle(fontSize: 17),
          ),
          SizedBox(
            height: 10,
          ),
          RaisedButton(
            focusElevation: 0,
            highlightElevation: 0,
            splashColor: Colors.white.withOpacity(0.1),
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            onPressed: () {
              user.sendEmailVerification();
              Navigator.pop(context);
            },
            color: Color(0xFF4F51C0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Send Verification Link Again',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  // ignore: non_constant_identifier_names
  showDialog(context: context, builder: (BuildContext) => popup);
}
