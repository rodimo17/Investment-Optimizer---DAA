import 'package:flutter/material.dart';
import 'package:flutter_projects/pages/details.dart';
import 'package:flutter_projects/pages/home.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: 0, // 0 = result.dart or result page - highlighted currently

        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailsPage()),
            );
          }
        },

        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize),
            label: 'Browse',
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.deepPurple,
            padding: EdgeInsets.only(
              top: 50,
              bottom: 30,
              left: 20,
              right: 20,
            ),
            child: Column(
              children: [
                Text(
                  'Investment Optimizer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'RESULTS',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
            ],
          ),
          )
        ],
      ),
    );
}
}