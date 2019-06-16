import 'dart:convert';
import 'dart:io';

import "package:flutter/material.dart";
import "package:path_provider/path_provider.dart";

void main() {
  runApp(MaterialApp(
    title: "Lista de Tarefas",
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _toDoController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastPos;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  Future<Null> _refreshData() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });

      _saveData();
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = new Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.clear();
      newToDo["ok"] = false;
      _toDoList.add(newToDo);

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Lista de Tarefas"),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
          actions: <Widget>[
            FlatButton(
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
              onPressed: _clearAll,
            )
          ],
        ),
        body: Column(children: <Widget>[
          Container(
            padding: EdgeInsets.all(10.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return "Insira um nome para a tarefa";
                      }
                    },
                  ),
                )),
                Container(
                  padding: EdgeInsets.only(left: 5.0),
                  width: 100.0,
                  height: 60.0,
                  child: RaisedButton(
                    color: Colors.blueAccent,
                    child: Text(
                      "Adicionar",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0),
                    ),
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        _addToDo();
                      }
                    },
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _toDoList.length,
                    itemBuilder: buildItem)),
          ),
        ]));
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          )),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child:
              Icon(_toDoList[index]["ok"] ? Icons.check_circle : Icons.error),
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
          _lastPos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
              content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
              action: SnackBarAction(
                  label: "Desfazer",
                  onPressed: () {
                    setState(() {
                      _toDoList.insert(_lastPos, _lastRemoved);
                      _saveData();
                    });
                  }),
              duration: Duration(seconds: 3));

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  void _clearAll() {
    setState(() {
      List fullList = _toDoList;

      _toDoList.clear();
      _saveData();
    });
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
