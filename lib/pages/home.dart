import 'package:flutter/material.dart';
import 'package:flutter_projects/pages/details.dart';
import 'package:flutter_projects/pages/result.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController capitalController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  String selectedHorizon = '1 month';
  String selectedRisk = 'Moderate';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: 1, // 1 = home.dart or home page - highlighted currently

        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ResultPage()),
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

          // Header 
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
                SizedBox(height: 4),
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
                  'CALCULATE',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable Body ──────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Your Inputs ────────────────────────
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
                          'Your Inputs',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Divider(),

                        // Total Capital
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Total Capital:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: capitalController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Insert Amount',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(),

                        // Time Horizon
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Time Horizon:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedHorizon,
                                isExpanded: true,
                                underline: SizedBox(),
                                items: ['1 month', '3 months', '6 months', '1 year']
                                    .map((h) => DropdownMenuItem(
                                          value: h,
                                          child: Text(h),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedHorizon = v!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Divider(),

                        // Risk Level
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Risk Level:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedRisk,
                                isExpanded: true,
                                underline: SizedBox(),
                                items: ['Conservative', 'Moderate', 'Aggressive']
                                    .map((r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedRisk = v!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Divider(),

                        // Amount
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Amount:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Insert Amount',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // ── Options Considered ─────────────────
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
                          'Options Considered',
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

                  SizedBox(height: 16),

                  // ── View ──────────────────────────────
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
                          'View',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Divider(),
                        SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ResultPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Backtracking Trace',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────
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