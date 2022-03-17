import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../model/model.dart';

class DbHelper {
  static String tblDocs = "docs";
  static String docId = "id";
  static String docTitle = "title";
  static String docExpiration = "expiration";
  static String fqYear = "fqYear";
  static String fqHalfYear = "fqHalfYear";
  static String fqQuarter = "fqQuarter";
  static String fqMonth = "fqMonth";

  // Singleton
  static final DbHelper _dbHelper = DbHelper._internal();

  // Factory constructor
  DbHelper._internal();

  factory DbHelper() {
    return _dbHelper;
  }

  // Database entry point
  late Database _db;

  Future<Database> get db async {
    _db = await initializeDb();
    return _db;
  }

  // Initialize the database
  Future<Database> initializeDb() async {
    Directory d = await getApplicationDocumentsDirectory();
    String p = d.path + "/docexpire.db";
    var db = await openDatabase(p, version: 1, onCreate: _createDb);
    return db;
  }

  // Create database table
  void _createDb(Database db, int version) async {
    await db.execute("CREATE TABLE $tblDocs($docId INTEGER PRIMARY KEY, "
        "$docTitle TEXT, $docExpiration TEXT, $fqYear INTEGER, "
        "$fqHalfYear INTEGER, $fqQuarter INTEGER, "
        "$fqMonth INTEGER)");
  }

  // Insert a new doc
  Future<int?> insertDoc(Doc doc) async {
    int? r;

    Database db = await this.db;
    try {
      r = await db.insert(tblDocs, doc.toJson());
      return r;
    } catch (e) {
      debugPrint("Inserting doc: $e");
    }
    return r;
  }

  // Get the list of docs
  Future<List> getDocs() async {
    Database db = await this.db;
    return await db.rawQuery("SELECT * FROM $tblDocs ORDER BY $docExpiration ASC");
  }

  // Gets a doc based on the id
  Future<List> getDoc(int id) async {
    Database db = await this.db;
    return await db
        .rawQuery("SELECT * FROM $tblDocs WHERE $docId = " + id.toString() + "");
  }

  // Gets a doc based on a string payload
  Future<List?> getDocFromStr(String payload) async {
    List<String> p = payload.split("|");
    if (p.length == 2) {
      Database db = await this.db;
      return await db.rawQuery("SELECT * FROM $tblDocs WHERE $docId = " +
          p[0] +
          " AND $docExpiration = '" +
          p[1] +
          "'");
    } else {
      return null;
    }
  }

  // Get the number of docs
  Future<int?> getDocsCount() async {
    Database db = await this.db;
    var r = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM $tblDocs"));
    return r;
  }

  // Get the max document id available on the database
  Future<int?> getMaxId() async {
    Database db = await this.db;
    var r = Sqflite.firstIntValue(await db.rawQuery("SELECT MAX(id) FROM $tblDocs"));
    return r;
  }

  // Update a doc
  Future<int> updateDoc(Doc doc) async {
    var db = await this.db;
    return await db.update(
      tblDocs,
      doc.toJson(),
      where: "$docId = ?",
      whereArgs: [doc.id],
    );
  }

  // Delete a doc
  Future<int> deleteDoc(int id) async {
    var db = await this.db;
    return await db.rawDelete("DELETE FROM $tblDocs WHERE $docId = $id");
  }

  // Delete all docs
  Future<int> deleteAllDocs(String tbl) async {
    var db = await this.db;
    return await db.rawDelete("DELETE FROM $tbl");
  }
}
