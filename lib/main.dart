import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(
    title: "Lista de Tarefas",
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        if (data != null) {
          _toDoList = json.decode(data);
        }
      });
    });
  }

  Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  Future<bool> _saveData() async {
    String data = json.encode(_toDoList);
    final prefs = await _getPrefs();
    return prefs.setString("toDoList", data);
  }

  Future<String> _readData() async {
    try {
      final prefs = await _getPrefs();
      print(prefs);
      return prefs.getString("toDoList");
    } catch (e) {
      return e;
    }
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        }
        return 0;
      });

      _saveData();
    });

    return null;
  }

  void _clearAll() {
    setState(() {
      List fullList = _toDoList;

      _toDoList.clear();
      _saveData();
    });
  }

  Widget buildItem(context, index) {
    return Dismissible(
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (checked) {
          setState(() {
            _toDoList[index]["ok"] = checked;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPosition = index;
          _toDoList.removeAt(index);
          _saveData();

          final snackBar = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Lista de tarefas"),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
          actions: <Widget>[
            TextButton(
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
              onPressed: _clearAll,
            )
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(
                children: [
                  Expanded(
                      child: Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _toDoController,
                      decoration: InputDecoration(
                          labelText: "Nova Tarefa",
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Insira um nome para a tarefa";
                        }
                      },
                    ),
                  )),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: Colors.blueAccent,
                          textStyle: TextStyle(color: Colors.white)),
                      child: Text("Adicionar"),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          _addToDo();
                        }
                      })
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 10.0),
                      itemCount: _toDoList.length,
                      itemBuilder: buildItem)),
            )
          ],
        ),
      ),
    );
  }
}
