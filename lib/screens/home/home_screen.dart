import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo_rem/models/todos.dart';

import '../../helper/database_helper.dart';
import '../addTodo/add_todo.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = "/home";
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  bool isGridMode = false;
  final Future<SharedPreferences> _pref = SharedPreferences.getInstance();
  late SharedPreferences prefs;

  List<Todos> myTodos = <Todos>[];
  int count = 0;

  @override
  void initState() {
    super.initState();
    updateListView();
    getValue();
  }

  @override
  void dispose() {
    super.dispose();
    _databaseHelper.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todos',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isGridMode = !isGridMode;
                prefs.setBool('boolValue', isGridMode);
              });
            },
            icon: isGridMode
                ? const Icon(
                    Icons.list,
                  )
                : const Icon(Icons.grid_4x4_outlined),
          ),
        ],
        backgroundColor: Colors.purple,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //Navigating to next Screen to add new Todo
          navigateToAddScreen('Add Todo', Todos('', '', 1, ''));
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            isGridMode
                ? GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 1.0,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 20,
                    ),
                    shrinkWrap: true,
                    itemCount: myTodos.length,
                    itemBuilder: ((context, index) => Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),

                          //Based on Priority value, set card COlor

                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(myTodos[index].priority == 1
                                    ? Icons.priority_high
                                    : Icons.low_priority),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 8),
                                  child: Text(
                                    myTodos[index].title,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  myTodos[index].description,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(.0),
                                  child: Divider(
                                    height: 2,
                                    thickness: 2,
                                    color: Colors.black12,
                                  ),
                                ),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      InkWell(
                                          onTap: () {
                                            delete(myTodos[index].id!);
                                          },
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          )),
                                      InkWell(
                                          onTap: () {
                                            //Navigating to Edit an existing TODO
                                            navigateToAddScreen(
                                                'Edit Todo', myTodos[index]);
                                          },
                                          child: const Icon(Icons.edit)),
                                    ]),
                              ],
                            ),
                          ),
                        )),
                  )
                : ListView.builder(
                    itemCount: count,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        //Based on Priority value, set card COlor
                        color: Colors.white,
                        child: ListTile(
                          title: Text(
                            myTodos[index].title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            myTodos[index].description,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: Icon(myTodos[index].priority == 1
                              ? Icons.priority_high
                              : Icons.low_priority),
                          trailing: SizedBox(
                            width: 56,
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  InkWell(
                                      onTap: () {
                                        delete(myTodos[index].id!);
                                      },
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      )),
                                  InkWell(
                                      onTap: () {
                                        //Navigating to Edit an existing TODO
                                        navigateToAddScreen(
                                            'Edit Todo', myTodos[index]);
                                      },
                                      child: const Icon(Icons.edit)),
                                ]),
                          ),
                        ),
                      );
                    },
                  )
          ],
        ),
      )),
    );
  }

  navigateToAddScreen(String title, Todos todos) async {
    bool result = await Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return AddTodoScreen(title, todos);
      },
    ));
    if (result == true) {
      updateListView();
    }
  }

  //updateListview
  updateListView() async {
    final Future<Database> dbFuture = _databaseHelper.initalizeDatabase();
    dbFuture.then(
      (value) {
        Future<List<Todos>> listFuture = _databaseHelper.getNoteList();
        listFuture.then(
          (list) {
            setState(() {
              myTodos = list;
              count = list.length;
            });
          },
        );
      },
    );
  }

  //Delete function
  void delete(int id) async {
    var result = _databaseHelper.deleteNote(id);
    if (result != 0) {
      showSimpleNotification(
          autoDismiss: true,
          position: NotificationPosition.bottom,
          const Text("Todo Deleted Successfully"),
          background: Colors.purple);
    } else {
      showSimpleNotification(
          autoDismiss: true,
          position: NotificationPosition.bottom,
          const Text("Error Deleting!!!"),
          background: Colors.purple);
    }
    updateListView();
  }

  getValue() async {
    prefs = await _pref;
    setState(() {
      isGridMode = (prefs.containsKey('boolValue')
          ? prefs.getBool('boolValue')
          : false)!;
      print(isGridMode);
    });
  }
}
