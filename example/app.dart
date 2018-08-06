import 'package:angular/angular.dart';

@Component(
  selector: 'app',
  template: '<button (click)="error()">Catch error</button>',
)
class AppComponent {
  void error() {
    throw Exception("Test error");
  }
}
