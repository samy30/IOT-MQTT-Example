import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'mqtt_app_state.dart';

class MQTTManager {
  final MQTTAppState _currentState;
  MqttServerClient _client;
  final String _identifier;
  final String _host;
  final String _topic;
  final Function(int) onTensionReduction;
  final Function(double) onPriceCalculation;

  // Constructor
  MQTTManager(
      {@required String host,
      @required String topic,
      @required String identifier,
        @required this.onTensionReduction,
        @required this.onPriceCalculation,
      @required MQTTAppState state})
      : _identifier = identifier,
        _host = host,
        _topic = topic,
        _currentState = state;

  // initialize
  void initializeMQTTClient(){
    _client = MqttServerClient(_host,_identifier);
    _client.port = 1883;
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = onDisconnected;
    _client.secure = false;
    _client.logging(on: false);

    /// Add the successful connection callback
    _client.onConnected = onConnected;
    _client.onSubscribed = onSubscribed;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(_identifier)
        .withWillTopic('willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::Mosquitto client connecting....');
    _client.connectionMessage = connMess;

  }

  // Connect to the host
  void connect() async{
    assert(_client != null);
    try {
      print('EXAMPLE::Mosquitto start client connecting....');
      _currentState.setAppConnectionState(MQTTAppConnectionState.connecting);
      await _client.connect();
    } on Exception catch (e) {
      print('EXAMPLE::client exception - $e');
      disconnect();
    }
  }

  void disconnect() {
    print('Disconnected');
    _client.disconnect();
  }

  void publish(String message){
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload);
  }

  void sendConsumption(double consumption){
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(consumption.toString());
    _client.publishMessage("consumption", MqttQos.exactlyOnce, builder.payload);
    _currentState.setReceivedText("sent consumption value :" + consumption.toString() + " to server");
  }

  void sendProduction(double production){
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(production.toString());
    _client.publishMessage("production", MqttQos.exactlyOnce, builder.payload);
    _currentState.setReceivedText("sent production value :" + production.toString() + " to server");
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    if (_client.connectionStatus.returnCode == MqttConnectReturnCode.noneSpecified) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    }
    _currentState.setAppConnectionState(MQTTAppConnectionState.disconnected);
  }

  /// The successful connect callback
  void onConnected() {
    _currentState.setAppConnectionState(MQTTAppConnectionState.connected);
    print('EXAMPLE::Mosquitto client connected....');
    mysubscribe("price");
    mysubscribe("reduction");
    _client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      print(c[0].topic);
      final MqttPublishMessage recMess = c[0].payload;
      final String pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      switch (c[0].topic) {
        case 'price':
          _currentState.setReceivedText("elevation of price by " + pt + " DT");
          onPriceCalculation(double.parse(pt));
          break;
        case 'reduction':
          _currentState.setReceivedText("reduction of tension by " + pt + " kW");
          onTensionReduction(int.parse(pt));
      }
    });
    print(
        'EXAMPLE::OnConnected client callback - Client connection was sucessful');
  }

  void mysubscribe(topic) {
    _client.subscribe(topic, MqttQos.atLeastOnce);
  }
}
