class DeviceUserDateInfo {
  bool mon = false;
  bool tue = false;
  bool wed = false;
  bool thur = false;
  bool fri = false;
  bool satu = false;
  bool sun = false;

  void setDay(bool mon, bool tue, bool wed, bool thur, bool fri, bool satu, bool sun) {
    this.mon = mon;
    this.tue = tue;
    this.wed = wed;
    this.thur = thur;
    this.fri = fri;
    this.satu = satu;
    this.sun = sun;
  }
  void setMapDay(Map<String, bool> map) {
    mon = map['mon']!;
    tue = map['tue']!;
    wed = map['wed']!;
    thur = map['thur']!;
    fri = map['fri']!;
    satu = map['satu']!;
    sun = map['sun']!;
  }
  void setAllDay() {
    this.mon = true;
    this.tue = true;
    this.wed = true;
    this.thur = true;
    this.fri = true;
    this.satu = true;
    this.sun = true;
  }

  void formDate(int date) {
    this.mon = ((date & 0x01) == 1);
    this.tue = ((date & 0x02) == 1);
    this.wed = ((date & 0x04) == 1);
    this.thur = ((date & 0x08) == 1);
    this.fri = ((date & 0x10) == 1);
    this.satu = ((date & 0x20) == 1);
    this.sun = ((date & 0x40) == 1);
  }

  int getValue() {
    int value = 0x00;

    if (mon) {
      value |= 0x01;
    }

    if (tue) {
      value |= 0x02;
    }

    if (wed) {
      value |= 0x04;
    }

    if (thur) {
      value |= 0x08;
    }

    if (fri) {
      value |= 0x10;
    }

    if (satu) {
      value |= 0x20;
    }

    if (sun) {
      value |= 0x40;
    }

    return value;
  }

  @override
  String toString() {
    return 'DeviceUserDateInfo{mon: $mon, tue: $tue, wed: $wed, thur: $thur, fri: $fri, satu: $satu, sun: $sun}';
  }
  Map toMap() {
    return {
      'mon': mon,
      'tue': tue,
      'wed': wed,
      'thur': thur,
      'fri': fri,
      'satu': satu,
      'sun': sun,
    };
  }
}