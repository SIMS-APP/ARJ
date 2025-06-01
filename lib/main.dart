import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const CalculatorTVApp());
}

class CalculatorTVApp extends StatelessWidget {
  const CalculatorTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '';
  final Map<String, FocusNode> _focusNodes = {};

  final List<String> _buttons = [
    '7',
    '8',
    '9',
    '/',
    '4',
    '5',
    '6',
    '*',
    '1',
    '2',
    '3',
    '-',
    '0',
    'C',
    '=',
    '+',
  ];

  @override
  void initState() {
    super.initState();
    for (var btn in _buttons) {
      _focusNodes[btn] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '';
      } else if (value == '=') {
        try {
          _result = _calculate(_expression);
        } catch (e) {
          _result = 'Error';
        }
      } else {
        _expression += value;
      }
    });
  }

  String _calculate(String expr) {
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/');
    try {
      final result = _evaluateExpression(expr);
      return result.toString();
    } catch (_) {
      return 'Error';
    }
  }

  double _evaluateExpression(String expr) {
    expr = expr.replaceAll(' ', '');
    return _Parser().evaluate(expr);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final screenWidth = media.size.width;

    final buttonsGridHeight = screenHeight * 0.6;
    final buttonGap = 8.0;
    final buttonRows = 4;
    final buttonHeight =
        (buttonsGridHeight - (buttonGap * (buttonRows - 1))) / buttonRows;
    final buttonFontSize = buttonHeight * 0.5;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  height: screenHeight * 0.15,
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _expression,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: screenHeight * 0.1,
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _result,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: buttonsGridHeight,
                  child: FocusTraversalGroup(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: buttonGap,
                        mainAxisSpacing: buttonGap,
                        childAspectRatio: (screenWidth / 4) / buttonHeight,
                      ),
                      itemCount: _buttons.length,
                      itemBuilder: (context, index) {
                        final btnText = _buttons[index];
                        return Focus(
                          focusNode: _focusNodes[btnText],
                          onKey: (FocusNode node, RawKeyEvent event) {
                            if (event is RawKeyDownEvent) {
                              if (event.logicalKey ==
                                      LogicalKeyboardKey.select ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.enter ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.gameButtonA ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.space) {
                                _onButtonPressed(btnText);
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Builder(
                            builder: (context) {
                              final hasFocus = Focus.of(context).hasFocus;
                              return GestureDetector(
                                onTap: () => _onButtonPressed(btnText),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: hasFocus
                                        ? Colors.blue
                                        : Colors.grey[850],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Center(
                                    child: Text(
                                      btnText,
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                        color: hasFocus
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Parser {
  const _Parser();

  double evaluate(String expr) {
    try {
      final sanitized = expr.replaceAll(RegExp(r'[^\d+\-*/().]'), '');
      return _evalSimple(sanitized);
    } catch (_) {
      throw Exception("Invalid Expression");
    }
  }

  double _evalSimple(String expr) {
    final tokens = expr
        .split(RegExp(r'(?<=[-+*/()])|(?=[-+*/()])'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final output = <String>[];
    final ops = <String>[];

    final prec = {'+': 1, '-': 1, '*': 2, '/': 2};

    for (var token in tokens) {
      if (double.tryParse(token) != null) {
        output.add(token);
      } else if ('+-*/'.contains(token)) {
        while (ops.isNotEmpty &&
            prec[ops.last] != null &&
            prec[ops.last]! >= prec[token]!) {
          output.add(ops.removeLast());
        }
        ops.add(token);
      } else if (token == '(') {
        ops.add(token);
      } else if (token == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          output.add(ops.removeLast());
        }
        ops.removeLast();
      }
    }

    while (ops.isNotEmpty) {
      output.add(ops.removeLast());
    }

    final stack = <double>[];
    for (var token in output) {
      if (double.tryParse(token) != null) {
        stack.add(double.parse(token));
      } else {
        final b = stack.removeLast();
        final a = stack.removeLast();
        switch (token) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            stack.add(a / b);
            break;
        }
      }
    }

    return stack.first;
  }
}
