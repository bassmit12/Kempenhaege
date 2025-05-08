import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'screens/event_form_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/preference_screen.dart';
import 'screens/admin_screen.dart'; // Import the admin screen
import 'theme/theme_provider.dart';
import 'services/event_manager.dart';
import 'services/user_preference_manager.dart';
import 'services/schedule_recommendation_service.dart';
import 'models/event.dart';

void main() async {
  // Ensure Flutter is initialized before doing any async work
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the schedule recommendation service in the background
  // without blocking app startup
  final recommendationService = ScheduleRecommendationService();
  // Don't wait for it to finish - let it initialize in the background
  recommendationService.initializeNetwork().catchError((error) {
    // Log the error but don't crash the app
    print('Failed to initialize neural network: $error');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => EventManager()),
        ChangeNotifierProvider(create: (context) => UserPreferenceManager()),
        // Add the recommendation service to the provider
        Provider.value(value: recommendationService),
      ],
      child: const KempenhaegeScheduleApp(),
    ),
  );
}

class KempenhaegeScheduleApp extends StatelessWidget {
  const KempenhaegeScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Kempenhaege Schedule',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const ScheduleHomePage(),
    );
  }
}

enum ViewType { day, week, month }

class ScheduleHomePage extends StatefulWidget {
  const ScheduleHomePage({super.key});

  @override
  State<ScheduleHomePage> createState() => _ScheduleHomePageState();
}

class _ScheduleHomePageState extends State<ScheduleHomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  ViewType _currentView = ViewType.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<String, Widget Function(BuildContext, DateTime, DateTime?)>
      _viewBuilders = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Initialize view builders
    _viewBuilders['Day'] = _buildDayView;
    _viewBuilders['Week'] = _buildWeekView;
    _viewBuilders['Month'] = _buildMonthView;

    // Load events from backend when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventManager>(context, listen: false).loadEvents();
    });
  }

  void _showAIScheduleRecommendations() {
    final preferenceManager =
        Provider.of<UserPreferenceManager>(context, listen: false);

    // Initialize preference manager if needed
    if (preferenceManager.categories.isEmpty) {
      preferenceManager.initialize().then((_) {
        _displayScheduleDialog(preferenceManager);
      });
    } else {
      _displayScheduleDialog(preferenceManager);
    }
  }

  void _displayScheduleDialog(UserPreferenceManager preferenceManager) {
    // Default date range: next 7 days
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    startDate = DateTime(startDate.year, startDate.month,
        startDate.day); // Normalize to midnight
    DateTime endDate = startDate.add(const Duration(days: 7));

    // Default requirements - one of each category
    final requirements = preferenceManager.categories.map((category) {
      return {
        'categoryId': category.id,
        'count': 1,
      };
    }).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('AI Schedule Recommendations'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: ThemeProvider.notionBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Let our AI suggest optimal events based on your preferences',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date range selection
                  Text(
                    'Date Range',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          initialValue:
                              DateFormat('MM/dd/yyyy').format(startDate),
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );

                            if (picked != null && picked != startDate) {
                              setState(() {
                                startDate = picked;
                                if (endDate.isBefore(startDate)) {
                                  endDate =
                                      startDate.add(const Duration(days: 7));
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          initialValue:
                              DateFormat('MM/dd/yyyy').format(endDate),
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate:
                                  startDate.add(const Duration(days: 365)),
                            );

                            if (picked != null && picked != endDate) {
                              setState(() {
                                endDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Event requirements
                  Text(
                    'Event Requirements',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'How many of each event type should be included:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  ...preferenceManager.categories.map((category) {
                    final requirement = requirements.firstWhere(
                      (r) => r['categoryId'] == category.id,
                      orElse: () => {'categoryId': category.id, 'count': 0},
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: category.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(category.name),
                          ),
                          SizedBox(
                            width: 100,
                            child: DropdownButtonFormField<int>(
                              value: requirement['count'] as int,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: List.generate(11, (index) {
                                return DropdownMenuItem<int>(
                                  value: index,
                                  child: Text('$index'),
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    final index = requirements.indexWhere(
                                      (r) => r['categoryId'] == category.id,
                                    );

                                    if (index >= 0) {
                                      requirements[index]['count'] = value;
                                    } else {
                                      requirements.add({
                                        'categoryId': category.id,
                                        'count': value,
                                      });
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  if (preferenceManager.categories.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Icon(Icons.category_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No event categories available. Please set up your preferences first.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PreferenceScreen(),
                                ),
                              );
                            },
                            child: const Text('Set Up Preferences'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: preferenceManager.categories.isEmpty
                    ? null
                    : () {
                        // Filter out requirements with zero count
                        final validRequirements = requirements
                            .where((r) => (r['count'] as int) > 0)
                            .toList();

                        if (validRequirements.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please specify at least one event requirement'),
                            ),
                          );
                          return;
                        }

                        // Generate schedule and show results
                        _generateAndShowSchedule(
                          startDate,
                          endDate,
                          validRequirements,
                        );

                        Navigator.pop(context);
                      },
                child: const Text('Generate'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _generateAndShowSchedule(
    DateTime startDate,
    DateTime endDate,
    List<Map<String, dynamic>> requirements,
  ) async {
    // Get the current user and preference manager
    final preferenceManager =
        Provider.of<UserPreferenceManager>(context, listen: false);
    final user = preferenceManager.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile not found')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Generate the schedule using the recommendation service
    final recommendationService = ScheduleRecommendationService();
    final suggestedEvents = await recommendationService.suggestSchedule(
      user: user,
      requiredEvents: requirements,
      startDate: startDate,
      endDate: endDate,
    );

    // Hide loading indicator
    Navigator.pop(context);

    // Show the suggested schedule
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome,
                color: ThemeProvider.notionBlue, size: 20),
            const SizedBox(width: 8),
            const Text('AI Suggested Schedule'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: suggestedEvents.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No events could be scheduled. Try adjusting your preferences or date range.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestedEvents.length,
                  itemBuilder: (context, index) {
                    final event = suggestedEvents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: event.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(event.title),
                        subtitle: Text(
                          '${DateFormat('EEE, MMM d').format(event.startTime)} at ${DateFormat('h:mm a').format(event.startTime)}',
                        ),
                        dense: true,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: suggestedEvents.isEmpty
                ? null
                : () {
                    // Add the suggested events to the calendar
                    final eventManager =
                        Provider.of<EventManager>(context, listen: false);
                    for (final event in suggestedEvents) {
                      eventManager.addEvent(event);
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${suggestedEvents.length} events added to your schedule'),
                        backgroundColor: ThemeProvider.notionBlue,
                      ),
                    );
                  },
            child: const Text('Add to Calendar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text(
          'Kempenhaege',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EventFormScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAIScheduleRecommendations,
        backgroundColor: ThemeProvider.notionBlue,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildViewSelector(),
          const Divider(height: 1),
          Expanded(
            child: _viewBuilders[_currentView == ViewType.month
                ? 'Month'
                : _currentView == ViewType.week
                    ? 'Week'
                    : 'Day']!(context, _focusedDay, _selectedDay),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDarkMode ? ThemeProvider.notionBlack : Colors.white,
      elevation: 0,
      child: Column(
        children: [
          // Header with logo
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/logo/Kempenhaeghe_logo.png',
                  height: 50, // Increased logo height from 36 to 50
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNotionMenuItem(
                  context,
                  icon: Icons.schedule,
                  title: 'Schedule',
                  isSelected: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Calendar',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Calendar view coming soon'),
                      ),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.people_outline,
                  title: 'Meetings',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meetings feature coming soon'),
                      ),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.event_note,
                  title: 'Schedule Preferences',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PreferenceScreen(),
                      ),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.task_alt,
                  title: 'Tasks',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tasks feature coming soon'),
                      ),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.admin_panel_settings,
                  title: 'Admin Panel',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'PERSONAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? ThemeProvider.notionGray
                          : const Color(0xFF9B9A97),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.bookmark_border,
                  title: 'Favorites',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Favorites feature coming soon'),
                      ),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings coming soon')),
                    );
                  },
                ),
                _buildNotionMenuItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom section
          InkWell(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ThemeProvider.notionBlue.withOpacity(0.2),
                    radius: 14,
                    child: const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: ThemeProvider.notionBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'User',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color:
                          isDarkMode ? Colors.white : ThemeProvider.notionBlack,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Provider.of<ThemeProvider>(context).themeMode ==
                              ThemeMode.light
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).toggleTheme();
                    },
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotionMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1F1F0))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isDarkMode ? Colors.white : ThemeProvider.notionBlack)
                  : (isDarkMode
                      ? ThemeProvider.notionGray
                      : const Color(0xFF9B9A97)),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected
                    ? (isDarkMode ? Colors.white : ThemeProvider.notionBlack)
                    : (isDarkMode
                        ? ThemeProvider.notionGray
                        : const Color(0xFF37352F)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(_focusedDay),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          SegmentedButton<ViewType>(
            segments: const [
              ButtonSegment<ViewType>(value: ViewType.day, label: Text('Day')),
              ButtonSegment<ViewType>(
                value: ViewType.week,
                label: Text('Week'),
              ),
              ButtonSegment<ViewType>(
                value: ViewType.month,
                label: Text('Month'),
              ),
            ],
            selected: {_currentView},
            onSelectionChanged: (Set<ViewType> selection) {
              setState(() {
                _currentView = selection.first;
                if (_currentView == ViewType.week) {
                  _calendarFormat = CalendarFormat.week;
                } else if (_currentView == ViewType.month) {
                  _calendarFormat = CalendarFormat.month;
                }
              });
            },
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity(horizontal: -1, vertical: -1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(
    BuildContext context,
    DateTime focusedDay,
    DateTime? selectedDay,
  ) {
    // Get events for each day to show markers
    final eventManager = Provider.of<EventManager>(context);

    // This function will check if a day has any events
    bool hasEventsOnDay(DateTime day) {
      final events = eventManager.getEventsForDay(day);
      return events.isNotEmpty;
    }

    // Event loader function for table calendar
    List<dynamic> getEventsForDay(DateTime day) {
      final events = eventManager.getEventsForDay(day);
      return events;
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<EventManager>(context, listen: false).loadEvents();
        // Optional: Show a success message
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule refreshed'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      color: ThemeProvider.notionBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) {
              return isSameDay(selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                // Switch to day view when a day is selected
                _currentView = ViewType.day;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            // Add event loader to display markers on days with events
            eventLoader: getEventsForDay,
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: const BoxDecoration(
                color: ThemeProvider.notionBlue,
                shape: BoxShape.circle,
              ),
              markerSize: 7.0,
              markersAlignment: Alignment.bottomCenter,
              markerMargin: const EdgeInsets.only(top: 1.0),
              isTodayHighlighted: true,
              todayDecoration: BoxDecoration(
                color: ThemeProvider.notionFaintBlue,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(3),
              ),
              todayTextStyle: const TextStyle(
                color: ThemeProvider.notionBlack,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                color: ThemeProvider.notionBlue.withOpacity(0.15),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: ThemeProvider.notionBlue, width: 1),
              ),
              selectedTextStyle: const TextStyle(
                color: ThemeProvider.notionBlue,
                fontWeight: FontWeight.bold,
              ),
              defaultDecoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(3),
              ),
              outsideDecoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(3),
              ),
              weekendDecoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(3),
              ),
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(4),
              cellPadding: const EdgeInsets.all(0),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: false,
              leftChevronVisible: false,
              rightChevronVisible: false,
              headerPadding: EdgeInsets.only(bottom: 16),
              titleTextStyle: TextStyle(
                fontSize:
                    0, // Hide the title as we're showing it in view selector
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: ThemeProvider.notionGray,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              weekendStyle: TextStyle(
                color: ThemeProvider.notionGray,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
            rowHeight: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekView(
    BuildContext context,
    DateTime focusedDay,
    DateTime? selectedDay,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<EventManager>(context, listen: false).loadEvents();
        // Optional: Show a success message
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule refreshed'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      color: ThemeProvider.notionBlue,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.week,
          selectedDayPredicate: (day) {
            return isSameDay(selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            isTodayHighlighted: true,
            todayDecoration: BoxDecoration(
              color: ThemeProvider.notionFaintBlue,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
            ),
            todayTextStyle: const TextStyle(
              color: ThemeProvider.notionBlack,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: BoxDecoration(
              color: ThemeProvider.notionBlue.withOpacity(0.15),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: ThemeProvider.notionBlue, width: 1),
            ),
            selectedTextStyle: const TextStyle(
              color: ThemeProvider.notionBlue,
              fontWeight: FontWeight.bold,
            ),
            defaultDecoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
            ),
            outsideDecoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
            ),
            weekendDecoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
            ),
            cellMargin: const EdgeInsets.all(4),
            cellPadding: const EdgeInsets.all(4),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: false,
            leftChevronVisible: false,
            rightChevronVisible: false,
            titleTextStyle: TextStyle(
              fontSize:
                  0, // Hide the title as we're showing it in view selector
            ),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: ThemeProvider.notionGray,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            weekendStyle: TextStyle(
              color: ThemeProvider.notionGray,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
          rowHeight: 60,
        ),
      ),
    );
  }

  Widget _buildDayView(
    BuildContext context,
    DateTime focusedDay,
    DateTime? selectedDay,
  ) {
    final dayToShow = selectedDay ?? focusedDay;
    final formatter = DateFormat('EEEE, MMMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                formatter.format(dayToShow),
                style: const TextStyle(
                  color: ThemeProvider.notionBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () {
                  setState(() {
                    _focusedDay = _focusedDay.subtract(const Duration(days: 1));
                    _selectedDay = _focusedDay;
                  });
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {
                  setState(() {
                    _focusedDay = _focusedDay.add(const Duration(days: 1));
                    _selectedDay = _focusedDay;
                  });
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await Provider.of<EventManager>(context, listen: false)
                  .loadEvents();
              // Optional: Show a success message
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Schedule refreshed'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            color: ThemeProvider.notionBlue,
            child: _buildTimeSlots(context, dayToShow),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots(BuildContext context, DateTime day) {
    // Create time slots from 6 AM to 9 PM
    final List<DateTime> timeSlots = [];
    DateTime startTime = DateTime(day.year, day.month, day.day, 6);

    // Get events for the selected day from the EventManager
    final eventManager = Provider.of<EventManager>(context);
    final eventsForDay = eventManager.getEventsForDay(day);

    for (int i = 0; i < 16; i++) {
      // 16 hours - 6 AM to 9 PM
      timeSlots.add(startTime.add(Duration(hours: i)));
    }

    return Stack(
      children: [
        // Time slots with events
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: timeSlots.length,
          itemBuilder: (context, index) {
            final time = timeSlots[index];
            final timeFormat = DateFormat('h:mm a');
            final isCurrentHour = time.hour == DateTime.now().hour &&
                time.day == DateTime.now().day &&
                time.month == DateTime.now().month;

            // Find events that overlap with this time slot
            final eventsAtThisHour = eventsForDay.where((event) {
              // Convert event times to same-day comparison to handle multi-day events
              final timeHour = time.hour;
              final eventStartHour = event.startTime.hour;
              final eventEndHour = event.endTime.hour;

              // Special case for events ending at midnight (0:00)
              final eventEndHourAdjusted =
                  (event.endTime.hour == 0 && event.endTime.minute == 0)
                      ? 24 // Represent midnight as hour 24 for comparison
                      : event.endTime.hour;

              // For same-day events
              if (isSameDay(event.startTime, event.endTime)) {
                // Check if this timeslot falls within the event hours
                return timeHour >= eventStartHour &&
                    timeHour < eventEndHourAdjusted;
              }

              // For multi-day events
              if (isSameDay(time, event.startTime)) {
                // First day of the event - show from start time onwards
                return timeHour >= eventStartHour;
              } else if (isSameDay(time, event.endTime)) {
                // Last day of the event - show until end time
                return timeHour < eventEndHourAdjusted;
              } else if (time.isAfter(event.startTime) &&
                  time.isBefore(event.endTime)) {
                // Middle day of multi-day event - show all hours
                return true;
              }

              return false;
            }).toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isCurrentHour
                      ? ThemeProvider.notionBlue
                      : Theme.of(context).dividerTheme.color!,
                  width: 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(3),
                onTap: () {
                  // Navigate to the event form screen with the selected time
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventFormScreen(initialDate: time),
                    ),
                  ).then((newEvent) {
                    // If a new event was created, add it to the EventManager
                    if (newEvent != null) {
                      eventManager.addEvent(newEvent);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        alignment: Alignment.center,
                        child: Text(
                          timeFormat.format(time),
                          style: TextStyle(
                            color: isCurrentHour
                                ? ThemeProvider.notionBlue
                                : ThemeProvider.notionGray,
                            fontWeight: isCurrentHour
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: eventsAtThisHour.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentHour
                                      ? ThemeProvider.notionFaintBlue
                                          .withOpacity(0.3)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: isCurrentHour
                                        ? ThemeProvider.notionBlue
                                            .withOpacity(0.3)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.drag_indicator,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).iconTheme.color?.withOpacity(0.5),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Click to add an event',
                                      style: TextStyle(
                                        color: ThemeProvider.notionGray,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: eventsAtThisHour.map((event) {
                                  final isDarkMode =
                                      Theme.of(context).brightness ==
                                          Brightness.dark;

                                  return GestureDetector(
                                    onTap: () {
                                      // Open the event editing form
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EventFormScreen(
                                            event: event,
                                          ),
                                        ),
                                      ).then((updatedEvent) {
                                        // If the event was updated
                                        if (updatedEvent != null) {
                                          eventManager.updateEvent(
                                            updatedEvent,
                                          );
                                        }
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        bottom: 4,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: event.color.withOpacity(
                                          isDarkMode ? 0.4 : 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: event.color.withOpacity(
                                            0.5,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: event.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  event.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : ThemeProvider
                                                            .notionBlack,
                                                  ),
                                                ),
                                                if (event
                                                    .location.isNotEmpty) ...[
                                                  const SizedBox(
                                                    height: 4,
                                                  ),
                                                  Text(
                                                    event.location,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDarkMode
                                                          ? ThemeProvider
                                                              .notionGray
                                                          : Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDarkMode
                                                  ? ThemeProvider.notionGray
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                          _buildEventBadge(event, isDarkMode),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Loading indicator - placed AFTER (above) the list view
        if (eventManager.isLoading)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
            child: const Center(child: CircularProgressIndicator()),
          ),

        // Error message - placed AFTER (above) the list view
        if (eventManager.error != null)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading events',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        eventManager.error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => eventManager.loadEvents(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Add a badge to AI-recommended events to distinguish them
  Widget _buildEventBadge(Event event, bool isDarkMode) {
    // Check if this is an AI-suggested event by looking at the ID prefix
    final isAISuggested = event.id.startsWith('suggested_');

    if (!isAISuggested) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: ThemeProvider.notionBlue.withOpacity(isDarkMode ? 0.3 : 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: ThemeProvider.notionBlue.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 12,
            color: ThemeProvider.notionBlue,
          ),
          const SizedBox(width: 4),
          Text(
            'AI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ThemeProvider.notionBlue,
            ),
          ),
        ],
      ),
    );
  }
}
