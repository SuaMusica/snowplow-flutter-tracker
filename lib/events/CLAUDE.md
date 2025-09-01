# CLAUDE.md - Events Module Documentation

## Module Overview

The events module defines all trackable event types in the Snowplow Flutter tracker. Each event represents a specific user interaction or system occurrence that can be sent to Snowplow collectors for analytics.

**Event Categories:**
- Standard events (ScreenView, Structured, Timing)
- Self-describing events (custom schemas)
- Media events (play, pause, seek, etc.)
- Consent events (GDPR compliance)
- Web-specific events (PageView, ScrollChanged)

## Event Implementation Pattern

### Base Event Contract
Every event must implement the `Event` interface:
```dart
@immutable
abstract class Event {
  String endpoint();     // Method channel endpoint name
  Map<String, Object?> toMap(); // Serialization
}
```

### Standard Event Template
```dart
@immutable
class EventName implements Event {
  final String requiredField;
  final String? optionalField;
  
  const EventName({
    required this.requiredField,
    this.optionalField,
  });
  
  EventName.fromMap(Map<String, Object?> map)
      : requiredField = map['requiredField'] as String,
        optionalField = map['optionalField'] as String?;
  
  @override
  String endpoint() => 'trackEventName';
  
  @override
  Map<String, Object?> toMap() {
    final data = <String, Object?>{
      'requiredField': requiredField,
      'optionalField': optionalField,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}
```

## Event Type Patterns

### 1. Simple Events (No Data)
For events with no additional data:
```dart
// ✅ Correct: Empty map for no-data events
@override
Map<String, Object?> toMap() {
  return <String, Object?>{};
}

// ❌ Wrong: Returning null
Map<String, Object?> toMap() => null;
```

### 2. Schema-Based Events
For self-describing events with schemas:
```dart
// ✅ Correct: Include schema and data
class SelfDescribing implements Event {
  final String schema;  // Iglu schema path
  final dynamic data;   // Schema-conforming data
}

// ❌ Wrong: Missing schema
class CustomEvent implements Event {
  final Map data; // No schema reference
}
```

### 3. Media Events
Media events follow a specific naming pattern:
```dart
// ✅ Correct: Media event endpoint pattern
String endpoint() => 'trackMediaPlayEvent';
String endpoint() => 'trackMediaPauseEvent';

// ❌ Wrong: Inconsistent naming
String endpoint() => 'mediaPlay'; // Missing track prefix
```

### 4. WebView Events
Special event for WebView integration:
```dart
// ✅ Correct: WebViewReader pattern
class WebViewReader implements Event {
  final String body; // JSON string from WebView
  
  @override
  String endpoint() => 'trackWebViewEvent';
}
```

## Event Serialization Rules

### Field Naming Convention
```dart
// ✅ Correct: Exact field names for native bridge
'previousName'     // camelCase for multi-word
'id'              // lowercase for single word
'type'            // avoid reserved words carefully

// ❌ Wrong: Incorrect naming
'previous_name'   // snake_case not used
'ID'             // uppercase not used
```

### Type Casting in fromMap
```dart
// ✅ Correct: Explicit type casting
EventName.fromMap(Map<String, Object?> map)
    : field = map['field'] as String?,
      number = map['number'] as int?;

// ❌ Wrong: No type checking
EventName.fromMap(Map map)
    : field = map['field']; // Runtime errors possible
```

## Media Event Hierarchy

### Media Event Categories
1. **Playback Events**: play, pause, end, ready
2. **Seek Events**: seekStart, seekEnd
3. **Buffer Events**: bufferStart, bufferEnd
4. **Quality Events**: qualityChange, playbackRateChange
5. **Ad Events**: adStart, adComplete, adSkip
6. **Ad Break Events**: adBreakStart, adBreakEnd

### Media Event Pattern
```dart
// All media events are empty (data in entities)
@immutable
class MediaPlayEvent implements Event {
  @override
  String endpoint() => 'trackMediaPlayEvent';
  
  @override
  Map<String, Object?> toMap() => <String, Object?>{};
}
```

## Consent Event Pattern

### GDPR Consent Events
```dart
// ✅ Correct: Consent with all fields
class ConsentGranted implements Event {
  final String expiry;
  final String documentId;
  final String version;
  // Additional fields...
}

// ❌ Wrong: Missing required GDPR fields
class ConsentEvent implements Event {
  final bool granted; // Too simple
}
```

## Platform-Specific Events

### Web-Only Events
```dart
// PageViewEvent - only on Web
class PageViewEvent implements Event {
  final String? title;
  final String? referrer;
  // Web-specific implementation
}
```

### Mobile-Only Context
```dart
// ScreenView - works on all platforms
// but screen context only attached on mobile
class ScreenView implements Event {
  final String name;
  final String? previousName; // For screen context
}
```

## Event Validation

### Required vs Optional Fields
```dart
// ✅ Correct: Clear required/optional distinction
const ScreenView({
  required this.name,      // Cannot be null
  this.id,                 // Can be null
  this.type,              // Can be null
});

// ❌ Wrong: All fields optional
const ScreenView({
  this.name,              // Should be required
});
```

### Dynamic Data Validation
```dart
// ✅ Correct: Accept dynamic for schema data
class SelfDescribing implements Event {
  final dynamic data; // Validated by schema
}

// ❌ Wrong: Over-restrictive typing
class SelfDescribing implements Event {
  final Map<String, String> data; // Too restrictive
}
```

## Common Event Mistakes

### 1. Forgetting Null Removal
```dart
// ❌ Wrong: Nulls in serialized map
Map<String, Object?> toMap() => {
  'field': nullableField, // May be null
};

// ✅ Correct: Remove null values
Map<String, Object?> toMap() {
  final map = {'field': nullableField};
  map.removeWhere((key, value) => value == null);
  return map;
}
```

### 2. Incorrect Endpoint Naming
```dart
// ❌ Wrong: Inconsistent endpoint
String endpoint() => 'ScreenView';

// ✅ Correct: Follow convention
String endpoint() => 'trackScreenView';
```

### 3. Mutable Event Fields
```dart
// ❌ Wrong: Mutable field
class Event {
  String name; // Can be changed
}

// ✅ Correct: Immutable field
class Event {
  final String name; // Cannot be changed
}
```

## Event Testing Pattern

```dart
test('event serialization', () {
  final event = ScreenView(
    name: 'home',
    id: '123',
  );
  
  final map = event.toMap();
  expect(map['name'], 'home');
  expect(map['id'], '123');
  expect(map.containsKey('type'), false); // null removed
});
```

## Quick Reference

### New Event Checklist
- [ ] Implements `Event` interface
- [ ] Has `@immutable` annotation
- [ ] All fields are `final`
- [ ] Required fields use `required` keyword
- [ ] Has const constructor
- [ ] Has `.fromMap()` factory constructor
- [ ] `endpoint()` returns 'track{EventName}'
- [ ] `toMap()` removes null values
- [ ] Added to snowplow_tracker.dart exports

### Event Endpoint Naming
- Standard: `track{EventName}` (e.g., `trackScreenView`)
- Media: `trackMedia{Action}Event` (e.g., `trackMediaPlayEvent`)
- Custom: `trackSelfDescribing` (for all custom events)

### Field Type Mapping
- `String?` for optional text
- `int?` for optional numbers
- `double?` for optional decimals
- `bool?` for optional flags
- `dynamic` for schema-validated data
- `List<SelfDescribing>?` for contexts

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