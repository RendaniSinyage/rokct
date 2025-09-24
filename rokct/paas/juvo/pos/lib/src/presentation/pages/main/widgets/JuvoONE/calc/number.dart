abstract class Number {
  String get display;
  String apply(String original);
}

class NormalNumber extends Number {
  @override
  final String display;

  NormalNumber(this.display);

  @override
  String apply(String original) {
    return original == '0' ? display : original + display;
  }
}

class SymbolNumber extends Number {
  @override
  String get display => '+/-';

  @override
  String apply(String original) {
    int index = original.indexOf('-');
    if (index == -1 && original != '0') {
      return '-' + original;
    } else {
      return original.replaceFirst(RegExp(r'-'), '');
    }
  }
}

class DecimalNumber extends Number {
  @override
  String get display => '.';

  @override
  String apply(String original) {
    int index = original.indexOf('.');
    if (index == -1) {
      return original + '.';
    } else if (index == original.length - 1) {
      return original.substring(0, original.length - 1);
    } else {
      return original;
    }
  }
}
