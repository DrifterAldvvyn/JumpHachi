import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final MyPlatformGame _game = MyPlatformGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // Stack allows the game view and on-screen controls
        body: Stack(
          children: [
            GameWidget(game: _game),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left movement button
                    GestureDetector(
                      onTapDown: (_) => _game.moveLeft(true),
                      onTapUp: (_) => _game.moveLeft(false),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.blue,
                        child: Icon(Icons.arrow_left, color: Colors.white),
                      ),
                    ),
                    // Jump button (chargeable)
                    GestureDetector(
                      onTapDown: (_) => _game.startChargingJump(),
                      onTapUp: (_) => _game.jump(),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.green,
                        child: Icon(Icons.arrow_upward, color: Colors.white),
                      ),
                    ),
                    // Right movement button
                    GestureDetector(
                      onTapDown: (_) => _game.moveRight(true),
                      onTapUp: (_) => _game.moveRight(false),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.blue,
                        child: Icon(Icons.arrow_right, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyPlatformGame extends FlameGame {
  late Player player;
  bool movingLeft = false;
  bool movingRight = false;
  final Random random = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Create the player near the bottom center.
    player = Player()
      ..position = Vector2(size.x / 2 - 25, size.y - 100)
      ..size = Vector2(50, 50);
    add(player);

    // Add a few random platforms.
    int numPlatforms = 3;
    for (int i = 0; i < numPlatforms; i++) {
      double platformWidth = 100;
      double platformHeight = 20;
      double x = random.nextDouble() * (size.x - platformWidth);
      // Distribute platforms vertically above the ground.
      double y = size.y - ((i + 1) * (size.y / (numPlatforms + 1)));
      add(PlatformComponent()
        ..position = Vector2(x, y)
        ..size = Vector2(platformWidth, platformHeight));
    }

    // Add a goal near the top of the screen.
    add(GoalComponent()
      ..position = Vector2(size.x / 2 - 25, 20)
      ..size = Vector2(50, 50));
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Handle horizontal movement from on-screen controls.
    if (movingLeft) {
      if (player.facing == -1.0) {
        player.moveHorizontally(-150 * dt);
      }
      player.facing = -1.0;
    } else if (movingRight) {
      if(player.facing == 1.0) {
        player.moveHorizontally(150 * dt);
      }
      player.facing = 1.0;
    }
  }

  void moveLeft(bool isPressed) {
    movingLeft = isPressed;
  }

  void moveRight(bool isPressed) {
    movingRight = isPressed;
  }

  void startChargingJump() {
    player.startChargingJump();
  }

  void jump() {
    player.executeJump();
  }
}

class Player extends PositionComponent with HasGameRef<MyPlatformGame> {
  Vector2 velocity = Vector2.zero();
  double gravity = 600;
  double jumpCharge = 0;
  final double maxJumpCharge = 1.5;
  double facing = 1.0;
  bool charging = false;
  bool isOnGroundOrPlatform = false;

  @override
  void update(double dt) {
    super.update(dt);

    // Charge jump
    if (charging) {
      jumpCharge += dt;
      if (jumpCharge > maxJumpCharge) jumpCharge = maxJumpCharge;
    }

    // Apply gravity
    velocity.y += gravity * dt;
    position += velocity * dt;

    // Reset ground detection
    isOnGroundOrPlatform = false;

    // Collision with ground
    if (position.y + size.y >= gameRef.size.y) {
      position.y = gameRef.size.y - size.y;
      velocity.y = 0;
      velocity.x = 0;
      isOnGroundOrPlatform = true;
    }

    // Collision with platforms
    for (final platform in gameRef.children.whereType<PlatformComponent>()) {
      final Rect playerRect = toRect();
      final Rect platformRect = platform.toRect();

      if (playerRect.overlaps(platformRect)) {
        // 🚀 **Landing on top of the platform**
        if (velocity.y > 0 && (position.y + size.y - platform.position.y).abs() < 10) {
          position.y = platform.position.y - size.y;
          velocity.y = 0;
          velocity.x = 0;
          isOnGroundOrPlatform = true;
        }
        // 🚀 **Hitting the bottom of the platform**
        else if (velocity.y < 0 && (position.y - (platform.position.y + platform.size.y)).abs() < 10) {
          position.y = platform.position.y + platform.size.y;
          velocity.y = 0;
        }
        // 🚀 **Side collisions (Left & Right)**
        else if (velocity.x > 0 && (position.x + size.x - platform.position.x).abs() < 10) {
          // Moving right, hitting the left side of the platform
          position.x = platform.position.x - size.x;
          velocity.x = 0;
        } else if (velocity.x < 0 && (position.x - (platform.position.x + platform.size.x)).abs() < 10) {
          // Moving left, hitting the right side of the platform
          position.x = platform.position.x + platform.size.x;
          velocity.x = 0;
        }
      }
    }

    if (velocity.y == 0) {
      isOnGroundOrPlatform = true;
    }

    // Collision with goal
    for (final goal in gameRef.children.whereType<GoalComponent>()) {
      if (toRect().overlaps(goal.toRect())) {
        print('Goal reached!');
      }
    }

    // Bounce off screen edges
    if (position.x < 0) {
      position.x = 0;
      velocity.x = -velocity.x * 0.5;
    } else if (position.x + size.x > gameRef.size.x) {
      position.x = gameRef.size.x - size.x;
      velocity.x = -velocity.x * 0.5;
    }
  }

  void moveHorizontally(double dx) {
    if (isOnGroundOrPlatform) {
      position.x += dx;
    }
  }

  void startChargingJump() {
    if (isOnGroundOrPlatform) {
      charging = true;
      jumpCharge = 0;
    }
  }

  void executeJump() {
    if (charging && isOnGroundOrPlatform) {
      double jumpStrength = 300 + (jumpCharge / maxJumpCharge) * 300;
      velocity.y = -jumpStrength;
      velocity.x = 200 * facing;
      charging = false;
      jumpCharge = 0;
      isOnGroundOrPlatform = false;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.red;
    canvas.drawRect(size.toRect(), paint);
  }
}

class PlatformComponent extends PositionComponent {
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.brown;
    canvas.drawRect(size.toRect(), paint);
  }
}

class GoalComponent extends PositionComponent {
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.yellow;
    canvas.drawRect(size.toRect(), paint);
  }
}
