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
  "met metro 6 1 # 2 1\n",
  "met metro 6 1 # 1 1\n",
  "met metro 2 1 # 1\n" // # is channel
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

  List<TextEditingController> _volt =
      List.generate(3, (i) => TextEditingController());
  List<TextEditingController> _curr =
      List.generate(3, (i) => TextEditingController());
  List<TextEditingController> _ener =
      List.generate(3, (i) => TextEditingController());

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
      if (_reader != null) _reader.close();
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
            double value = int.parse(valueStr, radix: 16) / 1000.0;
            int line = int.parse(dataStr[reMatch.end]);

            switch (i) {
              case 0:
                setState(() => _volt[line % 3].text = value.toString());
                break;
              case 1:
                setState(() => _curr[line % 3].text = value.toString());
                break;
              case 2:
                setState(() => _ener[line % 3].text = value.toString());
                break;

              default:
            }
            print('Decoded $i,$line: $value');
          }
        });
      });
    }
  }

  void _scan(int channel) {
    for (int i = 0; i < 3; i++) {
      if (_reader != null) {
        Future.delayed(Duration(milliseconds: 500 * i), () {
          // Call 3x metro command to get all 3 Lines
          String fullCommand =
              txCommands[channel].replaceFirst('#', (i + 1).toString());
          _chosenPort.write(new Uint8List.fromList(fullCommand.codeUnits));
          print('Sent $fullCommand');
        });
      }

      switch (channel) {
        case 0:
          setState(() => _volt[i].text = 'reading...');
          break;
        case 1:
          setState(() => _curr[i].text = 'reading...');
          break;
        case 2:
          setState(() => _ener[i].text = 'reading...');
          break;

        default:
      }
    }
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
            constraints: BoxConstraints(minWidth: 400),
            margin: const EdgeInsets.all(20.0),
            child: TabBarView(
              children: [
                Column(children: [
                  DropdownButton(
                      value: _chosenPortId,
                      disabledHint: Text("No serial ports available."),
                      onTap: () {
                        setState(
                            () => _availablePorts = SerialPort.availablePorts);
                      },
                      onChanged: (value) {
                        _newSerial(value);
                      },
                      items: List.generate(_availablePorts.length, (i) {
                        return DropdownMenuItem(
                            value: i,
                            child: SerialPortMenuItem(
                                SerialPort(_availablePorts[i]).description,
                                _availablePorts[i].toString()));
                      })),
                  Expanded(
                      child: SizedBox(
                          height: 200.0,
                          child: GridView.count(
                              crossAxisCount: 4,
                              childAspectRatio: 4,
                              crossAxisSpacing: 20.0,
                              mainAxisSpacing: 10.0,
                              children: [
                                SelectableField('Voltage L1', _volt[0], 'V'),
                                SelectableField('Voltage L2', _volt[1], 'V'),
                                SelectableField('Voltage L3', _volt[2], 'V'),
                                ElevatedButton(
                                    onPressed: () => _scan(0),
                                    child: Icon(Icons.refresh)),
                                SelectableField('Current L1', _curr[0], 'A'),
                                SelectableField('Current L2', _curr[1], 'A'),
                                SelectableField('Current L3', _curr[2], 'A'),
                                ElevatedButton(
                                    onPressed: () => _scan(1),
                                    child: Icon(Icons.refresh)),
                                SelectableField('Energy L1', _ener[0], 'Wh'),
                                SelectableField('Energy L2', _ener[1], 'Wh'),
                                SelectableField('Energy L3', _ener[2], 'Wh'),
                                ElevatedButton(
                                    onPressed: () => _scan(2),
                                    child: Icon(Icons.refresh))
                              ])))
                ]),
                Text("Test")
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget selectableField(
      String description, TextEditingController controller, String unit) {
    // TextEditingController controller;

    return TextFormField(
      controller: controller,
      readOnly: false,
      initialValue: '123',
      textAlign: TextAlign.right,
      decoration: InputDecoration(
          labelText: description,
          suffix: SizedBox(
              width: 30,
              child: Text(
                unit,
                textAlign: TextAlign.center,
              ))),
    );
  }
}

class SerialPortMenuItem extends StatelessWidget {
  final String description;
  final String address;

  SerialPortMenuItem(this.description, this.address);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 400.0,
        child: Row(children: [
          Text(description),
          Spacer(),
          Text(
            address,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
          )
        ]));
  }
}

class SelectableField extends StatelessWidget {
  final String description;
  final TextEditingController initialValue;
  final String unit;

  SelectableField(this.description, this.initialValue, this.unit);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: initialValue,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
          labelText: description,
          suffix: SizedBox(
              width: 30,
              child: Text(
                unit,
                textAlign: TextAlign.center,
              ))),
    );
  }
}
