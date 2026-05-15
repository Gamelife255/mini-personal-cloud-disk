package com.disk.service;

import com.disk.entity.*;

import java.util.List;
import java.util.Map;

public interface ForumService {
    List<Category> listCategories();

    Map<String, Object> listTopics(Long categoryId, int page, int size, String sortBy);
    Map<String, Object> getTopic(Long id);
    Map<String, Object> getTopicRaw(Long id);
    Topic createTopic(Topic topic, List<String> tagNames);
    Topic updateTopic(Topic topic, List<String> tagNames);
    int deleteTopic(Long id, Long userId, boolean isAdmin);

    Map<String, Object> listReplies(Long topicId, int page, int size);
    Reply createReply(Reply reply);
    int deleteReply(Long id, Long userId, boolean isAdmin);

    List<Tag> listTags();
    List<Tag> getTagsForTopic(Long topicId);

    Map<String, Object> toggleLike(Long topicId, Long userId);
    boolean hasLiked(Long topicId, Long userId);

    Map<String, Object> listUserTopics(Long userId, int page, int size);

    // Follow
    Map<String, Object> toggleFollow(Long followerId, Long followingId);
    boolean isFollowing(Long followerId, Long followingId);
    int countFollowers(Long userId);
    int countFollowing(Long userId);
    Map<String, Object> listFollowers(Long userId, int page, int size);
    Map<String, Object> listFollowing(Long userId, int page, int size);

    // Favorites (liked posts)
    Map<String, Object> listLikedTopics(Long userId, int page, int size);

    // Browsing history
    void recordBrowsing(Long userId, Long topicId);
    Map<String, Object> listBrowsingHistory(Long userId, int page, int size);
}
