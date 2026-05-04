enum RoverCommand {
  forward,
  backward,
  left,
  right,
  stop,
  ledOn,
  ledOff;

  String get path => switch (this) {
    RoverCommand.forward => '/go',
    RoverCommand.backward => '/back',
    RoverCommand.left => '/left',
    RoverCommand.right => '/right',
    RoverCommand.stop => '/stop',
    RoverCommand.ledOn => '/ledon',
    RoverCommand.ledOff => '/ledoff',
  };
}
