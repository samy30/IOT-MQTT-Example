import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import {IMqttServiceOptions, MqttModule} from 'ngx-mqtt';
import { environment as env } from '../environments/environment';
import { EventStreamComponent } from './event-stream/event-stream.component';
import {FormsModule} from '@angular/forms';
import {NgApexchartsModule} from 'ng-apexcharts';

export const MQTT_SERVICE_OPTIONS: IMqttServiceOptions = {
  hostname: env.mqtt.server,
  port: env.mqtt.port,
  path: '/mqtt'
};


@NgModule({
  declarations: [
    AppComponent,
    EventStreamComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    FormsModule,
    MqttModule.forRoot(MQTT_SERVICE_OPTIONS),
    NgApexchartsModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
