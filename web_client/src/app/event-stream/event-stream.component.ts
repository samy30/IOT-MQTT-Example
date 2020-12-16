import { Component, OnInit } from '@angular/core';
import {IMqttMessage} from 'ngx-mqtt';
import {Subscription} from 'rxjs';
import {MyMqttService} from '../mqtt.service';

@Component({
  selector: 'app-event-stream',
  templateUrl: './event-stream.component.html',
  styleUrls: ['./event-stream.component.css']
})
export class EventStreamComponent implements OnInit {

  events: any[];
  private deviceId: string;
  subscription: Subscription;

  constructor(
    private readonly eventMqtt: MyMqttService,
  ) {
  }

  ngOnInit() {
    this.subscribeToTopic();
  }

  ngOnDestroy(): void {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  private subscribeToTopic() {
    console.log("subscribing");
    this.subscription = this.eventMqtt.topic()
      .subscribe((data: IMqttMessage) => {
        console.log("result received");
        const item = JSON.parse(data.payload.toString());
        this.events.push(item);
      }, error => {
        alert('error');
      });
  }

}
