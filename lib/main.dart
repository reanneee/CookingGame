import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async' as async;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  runApp(GameWidget(game: MyCookingGame()));
}

class MyCookingGame extends FlameGame with HasCollisionDetection, TapDetector {
  late SpriteComponent background;
  List<Ingredient> ingredients = [];
  List<CookingStation> cookingStations = [];
  List<ServingPlate> servingPlates = [];
  Customer? currentCustomer;
  late TextComponent scoreText;
  late TextComponent timerText;
  async.Timer? gameTimer;
  int score = 0;
  int gameTime = 500;
  bool isGameOver = false;

  final List<Map<String, dynamic>> ingredientTypes = [
    {
      'name': 'Egg',
      'raw': 'egg.png',
      'cooked': 'cooked-egg.png',
      'cookTime': 2.0
    },
    {
      'name': 'Chicken',
      'raw': 'chicken.png',
      'cooked': 'cooked-chicken.png',
      'cookTime': 3.0
    },
    {'name': 'Meat', 'raw': 'meat.png', 'cooked': 'steak.png', 'cookTime': 4.0},
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor =
        Anchor.topLeft; // Ensure proper coordinate system

    background = SpriteComponent()
      ..sprite = await loadSprite("background.png")
      ..size = size;
    add(background);

    scoreText = TextComponent(
      text: 'Score: 0',
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      position: Vector2(20, 20),
    );
    add(scoreText);

    timerText = TextComponent(
      text: 'Time: 2:00',
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      position: Vector2(size.x - 150, 20),
    );
    add(timerText);

    _loadIngredients();
    _loadCookingStations();
    _loadServingPlates();
    _spawnCustomer();
    _startGameTimer();
  }

  void _loadIngredients() {
    double spacing = size.x / (ingredientTypes.length + 1);
    for (int i = 0; i < ingredientTypes.length; i++) {
      var data = ingredientTypes[i];
      add(Ingredient(
        name: data['name'],
        rawImage: data['raw'],
        cookedImage: data['cooked'],
        cookTime: data['cookTime'],
        position: Vector2(spacing * (i + 1), size.y - 100),
        game: this,
      ));
    }
  }

  void _loadCookingStations() {
    double spacing = size.x / 6;
    for (int i = 0; i < 4; i++) {
      CookingStation station = CookingStation(
        position: Vector2(spacing * (i + 1), size.y / 2 + 50),
        game: this,
      );
      add(station);
      cookingStations.add(station);
    }
  }

  void _loadServingPlates() {
    double spacing = size.x / 6;
    for (int i = 0; i < 4; i++) {
      // Modified position to ensure plates are "on the table"
      ServingPlate plate = ServingPlate(
        position: Vector2(spacing * (i + 1), size.y / 2 + 10),
        game: this,
      );
      add(plate);
      servingPlates.add(plate);
    }
  }

  void _spawnCustomer() {
    if (isGameOver || currentCustomer != null) return;
    Random random = Random();
    var orderItem = ingredientTypes[random.nextInt(ingredientTypes.length)];
    double patience = 10.0 + random.nextDouble() * 10.0;

    Customer customer = Customer(
      startPosition: Vector2(-100, size.y / 4),
      centerPosition: Vector2(size.x / 2, size.y / 4),
      exitPosition: Vector2(size.x + 100, size.y / 4),
      orderItem: orderItem['cooked'],
      orderName: orderItem['name'],
      patience: patience,
      game: this,
    );

    add(customer);
    currentCustomer = customer;
  }

  void _startGameTimer() {
    if (gameTimer != null) {
      gameTimer!.cancel();
    }
    const oneSec = Duration(seconds: 1);
    gameTimer = async.Timer.periodic(oneSec, (timer) {
      if (isGameOver) {
        timer.cancel();
        return;
      }

      gameTime--;
      int minutes = gameTime ~/ 60;
      int seconds = gameTime % 60;
      timerText.text = 'Time: $minutes:${seconds.toString().padLeft(2, '0')}';

      if (gameTime <= 0) {
        timer.cancel();
        _endGame();
      }
    });
  }

  void updateScore(int points) {
    score += points;
    scoreText.text = 'Score: $score';
  }

  Ingredient createNewIngredient(String name, String rawImage,
      String cookedImage, double cookTime, Vector2 position) {
    Ingredient newIngredient = Ingredient(
      name: name,
      rawImage: rawImage,
      cookedImage: cookedImage,
      cookTime: cookTime,
      position: position.clone(),
      game: this,
    );
    add(newIngredient);
    ingredients.add(newIngredient);
    return newIngredient;
  }

  void customerServed() {
    currentCustomer = null;
    if (!isGameOver) {
      Future.delayed(const Duration(seconds: 2), _spawnCustomer);
    }
  }

  void _endGame() {
    isGameOver = true;
    if (gameTimer != null) {
      gameTimer!.cancel();
    }

    // Remove all customers to prevent errors
    if (currentCustomer != null) {
      currentCustomer!.removeFromParent();
      currentCustomer = null;
    }

    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.black.withOpacity(0.7),
    ));

    add(TextComponent(
      text: 'GAME OVER\nFinal Score: $score',
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _checkInteractions();
  }

  void _checkInteractions() {
    List<Ingredient> ingredientsCopy = [...ingredients];
    for (var ingredient in ingredientsCopy) {
      if (!ingredient.isDragging && !ingredient.isBeingCooked) continue;

      for (var station in cookingStations) {
        if (!station.isOccupied &&
            ingredient.toRect().overlaps(station.toRect()) &&
            !ingredient.isCooked) {
          station.startCooking(ingredient);
          break;
        }
      }

      for (var plate in servingPlates) {
        if (!plate.isOccupied &&
            ingredient.toRect().overlaps(plate.toRect()) &&
            ingredient.isCooked) {
          plate.setFood(ingredient);
          break;
        }
      }

      if (currentCustomer != null &&
          ingredient.toRect().overlaps(currentCustomer!.toRect()) &&
          ingredient.isCooked &&
          ingredient.cookedImage == currentCustomer!.orderItem &&
          currentCustomer!.hasReachedCenter) {
        currentCustomer!.serve();
        ingredient.removeFromParent();
        ingredients.remove(ingredient);
      }
    }

    for (var plate in servingPlates) {
      if (plate.isDragging &&
          plate.foodItem != null &&
          currentCustomer != null) {
        if (plate.toRect().overlaps(currentCustomer!.toRect()) &&
            currentCustomer!.hasReachedCenter &&
            plate.foodItem!.cookedImage == currentCustomer!.orderItem) {
          Ingredient servedFood = plate.foodItem!;
          plate.releaseFood();

          // Ensure plate returns to its original position
          plate.position = plate.originalPosition.clone();

          currentCustomer!.serve();
          servedFood.removeFromParent();
          ingredients.remove(servedFood);
        }
      }
    }
  }

  @override
  void onRemove() {
    if (gameTimer != null) {
      gameTimer!.cancel();
    }
    super.onRemove();
  }
}

class Ingredient extends SpriteComponent with DragCallbacks {
  final String name;
  final String rawImage;
  final String cookedImage;
  final double cookTime;
  final MyCookingGame game;

  bool isDragging = false;
  bool isCooked = false;
  bool isBeingCooked = false;
  bool isOnServingPlate = false;
  Vector2 originalPosition;

  Ingredient({
    required this.name,
    required this.rawImage,
    required this.cookedImage,
    required this.cookTime,
    required Vector2 position,
    required this.game,
  })  : originalPosition = position.clone(),
        super(position: position, size: Vector2(80, 80)) {
    game.ingredients.add(this);
  }

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load(rawImage);
    priority = 2;
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (isBeingCooked) return;
    if (!isCooked && !isOnServingPlate) {
      game.createNewIngredient(
          name, rawImage, cookedImage, cookTime, originalPosition);
    }
    isDragging = true;
    priority = 20; // Significantly increased priority to ensure visibility
    if (isOnServingPlate) {
      for (var plate in game.servingPlates) {
        if (plate.foodItem == this) {
          plate.releaseFood();
          break;
        }
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isBeingCooked) return;
    position.add(event.localDelta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    isDragging = false;
    priority = isCooked ? 15 : 2; // Increased priority for cooked food
    if (isCooked && !_isOnValidTarget()) {
      removeFromParent();
      game.ingredients.remove(this);
    }
  }

  bool _isOnValidTarget() {
    for (var station in game.cookingStations) {
      if (toRect().overlaps(station.toRect()) &&
          !isCooked &&
          !station.isOccupied) return true;
    }
    for (var plate in game.servingPlates) {
      if (toRect().overlaps(plate.toRect()) && isCooked && !plate.isOccupied)
        return true;
    }
    if (game.currentCustomer != null &&
        toRect().overlaps(game.currentCustomer!.toRect()) &&
        isCooked &&
        cookedImage == game.currentCustomer!.orderItem &&
        game.currentCustomer!.hasReachedCenter) return true;
    return false;
  }

  Future<void> cook() async {
    isBeingCooked = true;
    sprite = await Sprite.load(cookedImage);
    isCooked = true;
    isBeingCooked = false;
    priority = 15; // Increased priority for cooked food
  }
}

class CookingStation extends SpriteComponent {
  bool isOccupied = false;
  Ingredient? cookingIngredient;
  late SpriteComponent progressBar;
  late RectangleComponent progressFill;
  final MyCookingGame game;

  CookingStation({required Vector2 position, required this.game})
      : super(size: Vector2(100, 100), position: position);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('cooking-station.png');
    priority = 1;

    // Create a better progress bar background
    progressBar = SpriteComponent()
      ..sprite = await Sprite.load('LoadingWheel.png')
      ..size = Vector2(80, 10)
      ..position = Vector2(10, -15)
      ..opacity = 0;
    add(progressBar);

    // This is the fill bar that shows cooking progress
    progressFill = RectangleComponent(
      size: Vector2(0, 8),
      position: Vector2(11, -14),
      paint: Paint()..color = Colors.green,
    );
    progressFill.priority = 5; // Ensure progress bar is visible
    add(progressFill);
  }

  void startCooking(Ingredient ingredient) {
    if (isOccupied) return;
    isOccupied = true;
    cookingIngredient = ingredient;
    ingredient.isBeingCooked = true;

    // Center the ingredient better on the cooking station
    ingredient.position = position + Vector2(10, 10);

    // Show progress bar components
    progressBar.opacity = 1;
    progressFill.opacity = 1;

    _cookWithProgress(ingredient);
  }

  Future<void> _cookWithProgress(Ingredient ingredient) async {
    double cookTime = ingredient.cookTime;
    double elapsed = 0;
    const updateInterval = 0.1;

    try {
      while (elapsed < cookTime) {
        await Future.delayed(
            Duration(milliseconds: (updateInterval * 1000).toInt()));
        if (game.isGameOver || ingredient.parent == null) {
          _resetStation();
          return;
        }
        elapsed += updateInterval;
        // Update the width of the progress fill bar based on cooking progress
        progressFill.size.x = 78 * (elapsed / cookTime);
      }
      await ingredient.cook();
    } catch (e) {
      print("Error during cooking: $e");
    } finally {
      _resetStation();
    }
  }

  void _resetStation() {
    isOccupied = false;
    cookingIngredient = null;
    progressBar.opacity = 0;
    progressFill.opacity = 0;
    progressFill.size.x = 0;
  }
}

class ServingPlate extends SpriteComponent with DragCallbacks {
  bool isOccupied = false;
  bool isDragging = false;
  Ingredient? foodItem;
  final MyCookingGame game;
  final Vector2 originalPosition;

  ServingPlate({required Vector2 position, required this.game})
      : originalPosition = position.clone(),
        super(size: Vector2(100, 100), position: position);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('plate.png');
    priority = 1;
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (isOccupied && foodItem != null) {
      isDragging = true;
      priority = 10; // Higher priority for plate when dragging
      if (foodItem != null) {
        foodItem!.priority = 20; // Much higher priority for food
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!isDragging) return;
    Vector2 delta = event.localDelta;
    position.add(delta);
    if (foodItem != null) {
      // Make sure food moves with plate
      foodItem!.position.add(delta);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    isDragging = false;
    priority = 1;

    // Check if we successfully served the customer
    bool served = false;
    if (foodItem != null && game.currentCustomer != null) {
      if (toRect().overlaps(game.currentCustomer!.toRect()) &&
          game.currentCustomer!.hasReachedCenter &&
          foodItem!.cookedImage == game.currentCustomer!.orderItem) {
        served = true;
      }
    }

    // If not served, return to original position
    if (!served) {
      position = originalPosition.clone();
      if (foodItem != null) {
        // Make food more visible on the plate - centered and elevated
        _repositionFoodOnPlate();
      }
    }
  }

  void setFood(Ingredient ingredient) {
    if (isOccupied) return;
    isOccupied = true;
    foodItem = ingredient;
    ingredient.isOnServingPlate = true;

    // Position food visibly on the plate
    _repositionFoodOnPlate();
  }

  void _repositionFoodOnPlate() {
    if (foodItem == null) return;

    // Position food centered and elevated on the plate for better visibility
    foodItem!.position = position + Vector2(10, -40);
    foodItem!.priority = 20; // Very high priority for visibility

    // Increase the size of the food to make it more visible
    foodItem!.scale = Vector2(1.5, 1.5);

    // Make sure the food is visible by bringing it to the front
    if (foodItem!.parent != null) {
      foodItem!.parent!.children.remove(foodItem!);
      foodItem!.parent!.children.add(foodItem!);
    }
  }

  void releaseFood() {
    if (foodItem != null) {
      foodItem!.isOnServingPlate = false;
      // Reset the scale when food is released
      foodItem!.scale = Vector2(1.0, 1.0);
      isOccupied = false;
      foodItem = null;
    }
  }
}

class Customer extends SpriteComponent {
  final Vector2 startPosition;
  final Vector2 centerPosition;
  final Vector2 exitPosition;
  final String orderItem;
  final String orderName;
  final double patience;
  final MyCookingGame game;

  bool isServed = false;
  bool hasReachedCenter = false;
  bool isLeaving = false;
  double timeWaiting = 0;

  RectangleComponent? orderBubble;
  SpriteComponent? orderIcon;
  RectangleComponent? patienceBar;
  RectangleComponent? patienceFill;

  bool isMoving = false;

  Customer({
    required this.startPosition,
    required this.centerPosition,
    required this.exitPosition,
    required this.orderItem,
    required this.orderName,
    required this.patience,
    required this.game,
  }) : super(position: startPosition, size: Vector2(100, 100));

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('male.png');
    priority = 1;
    _moveToCenter();
  }

  void _setupOrderDisplay() async {
    // Make the order bubble more visible
    orderBubble = RectangleComponent(
      size: Vector2(60, 60),
      position: Vector2(20, -70),
      paint: Paint()..color = Colors.white,
    );
    orderBubble!.priority = 4;
    add(orderBubble!);

    // Make the icon for the ordered food
    orderIcon = SpriteComponent()
      ..sprite = await Sprite.load(orderItem)
      ..size = Vector2(40, 40)
      ..position = Vector2(30, -60)
      ..priority = 5;
    add(orderIcon!);

    // Add text to show what the customer wants
    orderBubble!.add(TextComponent(
      text: orderName,
      textRenderer:
          TextPaint(style: const TextStyle(color: Colors.black, fontSize: 12)),
      position: Vector2(30, -15),
      anchor: Anchor.center,
    ));

    // Create patience bar background
    patienceBar = RectangleComponent(
      size: Vector2(80, 10),
      position: Vector2(10, -85),
      paint: Paint()..color = Colors.grey,
    );
    patienceBar!.priority = 4;
    add(patienceBar!);

    // Create patience bar fill that will shrink as patience decreases
    patienceFill = RectangleComponent(
      size: Vector2(80, 10),
      position: Vector2(10, -85),
      paint: Paint()..color = Colors.green,
    );
    patienceFill!.priority = 5;
    add(patienceFill!);
  }

  Future<void> _moveToCenter() async {
    if (isMoving) return;
    isMoving = true;

    const fps = 60.0;
    const moveDuration = 2.0;
    final totalFrames = (moveDuration * fps).toInt();

    for (int frame = 0; frame <= totalFrames; frame++) {
      if (game.isGameOver) {
        isMoving = false;
        return;
      }
      final t = frame / totalFrames;
      position = startPosition + (centerPosition - startPosition) * t;
      await Future.delayed(Duration(milliseconds: (1000 / fps).round()));
    }

    position = centerPosition.clone();
    hasReachedCenter = true;
    isMoving = false;
    _setupOrderDisplay();
  }

  Future<void> _moveToExit() async {
    if (isMoving) return;
    isMoving = true;

    // Clean up UI elements
    if (orderBubble != null) orderBubble!.removeFromParent();
    if (orderIcon != null) orderIcon!.removeFromParent();
    if (patienceBar != null) patienceBar!.removeFromParent();
    if (patienceFill != null) patienceFill!.removeFromParent();

    isLeaving = true;
    hasReachedCenter = false;

    const fps = 60.0;
    const moveDuration = 2.0;
    final totalFrames = (moveDuration * fps).toInt();
    final startPos = position.clone();

    for (int frame = 0; frame <= totalFrames; frame++) {
      if (game.isGameOver) {
        isMoving = false;
        break;
      }
      final t = frame / totalFrames;
      position = startPos + (exitPosition - startPos) * t;
      await Future.delayed(Duration(milliseconds: (1000 / fps).round()));
    }

    isServed = true;
    isMoving = false;
    removeFromParent();
    game.customerServed();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!hasReachedCenter || isLeaving || isServed) return;

    timeWaiting += dt;

    if (patienceFill != null) {
      double patiencePercent = 1 - (timeWaiting / patience);
      patienceFill!.size.x = 80 * patiencePercent;

      if (patiencePercent > 0.6) {
        patienceFill!.paint.color = Colors.green;
      } else if (patiencePercent > 0.3) {
        patienceFill!.paint.color = Colors.orange;
      } else {
        patienceFill!.paint.color = Colors.red;
      }

      if (timeWaiting >= patience && !isLeaving) {
        game.updateScore(-10);
        _moveToExit();
      }
    }
  }

  void serve() {
    if (isServed || isLeaving) return;

    isServed = true;

    double patiencePercent = 1 - (timeWaiting / patience);
    int points = (patiencePercent * 20).round() + 10;
    game.updateScore(points);

    // Score indicator
    add(TextComponent(
      text: '+$points',
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold)),
      position: Vector2(50, -50),
      anchor: Anchor.center,
    ));

    _moveToExit();
  }
}
