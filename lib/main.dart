import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'screens/event_form_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/theme_provider.dart';
import 'services/event_manager.dart';
import 'models/event.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => EventManager()),
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

    return Container(
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
            fontSize: 0, // Hide the title as we're showing it in view selector
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
    );
  }

  Widget _buildWeekView(
    BuildContext context,
    DateTime focusedDay,
    DateTime? selectedDay,
  ) {
    return Container(
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
            fontSize: 0, // Hide the title as we're showing it in view selector
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
        Expanded(child: _buildTimeSlots(context, dayToShow)),
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
}
