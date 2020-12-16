import { Injectable } from '@angular/core';
import {Observable} from 'rxjs';
import {IMqttMessage, MqttService} from 'ngx-mqtt';

@Injectable({
  providedIn: 'root'
})
export class MyMqttService {

  private endpoint: string;

  constructor(
    private mqttService: MqttService,
  ) {
    this.endpoint = 'GL5/SLE/SAMI';
  }

  topic(): Observable<IMqttMessage> {
    const topicName = `/${this.endpoint}`;
    console.log(topicName);
    return this.mqttService.observe(topicName);
  }
}
