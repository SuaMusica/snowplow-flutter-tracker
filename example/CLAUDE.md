# CLAUDE.md - Example App & Integration Testing Documentation

## Module Overview

The example directory contains a demonstration Flutter application that showcases the Snowplow tracker's capabilities and serves as the foundation for integration testing. It provides real-world usage patterns and end-to-end testing infrastructure.

**Key Components:**
- Demo application with UI for triggering events
- Integration tests for all tracker features
- Test helpers and utilities
- Platform-specific configuration examples

## Example App Architecture

### App Structure
```
example/
├── lib/
│   ├── main.dart           # App entry and tracker init
│   ├── main_page.dart      # Event triggering UI
│   ├── overview.dart       # Tracker info display
│   └── nested_page.dart    # Navigation testing
├── integration_test/
│   ├── configuration_test.dart
│   ├── events_test.dart
│   ├── media_test.dart
│   └── session_test.dart
└── web/
    └── index.html          # Web platform setup
```

## Tracker Initialization Pattern

### Complete Initialization Example
```dart
// ✅ Correct: Comprehensive tracker setup
final tracker = await Snowplow.createTracker(
  namespace: 'ns1',
  endpoint: const String.fromEnvironment('ENDPOINT'),
  trackerConfig: TrackerConfiguration(...),
  gdprConfig: GdprConfiguration(...),
  subjectConfig: SubjectConfiguration(...),
);

// ❌ Wrong: Hardcoded endpoint
final tracker = await Snowplow.createTracker(
  endpoint: 'http://localhost:9090', // Use environment
);
```

### Environment Configuration
```dart
// ✅ Correct: Environment-based config
endpoint: const String.fromEnvironment(
  'ENDPOINT',
  defaultValue: 'http://localhost:9090',
),

// ❌ Wrong: No default value
endpoint: const String.fromEnvironment('ENDPOINT'),
```

## Integration Testing Patterns

### Test Structure
```dart
// ✅ Correct: Integration test pattern
testWidgets('tracks events', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp(tracker: tracker));
  
  // Trigger event
  await tester.tap(find.text('Track Event'));
  await tester.pumpAndSettle();
  
  // Verify in Snowplow Micro
  final events = await getMicroEvents();
  expect(events.length, greaterThan(0));
});
```

### Snowplow Micro Integration
```dart
// ✅ Correct: Fetch events from Micro
Future<List<Map>> getMicroEvents(String endpoint) async {
  final microUrl = endpoint.replaceAll('9090', '9091');
  final response = await http.get('$microUrl/micro/good');
  return jsonDecode(response.body);
}

// ❌ Wrong: Not waiting for events
final events = getMicroEvents(); // Missing await
```

### Platform-Specific Testing
```dart
// ✅ Correct: Platform-aware test
if (!kIsWeb) {
  test('mobile-only feature', () async {
    // Test platform context
  });
}

// ❌ Wrong: Testing web features on mobile
test('page view tracking', () async {
  // PageView only works on Web
});
```

## Navigation Observer Pattern

### Observer Setup
```dart
// ✅ Correct: Add observer to MaterialApp
MaterialApp(
  navigatorObservers: [tracker.getObserver()],
  home: MainPage(),
);

// ❌ Wrong: Multiple observers for same tracker
MaterialApp(
  navigatorObservers: [
    tracker.getObserver(),
    tracker.getObserver(), // Duplicate
  ],
);
```

### Route Naming
```dart
// ✅ Correct: Named routes for tracking
Navigator.pushNamed(context, '/details/123');

// ❌ Wrong: Anonymous routes
Navigator.push(context, MaterialPageRoute(
  builder: (_) => DetailsPage(), // No route name
));
```

## Media Tracking Example

### Media Session Lifecycle
```dart
// ✅ Correct: Complete media tracking
final mediaTracking = await tracker.startMediaTracking(
  MediaTrackingConfiguration(id: 'video-1'),
);

await mediaTracking.track(MediaPlayEvent());
await mediaTracking.update(
  player: MediaPlayerEntity(currentTime: 30),
);
await tracker.endMediaTracking('video-1');

// ❌ Wrong: Not ending media session
final media = await tracker.startMediaTracking(...);
// Never calling endMediaTracking
```

## Web Platform Setup

### JavaScript Tracker Integration
```html
<!-- ✅ Correct: Load JS tracker in index.html -->
<script>
  (function(p,l,o,w,i,n,g){...}(...));
  window.snowplow('newTracker', 'sp', '...');
</script>

<!-- ❌ Wrong: Changing global function name -->
<script>
  window.myTracker('newTracker', ...); // Must be 'snowplow'
</script>
```

### Media Plugin Loading
```dart
// ✅ Correct: Configure media plugin URL
TrackerConfiguration(
  jsMediaPluginURL: 'media.js', // Local or CDN
);

// ❌ Wrong: Forgetting plugin for web media
// Media events won't work without plugin on Web
```

## Event Triggering Examples

### UI Event Patterns
```dart
// ✅ Correct: Button with clear action
ElevatedButton(
  onPressed: () async {
    await tracker.track(ScreenView(name: 'button_tap'));
  },
  child: Text('Track Screen View'),
);

// ❌ Wrong: Fire and forget
ElevatedButton(
  onPressed: () {
    tracker.track(event); // Not awaiting
  },
);
```

### Context Addition
```dart
// ✅ Correct: Add contexts to events
await tracker.track(
  Structured(category: 'ui', action: 'click'),
  contexts: [
    SelfDescribing(
      schema: 'iglu:com.example/context/1-0-0',
      data: {'button': 'submit'},
    ),
  ],
);
```

## Test Helper Patterns

### Event Waiting
```dart
// ✅ Correct: Wait for events to arrive
await Future.delayed(Duration(seconds: 2));
final events = await getMicroEvents();

// ❌ Wrong: Immediate check
final events = await getMicroEvents(); // Too fast
```

### Event Filtering
```dart
// ✅ Correct: Filter specific events
final screenViews = events.where((e) => 
  e['event']['event_name'] == 'screen_view'
).toList();

// ❌ Wrong: Assuming event structure
final name = events[0]['name']; // May not exist
```

## Common Testing Pitfalls

### 1. Tracker Initialization in Tests
```dart
// ❌ Wrong: Creating tracker in each test
testWidgets('test 1', (tester) async {
  final tracker = await Snowplow.createTracker(...);
});

// ✅ Correct: Reuse tracker or use setUpAll
setUpAll(() async {
  tracker = await Snowplow.createTracker(...);
});
```

### 2. Micro Endpoint Configuration
```dart
// ❌ Wrong: Same port for collector and Micro
endpoint: 'http://localhost:9090', // Collector
microEndpoint: 'http://localhost:9090', // Wrong

// ✅ Correct: Different ports
endpoint: 'http://localhost:9090', // Collector
microEndpoint: 'http://localhost:9091', // Micro
```

### 3. Async Event Tracking
```dart
// ❌ Wrong: Not awaiting track calls
tracker.track(event1);
tracker.track(event2);
// Events may not be sent

// ✅ Correct: Await tracking
await tracker.track(event1);
await tracker.track(event2);
```

## Running Tests

### Command Line
```bash
# Unit tests
flutter test

# Integration tests with Micro
cd example
flutter test integration_test \
  --dart-define=ENDPOINT=http://192.168.1.100:9090

# Web integration tests
./tool/e2e_tests.sh http://0.0.0.0:9090 "-d web-server"
```

### Environment Setup
```dart
// ✅ Correct: Check Micro is running
setUp(() async {
  final response = await http.get('$microUrl/micro/good');
  if (response.statusCode != 200) {
    throw Exception('Snowplow Micro not running');
  }
});
```

## Quick Reference

### Test Checklist
- [ ] Snowplow Micro is running
- [ ] Correct endpoint configured
- [ ] Tracker initialized in setUpAll
- [ ] Events are awaited
- [ ] Sufficient delay for event delivery
- [ ] Platform-specific tests guarded

### Common Test Assertions
```dart
// Event was tracked
expect(events.length, greaterThan(0));

// Specific event type
expect(event['eventType'], 'struct');

// Event property
expect(event['event']['se_category'], 'ui');

// Context attached
expect(event['event']['contexts'], isNotNull);
```

### Integration Test Files
- `configuration_test.dart` - Tracker setup
- `events_test.dart` - Event tracking
- `media_test.dart` - Media tracking
- `session_test.dart` - Session management
- `helpers.dart` - Shared utilities

## Contributing to CLAUDE.md

When adding or updating content in this document, please follow these guidelines:

### File Size Limit
- **CLAUDE.md must not exceed 40KB** (currently ~19KB)
- Check file size after updates: `wc -c CLAUDE.md`
- Remove outdated content if approaching the limit

### Code Examples
- Keep all code examples **4 lines or fewer**
- Focus on the essential pattern, not complete implementations
- Use `// ❌` and `// ✅` to clearly show wrong vs right approaches

### Content Organization
- Add new patterns to existing sections when possible
- Create new sections sparingly to maintain structure
- Update the architectural principles section for major changes
- Ensure examples follow current codebase conventions

### Quality Standards
- Test any new patterns in actual code before documenting
- Verify imports and syntax are correct for the codebase
- Keep language concise and actionable
- Focus on "what" and "how", minimize "why" explanations

### Multiple CLAUDE.md Files
- **Directory-specific CLAUDE.md files** can be created for specialized modules
- Follow the same structure and guidelines as this root CLAUDE.md
- Keep them focused on directory-specific patterns and conventions
- Maximum 20KB per directory-specific CLAUDE.md file

### Instructions for LLMs
When editing files in this repository, **always check for CLAUDE.md guidance**:

1. **Look for CLAUDE.md in the same directory** as the file being edited
2. **If not found, check parent directories** recursively up to project root
3. **Follow the patterns and conventions** described in the applicable CLAUDE.md
4. **Prioritize directory-specific guidance** over root-level guidance when conflicts exist