import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wifi/wifi.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Host To Share',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Host to Share'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  HttpServer server;
  String serverToConnect = "";

  bool started = false;

  @override
  void initState() {
    Future.delayed(Duration.zero).then((value) async {
      serverToConnect = "http://${await Wifi.ip}:7777";
      if (mounted) setState(() {});
    });
    super.initState();
  }

  void stopServer() => server?.close()?.then((value) {
        setState(() {
          started = false;
        });
      });
  void startServer() async {
    if (server != null) {
      server.close();
      server = null;
    }
    await HttpServer.bind(InternetAddress.anyIPv4, 7777, shared: true).then((server) {
      print("Server started");
      this.server = server;
      server.listen((HttpRequest req) async {
        if (req.method.toLowerCase() == "post") {
          Directory dir;
          if (Platform.isIOS) {
            dir = await getLibraryDirectory();
          } else if (Platform.isAndroid) {
            dir = await getExternalStorageDirectory();
          } else {
            throw AssertionError("Not support with your device");
          }

          var transform = await req.transform(StreamTransformer.fromBind((stream) => utf8.decoder.bind(stream))).join();
          Map<String, dynamic> data = Uri(query: transform).queryParameters;

          var rawData = base64.decode(data["base64"].toString().split(";").last.split("base64,").last);
          File file = File("${dir.path}/${data['file']}");
          file.writeAsBytes(rawData);

          print(file.path);
        }
        var web = await rootBundle.load("assets/index.html");
        req.response.headers.add('Content-Type', 'text/html; charset=utf-8');
        req.response.add(web.buffer.asUint8List());
        req.response.close();
      });

      started = true;
      setState(() {});
    }).catchError((e) {
      print(e);
      started = false;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(10),
          children: <Widget>[
            Text(
              'Make sure your devices connected to same LAN, and access this with browser after you start the server',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            SelectableText(
              serverToConnect,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Click button bellow to start the server',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            RaisedButton(
              onPressed: started ? stopServer : startServer,
              child: Text("${started ? "Stop" : "Start"} Server"),
            )
          ],
        ),
      ),
    );
  }
}
