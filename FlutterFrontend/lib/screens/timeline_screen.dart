import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../main.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({Key? key}) : super(key: key);

  @override
  _TimelineScreenState createState() => _TimelineScreenState();
}

class HistoricalEvent {
  final String yearLabel;
  final int? numericYear;
  final String event;
  final String importance;
  final String? year;

  HistoricalEvent({
    required this.yearLabel,
    this.numericYear,
    required this.event,
    required this.importance,
    this.year,
  });
}

class _TimelineScreenState extends State<TimelineScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  List<HistoricalEvent> _events = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTimelineData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int? _parseYear(String yearStr) {
    // Try to parse the year directly
    try {
      return int.parse(yearStr);
    } catch (_) {
      // Try to extract digits for years with prefixes/suffixes
      RegExp yearRegex = RegExp(r'(\d+)');
      final match = yearRegex.firstMatch(yearStr);
      if (match != null) {
        try {
          return int.parse(match.group(1)!);
        } catch (_) {}
      }

      // Handle BC/BCE years
      if (yearStr.contains('BC') || yearStr.contains('BCE')) {
        yearRegex = RegExp(r'(\d+)');
        final match = yearRegex.firstMatch(yearStr);
        if (match != null) {
          try {
            return -int.parse(match.group(1)!);
          } catch (_) {}
        }
      }
    }
    return null;
  }

  String _formatYearLabel(String yearStr) {
    // Replace underscores with spaces
    String label = yearStr.replaceAll('_', ' ');
    // Replace multiple spaces with single space
    label = label.replaceAll(RegExp(r'\s+'), ' ');
    return label;
  }

  Future<void> _loadTimelineData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot =
          await _database.ref('sri_lanka_historical_events_by_year').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        List<HistoricalEvent> events = [];

        data.forEach((yearStr, yearData) {
          // Skip entries that are not numeric years
          if (!_isNumericYear(yearStr)) {
            return; // Skip this iteration
          }

          // Each year can have multiple events
          if (yearData is List) {
            for (var eventData in yearData) {
              if (eventData != null && eventData is Map) {
                final eventMap = Map<String, dynamic>.from(eventData as Map);
                final yearField = eventMap['year']?.toString();

                // Only add events with numeric years
                if (yearField == null || _isNumericYear(yearField)) {
                  events.add(HistoricalEvent(
                    yearLabel: yearStr,
                    numericYear: _parseYear(yearField ?? yearStr),
                    event: eventMap['event'] ?? 'No event description',
                    importance: eventMap['importance'] ??
                        'No importance data available',
                    year: yearField,
                  ));
                }
              }
            }
          } else if (yearData is Map) {
            // Handle case where yearData is directly a map
            final eventMap = Map<String, dynamic>.from(yearData as Map);
            final yearField = eventMap['year']?.toString();

            // Only add events with numeric years
            if (yearField == null || _isNumericYear(yearField)) {
              events.add(HistoricalEvent(
                yearLabel: yearStr,
                numericYear: _parseYear(yearField ?? yearStr),
                event: eventMap['event'] ?? 'No event description',
                importance:
                    eventMap['importance'] ?? 'No importance data available',
                year: yearField,
              ));
            }
          }
        });

        // Updated sorting logic to prioritize the "year" field
        events.sort((a, b) {
          if (a.numericYear != null && b.numericYear != null) {
            return a.numericYear!.compareTo(b.numericYear!);
          } else if (a.numericYear != null) {
            return -1;
          } else if (b.numericYear != null) {
            return 1;
          }
          return 0; // This shouldn't happen anymore since we're filtering non-numeric years
        });

        setState(() {
          _events = events;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Timeline data not found";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading timeline data: $e";
        _isLoading = false;
      });
    }
  }

  // Helper method to check if a year string represents a numeric year
  bool _isNumericYear(String yearStr) {
    // Check if the string is purely numeric
    if (RegExp(r'^\d+$').hasMatch(yearStr)) {
      return true;
    }

    // Check for negative years (BC/BCE)
    if (RegExp(r'^-\d+$').hasMatch(yearStr)) {
      return true;
    }

    // Special case for years with leading zeros like "0100"
    if (RegExp(r'^0\d+$').hasMatch(yearStr)) {
      return true;
    }

    // Avoid other strings like "10500_years_ago", "Unknown", etc.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.timeline),
            SizedBox(width: 10),
            Text('Sri Lanka Timeline'),
          ],
        ),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimelineData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.shadowDark(context),
                              offset: const Offset(4, 4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: AppTheme.shadowLight(context),
                              offset: const Offset(-4, -4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.clockRotateLeft,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Sri Lankan History Timeline',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Explore major events in Sri Lankan history through this vertical timeline.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Vertical Timeline
                    Expanded(
                      child: _events.isEmpty
                          ? const Center(
                              child: Text("No historical events found"))
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _events.length,
                              itemBuilder: (context, index) {
                                final event = _events[index];
                                final displayYear = event.year != null
                                    ? _formatYearLabel(event.year!)
                                    : _formatYearLabel(event.yearLabel);
                                final isSpecialYear =
                                    event.numericYear != null &&
                                        (event.numericYear! % 100 == 0 ||
                                            event.numericYear! % 50 == 0);
                                final nextIndex = index + 1;
                                final isFirstOfYear = index == 0 ||
                                    (nextIndex < _events.length &&
                                        (event.year !=
                                            _events[nextIndex].year));

                                return Column(
                                  children: [
                                    if (isFirstOfYear || index == 0)
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: isSpecialYear
                                              ? AppTheme.primaryColor
                                                  .withOpacity(0.8)
                                              : AppTheme.cardColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  AppTheme.shadowDark(context),
                                              offset: const Offset(2, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSpecialYear
                                                  ? Icons.star
                                                  : Icons.calendar_today,
                                              color: isSpecialYear
                                                  ? Colors.white
                                                  : AppTheme.primaryColor,
                                              size: isSpecialYear ? 22 : 18,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              // Wrap with Expanded to prevent overflow
                                              child: Text(
                                                displayYear,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      isSpecialYear ? 18 : 16,
                                                  color: isSpecialYear
                                                      ? Colors.white
                                                      : null,
                                                ),
                                                overflow: TextOverflow
                                                    .ellipsis, // Add this to handle long text
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Event card
                                    Container(
                                      margin: const EdgeInsets.fromLTRB(
                                          16, 4, 16, 16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardColor,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ExpansionTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const FaIcon(
                                            FontAwesomeIcons.landmark,
                                            color: AppTheme.primaryColor,
                                            size: 16,
                                          ),
                                        ),
                                        title: Text(
                                          event.event,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 0, 16, 16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Divider(),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'Importance:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  event.importance,
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Timeline connector
                                    if (index < _events.length - 1)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 31),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            width: 2,
                                            height: 20,
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
