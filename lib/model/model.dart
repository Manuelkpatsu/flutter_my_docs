// ignore_for_file: must_be_immutable

import 'package:equatable/equatable.dart';

class Doc extends Equatable {
  int? id;
  final String title;
  final String expiration;
  final int fqYear;
  final int fqHalfYear;
  final int fqQuarter;
  final int fqMonth;

  Doc(this.title, this.expiration, this.fqYear, this.fqHalfYear, this.fqQuarter,
      this.fqMonth);

  Doc.withId(this.id, this.title, this.expiration, this.fqYear, this.fqHalfYear,
      this.fqQuarter, this.fqMonth);

  Doc.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        expiration = json['expiration'],
        fqYear = json['fqYear'],
        fqHalfYear = json['fqHalfYear'],
        fqQuarter = json['fqQuarter'],
        fqMonth = json['fqMonth'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['expiration'] = expiration;
    data['fqYear'] = fqYear;
    data['fqHalfYear'] = fqHalfYear;
    data['fqQuarter'] = fqQuarter;
    data['fqMonth'] = fqMonth;

    if (id != null) {
      data['id'] = id;
    }

    return data;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        expiration,
        fqYear,
        fqHalfYear,
        fqQuarter,
        fqMonth,
      ];
}
