import '../../core/network/api_client.dart';
import 'social_models.dart';

class SocialService {
  final ApiClient _api;
  SocialService(this._api);

  Future<List<SocialUser>> search(String q) async {
    final list = await _api.get('/social/search?q=${Uri.encodeQueryComponent(q)}') as List<dynamic>;
    return list.map((e) => SocialUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SocialUser> follow(int userId) async {
    final j = await _api.post('/social/follow/$userId') as Map<String, dynamic>;
    return SocialUser.fromJson(j);
  }

  Future<void> unfollow(int userId) async {
    await _api.delete('/social/follow/$userId');
  }

  Future<List<SocialUser>> requests() async {
    final list = await _api.get('/social/requests') as List<dynamic>;
    return list.map((e) => SocialUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> approve(int userId) async {
    await _api.post('/social/requests/$userId/approve');
  }

  Future<void> reject(int userId) async {
    await _api.post('/social/requests/$userId/reject');
  }

  Future<PublicProfile> profile(int userId) async {
    final j = await _api.get('/social/users/$userId') as Map<String, dynamic>;
    return PublicProfile.fromJson(j);
  }

  Future<List<SocialUser>> followers(int userId) async {
    final list = await _api.get('/social/users/$userId/followers') as List<dynamic>;
    return list.map((e) => SocialUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SocialUser>> following(int userId) async {
    final list = await _api.get('/social/users/$userId/following') as List<dynamic>;
    return list.map((e) => SocialUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CompareStats> compare(int userId) async {
    final j = await _api.get('/social/users/$userId/compare') as Map<String, dynamic>;
    return CompareStats.fromJson(j);
  }

  Future<List<FeedItem>> feed() async {
    final list = await _api.get('/social/feed') as List<dynamic>;
    return list.map((e) => FeedItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SocialCounts> counts() async {
    // Degrade to zeros on failure (e.g. a transient 401 from a token-refresh
    // race) instead of surfacing an unhandled exception in the profile header.
    try {
      final j = await _api.get('/social/me/counts') as Map<String, dynamic>;
      return SocialCounts.fromJson(j);
    } catch (_) {
      return SocialCounts();
    }
  }
}
