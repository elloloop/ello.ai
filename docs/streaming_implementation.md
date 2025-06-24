# Streaming LLM Responses

This document describes the streaming implementation improvements made to prevent UI jank and provide smooth token-by-token display of LLM responses.

## Features Implemented

### 1. Optimized StreamingText Widget
- **Debounced Updates**: Limits UI updates to ~60fps (16ms debounce) to prevent jank during rapid token arrivals
- **Efficient Rendering**: Only updates the specific text content without rebuilding entire message containers
- **Configurable Timing**: Adjustable update frequency based on streaming vs. static content

### 2. Enhanced Message State Management
- **Streaming State**: Messages track whether they're actively streaming with `isStreaming` flag
- **Unique IDs**: Each message has a UUID for precise tracking and updates
- **Lifecycle Management**: Proper handling of streaming start, update, and completion phases

### 3. Stream Interruption
- **Cancellation Support**: Users can interrupt streaming responses with a stop button
- **Clean Termination**: Proper cleanup of streaming state when interrupted
- **UI Feedback**: Visual indicators show streaming status and allow early termination

### 4. UI Optimizations
- **Input State**: Text input is disabled during streaming to prevent conflicts
- **Visual Indicators**: Progress indicators and streaming status display
- **Responsive Layout**: Stop/Send button toggles based on streaming state

## Technical Implementation

### StreamingText Widget
```dart
class StreamingText extends StatefulWidget {
  final String content;
  final int updateDebounceMs; // Default: 16ms (~60fps)
  // ... other properties
}
```

### Message Model
```dart
class Message {
  final String content;
  final bool isUser;
  final bool isStreaming;  // New
  final String? id;        // New
}
```

### ChatHistoryNotifier
```dart
class ChatHistoryNotifier extends StateNotifier<List<Message>> {
  Timer? _streamingDebounceTimer;
  
  void appendToLastMessage(String content) {
    // Debounced updates for smooth streaming
    _streamingDebounceTimer = Timer(Duration(milliseconds: 16), () {
      // Update state
    });
  }
}
```

### ChatController
```dart
class ChatController extends StateNotifier<AsyncValue<void>> {
  StreamSubscription<String>? _currentStreamSubscription;
  
  void cancelCurrentStream() {
    _currentStreamSubscription?.cancel();
    // Clean up streaming state
  }
}
```

## Performance Benefits

1. **Reduced UI Jank**: Debounced updates prevent excessive rebuilds during rapid token arrival
2. **Efficient Rendering**: Only the text content updates, not entire message containers
3. **Memory Efficiency**: Proper stream subscription management prevents memory leaks
4. **Responsive UI**: Early termination capability for better user control

## User Experience Improvements

1. **Smooth Token Display**: Tokens appear progressively without visual stuttering
2. **Interrupt Capability**: Users can stop unwanted responses early
3. **Visual Feedback**: Clear indicators for streaming status and progress
4. **Responsive Interface**: UI remains responsive during streaming operations

## Testing

- **Unit Tests**: Verify streaming state management and message handling
- **Widget Tests**: Ensure StreamingText renders and updates correctly
- **Mock Clients**: Enhanced simulation with realistic streaming timing

## Future Enhancements

- **Adaptive Timing**: Adjust debounce intervals based on token arrival rate
- **Progressive Enhancement**: Show partial sentences vs. individual tokens
- **Persistence**: Save streaming state across app restarts
- **Analytics**: Track streaming performance metrics