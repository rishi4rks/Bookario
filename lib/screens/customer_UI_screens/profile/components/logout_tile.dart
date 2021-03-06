import 'package:bookario/components/persistence_handler.dart';
import 'package:bookario/screens/sign_in/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../components/constants.dart';

class LogoutTile extends StatefulWidget {
  const LogoutTile({
    Key key,
  }) : super(key: key);

  @override
  _LogoutTileState createState() => _LogoutTileState();
}

class _LogoutTileState extends State<LogoutTile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User user;

  checkAuthentification() async {
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => SignInScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  @override
  void initState() {
    this.checkAuthentification();
    super.initState();
  }

  Future<bool> _logout(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
          ),
          title: Text(
            "Want to logout?",
            style: Theme.of(context).textTheme.headline6.copyWith(
                fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "No",
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(color: kSecondaryColor),
              ),
              splashColor: Colors.red[50],
            ),
            FlatButton(
              onPressed: () async {
                PersistenceHandler.deleteStore('userType');
                await FirebaseAuth.instance.signOut();
              },
              child: Text(
                "Yes",
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(color: kSecondaryColor),
              ),
              splashColor: kPrimaryColor,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _logout(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                SvgPicture.asset(
                  "assets/icons/logout.svg",
                  height: 17,
                  color: Colors.white70,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  'Logout',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: SvgPicture.asset("assets/icons/arrow_right.svg",
                  height: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
