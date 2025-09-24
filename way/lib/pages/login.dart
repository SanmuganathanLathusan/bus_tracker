import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        child: Stack(
          children: [
            Image.asset(
              "images/logo.jpg",
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 3.5,
              fit: BoxFit.cover,
            ),

            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(top: 50, left: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: const Color.fromARGB(157, 76, 175, 79),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height / 3.2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        children: [
                          Text(
                            "welcome Back",
                            style: TextStyle(
                              color: const Color.fromARGB(157, 76, 175, 79),
                              fontSize: 30,
                              fontFamily: 'poppins',
                            ),
                          ),
                          Text(
                            "Login to your account",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Image.asset("images/bg.jpg", height: 180, width: 100),
                    ],
                  ),
                  Container(
                    height: 60,
                    margin: EdgeInsets.only(left: 30, right: 30),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(67, 0, 0, 0),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.email,
                            color: const Color.fromARGB(67, 0, 0, 0),
                          ),
                          hintText: "enter email",
                          hintStyle: TextStyle(
                            color: const Color.fromARGB(67, 0, 0, 0),
                            fontFamily: 'poppins',
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Container(
                    height: 60,
                    margin: EdgeInsets.only(left: 30, right: 30),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(67, 0, 0, 0),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.password,
                            color: const Color.fromARGB(67, 0, 0, 0),
                          ),
                          hintText: "enter passsword",
                          hintStyle: TextStyle(
                            color: const Color.fromARGB(67, 0, 0, 0),
                            fontFamily: 'poppins',
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Forgot Password",
                          style: TextStyle(
                            color: const Color.fromARGB(157, 76, 175, 79),
                            fontSize: 18,
                            fontFamily: 'poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 120),
                  Container(
                    margin: EdgeInsets.only(left: 30, right: 20),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(157, 14, 92, 17),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: const Color.fromARGB(157, 84, 15, 7),
                          fontSize: 18,
                          fontFamily: 'poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
