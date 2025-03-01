import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(CookingApp());
}

class CookingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cooking App',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: CookingScreen(),
    );
  }
}

class CookingScreen extends StatefulWidget {
  @override
  _CookingScreenState createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> {
  final List<Map<String, dynamic>> ingredientDetails = [
    {
      'name': 'Egg',
      'image': 'images/egg.png',
      'cooked': 'images/cooked-egg.png',
      'count': 3
    },
    {
      'name': 'Chicken',
      'image': 'images/chicken.png',
      'cooked': 'images/cooked-chicken.png',
      'count': 3
    },
    {
      'name': 'Steak',
      'image': 'images/meat.png',
      'cooked': 'images/steak.png',
      'count': 3
    },
    {
      'name': 'Fries',
      'image': 'images/potato.png',
      'cooked': 'images/french-fries.png',
      'count': 3
    },
    {
      'name': 'Shrimp',
      'image': 'images/shrimp.png',
      'cooked': 'images/fried-shrimp.png',
      'count': 3
    },
  ];

  final List<String?> cookedImages = List.filled(6, null);
  final List<Map<String, dynamic>?> cookingArea = List.filled(6, null);

  final List<String> customerNames = [
    'Alice',
    'Bob',
    'Charlie',
    'David',
    'Emma'
  ];
  final List<Map<String, String>> activeCustomers = [];
  final Random random = Random();
  int coins = 9999;
  int xp = 0;
  int level = 1;
  int xpThreshold = 10;

  final List<bool> isCooking = List.filled(6, false);

  @override
  void initState() {
    super.initState();
    _generateCustomers();
  }

  void _generateCustomers() {
    setState(() {
      if (activeCustomers.isEmpty) {
        while (activeCustomers.length < 3) {
          String name = customerNames[random.nextInt(customerNames.length)];
          Map<String, dynamic> order =
              ingredientDetails[random.nextInt(ingredientDetails.length)];
          if (!activeCustomers.any((customer) => customer['name'] == name)) {
            activeCustomers.add({'name': name, 'order': order['cooked']!});
          }
        }
      } else {
        String newName = "";

        do {
          newName = customerNames[random.nextInt(customerNames.length)];
        } while (
            activeCustomers.any((customer) => customer['name'] == newName));
        Map<String, dynamic> order =
            ingredientDetails[random.nextInt(ingredientDetails.length)];
        activeCustomers.add({'name': newName, 'order': order['cooked']});
      }
    });
  }

  void _customerSatisfied(Map<String, String> customer) {
    setState(() {
      activeCustomers.remove(customer);
      coins += 5;
      xp += 5;
      if (xp >= xpThreshold) {
        level++;
        xp = 0;
        xpThreshold += 10;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('${customer['name']} is satisfied!'),
          backgroundColor: Colors.transparent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cooking Game')),
      body: Column(
        children: [
          Container(
            height: 80,
            color: Colors.orange[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Coins: \$ $coins',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('XP: $xp / $xpThreshold',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Level: $level',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            height: 120,
            color: Colors.orange[100],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ingredientDetails.length,
              itemBuilder: (context, index) {
                final ingredient = ingredientDetails[index];
                return ingredient['count'] > 0
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Draggable<Map<String, dynamic>>(
                          data: ingredient,
                          feedback: IngredientCard(image: ingredient['image']!),
                          onDragStarted: () {
                            setState(() {
                              ingredient['count'] -= 1;
                            });
                          },
                          onDraggableCanceled: (velocity, offset) {
                            setState(() {
                              ingredient['count'] += 1;
                            });
                          },
                          child: Stack(
                            children: [
                              IngredientCard(
                                  image: ingredient['image']!,
                                  name: ingredient['name']!),
                              Positioned(
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    // vertical: 2,
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                      color: Colors.red.shade900,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    ingredient['count'].toString(),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: IngredientCard(
                                image: ingredient['image']!,
                                name: ingredient['name']!),
                          ),
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    if (coins >= 10) {
                                      ingredient['count'] += 3;
                                      coins -= 10;
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('Not enough coins!')),
                                      );
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 0,
                                  ),
                                ),
                                child: Text(
                                  "Buy (+3)",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
              },
            ),
          ),
          SizedBox(height: 20),
          DragTarget<Map<String, dynamic>>(
            onAccept: (data) {
              setState(() {
                for (int i = 0; i < cookingArea.length; i++) {
                  if (cookingArea[i] == null) {
                    cookingArea[i] = {
                      ...data,
                      'isCooking': false,
                    };
                    _startCooking(i);
                    break;
                  }
                }
              });
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                height: 100,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final item = cookingArea[index];
                    return item == null
                        ? Container(
                            width: 40,
                            height: 40,
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black),
                            ),
                          )
                        : Draggable<Map<String, dynamic>>(
                            data: item,
                            feedback: Image.asset(item['cooked']!,
                                height: 50, width: 50),
                            childWhenDragging: SizedBox(width: 50, height: 50),
                            onDragCompleted: () {
                              setState(() {
                                cookingArea[index] = null;
                              });
                            },
                            child: item['isCooking']
                                ? Stack(children: [
                                    Image.asset(
                                      item['image']!,
                                      height: 50,
                                      width: 50,
                                    ),
                                    TweenAnimationBuilder(
                                      tween: Tween<double>(begin: 0, end: 1.0),
                                      duration: Duration(seconds: 3),
                                      builder: (context, value, child) {
                                        return CircularProgressIndicator(
                                          value: value,
                                          strokeWidth: 4,
                                          color: Colors.green,
                                        );
                                      },
                                    )
                                  ])
                                : Image.asset(item['cooked']!,
                                    height: 50, width: 50),
                          );
                  }),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: activeCustomers.map((customer) {
              return DragTarget<Map<String, dynamic>>(
                onWillAccept: (data) {
                  print("Accepting: $data['cooked']");

                  return data != null && data['cooked'] == customer['order'];
                },
                onAccept: (data) {
                  setState(() {
                    activeCustomers.remove(customer);
                    _customerSatisfied(customer);

                    _generateCustomers();
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    padding: const EdgeInsets.only(bottom: 50),
                    color: Colors.grey.shade200,
                    child: Column(
                      children: [
                        Text(customer['name']!,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Image.asset(customer['order']!, width: 40, height: 40),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Future<void> _startCooking(int panIndex, String cookedImage) async {
  //   // await _audioPlayer.play(AssetSource('sounds/frying_sound.mp3'));
  //   await Future.delayed(Duration(seconds: 3));
  //   setState(() {
  //     cookedImages[panIndex] = cookedImage;
  //   });
  // }

  void _startCooking(int index) {
    setState(() {
      cookingArea[index]!['isCooking'] = true;
    });

    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        cookingArea[index]!['isCooking'] = false;
        cookingArea[index]!['image'] = cookingArea[index]!['cooked'];
      });
    });
  }
}

class IngredientCard extends StatelessWidget {
  final String image;
  final String name;
  IngredientCard({required this.image, this.name = ""});

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [Image.asset(image, width: 50, height: 50), Text(name)]);
  }
}
