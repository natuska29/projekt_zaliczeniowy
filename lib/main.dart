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

      body: Padding(

        padding: EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(
              "Masz dziś ${tasks.length} zadania (zrobione: $doneCount)",
            ),

            SizedBox(height: 8),

            Row(

              children: [

                TextButton(

                  onPressed: () {

                    setState(() {
                      selectedFilter = "wszystkie";
                    });
                  },

                  child: Text(

                    "Wszystkie",

                    style: TextStyle(

                      color:
                      selectedFilter == "wszystkie"
                          ? Colors.blue
                          : Colors.black,
                    ),
                  ),
                ),

                TextButton(

                  onPressed: () {

                    setState(() {
                      selectedFilter = "do zrobienia";
                    });
                  },

                  child: Text(

                    "Do zrobienia",

                    style: TextStyle(

                      color:
                      selectedFilter == "do zrobienia"
                          ? Colors.blue
                          : Colors.black,
                    ),
                  ),
                ),

                TextButton(

                  onPressed: () {

                    setState(() {
                      selectedFilter = "wykonane";
                    });
                  },

                  child: Text(

                    "Wykonane",

                    style: TextStyle(

                      color:
                      selectedFilter == "wykonane"
                          ? Colors.blue
                          : Colors.black,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            Text(

              "Dzisiejsze zadania",

              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16),

            Expanded(

              child: ListView.builder(

                itemCount: filteredTasks.length,

                itemBuilder: (context, index) {

                  final task = filteredTasks[index];

                  return Dismissible(

                    key: ValueKey(task.id),

                    direction: DismissDirection.endToStart,

                    onDismissed: (direction) async {

                      await TaskLocalDatabase.deleteTask(task.id);

                      loadTasks();

                      ScaffoldMessenger.of(context).showSnackBar(

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

                      done: task.done,

                      onChanged: (value) async {

                        final updatedTask = Task(

                          id: task.id,
                          title: task.title,
                          deadline: task.deadline,
                          done: value!,
                          priority: task.priority,
                        );

                        await TaskLocalDatabase.updateTask(updatedTask);

                        loadTasks();
                      },

                      onTap: () async {

                        final Task? updatedTask =
                        await Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (context) =>
                                EditTaskScreen(task: task),
                          ),
                        );

                        if (updatedTask != null) {

                          await TaskLocalDatabase.updateTask(updatedTask);

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

      floatingActionButton: FloatingActionButton(

        onPressed: () async {

          final Task? newTask = await Navigator.push(

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

        child: Icon(Icons.add),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {

  final String title;
  final String subtitle;
  final bool done;

  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Card(

      margin: EdgeInsets.only(bottom: 12),

      child: ListTile(

        onTap: onTap,

        leading: Checkbox(
          value: done,
          onChanged: onChanged,
        ),

        title: Text(

          title,

          style: TextStyle(

            fontWeight: FontWeight.bold,

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

        subtitle: Text(

          subtitle,

          style: TextStyle(

            color:
            done
                ? Colors.grey
                : Colors.black,
          ),
        ),

        trailing: Icon(Icons.chevron_right),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {

  AddTaskScreen({super.key});

  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController deadlineController =
  TextEditingController();

  final TextEditingController priorityController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Nowe zadanie"),
      ),

      body: Padding(

        padding: EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            TextField(

              controller: titleController,

              decoration: InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            TextField(

              controller: deadlineController,

              decoration: InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            TextField(

              controller: priorityController,

              decoration: InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(

              onPressed: () {

                final newTask = Task(

                  id: Random().nextInt(1000000),

                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: false,
                  priority: priorityController.text,
                );

                Navigator.pop(context, newTask);
              },

              child: Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {

  final Task task;

  EditTaskScreen({
    super.key,
    required this.task,
  });

  late final TextEditingController titleController =
  TextEditingController(text: task.title);

  late final TextEditingController deadlineController =
  TextEditingController(text: task.deadline);

  late final TextEditingController priorityController =
  TextEditingController(text: task.priority);

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

              decoration: InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            TextField(

              controller: priorityController,

              decoration: InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(

              onPressed: () {

                final updatedTask = Task(

                  id: task.id,
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: task.done,
                  priority: priorityController.text,
                );

                Navigator.pop(context, updatedTask);
              },

              child: Text("Zapisz zmiany"),
            ),
          ],
        ),
      ),
    );
  }
}