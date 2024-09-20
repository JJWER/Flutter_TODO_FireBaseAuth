import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lab_todo/screen/signin_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab TODO',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const SigninScreen(),
    );
  }
}

class TodaApp extends StatefulWidget {
  const TodaApp({super.key});

  @override
  State<TodaApp> createState() => _TodaAppState();
}

class _TodaAppState extends State<TodaApp> {
  late TextEditingController _texteditController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _texteditController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  void addTodoHandle(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add new task"),
          content: SizedBox(
            width: 300,
            child: Column(
              children: [
                TextField(
                  controller: _texteditController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Input your task",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Description",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                CollectionReference tasks =
                    FirebaseFirestore.instance.collection("tasks");
                tasks.add({
                  'name': _texteditController.text,
                  'note': _descriptionController.text,
                  'status': false,
                }).then((res) {
                  print('Task added: $res');
                }).catchError((onError) {
                  print("Failed to add new Task: $onError");
                });
                setState(() {
                  _texteditController.clear();
                  _descriptionController.clear();
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void editTodoHandle(BuildContext context, DocumentSnapshot task) {
    _texteditController.text = task['name'];
    _descriptionController.text = task['note'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit task"),
          content: SizedBox(
            width: 300,
            child: Column(
              children: [
                TextField(
                  controller: _texteditController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Edit your task",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Edit Description",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection("tasks")
                    .doc(task.id)
                    .update({
                  'name': _texteditController.text,
                  'note': _descriptionController.text,
                }).then((res) {
                  print('Task updated');
                }).catchError((onError) {
                  print("Failed to update task: $onError");
                });
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void deleteTodoHandle(BuildContext context, DocumentSnapshot task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete task"),
          content: const Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection("tasks")
                    .doc(task.id)
                    .delete()
                    .then((res) {
                  print('Task deleted');
                }).catchError((onError) {
                  print("Failed to delete task: $onError");
                });
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todo"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SigninScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("tasks").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
            return const Center(child: Text("No tasks available"));
          }
          return ListView.builder(
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (context, index) {
              var task = snapshot.data?.docs[index];
              if (task == null || task.data() == null) {
                return const ListTile(
                  title: Text("Invalid task"),
                );
              }
              var taskData = task.data() as Map<String, dynamic>;
              var taskName = taskData.containsKey("name") ? taskData["name"] : "No name";
              var taskNote = taskData.containsKey("note") ? taskData["note"] : "No description available";
              var taskStatus = taskData.containsKey("status") && taskData["status"] is bool
                  ? taskData["status"] as bool
                  : false;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                elevation: 5,
                child: ListTile(
                  title: Text(taskName),
                  subtitle: Text(taskNote),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          editTodoHandle(context, task);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          deleteTodoHandle(context, task);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          taskStatus ? Icons.check_box : Icons.check_box_outline_blank,
                        ),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection("tasks")
                              .doc(task.id)
                              .update({'status': !taskStatus})
                              .then((res) {
                            print('Task status updated');
                          }).catchError((onError) {
                            print("Failed to update task status: $onError");
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addTodoHandle(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
