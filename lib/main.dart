import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayPal Payment Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PaymentPage(),
    );
  }
}

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String _receipt = '';

  // PayPal Credentials
  final String _clientId = 'ASZvCVQrTCkIeNTrFT1LIBaouemXY_qSTDW3ynCyWdOCco1AvPTmrUbHmxuw3VWXDb5ajrKdVAmhzo4H'; // Client ID
  final String _secret = 'EMQyPKPEo9pUR2-d9soDGmXRGjvmwJBquC9RJX7OL4TMfJwa20R_BdLiibFoFQRTPYj5zCOzb2RNHDAL'; // Secret Key

  Future<String> _getAccessToken() async {
    final url = Uri.parse('https://api.sandbox.paypal.com/v1/oauth2/token');
    final credentials = base64Encode(utf8.encode('$_clientId:$_secret'));

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
      },
    );

    final responseBody = json.decode(response.body);
    return responseBody['access_token'];
  }

  Future<void> _createPayment(String accessToken) async {
    final url = Uri.parse('https://api.sandbox.paypal.com/v1/payments/payment');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "intent": "sale",
        "payer": {
          "payment_method": "paypal"
        },
        "transactions": [
          {
            "amount": {
              "total": _amountController.text,
              "currency": "USD"
            },
            "description": "Payment from Flutter App"
          }
        ],
        "redirect_urls": {
          "return_url": "https://example.com/return",
          "cancel_url": "https://example.com/cancel"
        }
      }),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 201) {
      final approvalUrl = responseBody['links']
          .firstWhere((link) => link['rel'] == 'approval_url')['href'];
      
      setState(() {
        _receipt = 'Payment created! Approve it here: $approvalUrl';
      });
    } else {
      setState(() {
        _receipt = 'Payment failed: ${responseBody['message']}';
      });
    }
  }

  Future<void> _makePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accessToken = await _getAccessToken();
      await _createPayment(accessToken);
    } catch (error) {
      setState(() {
        _receipt = 'An error occurred: $error';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PayPal Payment Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Enter Amount (USD)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _makePayment,
                    child: Text('Make Payment'),
                  ),
            SizedBox(height: 20),
            Text(_receipt, style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
