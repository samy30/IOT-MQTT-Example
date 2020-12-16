import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mqtt_app_state.dart';
import 'mqtt_manager.dart';
import 'dart:io' show Platform;

class MQTTView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MQTTViewState();
  }
}

class _MQTTViewState extends State<MQTTView> {
  final TextEditingController _hostTextController = TextEditingController();
  final TextEditingController _messageTextController = TextEditingController();
  final TextEditingController _topicTextController = TextEditingController();
  MQTTAppState currentAppState;
  MQTTManager manager;
  MQTTManager manager2;
  double _currentSliderValue = 0;
  double _currentSlider2Value = 0;
  double price = 0;
  Timer _timer;
  void startTime() async{
    // _timer = Timer(new Duration(seconds: 5), sendMetrics);
    Timer.periodic(new Duration(seconds: 10), (timer) {
      sendMetrics();
    });
  }

  void sendMetrics() {
    manager.sendConsumption(_currentSliderValue);
    manager.sendProduction(_currentSlider2Value);
  }

  void connectToBroker( String host, String topic) {
    manager = MQTTManager(
      host: host,
      topic: topic,
      identifier: "mobile",
      state: currentAppState,
      onTensionReduction: (int val) {
        setState(() {
          (_currentSliderValue - val) < 0
              ? _currentSliderValue = 0
              : (_currentSliderValue - val) > 100
                  ? _currentSliderValue = 100
                  : _currentSliderValue -= val;
        });
      },
      onPriceCalculation: (double val) {
        setState(() {
              price += val;
        });
      },
    );
    manager.initializeMQTTClient();
    manager.connect();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      connectToBroker('34.202.230.18', 'test');
      // connectToBroker(manager2, '34.202.230.18', 'test2');
    });
    startTime();

    /*
    _hostTextController.addListener(_printLatestValue);
    _messageTextController.addListener(_printLatestValue);
    _topicTextController.addListener(_printLatestValue);
     */
  }

  @override
  void dispose() {
    _hostTextController.dispose();
    _messageTextController.dispose();
    _topicTextController.dispose();
    _timer.cancel();
    super.dispose();
  }

  /*
  _printLatestValue() {
    print("Second text field: ${_hostTextController.text}");
    print("Second text field: ${_messageTextController.text}");
    print("Second text field: ${_topicTextController.text}");
  }
   */

  @override
  Widget build(BuildContext context) {
    final MQTTAppState appState = Provider.of<MQTTAppState>(context);
    // Keep a reference to the app state.
    currentAppState = appState;
    final Scaffold scaffold =
        Scaffold(appBar: _buildAppBar(context), body: _buildColumn());
    return scaffold;
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('MQTT'),
      backgroundColor: Colors.greenAccent,
    );
  }

  Widget _buildColumn() {
    return Column(
      children: <Widget>[
        Container(
          height: 30,
          color: Colors.white,
        ),
        Container(
          height: 250,
          width: 250,
          child: FittedBox(fit: BoxFit.fitWidth, child: Text(price.toString() + ' DT')),
        ),
        Container(
          height: 30,
          color: Colors.white,
        ),
        Text("consumption: " + _currentSliderValue.round().toString() + "kW"),
        Slider(
          value: _currentSliderValue,
          min: 0,
          max: 100,
          divisions: 1000,
          activeColor: _currentSliderValue <= 25
              ? Colors.green
              : _currentSliderValue <= 50
                  ? Colors.yellow
                  : _currentSliderValue <= 75 ? Colors.orange : Colors.red,
          label: _currentSliderValue.round().toString(),
          onChanged: (double value) {
            setState(() {
              _currentSliderValue = value;
            });
          },
        ),
        Text("production: " + _currentSlider2Value.round().toString() + "kW"),
        Slider(
          value: _currentSlider2Value,
          min: 0,
          max: 100,
          divisions: 1000,
          label: _currentSlider2Value.round().toString(),
          onChanged: (double value) {
            setState(() {
              _currentSlider2Value = value;
            });
          },
        ),
        _buildScrollableTextWith(currentAppState.getHistoryText),
      ],
    );
  }

  Widget _buildEditableColumn() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          _buildTextFieldWith(_hostTextController, 'Enter broker address',
              currentAppState.getAppConnectionState),
          const SizedBox(height: 10),
          _buildTextFieldWith(
              _topicTextController,
              'Enter a topic to subscribe or listen',
              currentAppState.getAppConnectionState),
          const SizedBox(height: 10),
          _buildPublishMessageRow(),
          const SizedBox(height: 10),
          _buildConnecteButtonFrom(currentAppState.getAppConnectionState)
        ],
      ),
    );
  }

  Widget _buildPublishMessageRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: _buildTextFieldWith(_messageTextController, 'Enter a message',
              currentAppState.getAppConnectionState),
        ),
        _buildSendButtonFrom(currentAppState.getAppConnectionState)
      ],
    );
  }

  Widget _buildConnectionStateText(String status) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
              color: Colors.deepOrangeAccent,
              child: Text(status, textAlign: TextAlign.center)),
        ),
      ],
    );
  }

  Widget _buildTextFieldWith(TextEditingController controller, String hintText,
      MQTTAppConnectionState state) {
    bool shouldEnable = false;
    if (controller == _messageTextController &&
        state == MQTTAppConnectionState.connected) {
      shouldEnable = true;
    } else if ((controller == _hostTextController &&
            state == MQTTAppConnectionState.disconnected) ||
        (controller == _topicTextController &&
            state == MQTTAppConnectionState.disconnected)) {
      shouldEnable = true;
    }
    return TextField(
        enabled: shouldEnable,
        controller: controller,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.only(left: 0, bottom: 0, top: 0, right: 0),
          labelText: hintText,
        ));
  }

  Widget _buildScrollableTextWith(String text) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: 400,
        height: 200,
        child: SingleChildScrollView(
          child: Text(text),
        ),
      ),
    );
  }

  Widget _buildConnecteButtonFrom(MQTTAppConnectionState state) {
    return Row(
      children: <Widget>[
        Expanded(
          child: RaisedButton(
            color: Colors.lightBlueAccent,
            child: const Text('Connect'),
            onPressed: state == MQTTAppConnectionState.disconnected
                ? _configureAndConnect
                : null, //
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RaisedButton(
            color: Colors.redAccent,
            child: const Text('Disconnect'),
            onPressed: state == MQTTAppConnectionState.connected
                ? _disconnect
                : null, //
          ),
        ),
      ],
    );
  }

  Widget _buildSendButtonFrom(MQTTAppConnectionState state) {
    return RaisedButton(
      color: Colors.green,
      child: const Text('Send'),
      onPressed: state == MQTTAppConnectionState.connected
          ? () {
              _publishMessage(_messageTextController.text);
            }
          : null, //
    );
  }

  // Utility functions
  String _prepareStateMessageFrom(MQTTAppConnectionState state) {
    switch (state) {
      case MQTTAppConnectionState.connected:
        return 'Connected';
      case MQTTAppConnectionState.connecting:
        return 'Connecting';
      case MQTTAppConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  void _configureAndConnect() {
    // TODO: Use UUID
    String osPrefix = 'Flutter_iOS';
    if (Platform.isAndroid) {
      osPrefix = 'Flutter_Android';
    }
    manager = MQTTManager(
        host: _hostTextController.text,
        topic: _topicTextController.text,
        identifier: osPrefix,
        state: currentAppState);
    manager.initializeMQTTClient();
    manager.connect();
  }

  void _disconnect() {
    manager.disconnect();
  }

  void _publishMessage(String text) {
    String osPrefix = 'Flutter_iOS';
    if (Platform.isAndroid) {
      osPrefix = 'Flutter_Android';
    }
    final String message = osPrefix + ' says: ' + text;
    manager.publish(message);
    _messageTextController.clear();
  }
}
