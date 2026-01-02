// main.dart
import 'package:flutter/material.dart';
import 'dart:convert';

import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const CatalystApp());
}

class CatalystApp extends StatelessWidget {
  const CatalystApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catalyst',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFFFF6B35),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B35),
          secondary: Color(0xFFFF6B35),
          surface: Color(0xFF141414),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.local_fire_department, color: Color(0xFFFF6B35)),
            SizedBox(width: 8),
            Text('Catalyst', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF141414),
        child: Column(
          children: [
            // Header with flame icon
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF2A2A2A)),
                ),
              ),
              child: Column(
                children: const [
                  Icon(Icons.local_fire_department, 
                    color: Color(0xFFFF6B35), 
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Catalyst',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            ListTile(
              leading: const Icon(Icons.track_changes, color: Color(0xFFFF6B35)),
              title: const Text('Goals', style: TextStyle(fontSize: 18)),
              selected: _selectedIndex == 0,
              selectedTileColor: const Color(0x20FF6B35),
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt, color: Color(0xFFFF6B35)),
              title: const Text('Tasks', style: TextStyle(fontSize: 18)),
              selected: _selectedIndex == 1,
              selectedTileColor: const Color(0x20FF6B35),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            // Copyright
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '© 2025 Linus Lundblad',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha((0.3 * 255).round()),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _selectedIndex == 0 ? const GoalsScreen() : const TasksScreen(),
    );
  }
}

// Models
class Goal {
  final String id;
  final String name;
  final Color color;
  final String unit;
  final GoalType type;
  final bool hasCompletions;
  final String? completionLabel;

  Goal({
    required this.id,
    required this.name,
    required this.color,
    required this.unit,
    required this.type,
    this.hasCompletions = false,
    this.completionLabel,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value,
        'unit': unit,
        'type': type.index,
        'hasCompletions': hasCompletions,
        'completionLabel': completionLabel,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'],
        name: json['name'],
        color: Color(json['color']),
        unit: json['unit'],
        type: GoalType.values[json['type']],
        hasCompletions: json['hasCompletions'] ?? false,
        completionLabel: json['completionLabel'],
      );
}

enum GoalType { number, completion }

class DayData {
  double? value;
  List<String>? completions;

  DayData({this.value, this.completions});

  Map<String, dynamic> toJson() => {
    'value': value,
    'completions': completions,
  };

  factory DayData.fromJson(Map<String, dynamic> json) => DayData(
    value: json['value']?.toDouble(),
    completions: json['completions'] != null 
      ? List<String>.from(json['completions'])
      : null,
  );
}

class Task {
  final String id;
  final String title;
  bool completed;
  DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    this.completed = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        completed: json['completed'],
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
      );
}

// Goals Screen
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Color> _goalColors = [
    const Color(0xFFFF6B35), // orange
    const Color(0xFF4ADE80), // green
    const Color(0xFF3B82F6), // blue
    const Color(0xFFFACC15), // yellow
    const Color(0xFFFC6DAB), // pink
  ];
  int _year = DateTime.now().year;
  Map<String, Map<String, dynamic>> _data = {};
  List<Goal> _goals = [];
  final Map<String, bool> _expandedGoals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Color _getNextGoalColor() {
    if (_goals.isEmpty) return _goalColors[0]; // first goal
    int lastIndex = _goalColors.indexOf(_goals.last.color);
    int nextIndex = (lastIndex + 1) % _goalColors.length;
    return _goalColors[nextIndex];
  }

  Future<File> _goalsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/goals.json');
  }

  Future<File> _goalDataFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/goalData.json');
  }

  Future<void> _loadData() async {
    try {
      final goalsFile = await _goalsFile();
      if (await goalsFile.exists()) {
        final goalsJson = await goalsFile.readAsString();
        final goalsList = jsonDecode(goalsJson) as List;
        _goals = goalsList.map((g) => Goal.fromJson(g)).toList();
      } else {
        // Default goals
        _goals = [
          Goal(
            id: 'reading',
            name: 'Reading',
            color: const Color(0xFF4ADE80),
            unit: 'pages',
            type: GoalType.number,
            hasCompletions: true,
            completionLabel: 'Book Completed',
          ),
          Goal(
            id: 'japanese',
            name: 'Japanese',
            color: const Color(0xFF3B82F6),
            unit: 'minutes',
            type: GoalType.number,
          ),
        ];
        await _saveGoals();
      }

      final dataFile = await _goalDataFile();
      if (await dataFile.exists()) {
        final dataJson = await dataFile.readAsString();
        final decoded = jsonDecode(dataJson) as Map<String, dynamic>;
        _data = decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
      _goals = [];
      _data = {};
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveGoals() async {
    final file = await _goalsFile();
    final jsonStr = jsonEncode(_goals.map((g) => g.toJson()).toList());
    await file.writeAsString(jsonStr);
  }

  Future<void> _saveData() async {
    final file = await _goalDataFile();
    await file.writeAsString(jsonEncode(_data));
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int _calculateStreak(Goal goal) {
    int streak = 0;
    DateTime current = DateTime.now();
    
    while (true) {
      final key = _dateKey(current);
      final dayData = _data[key]?[goal.id];
      
      bool hasActivity = false;
      if (goal.type == GoalType.completion) {
        hasActivity = dayData is List && dayData.isNotEmpty;
      } else {
        final value = dayData is Map ? dayData['value'] : dayData;
        hasActivity = value != null && (value as num) > 0;
      }
      
      if (!hasActivity) break;
      
      streak++;
      current = current.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  void _addValue(Goal goal) async {
    if (goal.type == GoalType.completion) {
      final controller = TextEditingController();
      final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          title: Text(goal.name),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter name',
              hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context, controller.text);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );

      if (name != null) {
        setState(() {
          final today = _dateKey(DateTime.now());
          _data[today] ??= {};
          _data[today]![goal.id] = [
            ...(_data[today]![goal.id] as List? ?? []),
            name
          ];
        });
        await _saveData();
      }
    } else {
      // Number type with optional completion
      final valueController = TextEditingController();
      final completionController = TextEditingController();
      bool addCompletion = false;
      
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF141414),
            title: Text('Add ${goal.unit} for ${goal.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter ${goal.unit}',
                      hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
                    ),
                  ),
                  if (goal.hasCompletions) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: addCompletion,
                          onChanged: (val) {
                            setDialogState(() => addCompletion = val ?? false);
                          },
                        ),
                        Text(goal.completionLabel ?? 'Mark completion'),
                      ],
                    ),
                    if (addCompletion) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: completionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Completion name',
                          hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final val = double.tryParse(valueController.text);
                  if (val != null) {
                    Navigator.pop(context, {
                      'value': val,
                      'completion': addCompletion ? completionController.text : null,
                    });
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      );

      if (result != null && result['value'] != null) {
        setState(() {
          final today = _dateKey(DateTime.now());
          _data[today] ??= {};
          
          final currentData = _data[today]![goal.id];
          if (currentData is Map) {
            _data[today]![goal.id] = {
              'value': (currentData['value'] ?? 0.0) + result['value'],
              'completions': currentData['completions'] ?? [],
            };
          } else {
            _data[today]![goal.id] = {
              'value': (currentData as double? ?? 0.0) + result['value'],
              'completions': [],
            };
          }
          
          if (result['completion'] != null && result['completion'].toString().isNotEmpty) {
            (_data[today]![goal.id]['completions'] as List).add(result['completion']);
          }
        });
        await _saveData();
      }
    }
  }

  List<DateTime> _getYearDays() {
    final start = DateTime(_year, 1, 1);
    final end = DateTime(_year, 12, 31);
    final days = <DateTime>[];
    for (var d = start;
        d.isBefore(end.add(const Duration(days: 1)));
        d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    return days;
  }

  double _getMaxValueForGoal(Goal goal) {
    double maxValue = 1;
    for (final entry in _data.values) {
      final value = entry[goal.id];
      if (value != null) {
        if (goal.type == GoalType.number) {
          final num = value is Map ? (value['value'] as double? ?? 0) : (value as double? ?? 0);
          if (num > maxValue) maxValue = num;
        }
      }
    }
    return maxValue;
  }

  Color _getHeatmapColor(Goal goal, dynamic value, {bool hasCompletion = false}) {
    if (value == null) return const Color(0xFF1A1A1A);

    // Special color for completion days
    if (hasCompletion) {
      return goal.color.withAlpha((1 * 255).round());
    }

    if (goal.type == GoalType.completion) {
      final count = (value as List).length;
      if (count == 0) return const Color(0xFF1A1A1A);
      if (count == 1) return goal.color.withAlpha((0.4 * 255).round());
      if (count == 2) return goal.color.withAlpha((0.7 * 255).round());
      return goal.color;
    } else {
      final num = value is Map ? (value['value'] as double? ?? 0) : (value as double? ?? 0);
      if (num <= 0) return const Color(0xFF1A1A1A);
      
      final maxValue = _getMaxValueForGoal(goal);
      final ratio = num / maxValue;
      
      final opacity = 0.3 + (ratio * 0.7);
      return goal.color.withAlpha((opacity * 255).round());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final yearDays = _getYearDays();
    final today = _dateKey(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Year selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => setState(() => _year--),
              icon: const Icon(Icons.chevron_left),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF141414),
              ),
            ),
            const SizedBox(width: 20),
            Text(
              '$_year',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 20),
            IconButton(
              onPressed: () => setState(() => _year++),
              icon: const Icon(Icons.chevron_right),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF141414),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // Quick add controls
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Progress",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFA0A0A0),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _goals.map((goal) {
                  return OutlinedButton.icon(
                    onPressed: () => _addValue(goal),
                    icon: const Icon(Icons.add),
                    label: Text(goal.name),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: goal.color, width: 2),
                      backgroundColor: const Color(0xFF1A1A1A),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Heatmaps
        for (final goal in _goals) ...[
          Dismissible(
            key: Key(goal.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) async {
              setState(() {
                _goals.remove(goal);
                _expandedGoals.remove(goal.id);
              });
              await _saveGoals();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side: goal name and streak
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: goal.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, size: 16, color: Color(0xFFFF6B35)),
                            const SizedBox(width: 4),
                            Text(
                              '${_calculateStreak(goal)} day streak',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFA0A0A0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Right side: expand icon + delete button
                    Row(
                      children: [
                        // Delete button
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF141414),
                                title: const Text('Delete Goal?'),
                                content: Text('Delete "${goal.name}" permanently?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              setState(() {
                                _goals.remove(goal);
                                _expandedGoals.remove(goal.id);
                              });
                              await _saveGoals();
                            }
                          },
                        ),

                        // Expand/collapse icon
                        IconButton(
                          icon: Icon(
                            _expandedGoals[goal.id] == true ? Icons.expand_less : Icons.expand_more,
                          ),
                          onPressed: () {
                            setState(() {
                              _expandedGoals[goal.id] = !(_expandedGoals[goal.id] ?? false);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 53,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemCount: yearDays.length,
                  itemBuilder: (context, index) {
                    final date = yearDays[index];
                    final key = _dateKey(date);
                    final value = _data[key]?[goal.id];
                    final isToday = key == today;
                    
                    bool hasCompletion = false;
                    if (value is Map && value['completions'] != null) {
                      hasCompletion = (value['completions'] as List).isNotEmpty;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: _getHeatmapColor(goal, value, hasCompletion: hasCompletion),
                        borderRadius: BorderRadius.circular(2),
                        border: isToday
                            ? Border.all(color: const Color(0xFFFF6B35), width: 2)
                            : hasCompletion && goal.type != GoalType.completion
                            ? Border.all(color: Colors.white.withAlpha((0.5 * 255).round()), width: 1)
                            : null,
                      ),
                    );
                  },
                ),
                if (_expandedGoals[goal.id] == true &&
                    (goal.hasCompletions || goal.type == GoalType.completion)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completed ${goal.completionLabel ?? goal.unit}:',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFA0A0A0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...() {
                          final allItems = <String>[];
                          _data.forEach((date, values) {
                            final dayData = values[goal.id];
                            if (goal.type == GoalType.completion) {
                              if (dayData is List) {
                                for (final item in dayData) {
                                  allItems.add('$item ($date)');
                                }
                              }
                            } else if (dayData is Map && dayData['completions'] != null) {
                              for (final item in dayData['completions']) {
                                allItems.add('$item ($date)');
                              }
                            }
                          });
                          if (allItems.isEmpty) {
                            return [
                              const Text(
                                'No completed items yet',
                                style: TextStyle(
                                  color: Color(0xFFA0A0A0),
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            ];
                          }
                          return allItems.reversed
                              .map((item) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Text('• $item'),
                                  ))
                              .toList();
                        }(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],

        // Add goal button
        OutlinedButton.icon(
          onPressed: _addGoal,
          icon: const Icon(Icons.add),
          label: const Text('Add Goal'),
            style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            side: const BorderSide(
              color: Color(0xFFFF6B35),
              width: 2,
              style: BorderStyle.solid,
            ),
            backgroundColor: const Color(0x20FF6B35),
          ),
        ),
      ],
    );
  }

  void _addGoal() async {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final completionLabelController = TextEditingController();
    GoalType selectedType = GoalType.number;
    bool hasCompletions = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          title: const Text('Add New Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Goal name',
                    hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    hintText: 'Unit (e.g., pages, minutes)',
                    hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GoalType>(
                  value: selectedType,
                  dropdownColor: const Color(0xFF1A1A1A),
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(color: Color(0xFFA0A0A0)),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: GoalType.number,
                      child: Text('Number value'),
                    ),
                    DropdownMenuItem(
                      value: GoalType.completion,
                      child: Text('Completion only'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedType = val);
                    }
                  },
                ),
                if (selectedType == GoalType.number) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: hasCompletions,
                        onChanged: (val) {
                          setDialogState(() => hasCompletions = val ?? false);
                        },
                      ),
                      const Text('Track completions'),
                    ],
                  ),
                  if (hasCompletions) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: completionLabelController,
                      decoration: const InputDecoration(
                        hintText: 'Completion label (e.g., "Book Completed")',
                        hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    unitController.text.isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _goals.add(Goal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameController.text,
          color: _getNextGoalColor(),
          unit: unitController.text,
          type: selectedType,
          hasCompletions: hasCompletions,
          completionLabel: hasCompletions ? completionLabelController.text : null,
        ));
      });
      await _saveGoals();
    }
  }
}

// Tasks Screen (unchanged)
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<File> _tasksFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/tasks.json');
  }

  Future<void> _loadTasks() async {
    try {
      final file = await _tasksFile();
      if (await file.exists()) {
        final tasksJson = await file.readAsString();
        final tasksList = jsonDecode(tasksJson) as List;
        _tasks = tasksList.map((t) => Task.fromJson(t)).toList();
      } else {
        await _saveTasks(); // create empty tasks file
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      _tasks = [];
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveTasks() async {
    final file = await _tasksFile();
    final jsonStr = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await file.writeAsString(jsonStr);
  }

  void _addTask() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Add New Task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Task description',
            hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (title != null) {
      setState(() {
        _tasks.add(Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
        ));
      });
      await _saveTasks();
    }
  }

  void _toggleTask(Task task) async {
    setState(() {
      task.completed = true;
      task.completedAt = DateTime.now();
    });
    await _saveTasks();
  }

  void _deleteTask(Task task) async {
    setState(() {
      _tasks.remove(task);
    });
    await _saveTasks();
  }

  void _undoTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Undo Completion?'),
        content: const Text('Mark this task as incomplete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Undo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        task.completed = false;
        task.completedAt = null;
      });
      await _saveTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final activeTasks = _tasks.where((t) => !t.completed).toList();
    final completedTasks = _tasks.where((t) => t.completed).toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Active Tasks
        const Text(
          'Active Tasks',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        if (activeTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No active tasks',
              style: TextStyle(
                color: Color(0xFFA0A0A0),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...activeTasks.map((task) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: ListTile(
                  leading: Checkbox(
                    value: task.completed,
                    onChanged: (val) {
                      if (val == true) {
                        _toggleTask(task);
                      }
                    },
                    activeColor: const Color(0xFFFF6B35),
                  ),
                  title: Text(task.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteTask(task),
                  ),
                ),
              )),

        const SizedBox(height: 40),
        // Completed Tasks
        const Text(
          'Completed Tasks',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        if (completedTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No completed tasks',
              style: TextStyle(
                color: Color(0xFFA0A0A0),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...completedTasks.map((task) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4ADE80),
                  ),
                  title: Text(
                    task.title,
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    task.completedAt?.toLocal().toString().split(' ')[0] ?? '',
                    style: const TextStyle(color: Color(0xFFA0A0A0)),
                  ),
                  trailing: TextButton(
                    onPressed: () => _undoTask(task),
                    child: const Text('Undo'),
                  ),
                ),
              )),

        const SizedBox(height: 40),
        // Add Task Button
        OutlinedButton.icon(
          onPressed: _addTask,
          icon: const Icon(Icons.add),
          label: const Text('Add Task'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            side: const BorderSide(color: Color(0xFFFF6B35), width: 2),
            backgroundColor: const Color(0xFFFF6B3520),
          ),
        ),
      ],
    );
  }
}