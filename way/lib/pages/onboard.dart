import "package:flutter/material.dart";
import "package:way_go/services/widget_support.dart";

class Onboard extends StatefulWidget {
  const Onboard({super.key});

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            Image.asset(
              "images/BG1.jpg",
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 20, top: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                    "The best\nWay to\nJourny ",
                    style: AppWidget.healingTextstyle(50),
                  ),
                    Spacer(),
                  Container(
                    height: 50,
                    margin: const EdgeInsets.only(right: 30),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(102, 255, 255, 255),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        "Sign in",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'poppins'
                        ),
                      ),
                    ),
                  ),
                   SizedBox(height: 20),
                   Center(
                    child: Text(
                      "Create An Account",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'poppins'
                      )
                    ),
                  ),
                    SizedBox(height: 150),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
