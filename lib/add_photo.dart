import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

String _name;
String _hashtag;

class AddPhotoPage extends StatefulWidget {
  @override
  _AddPhotoPageState createState() => _AddPhotoPageState();
}

class _AddPhotoPageState extends State<AddPhotoPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool showspinner = false;

  final _auth = FirebaseAuth.instance;
  FirebaseUser loggedInUser;

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async {
    FirebaseUser _user = await _auth.currentUser();
    setState(() {
      loggedInUser = _user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: showspinner,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            "Share A Pic",
            style: TextStyle(
              fontFamily: 'Montserrat',
            ),
          ),
          elevation: 0,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                SizedBox(
                  height: 100,
                ),
                TextFormField(
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Name',
                    hintStyle: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white60,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  cursorColor: Colors.white,
                  maxLength: 32,
                  maxLengthEnforced: true,
                  validator: (String value) {
                    if (value.isEmpty) {
                      return 'Name is Required';
                    }
                    return null;
                  },
                  onSaved: (String value) {
                    _name = value;
                  },
                ),
                SizedBox(
                  height: 30,
                ),
                TextFormField(
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Hashtag',
                    hintStyle: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white60,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  cursorColor: Colors.white,
                  maxLength: 32,
                  maxLengthEnforced: true,
                  validator: (String value) {
                    if (value.isEmpty) {
                      return 'Hashtag is Required';
                    }
                    return null;
                  },
                  onSaved: (String value) {
                    _hashtag = value;
                  },
                ),
                SizedBox(
                  height: 30,
                ),
                FlatButton(
                  onPressed: () {
                    if (!_formKey.currentState.validate()) {
                      return;
                    }
                    _formKey.currentState.save();
                    getImage(context);
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Upload Photo',
                      style: TextStyle(
                          color: Colors.black, fontFamily: 'Montserrat'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future getImage(BuildContext context) async {
    // Get image from gallery.
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
        // ignore: deprecated_member_use
        var image = await ImagePicker.pickImage(source: ImageSource.gallery);
        setState(() {
          showspinner = true;
        });
        await _uploadImageToFirebase(image, context);
        setState(() {
          showspinner = false;
        });
        showDialogBox(context);
      }
    } on SocketException catch (_) {
      print('not connected');
      showDialogBox2(context);
    }
  }

  Future<void> _uploadImageToFirebase(File image, BuildContext context) async {
    try {
      // Make random image name.
      int randomNumber = Random().nextInt(10000000);
      String imageLocation = 'images/image$randomNumber.jpg';
      // Upload image to firebase.
      final StorageReference storageReference =
          FirebaseStorage().ref().child(imageLocation);
      final StorageUploadTask uploadTask = storageReference.putFile(image);
      await uploadTask.onComplete;
      _addPathToDatabase(imageLocation, context);
    } catch (e) {
      print(e.message);
      showDialog(
          builder: (context) {
            return AlertDialog(
              content: Text(e.message),
            );
          },
          context: null);
    }
  }

  Future<void> _addPathToDatabase(String text, BuildContext context) async {
    try {
      // Get image URL from firebase
      final ref = FirebaseStorage().ref().child(text);
      var imageString = await ref.getDownloadURL();
      print(imageString);
      print(text);
      print(_name);
      print(_hashtag);
      print(loggedInUser.uid);
      await Firestore.instance.collection('images').add({
        'url': imageString,
        'location': text,
        'name': _name,
        'hashtag': _hashtag,
        'uid': loggedInUser.uid,
        'createdOn': FieldValue.serverTimestamp()
      });
      print('3');
    } catch (e) {
      print(e.message);
      showDialog(
          builder: (context) {
            return AlertDialog(
              content: Text(e.message),
            );
          },
          context: null);
    }
  }
}

void showDialogBox(BuildContext context) {
  var popup = AlertDialog(
    content: SingleChildScrollView(
      child: Column(
        children: [
          Align(
            alignment: Alignment.center,
            child: Text('Your photo has been successfully added'),
          ),
          SizedBox(
            height: 20,
          ),
          RaisedButton(
            focusElevation: 0,
            highlightElevation: 0,
            splashColor: Colors.white.withOpacity(0.1),
            padding: EdgeInsets.symmetric(vertical: 20),
            onPressed: () {
              Navigator.pop(context);
            },
            color: Color(0xFF4F51C0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Okay',
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

void showDialogBox2(BuildContext context) {
  var popup = AlertDialog(
    content: SingleChildScrollView(
      child: Column(
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
                'Failed to add photo. Please check your internet connection.'),
          ),
          SizedBox(
            height: 30,
          ),
          RaisedButton(
            focusElevation: 0,
            highlightElevation: 0,
            splashColor: Colors.white.withOpacity(0.1),
            padding: EdgeInsets.symmetric(vertical: 20),
            onPressed: () {
              Navigator.pop(context);
            },
            color: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Okay',
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
