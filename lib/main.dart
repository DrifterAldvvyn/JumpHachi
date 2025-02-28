import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';

void main() {
  runApp(MyApp());
}

class BackgroundComponent extends SpriteComponent with HasGameRef<MyPlatformGame>{
  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('background.jpeg');
    size = gameRef.size;
    priority = -1; // Ensures the background is behind all other components.
  }
}

class MyApp extends StatelessWidget {
  final MyPlatformGame _game = MyPlatformGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
      fontFamily: 'BaksoSapi',
      ),
      home: Scaffold(
        // Use a Stack to overlay the timer, game view, controls, and winning overlay.
        body: Stack(
          children: [
            GameWidget(
              game: _game,
              overlayBuilderMap: {
                'CongratulationOverlay': (BuildContext context, MyPlatformGame game) {
                  return Center(
                    child: Container(
                      color: Colors.black54,
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/images/won.png', width: 200),
                          SizedBox(height: 20),
                          Text(
                            "Congratulation!",
                            style: TextStyle(fontSize: 40, color: Colors.white),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Your time: ${game.finishTime.toStringAsFixed(1)} seconds",
                            style: TextStyle(fontSize: 24, color: Colors.white),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              game.resetGame();
                            },
                            child: Text("New Game"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              },
            ),
            // Timer display in the top-right corner.
            Positioned(
              top: 16,
              right: 16,
              child: ValueListenableBuilder<double>(
                valueListenable: _game.timerNotifier,
                builder: (context, value, child) {
                  return Text(
                    "Time: ${value.toStringAsFixed(1)}",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  );
                },
              ),
            ),
            // On-screen controls at the bottom.
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Move left button (now in the center).
                    GestureDetector(
                      onTapDown: (_) => _game.moveLeft(true),
                      onTapUp: (_) => _game.moveLeft(false),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.66),
                        ),
                        child: Icon(Icons.arrow_left, color: Colors.white),
                      ),
                    ),
                    // Right movement button (remains on the right).
                    GestureDetector(
                      onTapDown: (_) => _game.moveRight(true),
                      onTapUp: (_) => _game.moveRight(false),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.66),
                        ),
                        child: Icon(Icons.arrow_right, color: Colors.white),
                      ),
                    ),
                    // Jump button (now on the left).
                    GestureDetector(
                      onTapDown: (_) => _game.startChargingJump(),
                      onTapUp: (_) => _game.jump(),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.66),
                        ),
                        child: Icon(Icons.arrow_upward, color: Colors.white),
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

  // Timer variables.
  double gameTime = 0.0;
  double finishTime = 0.0;
  bool gameOver = false;
  // ValueNotifier to update the UI timer overlay.
  ValueNotifier<double> timerNotifier = ValueNotifier(0.0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(BackgroundComponent());
    // Reset timer and game state.
    gameTime = 0.0;
    finishTime = 0.0;
    gameOver = false;
    timerNotifier.value = 0.0;

    // Create the player near the bottom center.
    player = Player()
      ..position = Vector2(size.x / 2 - 25, size.y - 100)
      ..size = Vector2(50, 50);
    add(player);

    // Platform dimensions.
    double platformWidth = 100;
    double platformHeight = 20;
    // Minimum horizontal offset required: 1.3 x player's width.
    double minOffset = 1.3 * player.size.x; // 65 pixels

    // Number of normal platforms.
    int numNormalPlatforms = 3;

    // Generate the first platform randomly.
    double currentX = random.nextDouble() * (size.x - platformWidth);
    double y = size.y - (size.y / (numNormalPlatforms + 2));
    add(PlatformComponent()
      ..position = Vector2(currentX, y)
      ..size = Vector2(platformWidth, platformHeight));

    // For each subsequent platform, generate a candidate x until the offset condition is met.
    for (int i = 1; i < numNormalPlatforms; i++) {
      double candidateX;
      int attempts = 0;
      do {
        candidateX = random.nextDouble() * (size.x - platformWidth);
        attempts++;
      } while ((candidateX - currentX).abs() < minOffset && attempts < 100);
      currentX = candidateX;
      y = size.y - ((i + 1) * (size.y / (numNormalPlatforms + 2)));
      add(PlatformComponent()
        ..position = Vector2(currentX, y)
        ..size = Vector2(platformWidth, platformHeight));
    }

    // Generate the goal platform with the same offset constraint.
    double candidateX;
    int attempts = 0;
    do {
      candidateX = random.nextDouble() * (size.x - platformWidth);
      attempts++;
    } while ((candidateX - currentX).abs() < minOffset && attempts < 100);
    currentX = candidateX;
    double goalY = size.y - ((numNormalPlatforms + 1) * (size.y / (numNormalPlatforms + 2)));
    add(GoalPlatformComponent()
      ..position = Vector2(currentX, goalY)
      ..size = Vector2(platformWidth, platformHeight));
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Update timer if game is not over.
    if (!gameOver) {
      gameTime += dt;
      timerNotifier.value = gameTime;
    }

    // Handle horizontal movement.
    if (movingLeft) {
      if (player.facing == -1.0) {
        player.moveHorizontally(-150 * dt);
      }
      player.facing = -1.0;
    } else if (movingRight) {
      if (player.facing == 1.0) {
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

  // Call this method to reset the game.
  Future<void> resetGame() async {
    if (overlays.isActive('CongratulationOverlay')) {
      overlays.remove('CongratulationOverlay');
    }
    movingLeft = false;
    movingRight = false;
    children.clear();
    await onLoad();
  }
}

class Player extends SpriteComponent with HasGameRef<MyPlatformGame> {
  Vector2 velocity = Vector2.zero();
  double gravity = 600;
  double jumpCharge = 0;
  final double maxJumpCharge = 1.5;
  double facing = 1.0;
  bool charging = false;
  bool isOnGroundOrPlatform = false;
  late Sprite normalSprite;
  late Sprite chargeSprite;

  @override
  Future<void> onLoad() async {
    // Load both sprites.
    normalSprite = await Sprite.load('hachi.png');
    chargeSprite = await Sprite.load('hachi_charge.png');
    sprite = normalSprite;
    size = Vector2(50, 50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Update sprite based on charging status.
    sprite = charging ? chargeSprite : normalSprite;
    // Charge jump if applicable.
    if (charging) {
      jumpCharge += dt;
      if (jumpCharge > maxJumpCharge) jumpCharge = maxJumpCharge;
    }

    // Apply gravity.
    velocity.y += gravity * dt;
    position += velocity * dt;

    bool grounded = false;

    // Collision with ground.
    if (position.y + size.y >= gameRef.size.y) {
      position.y = gameRef.size.y - size.y;
      velocity.y = 0;
      grounded = true;
    }

    // Collision with platforms (normal and goal).
    for (final platform in gameRef.children.whereType<PlatformComponent>()) {
      final Rect playerRect = toRect();
      final Rect platformRect = platform.toRect();

      if (playerRect.overlaps(platformRect)) {
        // Landing on top of the platform.
        if (velocity.y > 0 && (position.y + size.y - platform.position.y).abs() < 10) {
          position.y = platform.position.y - size.y;
          velocity.y = 0;
          grounded = true;
          // If this is the goal platform, trigger win and stop the timer.
          if (platform is GoalPlatformComponent && !gameRef.overlays.isActive('CongratulationOverlay')) {
            gameRef.gameOver = true;
            gameRef.finishTime = gameRef.gameTime;
            gameRef.overlays.add('CongratulationOverlay');

            FlameAudio.play('won_music.mp3');
          }
        }
        // Hitting the bottom of the platform.
        else if (velocity.y < 0 &&
            (position.y - (platform.position.y + platform.size.y)).abs() < 10) {
          position.y = platform.position.y + platform.size.y;
          velocity.y = 0;
        }
        // Side collisions.
        else if (velocity.x > 0 && (position.x + size.x - platform.position.x).abs() < 10) {
          position.x = platform.position.x - size.x;
          velocity.x = 0;
        } else if (velocity.x < 0 &&
            (position.x - (platform.position.x + platform.size.x)).abs() < 10) {
          position.x = platform.position.x + platform.size.x;
          velocity.x = 0;
        }
      }
    }
    isOnGroundOrPlatform = grounded;

    // Apply friction if on ground and no horizontal input.
    if (isOnGroundOrPlatform && !gameRef.movingLeft && !gameRef.movingRight) {
      velocity.x *= 0.9;
      if (velocity.x.abs() < 1) velocity.x = 0;
    }

    // Bounce off screen edges.
    if (position.x < 0) {
      position.x = 0;
      velocity.x = -velocity.x * 0.75;
    } else if (position.x + size.x > gameRef.size.x) {
      position.x = gameRef.size.x - size.x;
      velocity.x = -velocity.x * 0.75;
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
      velocity.x = 150 * facing;
      charging = false;
      jumpCharge = 0;
      isOnGroundOrPlatform = false;

      FlameAudio.play('hachi_jump.mp3');
    }
  }

  @override
  void render(Canvas canvas) {
    if (facing == 1.0) {
      canvas.translate(size.x, 0); // Move origin to the right edge
      canvas.scale(-1, 1); // Flip horizontally
    }
    super.render(canvas);
    final paint = Paint()..color = Colors.red;
    // canvas.drawRect(size.toRect(), paint);
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

class GoalPlatformComponent extends PlatformComponent with HasGameRef<MyPlatformGame> {
  late Sprite goalSprite;
  
@override
  Future<void> onLoad() async {
    await super.onLoad();
    // Load the goal sprite.
    goalSprite = await Sprite.load('chii_roll.png');
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.yellow;
    canvas.drawRect(size.toRect(), paint);

    // Draw the goal sprite slightly above the platform.
    // For instance, we can draw it centered horizontally and a bit above.
    // Adjust the offset and size as needed.
    final double spriteWidth = size.x;
    final double spriteHeight = size.y * 2.6; // slightly larger than the platform height
    final Rect dstRect = Rect.fromLTWH(
      0,
      -spriteHeight - 1, // 5 pixels gap above the platform
      spriteWidth,
      spriteHeight,
    );
    goalSprite.renderRect(canvas, dstRect);
  }
}
