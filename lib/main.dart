import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox("tasks");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      theme: ThemeData(

        primarySwatch: Colors.pink,

        scaffoldBackgroundColor: Color(0xFFF5F3FF),

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        floatingActionButtonTheme:
        FloatingActionButtonThemeData(
          backgroundColor: Colors.pinkAccent,
        ),
      ),

      home: HomeScreen(),
    );
  }
}

class Task {

  final int id;
  String title;
  String deadline;
  bool done;
  String priority;

  Task({
    required this.id,
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });

  Map<String, dynamic> toMap() {

    return {
      "id": id,
      "title": title,
      "deadline": deadline,
      "done": done,
      "priority": priority,
    };
  }

  factory Task.fromMap(Map map) {

    return Task(
      id: map["id"],
      title: map["title"],
      deadline: map["deadline"],
      done: map["done"],
      priority: map["priority"],
    );
  }
}

class TaskLocalDatabase {

  static Box get _box => Hive.box("tasks");

  static List<Task> getTasks() {

    return _box.values.map((item) {

      return Task.fromMap(
        Map<String, dynamic>.from(item),
      );

    }).toList();
  }

  static Future<void> addTask(Task task) async {

    await _box.put(task.id, task.toMap());
  }

  static Future<void> updateTask(Task task) async {

    await _box.put(task.id, task.toMap());
  }

  static Future<void> deleteTask(int id) async {

    await _box.delete(id);
  }

  static Future<void> deleteAllTasks() async {

    await _box.clear();
  }
}

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String selectedFilter = "wszystkie";

  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  void loadTasks() {

    final loadedTasks = TaskLocalDatabase.getTasks();

    setState(() {
      tasks = loadedTasks;
    });
  }

  @override
  Widget build(BuildContext context) {

    int doneCount = tasks.where((t) => t.done).length;

    List<Task> filteredTasks = tasks;

    if (selectedFilter == "wykonane") {

      filteredTasks =
          tasks.where((task) => task.done).toList();
    }

    else if (selectedFilter == "do zrobienia") {

      filteredTasks =
          tasks.where((task) => !task.done).toList();
    }

    return Scaffold(

      appBar: AppBar(

        title: Text("KrakFlow"),

        actions: [

          IconButton(

            icon: Icon(Icons.delete),

            onPressed: () {

              showDialog(

                context: context,

                builder: (context) {

                  return AlertDialog(

                    title: Text("Potwierdzenie"),

                    content: Text(
                      "Czy na pewno chcesz usunąć wszystkie zadania?",
                    ),

                    actions: [

                      TextButton(

                        onPressed: () {
                          Navigator.pop(context);
                        },

                        child: Text("Anuluj"),
                      ),

                      TextButton(

                        onPressed: () async {

                          await TaskLocalDatabase.deleteAllTasks();

                          loadTasks();

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(

                            SnackBar(
                              content: Text(
                                "Usunięto wszystkie zadania",
                              ),
                            ),
                          );
                        },

                        child: Text("Usuń"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),

      body: Container(

        decoration: BoxDecoration(

          gradient: LinearGradient(

            colors: [
              Color(0xFFF3E7FF),
              Color(0xFFE4D4FF),
            ],

            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Padding(

          padding: EdgeInsets.all(16),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                "Masz dziś ${tasks.length} zadania (zrobione: $doneCount)",

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 12),

              Row(

                children: [

                  filterButton("wszystkie", "Wszystkie"),

                  filterButton(
                    "do zrobienia",
                    "Do zrobienia",
                  ),

                  filterButton(
                    "wykonane",
                    "Wykonane",
                  ),
                ],
              ),

              SizedBox(height: 20),

              Text(

                "Dzisiejsze zadania ✨",

                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),

              SizedBox(height: 20),

              Expanded(

                child: ListView.builder(

                  itemCount: filteredTasks.length,

                  itemBuilder: (context, index) {

                    final task = filteredTasks[index];

                    return Dismissible(

                      key: ValueKey(task.id),

                      direction:
                      DismissDirection.endToStart,

                      background: Container(

                        alignment: Alignment.centerRight,

                        padding: EdgeInsets.only(right: 20),

                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                          BorderRadius.circular(20),
                        ),

                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),

                      onDismissed: (direction) async {

                        await TaskLocalDatabase
                            .deleteTask(task.id);

                        loadTasks();

                        ScaffoldMessenger.of(context)
                            .showSnackBar(

                          SnackBar(

                            content: Text(
                              "Usunięto zadanie: ${task.title}",
                            ),
                          ),
                        );
                      },

                      child: TaskCard(

                        title: task.title,

                        subtitle:
                        "termin: ${task.deadline} | priorytet: ${task.priority}",

                        priority: task.priority,

                        done: task.done,

                        onChanged: (value) async {

                          final updatedTask = Task(

                            id: task.id,
                            title: task.title,
                            deadline: task.deadline,
                            done: value!,
                            priority: task.priority,
                          );

                          await TaskLocalDatabase
                              .updateTask(updatedTask);

                          loadTasks();
                        },

                        onTap: () async {

                          final Task? updatedTask =
                          await Navigator.push(

                            context,

                            MaterialPageRoute(

                              builder: (context) =>
                                  EditTaskScreen(
                                    task: task,
                                  ),
                            ),
                          );

                          if (updatedTask != null) {

                            await TaskLocalDatabase
                                .updateTask(updatedTask);

                            loadTasks();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton:
      FloatingActionButton.extended(

        icon: Icon(Icons.add),

        label: Text("Dodaj"),

        onPressed: () async {

          final Task? newTask =
          await Navigator.push(

            context,

            MaterialPageRoute(
              builder: (context) => AddTaskScreen(),
            ),
          );

          if (newTask != null) {

            await TaskLocalDatabase.addTask(newTask);

            loadTasks();
          }
        },
      ),
    );
  }

  Widget filterButton(
      String value,
      String label,
      ) {

    return Padding(

      padding: EdgeInsets.only(right: 8),

      child: ElevatedButton(

        style: ElevatedButton.styleFrom(

          backgroundColor:
          selectedFilter == value
              ? Colors.pinkAccent
              : Colors.white,

          foregroundColor:
          selectedFilter == value
              ? Colors.white
              : Colors.black,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        onPressed: () {

          setState(() {
            selectedFilter = value;
          });
        },

        child: Text(label),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {

  final String title;
  final String subtitle;
  final String priority;
  final bool done;

  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({

    super.key,

    required this.title,
    required this.subtitle,
    required this.priority,
    required this.done,

    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    Color priorityColor = Colors.green;
    IconData priorityIcon = Icons.low_priority;

    if (priority == "wysoki") {

      priorityColor = Colors.red;
      priorityIcon = Icons.priority_high;
    }

    else if (priority == "średni") {

      priorityColor = Colors.orange;
      priorityIcon = Icons.notifications;
    }

    return Card(

      elevation: 6,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      margin: EdgeInsets.only(bottom: 14),

      child: ListTile(

        contentPadding: EdgeInsets.all(12),

        onTap: onTap,

        leading: Checkbox(
          value: done,
          onChanged: onChanged,
        ),

        title: Text(

          title,

          style: TextStyle(

            fontWeight: FontWeight.bold,

            fontSize: 18,

            decoration:
            done
                ? TextDecoration.lineThrough
                : TextDecoration.none,

            color:
            done
                ? Colors.grey
                : Colors.black,
          ),
        ),

        subtitle: Padding(

          padding: EdgeInsets.only(top: 6),

          child: Text(

            subtitle,

            style: TextStyle(

              color: priorityColor,

              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        trailing: Icon(
          priorityIcon,
          color: priorityColor,
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {

  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() =>
      _AddTaskScreenState();
}

class _AddTaskScreenState
    extends State<AddTaskScreen> {

  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController deadlineController =
  TextEditingController();

  String selectedPriority = "średni";

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Nowe zadanie"),
      ),

      body: Container(

        decoration: BoxDecoration(

          gradient: LinearGradient(

            colors: [
              Color(0xFFF3E7FF),
              Color(0xFFE4D4FF),
            ],

            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Padding(

          padding: EdgeInsets.all(16),

          child: Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Text(

                "Dodaj nowe zadanie ✨",

                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),

              SizedBox(height: 24),

              TextField(

                controller: titleController,

                decoration: InputDecoration(

                  labelText: "Tytuł zadania",

                  prefixIcon: Icon(Icons.task_alt),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                ),
              ),

              SizedBox(height: 16),

              TextField(

                controller: deadlineController,

                readOnly: true,

                decoration: InputDecoration(

                  labelText: "Termin",

                  prefixIcon:
                  Icon(Icons.calendar_month),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                ),

                onTap: () async {

                  DateTime? pickedDate =
                  await showDatePicker(

                    context: context,

                    initialDate: DateTime.now(),

                    firstDate: DateTime(2024),

                    lastDate: DateTime(2030),
                  );

                  if (pickedDate != null) {

                    String formattedDate =
                        "${pickedDate.day}.${pickedDate.month}.${pickedDate.year}";

                    setState(() {

                      deadlineController.text =
                          formattedDate;
                    });
                  }
                },
              ),

              SizedBox(height: 16),

              DropdownButtonFormField(

                value: selectedPriority,

                decoration: InputDecoration(

                  labelText: "Priorytet",

                  prefixIcon: Icon(Icons.flag),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                ),

                items: [

                  DropdownMenuItem(
                    value: "niski",
                    child: Text("Niski"),
                  ),

                  DropdownMenuItem(
                    value: "średni",
                    child: Text("Średni"),
                  ),

                  DropdownMenuItem(
                    value: "wysoki",
                    child: Text("Wysoki"),
                  ),
                ],

                onChanged: (value) {

                  setState(() {
                    selectedPriority = value!;
                  });
                },
              ),

              SizedBox(height: 30),

              SizedBox(

                width: double.infinity,

                height: 55,

                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                    Colors.pinkAccent,

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                  ),

                  onPressed: () {

                    final newTask = Task(

                      id: Random().nextInt(1000000),

                      title: titleController.text,

                      deadline:
                      deadlineController.text,

                      done: false,

                      priority: selectedPriority,
                    );

                    Navigator.pop(
                      context,
                      newTask,
                    );
                  },

                  child: Text(

                    "Zapisz",

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatefulWidget {

  final Task task;

  const EditTaskScreen({

    super.key,
    required this.task,
  });

  @override
  State<EditTaskScreen> createState() =>
      _EditTaskScreenState();
}

class _EditTaskScreenState
    extends State<EditTaskScreen> {

  late final TextEditingController titleController =
  TextEditingController(
    text: widget.task.title,
  );

  late final TextEditingController
  deadlineController =
  TextEditingController(
    text: widget.task.deadline,
  );

  late String selectedPriority =
      widget.task.priority;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Edytuj zadanie"),
      ),

      body: Padding(

        padding: EdgeInsets.all(16),

        child: Column(

          children: [

            TextField(

              controller: titleController,

              decoration: InputDecoration(
                labelText: "Tytuł",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            TextField(

              controller: deadlineController,

              readOnly: true,

              decoration: InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
                suffixIcon:
                Icon(Icons.calendar_month),
              ),

              onTap: () async {

                DateTime? pickedDate =
                await showDatePicker(

                  context: context,

                  initialDate: DateTime.now(),

                  firstDate: DateTime(2024),

                  lastDate: DateTime(2030),
                );

                if (pickedDate != null) {

                  String formattedDate =
                      "${pickedDate.day}.${pickedDate.month}.${pickedDate.year}";

                  setState(() {

                    deadlineController.text =
                        formattedDate;
                  });
                }
              },
            ),

            SizedBox(height: 16),

            DropdownButtonFormField(

              value: selectedPriority,

              decoration: InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),

              items: [

                DropdownMenuItem(
                  value: "niski",
                  child: Text("Niski"),
                ),

                DropdownMenuItem(
                  value: "średni",
                  child: Text("Średni"),
                ),

                DropdownMenuItem(
                  value: "wysoki",
                  child: Text("Wysoki"),
                ),
              ],

              onChanged: (value) {

                setState(() {
                  selectedPriority = value!;
                });
              },
            ),

            SizedBox(height: 20),

            SizedBox(

              width: double.infinity,

              height: 50,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(

                  backgroundColor:
                  Colors.pinkAccent,

                  foregroundColor:
                  Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                ),

                onPressed: () {

                  final updatedTask = Task(

                    id: widget.task.id,

                    title: titleController.text,

                    deadline:
                    deadlineController.text,

                    done: widget.task.done,

                    priority: selectedPriority,
                  );

                  Navigator.pop(
                    context,
                    updatedTask,
                  );
                },

                child: Text(
                  "Zapisz zmiany",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}