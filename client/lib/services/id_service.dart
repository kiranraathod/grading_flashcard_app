import 'package:uuid/uuid.dart';

/// Simple ID generation service using industry-standard UUID
/// 
/// Replaces the complex 189-line IdGeneratorService with a 15-line solution
/// using RFC4122 compliant UUIDs that guarantee uniqueness without custom logic.
class IdService {
  static const _uuid = Uuid();
  
  /// Generate a unique ID for flashcard entities
  static String flashcard() => 'flashcard_${_uuid.v4()}';
  
  /// Generate a unique ID for interview question entities
  static String interview() => 'interview_${_uuid.v4()}';
  
  /// Generate a unique ID for flashcard set entities
  static String set() => 'set_${_uuid.v4()}';
  
  /// Generate a unique ID for job description entities
  static String job() => 'job_${_uuid.v4()}';
  
  /// Generate a unique ID with custom prefix
  static String custom([String? prefix]) => '${prefix ?? ''}${_uuid.v4()}';
}
