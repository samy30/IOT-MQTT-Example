import {Component, ElementRef, OnDestroy, OnInit, ViewChild} from '@angular/core';
import {Subscription} from 'rxjs';
import {IMqttMessage, MqttService} from 'ngx-mqtt';
import {
  ApexAxisChartSeries,
  ApexChart,
  ApexDataLabels,
  ApexStroke,
  ApexGrid,
  ApexXAxis,
  ApexTitleSubtitle,
  ChartComponent,
  ApexYAxis
} from 'ng-apexcharts';

export type ChartOptions = {
  series: ApexAxisChartSeries;
  chart: ApexChart;
  yaxis: ApexYAxis;
  dataLabels: ApexDataLabels;
  grid: ApexGrid;
  stroke: ApexStroke;
  title: ApexTitleSubtitle;
};

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit, OnDestroy {
  @ViewChild('chart') chart: ChartComponent;
  public chartOptions: Partial<ChartOptions>;
  public chartOptions2: Partial<ChartOptions>;

  private subscription: Subscription;
  topicname: any;
  msg: any;
  isConnected = false;
  series: any[];
  series2: any[];
  data = [];
  data2 = [];
  reducedTension = 0;
  price = 0;
  @ViewChild('msglog', { static: true }) msglog: ElementRef;

  constructor(private mqttService: MqttService) {
    this.series = [
      {
        name: 'kW',
        data: []
      }
    ];

    this.series2 = [
      {
        name: 'kW',
        colors: ['#f3f3f3'],
        data: []
      }
    ];
    this.chartOptions = {
      chart: {
        height: 350,
        type: 'line',
        zoom: {
          enabled: false
        }
      },
      yaxis: {
        min: 0,
        max: 100},
      dataLabels: {
        enabled: false
      },
      stroke: {
        curve: 'straight'
      },
      title: {
        text: 'Power consumption by save',
        align: 'left'
      },
      grid: {
        row: {
          colors: ['#f3f3f3', 'transparent'], // takes an array which will be repeated on columns
          opacity: 0.5
        }
      },
    };

    this.chartOptions2 = {
      chart: {
        height: 350,
        type: 'line',
        zoom: {
          enabled: false
        }
      },
      yaxis: {
        min: 0,
        max: 100},
      dataLabels: {
        enabled: false
      },
      stroke: {
        curve: 'straight'
      },
      title: {
        text: 'Power production by save',
        align: 'left'
      },
      grid: {
        row: {
          colors: ['#f3f3f3', 'transparent'], // takes an array which will be repeated on columns
          opacity: 0.5
        }
      },
    };
  }

  ngOnInit(): void {
    this.subscribeNewTopic('consumption');
    this.subscribeNewTopic('production');
  }

  ngOnDestroy(): void {
    this.subscription.unsubscribe();
  }


  subscribeNewTopic(localtopicname): void {
    console.log('inside subscribe new topic');
    this.subscription = this.mqttService.observe(localtopicname).subscribe((message: IMqttMessage) => {
      if (message.topic === 'consumption') {
        this.data.push(Math.round(Number(message.payload.toString())));
        this.series = [
          {
            name: 'kW',
            data: this.data
          }
        ];
        this.logMsg('Consumption: ' + Math.round(Number(message.payload.toString())) + 'kW');
      }

      if (message.topic === 'production') {
        this.data2.push(Math.round(Number(message.payload.toString())));
        this.series2 = [
          {
            name: 'kW',
            data: this.data2
          }
        ];
        this.logMsg('Production : ' + Math.round(Number(message.payload.toString())) + 'kW');
      }
      this.msg = message;

    });
    this.logMsg('subscribed to topic: ' + localtopicname);
  }

  sendmsg(): void {
    // use unsafe publish for non-ssl websockets
    this.mqttService.unsafePublish(this.topicname, this.msg, { qos: 1, retain: true });
    this.msg = '';
  }

  reduceTension(): void {
    // use unsafe publish for non-ssl websockets
    this.mqttService.unsafePublish('reduction', this.reducedTension + '', { qos: 2, retain: true });
    this.logMsg('Sending reduction signal of: ' + this.reducedTension + 'kW');
    this.reducedTension = 0;
  }

  calculateAndSendPrice(): void {
    // use unsafe publish for non-ssl websockets
    const part1 = (this.data.length !== 0) ? this.data[this.data.length - 1] : 0;
    const part2 = (this.data2.length !== 0) ? this.data2[this.data2.length - 1] : 0;
    this.price = part1 - part2;
    this.mqttService.unsafePublish('price', this.price + '', { qos: 1, retain: true });
    this.logMsg('Sending price : ' + this.price + 'DT');
  }

  logMsg(message): void {
    this.msglog.nativeElement.innerHTML += '<br><hr>' + message;
  }

  clear(): void {
    this.msglog.nativeElement.innerHTML = '';
  }
}
