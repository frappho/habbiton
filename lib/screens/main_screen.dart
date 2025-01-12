import "package:flutter/material.dart";
import "package:habbit_tracker/db/database_helper.dart";

class HabitTrackerScreen extends StatefulWidget {
  @override
  _HabitTrackerScreenState createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  List<String> titles = ['Habbit 1'];
  List<List<int>> gridData = [List.generate(365, (index) => 0)];
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<int> screenIds = [];

  void _addScreen() async {
    final screenId = await DatabaseHelper.instance.insertScreen('Habbit ${titles.length + 1}');
    setState(() {
      titles.add('Habbit ${titles.length + 1}');
      screenIds.add(screenId);
      gridData.add(List.generate(365, (index) => 0));
      _pageController.jumpToPage(titles.length);
    });
    print("Screens-titles: $titles");
  }

  void _updateTitle(int screenindex) async {
    final screenId = await DatabaseHelper.instance.fetchScreens();
    TextEditingController titleController = TextEditingController();
    final FocusNode titleFocus = FocusNode();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Namen ändern'),
        content: TextField(
          focusNode: titleFocus,
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Name des Habbits'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.updateScreen(screenId[screenindex]["id"], titleController.text);
              titleController.text != ""
                  ? setState(() {
                      titles[screenindex] = titleController.text;
                    })
                  : null;
              Navigator.of(context).pop();
            },
            child: const Text('Ändern'),
          ),
        ],
      ),
    ).then((_) {
      titleFocus.dispose();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      titleFocus.requestFocus();
    });
  }

  void _updateBox(int screenIndex, int boxIndex) {
    TextEditingController valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stunden für Tag ${boxIndex + 1} angeben'),

        ///TODO: Date instead of year
        content: TextField(
          controller: valueController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Eingabe Stunden (1-24)'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              int value = int.tryParse(valueController.text) ?? 0;
              if (value >= 0 && value <= 24) {
                _updateGrid(screenIndex, boxIndex, value);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _updateGrid(int screenIndex, int boxIndex, int value) async {
    // print("updateGrid-screenIndex=$screenIndex");
    final screenId = screenIds[screenIndex];
    // await DatabaseHelper.instance.updateBox(screenId[screenIndex]['id'], boxIndex, value);
    await DatabaseHelper.instance.insertBox(screenId, boxIndex, value);
    setState(() {
      gridData[screenIndex][boxIndex] = value;
    });
  }

  Future<void> _loadScreens() async {
    final screens = await DatabaseHelper.instance.fetchScreens();
    setState(() {
      titles = screens.map((e) => e['title'].toString()).toList();
      screenIds = screens.map((e) => e['id'] as int).toList();
      gridData = screens.map((e) => List.generate(365, (index) => 0)).toList();

      // Lade Box-Daten für jeden Screen
      for (int i = 0; i < screens.length; i++) {
        _loadBoxes(screens[i]['id'], i);
      }
    });
  }

  Future<void> _loadBoxes(int screenId, int index) async {
    final boxes = await DatabaseHelper.instance.fetchBoxes(screenId);
    setState(() {
      for (var box in boxes) {
        gridData[index][box['box_index']] = box['hours'];
      }
    });
  }

  void _deleteScreen(int index) async {
    final screenIdToDelete = screenIds[index];

    await DatabaseHelper.instance.deleteScreen(screenIdToDelete);

    setState(() {
      titles.removeAt(index);
      gridData.removeAt(index);
      screenIds.removeAt(index);
      if (index == titles.length) {
        _currentIndex = index - 1;
      } else {
        _currentIndex = index;
      }
    });
  }

  void _showDeletePopup(String name, int screenIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Habbit löschen"),
        content: Text("Wirklich $name löschen?"),
        actions: [
          TextButton(
            onPressed: () {
              _deleteScreen(screenIndex);
              Navigator.of(context).pop();
            },
            child: const Text("Löschen"),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadScreens();
    // DatabaseHelper.instance.initializeDatabase();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Habbiton",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      titles.length,
                      (index) => GestureDetector(
                        onTap: () => _pageController.jumpToPage(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 20,
                          width: 40,
                          color: index == _currentIndex ? Colors.blueGrey : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_box_outlined),
                onPressed: _addScreen,
              ),
            ],
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: titles.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    GestureDetector(
                      onLongPress: () => _showDeletePopup(titles[index], index),
                      onTap: () => _updateTitle(index),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          titles[index],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 15,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: 365,
                          itemBuilder: (context, boxIndex) {
                            int value = gridData[index][boxIndex];
                            Color boxColor = value == 0 ? Colors.grey[300]! : Color.lerp(Colors.green[100], Colors.green, value / 10)!;
                            int boxNum = boxIndex + 1;
                            return GestureDetector(
                              onTap: () => _updateBox(index, boxIndex),
                              child: Container(
                                alignment: Alignment.center,
                                color: boxColor,
                                child: Text(
                                  boxNum.toString(),
                                  style: const TextStyle(color: Colors.black, fontSize: 10),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
