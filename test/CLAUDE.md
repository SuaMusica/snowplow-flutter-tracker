# Test Directory Documentation

## Project Overview

The test directory contains unit and integration tests for the Snowplow Flutter tracker, focusing on platform channel mocking, event serialization validation, and tracker behavior verification. Tests ensure proper communication between Dart and native platforms.

## Development Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/snowplow_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests in verbose mode
flutter test -v

# Run tests with specific platform
flutter test --platform chrome  # For web tests
```

## Architecture

### Testing Strategy

The test suite uses Flutter's platform channel mocking to verify:

1. **Method Channel Communication**: Correct method names and arguments
2. **Event Serialization**: Proper conversion to platform message format
3. **Configuration Validation**: Correct configuration structure
4. **Return Value Handling**: Proper async result processing

### Core Testing Components

- **Method Channel Mocking**: Intercepts and validates platform calls
- **Test Data Builders**: Consistent test data creation
- **Matcher Utilities**: Custom matchers for method call validation
- **Mock Handlers**: Simulate platform responses

## Core Testing Principles

### 1. Platform Channel Mocking Pattern

All tests mock the platform channel to verify communication:

```dart
// ✅ Proper channel mock setup
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(channel, (MethodCall call) async {
      methodCall = call;
      return returnValue;
    });
```

### 2. Method Call Validation

Use `isMethodCall` matcher for comprehensive validation:

```dart
// ✅ Complete method call verification
expect(methodCall, isMethodCall('createTracker', arguments: {
  'namespace': 'tns1',
  'networkConfig': {'endpoint': 'https://example.com'}
}));
```

### 3. Setup and Teardown Hygiene

Always clean up mock handlers:

```dart
// ✅ Proper cleanup in tearDown
tearDown(() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
});
```

## Test Organization & Structure

### Test File Categories

1. **`snowplow_test.dart`**: Main API and configuration tests
2. **`tracker_test.dart`**: Tracker instance method tests
3. **`web_view_integration_test.dart`**: WebView tracker integration
4. **`events/web_view_reader_test.dart`**: WebView event processing

### Test Structure Pattern

```dart
void main() {
  // Test state variables
  MethodCall? methodCall;
  dynamic returnValue;
  
  // Setup and teardown
  setUp(() { /* Initialize mocks */ });
  tearDown(() { /* Clean up */ });
  
  // Grouped tests
  test('descriptive test name', () async {
    // Arrange, Act, Assert
  });
}
```

## Critical Testing Patterns

### 1. Method Call Capture Pattern

```dart
// ✅ Capture method calls for verification
MethodCall? methodCall;
setMockMethodCallHandler(channel, (call) async {
  methodCall = call;  // Capture for assertions
  return returnValue;
});
```

### 2. Return Value Simulation

```dart
// ✅ Simulate platform responses
returnValue = 'sessionId123';
String? sessionId = await Snowplow.getSessionId();
expect(sessionId, equals('sessionId123'));
```

### 3. Argument Extraction Pattern

```dart
// ✅ Extract and verify nested arguments
expect(methodCall?.arguments['tracker'], equals('ns1'));
expect(methodCall?.arguments['eventData']['category'], equals('c1'));
```

## Essential Testing Utilities

### 1. TestWidgetsFlutterBinding

```dart
// ✅ Required for platform channel tests
TestWidgetsFlutterBinding.ensureInitialized();
```

### 2. Custom Matchers

```dart
// ✅ isMethodCall matcher usage
expect(methodCall, isMethodCall('trackStructured', arguments: {
  'tracker': 'ns1',
  'eventData': {'category': 'c1', 'action': 'a1'}
}));
```

### 3. Async Test Patterns

```dart
// ✅ Proper async testing
test('async operation', () async {
  final result = await Snowplow.createTracker(...);
  expect(methodCall, isNotNull);
});
```

## Event Testing Patterns

### 1. Structured Event Testing

```dart
// ✅ Complete structured event test
test('tracks structured event', () async {
  Event event = const Structured(category: 'c1', action: 'a1');
  await Snowplow.track(event, tracker: 'tns3');
  
  expect(methodCall?.method, equals('trackStructured'));
  expect(methodCall?.arguments['eventData'], containsPair('category', 'c1'));
});
```

### 2. Self-Describing Event Testing

```dart
// ✅ Schema and data validation
test('tracks self-describing event', () async {
  Event event = const SelfDescribing(
    schema: 'iglu:com.example/event/jsonschema/1-0-0',
    data: {'key': 'value'}
  );
  await Snowplow.track(event);
  
  expect(methodCall?.arguments['eventData']['schema'], contains('iglu:'));
});
```

### 3. Context Testing

```dart
// ✅ Context array validation
test('tracks event with contexts', () async {
  await Snowplow.track(event, contexts: [
    const SelfDescribing(schema: 'schema1', data: {'x': 'y'})
  ]);
  
  expect(methodCall?.arguments['contexts'], isList);
  expect(methodCall?.arguments['contexts'][0]['schema'], equals('schema1'));
});
```

## Configuration Testing Patterns

### 1. Tracker Configuration Testing

```dart
// ✅ Configuration serialization test
test('creates tracker with config', () async {
  await Snowplow.createTracker(
    namespace: 'ns1',
    endpoint: 'https://example.com',
    trackerConfig: const TrackerConfiguration(
      devicePlatform: DevicePlatform.mobile,
      base64Encoding: true
    )
  );
  
  final config = methodCall?.arguments['trackerConfig'];
  expect(config['devicePlatform'], equals('mob'));
  expect(config['base64Encoding'], isTrue);
});
```

### 2. Optional Configuration Testing

```dart
// ✅ Test optional configurations
test('handles optional configs', () async {
  await Snowplow.createTracker(
    namespace: 'ns1',
    endpoint: 'endpoint',
    gdprConfig: null  // Explicitly test null
  );
  
  expect(methodCall?.arguments.containsKey('gdprConfig'), isFalse);
});
```

## Common Testing Pitfalls & Solutions

### 1. Forgetting TestWidgetsFlutterBinding

```dart
// ❌ Missing binding initialization
void main() {
  test('test', () async {
    // Will fail with platform channel errors
  });
}

// ✅ Proper initialization
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('test', () async {
    // Works correctly
  });
}
```

### 2. Not Clearing Mock Handlers

```dart
// ❌ Leaking mock handlers between tests
setUp(() {
  setMockMethodCallHandler(channel, handler);
});
// Missing tearDown!

// ✅ Proper cleanup
tearDown(() {
  setMockMethodCallHandler(channel, null);
});
```

### 3. Incorrect Async Handling

```dart
// ❌ Missing async/await
test('async test', () {
  Snowplow.track(event);  // Returns Future
  expect(methodCall, isNotNull);  // May fail
});

// ✅ Proper async handling
test('async test', () async {
  await Snowplow.track(event);
  expect(methodCall, isNotNull);
});
```

## Mock Patterns for Platform Channels

### 1. Simple Mock Handler

```dart
// ✅ Basic mock handler
setMockMethodCallHandler(channel, (call) async {
  return null;  // Simple acknowledgment
});
```

### 2. Conditional Response Mock

```dart
// ✅ Different responses based on method
setMockMethodCallHandler(channel, (call) async {
  switch (call.method) {
    case 'getSessionId': return 'session123';
    case 'getSessionIndex': return 42;
    default: return null;
  }
});
```

### 3. Error Simulation

```dart
// ✅ Test error handling
setMockMethodCallHandler(channel, (call) async {
  throw PlatformException(code: 'ERROR', message: 'Test error');
});
```

## Media Tracking Test Patterns

### 1. Media Configuration Testing

```dart
// ✅ Media tracking configuration test
test('starts media tracking', () async {
  await Snowplow.startMediaTracking(
    configuration: const MediaTrackingConfiguration(
      id: 'media1',
      boundaries: [10, 25, 50, 75]
    )
  );
  
  final config = methodCall?.arguments['configuration'];
  expect(config['id'], equals('media1'));
  expect(config['boundaries'], equals([10, 25, 50, 75]));
});
```

### 2. Media Entity Testing

```dart
// ✅ Media entity serialization test
test('updates media tracking', () async {
  await Snowplow.updateMediaTracking(
    id: 'm1',
    player: const MediaPlayerEntity(currentTime: 30.5)
  );
  
  final player = methodCall?.arguments['player'];
  expect(player['currentTime'], equals(30.5));
});
```

## Test Data Creation Patterns

### 1. Test Data Constants

```dart
// ✅ Reusable test data
const testNamespace = 'test_namespace';
const testEndpoint = 'https://test.endpoint.com';
const testEvent = Structured(category: 'test', action: 'click');
```

### 2. Builder Pattern for Complex Data

```dart
// ✅ Builder for complex test objects
TrackerConfiguration buildTestConfig({
  bool? base64Encoding,
  DevicePlatform? platform
}) {
  return TrackerConfiguration(
    base64Encoding: base64Encoding ?? false,
    devicePlatform: platform ?? DevicePlatform.mobile
  );
}
```

## File Structure Template

```
test/
├── snowplow_test.dart              # Main API tests
├── tracker_test.dart               # Tracker instance tests
├── web_view_integration_test.dart  # WebView integration tests
├── events/
│   └── web_view_reader_test.dart  # WebView event tests
└── fixtures/                       # Test data files (if needed)
    └── test_data.json
```

## Quick Reference

### Test Setup Checklist

- [ ] Call `TestWidgetsFlutterBinding.ensureInitialized()`
- [ ] Create method channel with correct name
- [ ] Set up mock method call handler
- [ ] Initialize test state variables
- [ ] Implement proper tearDown cleanup

### Method Call Verification Checklist

- [ ] Verify method name matches expected
- [ ] Check all required arguments present
- [ ] Validate argument types and values
- [ ] Test optional argument handling
- [ ] Verify nested data structures

### Async Testing Checklist

- [ ] Mark test function as `async`
- [ ] Use `await` for all Future operations
- [ ] Set return values before async calls
- [ ] Verify method calls after await
- [ ] Handle potential exceptions

## Contributing to CLAUDE.md

When adding or updating content in this document, please follow these guidelines:

### File Size Limit
- **CLAUDE.md must not exceed 40KB** (currently ~11KB)
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