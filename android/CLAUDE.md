# CLAUDE.md - Android Platform Implementation Documentation

## Module Overview

The Android platform implementation provides the Kotlin-based bridge between Flutter's Dart API and the native Snowplow Android tracker. It handles method channel communication, message deserialization, and delegates to the native Android tracker SDK.

**Core Technologies:**
- Kotlin for Android implementation
- Flutter MethodChannel for communication
- Snowplow Android Tracker SDK
- Android Embedding V2 API

## Architecture

### Platform Plugin Structure
```
android/
├── src/main/kotlin/
│   └── com/snowplowanalytics/snowplow_tracker/
│       ├── SnowplowTrackerPlugin.kt    # Plugin entry point
│       ├── SnowplowTrackerController.kt # Business logic
│       ├── TrackerVersion.kt           # Version info
│       └── readers/                    # Deserialization
│           ├── configurations/
│           ├── events/
│           ├── entities/
│           └── messages/
```

## Method Channel Pattern

### Plugin Registration
```kotlin
// ✅ Correct: Flutter embedding V2
class SnowplowTrackerPlugin : FlutterPlugin, MethodCallHandler {
  override fun onAttachedToEngine(binding: FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "snowplow_tracker")
    channel.setMethodCallHandler(this)
  }
}

// ❌ Wrong: Old embedding API
// Using static registerWith method
```

### Method Call Handling
```kotlin
// ✅ Correct: Exhaustive when expression
override fun onMethodCall(call: MethodCall, result: Result) {
  when (call.method) {
    "createTracker" -> createTracker(call, result)
    "trackScreenView" -> trackScreenView(call, result)
    else -> result.notImplemented()
  }
}

// ❌ Wrong: If-else chains
if (call.method == "createTracker") { }
```

## Reader Pattern

### Message Reader Structure
```kotlin
// ✅ Correct: Nullable reader pattern
class EventMessageReader(values: Map<String, Any>) {
  val eventData: Map<String, Any>? by values
  val contexts: List<Map<String, Any>>? by values
  val trackerNamespace: String by values
}

// ❌ Wrong: Non-null assertions
val eventData = values["eventData"]!! // Crashes on null
```

### Configuration Reader Pattern
```kotlin
// ✅ Correct: Safe casting with defaults
class TrackerConfigurationReader(values: Map<String, Any>) {
  val appId: String? by values
  val base64Encoding: Boolean = 
    values["base64Encoding"] as? Boolean ?: true
}

// ❌ Wrong: Unsafe casting
val appId = values["appId"] as String // ClassCastException
```

## Kotlin Delegation Pattern

### Property Delegation
```kotlin
// ✅ Correct: By delegation for clean access
class Reader(private val values: Map<String, Any>) {
  val field: String? by values
  val nested: Map<String, Any>? by values
}

// ❌ Wrong: Manual extraction
class Reader(values: Map<String, Any>) {
  val field = values["field"] as? String
}
```

## Native Tracker Integration

### Tracker Creation
```kotlin
// ✅ Correct: Configure native tracker
val tracker = Snowplow.createTracker(
  context = context,
  namespace = namespace,
  network = NetworkConfiguration(endpoint),
  configurations = arrayOf(
    trackerConfig?.toConfiguration(),
    subjectConfig?.toConfiguration()
  ).filterNotNull()
)

// ❌ Wrong: Missing context
val tracker = Snowplow.createTracker(namespace, endpoint)
```

### Event Tracking
```kotlin
// ✅ Correct: Build native event
val event = ScreenView(name).apply {
  contexts = contextEntities
  trueTimestamp = timestamp
}
tracker.track(event)

// ❌ Wrong: Manual event construction
tracker.track(mapOf("name" to name)) // Not a valid event
```

## Error Handling Pattern

### Result Callbacks
```kotlin
// ✅ Correct: Proper result handling
try {
  val result = performOperation()
  result.success(result)
} catch (e: Exception) {
  result.error("ERROR_CODE", e.message, null)
}

// ❌ Wrong: Uncaught exceptions
val result = performOperation() // May crash
result.success(result)
```

### Null Safety
```kotlin
// ✅ Correct: Safe calls and Elvis operator
val appId = config?.appId ?: getDefaultAppId()
val tracker = trackers[namespace]?.tracker

// ❌ Wrong: Force unwrapping
val appId = config!!.appId
val tracker = trackers[namespace]!!.tracker
```

## Controller Pattern

### Tracker Management
```kotlin
// ✅ Correct: Store trackers by namespace
class SnowplowTrackerController {
  private val trackers = mutableMapOf<String, TrackerController>()
  
  fun createTracker(namespace: String, ...): Boolean {
    trackers[namespace] = TrackerController(...)
    return true
  }
}

// ❌ Wrong: Single tracker instance
private var tracker: TrackerController? = null
```

### Thread Safety
```kotlin
// ✅ Correct: Synchronized access
@Synchronized
fun getTracker(namespace: String): TrackerController? {
  return trackers[namespace]
}

// ❌ Wrong: Unsynchronized map access
fun getTracker(namespace: String) = trackers[namespace]
```

## Type Conversion Patterns

### Flutter to Kotlin Types
```kotlin
// ✅ Correct: Safe type conversion
val stringValue = map["key"] as? String
val intValue = (map["number"] as? Number)?.toInt()
val boolValue = map["flag"] as? Boolean ?: false

// ❌ Wrong: Direct casting
val stringValue = map["key"] as String // May fail
```

### Kotlin to Flutter Types
```kotlin
// ✅ Correct: Platform-compatible types
result.success(mapOf(
  "id" to sessionId,
  "index" to sessionIndex,
  "userId" to userId
))

// ❌ Wrong: Kotlin-specific types
result.success(data class Result(...)) // Not serializable
```

## Media Tracking Pattern

### Media Entity Updates
```kotlin
// ✅ Correct: Update media entities
fun updateMediaTracking(call: MethodCall, result: Result) {
  val message = UpdateMediaTrackingMessageReader(call.arguments)
  val id = MediaTrackingId(message.trackerNamespace, message.id)
  
  message.player?.let { 
    mediaTrackingController.updatePlayer(id, it)
  }
  result.success(null)
}
```

## Common Android Pitfalls

### 1. Context Management
```kotlin
// ❌ Wrong: Storing activity context
class Plugin(private val context: Context) // Memory leak

// ✅ Correct: Use application context
class Plugin(context: Context) {
  private val appContext = context.applicationContext
}
```

### 2. Main Thread Blocking
```kotlin
// ❌ Wrong: Network on main thread
override fun onMethodCall(call: MethodCall, result: Result) {
  val response = makeNetworkRequest() // Blocks UI
}

// ✅ Correct: Async operations
override fun onMethodCall(call: MethodCall, result: Result) {
  scope.launch { 
    val response = makeNetworkRequest()
    result.success(response)
  }
}
```

### 3. Resource Cleanup
```kotlin
// ✅ Correct: Clean up in onDetachedFromEngine
override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
  channel.setMethodCallHandler(null)
  trackers.clear()
}
```

## Testing Patterns

### Unit Testing Readers
```kotlin
@Test
fun `reader extracts values correctly`() {
  val map = mapOf("field" to "value")
  val reader = EventReader(map)
  
  assertEquals("value", reader.field)
  assertNull(reader.optionalField)
}
```

## Quick Reference

### Reader Checklist
- [ ] Uses property delegation (`by values`)
- [ ] Handles null values safely
- [ ] Provides default values where appropriate
- [ ] Converts types safely (Number to Int/Double)

### Method Handler Checklist
- [ ] Uses `when` expression for method routing
- [ ] Has `else -> result.notImplemented()`
- [ ] Wraps operations in try-catch
- [ ] Calls result.success() or result.error()

### Type Mapping
| Dart Type | Kotlin Type | Notes |
|-----------|------------|-------|
| String | String? | Nullable by default |
| int | Int? | Cast from Number |
| double | Double? | Cast from Number |
| bool | Boolean? | Nullable |
| Map | Map<String, Any> | Type-erased |
| List | List<Any> | Type-erased |

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