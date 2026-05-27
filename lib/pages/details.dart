import 'package:flutter/material.dart';
import 'package:flutter_projects/pages/home.dart';
import 'package:flutter_projects/pages/result.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: 2, // 2 = details.dart or details page - highlighted currently

        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ResultPage()),
            );
          }
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
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

      //header
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
                  'DETAILS',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
            ],
          ),
        ),
 
        Expanded(
        child:SingleChildScrollView(
          padding:EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investment Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Here are the bank promos offered by PH digital banks and prices of specific ETFs',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),                   
                  ],
                ),
              ),
              
              SizedBox(height: 16),

                  // Table List of Bank Rates and ETF's
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Promos & ETF Returns',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Divider(),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Banks
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Digital Banks (Annual)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  _bankRow('GoTyme',   '6.00%'),
                                  _bankRow('Tonik',    '6.50%'),
                                  _bankRow('Maya',     '3.50%'),
                                  _bankRow('CIMB',     '2.50%'),
                                  _bankRow('Maribank', '2.50%'),
                                ],
                              ),
                            ),

                            SizedBox(width: 12),

                            // ETFs
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ETFs (avg monthly return)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  _etfRow('QQQ', '~1.80%'),
                                  _etfRow('VOO', '~1.20%'),
                                  _etfRow('VTI', '~1.15%'),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Warning
                        Container(
                          padding: EdgeInsets.all(8),
                          color: Color(0xFFFFF3E0),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange, size: 16),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'ETF returns are estimated, not guaranteed.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        )
      ),
    )
      ],
    )
  );
}
 Widget _bankRow(String name, String rate) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(fontSize: 13)),
          Text(rate,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              )),
        ],
      ),
    );
  }

  Widget _etfRow(String ticker, String rate) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(ticker, style: TextStyle(fontSize: 13)),
          Text(rate,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              )),
        ],
      ),
    );
  }
}