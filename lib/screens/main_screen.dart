import "package:flutter/material.dart";
import "package:Habbiton/const/years.dart";
import "package:Habbiton/db/database_helper.dart";
import "package:Habbiton/screens/settings_screen.dart";

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
  List<int> screenType = [];
  List<String> yearsList = [];
  bool isLoading = true;

  void _addScreen() async {
    final List<String> years = ["2025", "2026", "2027", "2028", "2029", "2030", "2031", "2032", "2033", "2034", "2035"];
    bool hoursCheck = true;
    bool doneCheck = false;
    String? selectedValue = DateTime.now().year.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Habbit erstellen"),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void _onCheckboxChanged(int checkboxIndex) {
              setState(() {
                if (checkboxIndex == 1) {
                  hoursCheck = true;
                  doneCheck = false;
                } else if (checkboxIndex == 2) {
                  hoursCheck = false;
                  doneCheck = true;
                }
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text("Für welches Jahr? "),
                    DropdownButton<String>(
                      value: selectedValue,
                      items: years.map((String items) {
                        return DropdownMenuItem<String>(
                          value: items,
                          child: Text(items),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedValue = newValue;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Art des Eintragens"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        const Text("Stunden"),
                        Checkbox(
                          value: hoursCheck,
                          onChanged: (value) {
                            _onCheckboxChanged(1);
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text("Erledigt"),
                        Checkbox(
                          value: doneCheck,
                          onChanged: (value) {
                            _onCheckboxChanged(2);
                          },
                        ),
                      ],
                    ),
                  ],
                )
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final int days = yearMap[selectedValue!]?["days"] ?? 365;
              int type = hoursCheck ? 0 : 1;

              final screenId = await DatabaseHelper.instance.insertScreen(
                'Habbit ${titles.length + 1}',
                days,
                type,
                selectedValue!,
              );

              setState(() {
                if (titles.length == 0) {
                  _currentIndex = 0;
                };
                titles.add('Habbit ${titles.length + 1}');
                screenIds.add(screenId);
                screenType.add(type);
                yearsList.add(selectedValue!);

                gridData.add(List.generate(days, (index) => 0));
                Future.delayed(Duration(milliseconds: 500), () {
                  _pageController.animateToPage(
                    titles.length,
                    duration: Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                  );
                });
              });
              Navigator.of(context).pop();
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  void _updateTitle(int screenindex) async {
    final screenId = await DatabaseHelper.instance.fetchScreens();
    TextEditingController titleController = TextEditingController();
    final FocusNode titleFocus = FocusNode();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Namen ändern'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Name darf nicht leer sein!";
              } else if (value.length > 15) {
                return "Name darf nicht länger als 15 Zeichen sein!";
              }
              return null;
            },
            focusNode: titleFocus,
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Name des Habbits',
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2.0),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await DatabaseHelper.instance.updateScreen(
                  screenId[screenindex]["id"],
                  titleController.text,
                );
                setState(() {
                  titles[screenindex] = titleController.text;
                });
                Navigator.of(context).pop();
              } else {
                titleController.clear();
              }
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

  void _updateBox(int screenIndex, int gridIndex, int boxIndex, String month) {
    TextEditingController valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eintrag für den ${boxIndex + 1}. ${month}'),
        content: TextField(
          controller: valueController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Eingabe Stunden (1-24)'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              int value = double.tryParse(valueController.text.replaceAll(',', '.'))?.round() ?? 0;
              if (value >= 0 && value <= 12) {
                _updateGrid(screenIndex, gridIndex, value);
              } else if (value > 12 && value <= 24) {
                _updateGrid(screenIndex, gridIndex, 13);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _updateGrid(int screenIndex, int gridIndex, int value) async {
    final screenId = screenIds[screenIndex];
    await DatabaseHelper.instance.insertBox(screenId, gridIndex, value);
    setState(() {
      gridData[screenIndex][gridIndex] = value;
    });
  }

  Future<void> _loadScreens() async {
    setState(() {
      isLoading = true;
    });

    final screens = await DatabaseHelper.instance.fetchScreens();
    setState(() {
      titles = screens.map((e) => e['title'].toString()).toList();
      screenIds = screens.map((e) => e['id'] as int).toList();
      screenType = screens.map((e) => e['type'] as int).toList();
      yearsList = screens.map((e) => e['year'].toString()).toList();

      gridData = screens.map((e) {
        int days = e["days"] ?? 365;
        return List.generate(days, (index) => 0);
      }).toList();

      for (int i = 0; i < screens.length; i++) {
        _loadBoxes(screens[i]['id'], i);
      }

      isLoading = false;
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
      screenIds.removeAt(index);
      screenType.removeAt(index);
      yearsList.removeAt(index);

      if (index < gridData.length) {
        gridData.removeAt(index);
      }

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

  int calculateStartIndex(String year, int monthIndex) {
    int start = yearMap[year]?["start"]-1 ?? 1;
    int accumulatedDays = 0;

    for (int i = 0; i < monthIndex; i++) {
      String prevMonth = yearMap[year]?.keys.elementAt(i) ?? "";
      int prevDays = yearMap[year]?[prevMonth] ?? 0;
      accumulatedDays += prevDays;
    }

    return (start + accumulatedDays) % 7;
  }


  @override
  void initState() {
    super.initState();
    _loadScreens();
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
        actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen())), icon: Icon(Icons.notification_add))],
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
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
                titles.length == 0
                    ? Center(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/Habbiton-bean-3-sad-no-bg.png",
                            scale: 1.5,
                          ),
                          Text(
                            "Noch kein Habbit vorhanden",
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ))
                    : Expanded(
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
                                    padding: const EdgeInsets.fromLTRB(16.0,16.0,16.0,0.0),
                                    child: Text(
                                      titles[index],
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Text(
                                  yearsList[index],
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: SizedBox(
                                    child: GridView.builder(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 14,
                                        crossAxisSpacing: 4,
                                        mainAxisSpacing: 0,
                                      ), itemCount: 14
                                      , itemBuilder: (context, index) {
                                      List<String> weekDays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So","Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];
                                      return Container(
                                        alignment: Alignment.center,
                                        color: Colors.transparent,
                                        child: Text(
                                          weekDays[index],
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    },),height: 30,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                    child: ListView.builder(
                                      itemCount: 12,
                                      itemBuilder: (context, monthIndex) {
                                        final String year = yearsList[index];
                                        final String month = yearMap[year]?.keys.elementAt(monthIndex) ?? "";
                                        final int daysInMonth = yearMap[year]?[month] ?? 0;

                                        int startIndex = calculateStartIndex(year, monthIndex);

                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              child: Text(
                                                month,
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            GridView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 14,
                                                crossAxisSpacing: 4,
                                                mainAxisSpacing: 4,
                                              ),
                                              itemCount: daysInMonth + startIndex,
                                              itemBuilder: (context, dayIndex) {
                                                if (dayIndex < startIndex) {
                                                  return Container(color: Colors.transparent);
                                                }

                                                int globalIndex = dayIndex - startIndex;
                                                int value = gridData[index][globalIndex];
                                                Color boxColor = value == 0 ? Colors.grey[300]! : Color.lerp(Colors.green[100], Colors.green[900], value / 10)!;

                                                return GestureDetector(
                                                  onTap: () => screenType[index] == 0
                                                      ? _updateBox(index, globalIndex, dayIndex - startIndex, month)
                                                      : value == 10
                                                      ? _updateGrid(index, globalIndex, 0)
                                                      : _updateGrid(index, globalIndex, 10),
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    color: boxColor,
                                                    child: Text(
                                                      "${dayIndex - startIndex + 1}",
                                                      style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
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
