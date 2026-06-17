import 'package:flutter_test/flutter_test.dart';
import 'package:ello_ai/src/core/dependencies.dart';
import 'package:ello_ai/src/models/message.dart';

void main() {
  group('ChatHistoryNotifier', () {
    late ChatHistoryNotifier notifier;

    setUp(() {
      notifier = ChatHistoryNotifier();
    });

    test('initializes with empty list', () {
      expect(notifier.state, isEmpty);
    });

    group('addUserMessage', () {
      test('adds user message to empty history', () {
        notifier.addUserMessage('Hello');
        
        expect(notifier.state.length, equals(1));
        expect(notifier.state.first.content, equals('Hello'));
        expect(notifier.state.first.isUser, isTrue);
      });

      test('adds multiple user messages', () {
        notifier.addUserMessage('First message');
        notifier.addUserMessage('Second message');
        
        expect(notifier.state.length, equals(2));
        expect(notifier.state[0].content, equals('First message'));
        expect(notifier.state[1].content, equals('Second message'));
        expect(notifier.state.every((msg) => msg.isUser), isTrue);
      });

      test('handles empty content', () {
        notifier.addUserMessage('');
        
        expect(notifier.state.length, equals(1));
        expect(notifier.state.first.content, isEmpty);
        expect(notifier.state.first.isUser, isTrue);
      });
    });

    group('addAssistantMessage', () {
      test('adds assistant message to empty history', () {
        notifier.addAssistantMessage('AI response');
        
        expect(notifier.state.length, equals(1));
        expect(notifier.state.first.content, equals('AI response'));
        expect(notifier.state.first.isUser, isFalse);
      });

      test('adds multiple assistant messages', () {
        notifier.addAssistantMessage('First AI response');
        notifier.addAssistantMessage('Second AI response');
        
        expect(notifier.state.length, equals(2));
        expect(notifier.state[0].content, equals('First AI response'));
        expect(notifier.state[1].content, equals('Second AI response'));
        expect(notifier.state.every((msg) => !msg.isUser), isTrue);
      });
    });

    group('appendToLastMessage', () {
      test('creates new assistant message when history is empty', () {
        notifier.appendToLastMessage('New content');
        
        expect(notifier.state.length, equals(1));
        expect(notifier.state.first.content, equals('New content'));
        expect(notifier.state.first.isUser, isFalse);
      });

      test('appends to last message when history is not empty', () {
        notifier.addAssistantMessage('Initial');
        notifier.appendToLastMessage(' appended');
        
        expect(notifier.state.length, equals(1));
        expect(notifier.state.first.content, equals('Initial appended'));
        expect(notifier.state.first.isUser, isFalse);
      });

      test('appends to user message correctly', () {
        notifier.addUserMessage('User says');
        notifier.appendToLastMessage(' more');
        
        expect(notifier.state.length, equals(1));
        expect(notifier.state.first.content, equals('User says more'));
        expect(notifier.state.first.isUser, isTrue);
      });

      test('preserves earlier messages when appending', () {
        notifier.addUserMessage('First');
        notifier.addAssistantMessage('Second');
        notifier.addUserMessage('Third');
        notifier.appendToLastMessage(' extended');
        
        expect(notifier.state.length, equals(3));
        expect(notifier.state[0].content, equals('First'));
        expect(notifier.state[1].content, equals('Second'));
        expect(notifier.state[2].content, equals('Third extended'));
      });
    });

    group('clear', () {
      test('clears empty history', () {
        notifier.clear();
        expect(notifier.state, isEmpty);
      });

      test('clears history with messages', () {
        notifier.addUserMessage('User message');
        notifier.addAssistantMessage('AI response');
        
        expect(notifier.state.length, equals(2));
        
        notifier.clear();
        expect(notifier.state, isEmpty);
      });
    });

    group('mixed operations', () {
      test('handles alternating user and assistant messages', () {
        notifier.addUserMessage('User 1');
        notifier.addAssistantMessage('AI 1');
        notifier.addUserMessage('User 2');
        notifier.addAssistantMessage('AI 2');
        
        expect(notifier.state.length, equals(4));
        expect(notifier.state[0].isUser, isTrue);
        expect(notifier.state[1].isUser, isFalse);
        expect(notifier.state[2].isUser, isTrue);
        expect(notifier.state[3].isUser, isFalse);
      });

      test('handles streaming response pattern', () {
        notifier.addUserMessage('What is AI?');
        notifier.addAssistantMessage('AI is');
        notifier.appendToLastMessage(' a technology');
        notifier.appendToLastMessage(' that simulates');
        notifier.appendToLastMessage(' human intelligence');
        
        expect(notifier.state.length, equals(2));
        expect(notifier.state.last.content, 
               equals('AI is a technology that simulates human intelligence'));
      });
    });
  });

  group('ModelNotifier', () {
    late ModelNotifier notifier;

    setUp(() {
      notifier = ModelNotifier();
    });

    test('initializes with default model', () {
      expect(notifier.state, equals('gpt-3.5-turbo'));
    });

    test('selectModel updates state', () {
      notifier.selectModel('gpt-4');
      expect(notifier.state, equals('gpt-4'));
    });

    test('selectModel handles different model names', () {
      final models = ['claude-3', 'gemini-pro', 'custom-model'];
      
      for (final model in models) {
        notifier.selectModel(model);
        expect(notifier.state, equals(model));
      }
    });

    test('selectModel handles empty string', () {
      notifier.selectModel('');
      expect(notifier.state, isEmpty);
    });
  });

  group('GrpcHostNotifier', () {
    late GrpcHostNotifier notifier;

    setUp(() {
      notifier = GrpcHostNotifier();
    });

    test('initializes with default host', () {
      expect(notifier.state, equals('grpc-server-4rwujpfquq-uc.a.run.app'));
    });

    test('updateHost changes state', () {
      notifier.updateHost('localhost');
      expect(notifier.state, equals('localhost'));
    });

    test('updateHost handles different hosts', () {
      final hosts = [
        'example.com',
        '192.168.1.1',
        'custom-server.run.app',
        ''
      ];
      
      for (final host in hosts) {
        notifier.updateHost(host);
        expect(notifier.state, equals(host));
      }
    });
  });

  group('GrpcPortNotifier', () {
    late GrpcPortNotifier notifier;

    setUp(() {
      notifier = GrpcPortNotifier();
    });

    test('initializes with default port', () {
      expect(notifier.state, equals(443));
    });

    test('updatePort changes state', () {
      notifier.updatePort(8080);
      expect(notifier.state, equals(8080));
    });

    test('setForDebug sets debug port', () {
      notifier.setForDebug();
      expect(notifier.state, equals(50051));
    });

    test('setForProduction sets production port', () {
      notifier.setForProduction();
      expect(notifier.state, equals(443));
    });

    test('handles various port numbers', () {
      final ports = [80, 443, 8080, 3000, 50051, 65535];
      
      for (final port in ports) {
        notifier.updatePort(port);
        expect(notifier.state, equals(port));
      }
    });
  });

  group('GrpcSecureNotifier', () {
    late GrpcSecureNotifier notifier;

    setUp(() {
      notifier = GrpcSecureNotifier();
    });

    test('initializes with secure=true', () {
      expect(notifier.state, isTrue);
    });

    test('toggle changes state from true to false', () {
      notifier.toggle();
      expect(notifier.state, isFalse);
    });

    test('toggle changes state from false to true', () {
      notifier.toggle(); // true -> false
      notifier.toggle(); // false -> true
      expect(notifier.state, isTrue);
    });

    test('setSecure sets explicit value', () {
      notifier.setSecure(false);
      expect(notifier.state, isFalse);
      
      notifier.setSecure(true);
      expect(notifier.state, isTrue);
    });
  });

  group('MockGrpcNotifier', () {
    late MockGrpcNotifier notifier;

    setUp() {
      notifier = MockGrpcNotifier();
    }

    test('initializes with mock=false', () {
      expect(notifier.state, isFalse);
    });

    test('toggle changes state', () {
      notifier.toggle();
      expect(notifier.state, isTrue);
      
      notifier.toggle();
      expect(notifier.state, isFalse);
    });
  });

  group('DirectApiNotifier', () {
    late DirectApiNotifier notifier;

    setUp() {
      notifier = DirectApiNotifier();
    }

    test('initializes with directApi=false', () {
      expect(notifier.state, isFalse);
    });

    test('toggle changes state', () {
      notifier.toggle();
      expect(notifier.state, isTrue);
      
      notifier.toggle();
      expect(notifier.state, isFalse);
    });
  });

  group('ConnectionStatusNotifier', () {
    late ConnectionStatusNotifier notifier;

    setUp() {
      notifier = ConnectionStatusNotifier();
    }

    test('initializes with disconnected status', () {
      expect(notifier.state, equals(ConnectionStatus.disconnected));
    });

    test('setConnected updates state to connected', () {
      notifier.setConnected();
      expect(notifier.state, equals(ConnectionStatus.connected));
    });

    test('setConnecting updates state to connecting', () {
      notifier.setConnecting();
      expect(notifier.state, equals(ConnectionStatus.connecting));
    });

    test('setDisconnected updates state to disconnected', () {
      notifier.setConnected(); // First change to different state
      notifier.setDisconnected();
      expect(notifier.state, equals(ConnectionStatus.disconnected));
    });

    test('setFailed updates state to failed', () {
      notifier.setFailed();
      expect(notifier.state, equals(ConnectionStatus.failed));
    });

    test('state transitions work correctly', () {
      // Test various state transitions
      notifier.setConnecting();
      expect(notifier.state, equals(ConnectionStatus.connecting));
      
      notifier.setConnected();
      expect(notifier.state, equals(ConnectionStatus.connected));
      
      notifier.setFailed();
      expect(notifier.state, equals(ConnectionStatus.failed));
      
      notifier.setDisconnected();
      expect(notifier.state, equals(ConnectionStatus.disconnected));
    });
  });
}