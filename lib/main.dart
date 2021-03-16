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

  List _toDoList = [];

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

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Lista de tarefas"),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
        ),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _toDoController,
                      decoration: InputDecoration(
                          labelText: "Nova Tarefa",
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                    ),
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: Colors.blueAccent,
                          textStyle: TextStyle(color: Colors.white)),
                      child: Text("Adicionar"),
                      onPressed: _addToDo)
                ],
              ),
            ),
            Expanded(
                child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _toDoList.length,
                    itemBuilder: (context, index) {
                      return CheckboxListTile(
                        title: Text(_toDoList[index]["title"]),
                        value: _toDoList[index]["ok"],
                        secondary: CircleAvatar(
                          child: Icon(_toDoList[index]["ok"]
                              ? Icons.check
                              : Icons.error),
                        ),
                        onChanged: (checked) {
                          setState(() {
                            _toDoList[index]["ok"] = checked;
                            _saveData();
                          });
                        },
                      );
                    }))
          ],
        ),
      ),
    );
  }
}
