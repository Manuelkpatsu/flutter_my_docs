import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_docs/ui/doc_detail_screen.dart';
import 'package:my_docs/util/db_helper.dart';
import 'package:my_docs/util/utils.dart';

import '../model/model.dart';

const menuReset = 'Rest Local Data';
List<String> menuOptions = [menuReset];

class DocListScreen extends StatefulWidget {
  const DocListScreen({Key? key}) : super(key: key);

  @override
  State<DocListScreen> createState() => _DocListScreenState();
}

class _DocListScreenState extends State<DocListScreen> {
  final DbHelper _dbHelper = DbHelper();
  List<Doc>? _docs;
  late DateTime cDate;

  Future getData() async {
    final dbFuture = _dbHelper.initializeDb();
    dbFuture.then((result) {
      final docsFuture = _dbHelper.getDocs();
      docsFuture.then((result) {
        if (result.isNotEmpty) {
          List<Doc> docList = [];
          for (int i = 0; i <= result.length - 1; i++) {
            docList.add(Doc.fromJson(result[i]));
          }
          setState(() {
            if (_docs!.isNotEmpty) {
              _docs!.clear();
            }
            _docs = docList;
          });
        }
      });
    });
  }

  void _checkDate() {
    const secs = Duration(seconds: 10);

    Timer.periodic(secs, (Timer t) {
      DateTime now = DateTime.now();
      if (cDate.day != now.day || cDate.month != now.month || cDate.year != now.year) {
        getData();
        cDate = DateTime.now();
      }
    });
  }

  void _navigateToDetail(Doc doc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocDetailScreen(doc: doc)),
    );
  }

  void _showResetDialog() {
    showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Reset'),
            content: const Text('Do you want to delete all local data?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Future f = _resetLocalData();
                  f.then((result) => Navigator.of(context).pop());
                },
                child: const Text("OK"),
              ),
            ],
          );
        });
  }

  Future _resetLocalData() async {
    final dbFuture = _dbHelper.initializeDb();
    dbFuture.then((result) {
      final dDocs = _dbHelper.deleteAllDocs(DbHelper.tblDocs);
      dDocs.then((result) {
        setState(() {
          _docs!.clear();
        });
      });
    });
  }

  void _selectMenu(String value) async {
    switch (value) {
      case menuReset:
        _showResetDialog();
    }
  }

  @override
  void initState() {
    super.initState();
    if (_docs == null) {
      _docs = [];
      getData();
    }
    _checkDate();
  }

  @override
  Widget build(BuildContext context) {
    cDate = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DocExpire'),
        actions: [
          PopupMenuButton(
            onSelected: _selectMenu,
            itemBuilder: (BuildContext ctx) {
              return menuOptions.map((choice) {
                return PopupMenuItem<String>(value: choice, child: Text(choice));
              }).toList();
            },
          )
        ],
      ),
      body: Center(
        child: docListItems(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToDetail(Doc.withId(-1, "", "", 1, 1, 1, 1)),
        tooltip: "Add new doc",
        child: const Icon(Icons.add),
      ),
    );
  }

  ListView docListItems() {
    return ListView.builder(
      itemCount: _docs!.length,
      itemBuilder: (BuildContext ctx, int index) {
        Doc doc = _docs![index];
        String dd = Val.getExpiryStr(doc.expiration);
        String dl = (dd != "1") ? " days left" : " day left";

        return Card(
          color: Colors.white,
          elevation: 1,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  (Val.getExpiryStr(doc.expiration) != "0") ? Colors.blue : Colors.red,
              child: Text(doc.id.toString()),
            ),
            title: Text(doc.title),
            subtitle: Text(
                "${Val.getExpiryStr(doc.expiration)} $dl \nExp: ${DateUtil.convertDateToFull(doc.expiration)}"),
            onTap: () => _navigateToDetail(doc),
          ),
        );
      },
    );
  }
}
