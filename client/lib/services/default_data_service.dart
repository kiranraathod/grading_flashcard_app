import 'package:flutter/foundation.dart';
import '../models/flashcard_set.dart';
import '../models/flashcard.dart';
import '../models/interview_question.dart';
import 'enhanced_http_client_service.dart';
import 'enhanced_cache_manager.dart';
import 'simple_error_handler.dart';

class DefaultDataService extends ChangeNotifier {
  static final DefaultDataService _instance = DefaultDataService._internal();
  factory DefaultDataService() => _instance;
  DefaultDataService._internal();

  final EnhancedHttpClientService _httpClient = EnhancedHttpClientService();
  final EnhancedCacheManager _cache = EnhancedCacheManager();

  Future<List<FlashcardSet>> loadDefaultFlashcardSets({String? userId}) async {
    return await SimpleErrorHandler.safe<List<FlashcardSet>>(
      () async {
        final cachedData = await _cache.getCachedData('default_flashcard_sets');
        if (cachedData != null && cachedData['flashcard_sets'] != null) {
          return _parseFlashcardSets(cachedData['flashcard_sets']);
        }

        final queryParameters = userId != null ? {'user_id': userId} : null;
        final response = await _httpClient.get('/api/default-data/flashcard-sets', queryParameters: queryParameters);

        if (response.statusCode == 200) {
          final data = response.data;
          await _cache.cacheData('default_flashcard_sets', {'flashcard_sets': data});
          return _parseFlashcardSets(data);
        }
        return <FlashcardSet>[];
      },
      fallback: <FlashcardSet>[],
      operationName: 'load_default_flashcard_sets',
    );
  }

  Future<List<InterviewQuestion>> loadDefaultInterviewQuestions({
    String? userId, String? category, String? difficulty}) async {
    return await SimpleErrorHandler.safe<List<InterviewQuestion>>(
      () async {
        final cacheKey = 'interview_${category ?? 'all'}_${difficulty ?? 'all'}';
        final cachedData = await _cache.getCachedData(cacheKey);
        if (cachedData != null && cachedData['data'] != null) {
          return _parseInterviewQuestions(cachedData['data']);
        }

        final queryParams = <String, String>{};
        if (userId != null) queryParams['user_id'] = userId;
        if (category != null) queryParams['category'] = category;
        if (difficulty != null) queryParams['difficulty'] = difficulty;

        final response = await _httpClient.get('/api/default-data/interview-questions',
            queryParameters: queryParams.isNotEmpty ? queryParams : null);

        if (response.statusCode == 200) {
          final data = response.data;
          await _cache.cacheData(cacheKey, {'data': data});
          return _parseInterviewQuestions(data);
        }
        return <InterviewQuestion>[];
      },
      fallback: <InterviewQuestion>[],
      operationName: 'load_default_interview_questions',
    );
  }

  Future<List<Map<String, dynamic>>> loadDefaultCategories() async {
    return await SimpleErrorHandler.safe<List<Map<String, dynamic>>>(
      () async {
        final cachedData = await _cache.getCachedData('categories');
        if (cachedData != null && cachedData['data'] != null) {
          return List<Map<String, dynamic>>.from(cachedData['data']);
        }

        final response = await _httpClient.get('/api/default-data/categories');
        if (response.statusCode == 200) {
          final data = response.data;
          await _cache.cacheData('categories', {'data': data});
          return List<Map<String, dynamic>>.from(data);
        }
        return <Map<String, dynamic>>[];
      },
      fallback: <Map<String, dynamic>>[],
      operationName: 'load_default_categories',
    );
  }

  Future<Map<String, int>> loadCategoryCounts({String? userId}) async {
    return await SimpleErrorHandler.safe<Map<String, int>>(
      () async {
        final cachedData = await _cache.getCachedData('category_counts');
        if (cachedData != null && cachedData['counts'] != null) {
          return Map<String, int>.from(cachedData['counts']);
        }

        final queryParameters = userId != null ? {'user_id': userId} : null;
        final response = await _httpClient.get('/api/default-data/category-counts', queryParameters: queryParameters);

        if (response.statusCode == 200) {
          final data = response.data;
          final counts = Map<String, int>.from(data['counts']);
          await _cache.cacheData('category_counts', {'counts': counts});
          return counts;
        }
        return _getDefaultCounts();
      },
      fallback: _getDefaultCounts(),
      operationName: 'load_category_counts',
    );
  }

  Map<String, int> _getDefaultCounts() => {
    'Data Analysis': 18, 'Web Development': 15, 'Machine Learning': 22, 
    'SQL': 10, 'Python': 14, 'Statistics': 8
  };

  List<FlashcardSet> _parseFlashcardSets(List<dynamic> data) {
    return data.map((setData) {
      final flashcards = (setData['flashcards'] as List<dynamic>)
          .map((cardData) => Flashcard(
                id: cardData['id'], question: cardData['question'],
                answer: cardData['answer'], isCompleted: cardData['is_completed'] ?? false,
              )).toList();
      return FlashcardSet(
        id: setData['id'], title: setData['title'], description: setData['description'],
        isDraft: setData['is_draft'] ?? false, rating: (setData['rating'] ?? 0.0).toDouble(),
        ratingCount: setData['rating_count'] ?? 0, flashcards: flashcards,
      );
    }).toList();
  }

  List<InterviewQuestion> _parseInterviewQuestions(List<dynamic> data) {
    return data.map((q) => InterviewQuestion(
          id: q['id'], 
          text: q['text'], 
          category: q['category'], 
          subtopic: q['subtopic'],
          difficulty: q['difficulty'], 
          answer: q['answer'], 
          categoryId: q['category_id'], // ✅ ADDED: Parse category_id from server
          isStarred: q['is_starred'] ?? false,
          isCompleted: q['is_completed'] ?? false, 
          isDraft: q['is_draft'] ?? false,
        )).toList();
  }

  Future<void> clearCache() async {
    await _cache.clearCache(key: 'default_flashcard_sets');
    await _cache.clearCache(key: 'category_counts');
    await _cache.clearCache(key: 'categories');
  }
}
