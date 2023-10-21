class Levelling {
  double startingTbm;
  double? closingTbm;
  int k;
  int roundDigits;
  List<Map<String, dynamic>> data = [];

  Levelling({
    required this.startingTbm,
    this.closingTbm,
    this.k = 3,
    this.roundDigits = 4,
  });

  void readFromFile(String filePath) {
    // Use dart:io to read the file and populate the data list
  }

  void addData(String station, double bs, double is_, double fs) {
    // Add data to the data list
  }

  void computeMisclose() {
    // Logic for computing misclose
  }

  // ... other methods ...

  @override
  String toString() {
    // Return a string representation of the data (analogous to __repr__ in Python)
  }
}
