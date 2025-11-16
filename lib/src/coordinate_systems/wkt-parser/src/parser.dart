const NEUTRAL = 1;
const KEYWORD = 2;
const NUMBER = 3;
const QUOTED = 4;
const AFTERQUOTE = 5;
const ENDED = -1;
var whitespaceRegexp = RegExp(r'\s');
var latinRegexp = RegExp(r'[A-Za-z]');
var keywordRegex = RegExp(r'[A-Za-z84]');
var endThingsRegexp = RegExp(r'[,\]]');
var digetsRegexp = RegExp(r'[\d\.E\-\+]');

class Parser {
  String text;
  int level;
  int place;
  List<dynamic>? root;
  List<dynamic> stack;
  List<dynamic>? currentObject;
  int state;
  dynamic word;

  Parser(String text)
      : text = text.trim(),
        level = 0,
        place = 0,
        root = null,
        stack = <dynamic>[],
        currentObject = null,
        state = NEUTRAL;

  static List<dynamic> parseString(String txt) {
    var parser = Parser(txt);
    return parser._output();
  }

  void _readCharacter() {
    var char = text[place++];
    if (state != QUOTED) {
      while (whitespaceRegexp.hasMatch(char)) {
        if (place >= text.length) {
          return;
        }
        char = text[place++];
      }
    }
    switch (state) {
      case NEUTRAL:
        return _neutral(char);
      case KEYWORD:
        return _keyword(char);
      case QUOTED:
        return _quoted(char);
      case AFTERQUOTE:
        return _afterquote(char);
      case NUMBER:
        return _number(char);
      case ENDED:
        return;
    }
  }

  void _afterquote(String char) {
    if (char == '"') {
      word += '"';
      state = QUOTED;
      return;
    }
    if (endThingsRegexp.hasMatch(char)) {
      word = word.trim();
      _afterItem(char);
      return;
    }
    throw Exception('haven\'t handled "$char" in afterquote yet, index $place');
  }

  void _afterItem(String char) {
    if (char == ',') {
      if (word != null) {
        currentObject!.add(word);
      }
      word = null;
      state = NEUTRAL;
      return;
    }
    if (char == ']') {
      level--;
      if (word != null) {
        currentObject!.add(word);
        word = null;
      }
      state = NEUTRAL;
      currentObject = stack.removeLast();
      if (currentObject == null) {
        state = ENDED;
      }
      return;
    }
  }

  void _quoted(String char) {
    if (char == '"') {
      state = AFTERQUOTE;
      return;
    }
    word += char;
    return;
  }

  void _keyword(String char) {
    if (keywordRegex.hasMatch(char)) {
      word += char;
      return;
    }
    if (char == '[') {
      var newObjects = <dynamic>[];
      newObjects.add(word);
      level++;
      if (root == null) {
        root = newObjects;
      } else {
        currentObject!.add(newObjects);
      }
      stack.add(currentObject);
      currentObject = newObjects;
      state = NEUTRAL;
      return;
    }
    if (endThingsRegexp.hasMatch(char)) {
      _afterItem(char);
      return;
    }
    throw Exception('havn\'t handled "$char" in keyword yet, index $place');
  }

  void _number(String char) {
    if (digetsRegexp.hasMatch(char)) {
      word += char;
      return;
    }
    if (endThingsRegexp.hasMatch(char)) {
      word = double.parse(word);
      _afterItem(char);
      return;
    }
    throw Exception('haven\'t handled "$char" in number yet, index $place');
  }

  void _neutral(String char) {
    if (latinRegexp.hasMatch(char)) {
      word = char;
      state = KEYWORD;
      return;
    }
    if (char == '"') {
      word = '';
      state = QUOTED;
      return;
    }
    if (digetsRegexp.hasMatch(char)) {
      word = char;
      state = NUMBER;
      return;
    }
    if (endThingsRegexp.hasMatch(char)) {
      _afterItem(char);
      return;
    }
    throw Exception('haven\'t handled "$char" in neutral yet, index $place');
  }

  List<dynamic> _output() {
    while (place < text.length) {
      _readCharacter();
    }
    if (state == ENDED) {
      return root!;
    }
    throw Exception('unable to parse string $text. State is $state');
  }
}
