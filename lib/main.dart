import 'package:flutter/material.dart';
import 'package:flutter_serial_port/flutter_serial_port.dart';

void main() {
  final name = SerialPort.availablePorts.first;
  print(name);
  final port = SerialPort(name);
  if (!port.openReadWrite()) {
    print(SerialPort.lastError);
  }

  final reader = SerialPortReader(port);
  reader.stream.listen((data) {
    print('received: $data');
  });

  runApp(PowerBoardTest());
}

class PowerBoardTest extends StatefulWidget {
  PowerBoardTest({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<PowerBoardTest> {
  var _availablePorts = [];
  int _chosenPortId = 0;
  SerialPort _chosenPort;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    setState(() => _availablePorts = SerialPort.availablePorts);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.flash_on)),
                Tab(icon: Icon(Icons.tune)),
              ],
            ),
            title: Text('Power Board Testing'),
          ),
          body: Container(
            margin: const EdgeInsets.all(20.0),
            child: TabBarView(
              children: [
                DropdownButton(
                    value: _chosenPortId,
                    disabledHint: Text("No serial ports available."),
                    onChanged: (value) {
                      setState(() {
                        _chosenPortId = value;
                        _chosenPort = SerialPort(_availablePorts[value]);

                        SerialPort(SerialPort.availablePorts.first)
                            .openReadWrite();
                        print(SerialPort.lastError);

                        print(_chosenPort);
                        print(_chosenPort.openReadWrite());
                        print(SerialPort.lastError);

                        final reader = SerialPortReader(_chosenPort);
                        reader.stream.listen((data) {
                          print('received: $data');
                        });
                      });
                      String poortje = _availablePorts[value];
                      print('$poortje chosen ($value)');
                    },
                    items: //[
                        List.generate(_availablePorts.length, (i) {
                      return DropdownMenuItem(
                          value: i,
                          child:
                              Text(SerialPort(_availablePorts[i]).description));
                    })),
                Text("Test")
              ],
            ),
          ),
        ),
      ),
    );
  }
}
