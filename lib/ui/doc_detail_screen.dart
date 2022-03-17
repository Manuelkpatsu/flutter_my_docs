import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:my_docs/model/model.dart';
import 'package:my_docs/util/db_helper.dart';
import 'package:my_docs/util/utils.dart';

const menuDelete = "Delete";
final List<String> _menuOptions = [menuDelete];

class DocDetailScreen extends StatefulWidget {
  final Doc doc;

  const DocDetailScreen({Key? key, required this.doc}) : super(key: key);

  @override
  State<DocDetailScreen> createState() => _DocDetailScreenState();
}

class _DocDetailScreenState extends State<DocDetailScreen> {
  final DbHelper _dbHelper = DbHelper();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final int _daysAhead = 5475;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _expirationController =
      MaskedTextController(mask: '2000-00-00');
  bool _fqYearCtrl = true;
  bool _fqHalfYearCtrl = true;
  bool _fqQuarterCtrl = true;
  bool _fqMonthCtrl = true;

  void _initCtrls() {
    _titleController.text = widget.doc.title.isNotEmpty ? widget.doc.title : "";
    _expirationController.text =
        widget.doc.expiration.isNotEmpty ? widget.doc.expiration : "";
    _fqYearCtrl = widget.doc.fqYear.toString().isNotEmpty
        ? Val.intToBool(widget.doc.fqYear)
        : false;
    _fqHalfYearCtrl = widget.doc.fqHalfYear.toString().isNotEmpty
        ? Val.intToBool(widget.doc.fqHalfYear)
        : false;
    _fqQuarterCtrl = widget.doc.fqQuarter.toString().isNotEmpty
        ? Val.intToBool(widget.doc.fqQuarter)
        : false;
    _fqMonthCtrl = widget.doc.fqMonth.toString().isNotEmpty
        ? Val.intToBool(widget.doc.fqMonth)
        : false;
  }

  @override
  void initState() {
    super.initState();
    _initCtrls();
  }

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    _expirationController.dispose();
  }

  // Date picker & date function
  Future _chooseDate(BuildContext context, String initialDateString) async {
    var now = DateTime.now();
    var initialDate = DateUtil.convertToDate(initialDateString) ?? now;

    initialDate =
        (initialDate.year >= now.year && initialDate.isAfter(now) ? initialDate : now);

    DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      onConfirm: (date) {
        setState(() {
          DateTime dt = date;
          String r = DateUtil.ftDateAsStr(dt);
          _expirationController.text = r;
        });
      },
      currentTime: initialDate,
    );
  }

  void _selectMenu(String value) async {
    switch (value) {
      case menuDelete:
        if (widget.doc.id == -1) {
          return;
        }
        await _deleteDoc(widget.doc.id!);
    }
  }

  // Delete doc
  Future<void> _deleteDoc(int id) async {
    await _dbHelper.deleteDoc(id);
    Navigator.pop(context, true);
  }

  // Save doc
  void _saveDoc() {
    if (widget.doc.id! > -1) {
      debugPrint("Updating doc with ID: ${widget.doc.id}");
      Doc doc = Doc(
        _titleController.text,
        _expirationController.text,
        Val.boolToInt(_fqYearCtrl),
        Val.boolToInt(_fqHalfYearCtrl),
        Val.boolToInt(_fqQuarterCtrl),
        Val.boolToInt(_fqMonthCtrl),
      );
      _dbHelper.updateDoc(doc);
      Navigator.pop(context, true);
    } else {
      Future<int?> idd = _dbHelper.getMaxId();
      idd.then((result) {
        debugPrint("Inserting doc with ID: ${widget.doc.id}");
        widget.doc.id = (result != null) ? result + 1 : 1;
        Doc doc = Doc.withId(
          widget.doc.id!,
          _titleController.text,
          _expirationController.text,
          Val.boolToInt(_fqYearCtrl),
          Val.boolToInt(_fqHalfYearCtrl),
          Val.boolToInt(_fqQuarterCtrl),
          Val.boolToInt(_fqMonthCtrl),
        );
        _dbHelper.insertDoc(doc);
        Navigator.pop(context, true);
      });
    }
  }

  // Submit form
  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      showMessage("Some data is invalid. Please correct.");
    } else {
      _saveDoc();
    }
  }

  void showMessage(String message, [MaterialColor color = Colors.red]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    TextStyle? style = Theme.of(context).textTheme.titleLarge;
    String ttl = widget.doc.title;

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(ttl != "" ? widget.doc.title : "New Document"),
        actions: (ttl == "")
            ? []
            : [
                PopupMenuButton(
                  onSelected: _selectMenu,
                  itemBuilder: (BuildContext ctx) {
                    return _menuOptions.map((choice) {
                      return PopupMenuItem<String>(value: choice, child: Text(choice));
                    }).toList();
                  },
                )
              ],
      ),
      body: Form(
        key: _formKey,
        child: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              TextFormField(
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp("[a-zA-Z0-9]")),
                ],
                controller: _titleController,
                style: style,
                validator: (val) => Val.validateTitle(val!),
                decoration: const InputDecoration(
                  icon: Icon(Icons.title),
                  hintText: "Enter the document name",
                  labelText: "Document Name",
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expirationController,
                      maxLength: 10,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.calendar_today),
                        hintText:
                            "Expiry date (i.e. ${DateUtil.daysAheadAsStr(_daysAhead)})",
                        labelText: "Expiry date",
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          DateUtil.isValidDate(val!) ? null : "Not a valid future date",
                    ),
                  ),
                  IconButton(
                    tooltip: 'Choose date',
                    onPressed: () => _chooseDate(context, _expirationController.text),
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(child: Text('a: Alert @ 1.5 & 1 year(s)')),
                  Switch(
                    value: _fqYearCtrl,
                    onChanged: (bool value) {
                      setState(() {
                        _fqYearCtrl = value;
                      });
                    },
                  )
                ],
              ),
              Row(
                children: [
                  const Expanded(child: Text('b: Alert @ 6 months')),
                  Switch(
                    value: _fqHalfYearCtrl,
                    onChanged: (bool value) {
                      setState(() {
                        _fqHalfYearCtrl = value;
                      });
                    },
                  )
                ],
              ),
              Row(
                children: [
                  const Expanded(child: Text('c: Alert @ 3 months')),
                  Switch(
                    value: _fqQuarterCtrl,
                    onChanged: (bool value) {
                      setState(() {
                        _fqQuarterCtrl = value;
                      });
                    },
                  )
                ],
              ),
              Row(
                children: [
                  const Expanded(child: Text('d: Alert @ 1 month or less')),
                  Switch(
                    value: _fqMonthCtrl,
                    onChanged: (bool value) {
                      setState(() {
                        _fqMonthCtrl = value;
                      });
                    },
                  )
                ],
              ),
              Container(
                padding: const EdgeInsets.only(left: 40, top: 20),
                child: ElevatedButton(
                  child: const Text('Save'),
                  onPressed: _submitForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
