import 'package:flutter/material.dart';
import 'package:flutter_serial_port/flutter_serial_port.dart';
//import 'package:dart_serial_port/dart_serial_port.dart';
import 'dart:typed_data';

var rxPatterns = [
  r'Voltage for Channel 0',
  r'Current for Channel 0',
  r'W\_ACTIVE for Channel 0'
]; // follows with  // '1 :  0x00000000'

var txCommands = [
  "met metro 6 1 1 2 1\n",
  "met metro 6 1 1 1 1\n",
  "met metro 2 1 1 1\n"
];

void main() {
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
  SerialPortReader _reader;

  void _newSerial(int newId) {
    setState(() {
      _chosenPortId = newId;
      _chosenPort = SerialPort(_availablePorts[newId]);
    });

    if (!_chosenPort.openReadWrite()) {
      print('Error opening ' +
          _chosenPort.toString() +
          "\n" +
          SerialPort.lastError.toString());
    } else {
      _reader = SerialPortReader(_chosenPort);
      _reader.stream.listen((data) {
        String dataStr = String.fromCharCodes(data);
        print('received: $dataStr');

        rxPatterns.asMap().forEach((i, pattern) {
          RegExp re = new RegExp(pattern);
          if (re.hasMatch(dataStr)) {
            Match reMatch = re.firstMatch(dataStr);
            String valueStr =
                dataStr.substring(reMatch.end + 7, reMatch.end + 15);
            double value = int.parse(valueStr, radix: 16) / 1000.1;
            print(
                'Decoded $i,${dataStr.substring(reMatch.end, reMatch.end + 1)}: $value');
          }
        });
      });
    }
  }

  void _scan() {
    txCommands.asMap().forEach((i, command) {
      Future.delayed(Duration(milliseconds: 500 * i), () {
        _chosenPort.write(new Uint8List.fromList(command.codeUnits));
        print('Sent $command');
      });
    });
  }

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
                Column(children: [
                  DropdownButton(
                      value: _chosenPortId,
                      disabledHint: Text("No serial ports available."),
                      onChanged: (value) {
                        _newSerial(value);
                      },
                      items: List.generate(_availablePorts.length, (i) {
                        return DropdownMenuItem(
                            value: i,
                            child: Text(
                                SerialPort(_availablePorts[i]).description));
                      })),
                  RaisedButton(
                    onPressed: _scan,
                    child: Icon(Icons.refresh),
                  )
                ]),
                Text("Test")
              ],
            ),
          ),
        ),
      ),
    );
  }
}
