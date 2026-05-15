package com.disk.service.impl;

import com.disk.entity.*;
import com.disk.mapper.*;
import com.disk.service.ForumService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class ForumServiceImpl implements ForumService {

    @Autowired
    private CategoryMapper categoryMapper;

    @Autowired
    private TopicMapper topicMapper;

    @Autowired
    private ReplyMapper replyMapper;

    @Autowired
    private TagMapper tagMapper;

    @Autowired
    private TopicTagMapper topicTagMapper;

    @Autowired
    private LikeMapper likeMapper;

    @Autowired
    private FollowMapper followMapper;

    @Autowired
    private BrowsingHistoryMapper browsingHistoryMapper;

    @Override
    public List<Category> listCategories() {
        return categoryMapper.findAll();
    }

    @Override
    public Map<String, Object> listTopics(Long categoryId, int page, int size, String sortBy) {
        int offset = (page - 1) * size;
        List<Map<String, Object>> topics = topicMapper.findByCategoryId(categoryId, offset, size, sortBy);
        int total = topicMapper.countByCategoryId(categoryId);

        // Attach tags for each topic
        for (Map<String, Object> topic : topics) {
            Long topicId = ((Number) topic.get("id")).longValue();
            List<Tag> tags = tagMapper.findByTopicId(topicId);
            topic.put("tags", tags);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("items", topics);
        result.put("total", total);
        result.put("page", page);
        result.put("size", size);
        return result;
    }

    @Override
    public Map<String, Object> getTopic(Long id) {
        topicMapper.incrementViewCount(id);
        Map<String, Object> topic = topicMapper.findByIdWithAuthor(id);
        if (topic != null) {
            Long topicId = ((Number) topic.get("id")).longValue();
            List<Tag> tags = tagMapper.findByTopicId(topicId);
            topic.put("tags", tags);
        }
        return topic;
    }

    @Override
    public Map<String, Object> getTopicRaw(Long id) {
        Map<String, Object> topic = topicMapper.findByIdWithAuthor(id);
        if (topic != null) {
            Long topicId = ((Number) topic.get("id")).longValue();
            List<Tag> tags = tagMapper.findByTopicId(topicId);
            topic.put("tags", tags);
        }
        return topic;
    }

    @Override
    public Topic createTopic(Topic topic, List<String> tagNames) {
        long now = System.currentTimeMillis();
        topic.setCreatedAt(now);
        topic.setUpdatedAt(now);
        topic.setViewCount(0);
        topic.setReplyCount(0);
        topic.setLikeCount(0);
        topic.setStatus(1);
        topicMapper.insert(topic);

        // Update category topic count
        categoryMapper.updateTopicCount(topic.getCategoryId(), 1);

        // Handle tags
        if (tagNames != null && !tagNames.isEmpty()) {
            for (String name : tagNames) {
                if (name == null || name.trim().isEmpty()) continue;
                name = name.trim();
                Tag tag = tagMapper.findByName(name);
                if (tag == null) {
                    tag = new Tag();
                    tag.setName(name);
                    tag.setCreatedAt(now);
                    tagMapper.insert(tag);
                }
                TopicTag tt = new TopicTag();
                tt.setTopicId(topic.getId());
                tt.setTagId(tag.getId());
                topicTagMapper.insert(tt);
            }
        }

        return topic;
    }

    @Override
    public Topic updateTopic(Topic topic, List<String> tagNames) {
        topic.setUpdatedAt(System.currentTimeMillis());
        topicMapper.update(topic);

        // Replace tags
        topicTagMapper.deleteByTopicId(topic.getId());
        if (tagNames != null && !tagNames.isEmpty()) {
            long now = System.currentTimeMillis();
            for (String name : tagNames) {
                if (name == null || name.trim().isEmpty()) continue;
                name = name.trim();
                Tag tag = tagMapper.findByName(name);
                if (tag == null) {
                    tag = new Tag();
                    tag.setName(name);
                    tag.setCreatedAt(now);
                    tagMapper.insert(tag);
                }
                TopicTag tt = new TopicTag();
                tt.setTopicId(topic.getId());
                tt.setTagId(tag.getId());
                topicTagMapper.insert(tt);
            }
        }

        return topic;
    }

    @Override
    public int deleteTopic(Long id, Long userId, boolean isAdmin) {
        Map<String, Object> topic = topicMapper.findByIdWithAuthor(id);
        if (topic == null) return 0;

        Long authorId = ((Number) topic.get("userId")).longValue();
        if (!isAdmin && !authorId.equals(userId)) return 0;

        topicMapper.softDelete(id);
        // Decrement category topic count
        Long categoryId = ((Number) topic.get("categoryId")).longValue();
        categoryMapper.updateTopicCount(categoryId, -1);
        return 1;
    }

    @Override
    public Map<String, Object> listReplies(Long topicId, int page, int size) {
        int offset = (page - 1) * size;
        List<Map<String, Object>> replies = replyMapper.findByTopicId(topicId, offset, size);
        int total = replyMapper.countByTopicId(topicId);

        Map<String, Object> result = new HashMap<>();
        result.put("items", replies);
        result.put("total", total);
        result.put("page", page);
        result.put("size", size);
        return result;
    }

    @Override
    public Reply createReply(Reply reply) {
        long now = System.currentTimeMillis();
        reply.setCreatedAt(now);
        reply.setUpdatedAt(now);
        reply.setStatus(1);
        replyMapper.insert(reply);

        // Update topic reply info
        topicMapper.updateReplyInfo(reply.getTopicId(), now, reply.getUserId());

        return reply;
    }

    @Override
    public int deleteReply(Long id, Long userId, boolean isAdmin) {
        Map<String, Object> reply = replyMapper.findById(id);
        if (reply == null) return 0;
        Long replyUserId = ((Number) reply.get("userId")).longValue();
        if (!isAdmin && !replyUserId.equals(userId)) return 0;
        replyMapper.softDelete(id);
        return 1;
    }

    @Override
    public List<Tag> listTags() {
        return tagMapper.findAll();
    }

    @Override
    public List<Tag> getTagsForTopic(Long topicId) {
        return tagMapper.findByTopicId(topicId);
    }

    @Override
    public Map<String, Object> toggleLike(Long topicId, Long userId) {
        Map<String, Object> result = new HashMap<>();
        if (likeMapper.exists(topicId, userId) > 0) {
            likeMapper.delete(topicId, userId);
            topicMapper.decrementLikeCount(topicId);
            result.put("liked", false);
        } else {
            Like like = new Like();
            like.setTopicId(topicId);
            like.setUserId(userId);
            like.setCreatedAt(System.currentTimeMillis());
            likeMapper.insert(like);
            topicMapper.incrementLikeCount(topicId);
            result.put("liked", true);
        }
        // Return actual count from DB to avoid frontend count drift
        result.put("likeCount", likeMapper.countByTopicId(topicId));
        return result;
    }

    @Override
    public boolean hasLiked(Long topicId, Long userId) {
        return likeMapper.exists(topicId, userId) > 0;
    }

    @Override
    public Map<String, Object> listUserTopics(Long userId, int page, int size) {
        int offset = (page - 1) * size;
        List<Map<String, Object>> topics = topicMapper.findByUserId(userId, offset, size);
        int total = topicMapper.countByUserId(userId);

        for (Map<String, Object> topic : topics) {
            Long topicId = ((Number) topic.get("id")).longValue();
            List<Tag> tags = tagMapper.findByTopicId(topicId);
            topic.put("tags", tags);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("items", topics);
        result.put("total", total);
        result.put("page", page);
        result.put("size", size);
        return result;
    }

    // ---- Follow ----

    @Override
    public Map<String, Object> toggleFollow(Long followerId, Long followingId) {
        Map<String, Object> result = new HashMap<>();
        if (followMapper.exists(followerId, followingId) > 0) {
            followMapper.delete(followerId, followingId);
            result.put("following", false);
        } else {
            Follow follow = new Follow();
            follow.setFollowerId(followerId);
            follow.setFollowingId(followingId);
            follow.setCreatedAt(System.currentTimeMillis());
            followMapper.insert(follow);
            result.put("following", true);
        }
        return result;
    }

    @Override
    public boolean isFollowing(Long followerId, Long followingId) {
        return followMapper.exists(followerId, followingId) > 0;
    }

    @Override
    public int countFollowers(Long userId) {
        return followMapper.countFollowers(userId);
    }

    @Override
    public int countFollowing(Long userId) {
        return followMapper.countFollowing(userId);
    }

    @Override
    public Map<String, Object> listFollowers(Long userId, int page, int size) {
        int offset = (page - 1) * size;
        List<Map<String, Object>> users = followMapper.findFollowers(userId, offset, size);
        int total = followMapper.countFollowers(userId);

        Map<String, Object> result = new HashMap<>();
        result.put("items", users);
        result.put("total", total);
        result.put("page", page);
        result.put("size", size);
        return result;
    }

    @Override
    public Map<String, Object> listFollowing(Long userId, int page, int size) {
        int offset = (page - 1) * size;
        List<Map<String, Object>> users = followMapper.findFollowing(userId, offset, size);
        int total = followMapper.countFollowing(userId);

        Map<String, Object> result = new HashMap<>();
        result.put("items", users);
        result.put("total", total);
        result.put("page", page);
        result.put("size", size);
        return result;
    }

    // ---- Favorites (liked topics) ----

    @Override
    public Map<String, Object> listLikedTopics(Long userId, int page, int size) {
        int offset = (page - 1) * size;
        List<Map<String, Object>> topics = likeMapper.findByUserId(userId, offset, size);
        int total = likeMapper.countByUserId(userId);

        Map<String, Object> result = new HashMap<>();
        result.put("items", topics);
        result.put("total", total);
        result.put("page", page);
        result.put("size", size);
        return result;
    }

    // ---- Browsing history ----

    @Override
    public void recordBrowsing(Long userId, Long topicId) {
        // Delete old entry if exists, then insert new one (update timestamp)
        browsingHistoryMapper.deleteByUserIdAndTopicId(userId, topicId);
        BrowsingHistory history = new BrowsingHistory();
        history.setUserId(userId);
        history.setTopicId(topicId);
        history.setCreatedAt(System.currentTimeMillis());
        browsingHistoryMapper.insert(history);
    }

    @Override
    public Map<String, Object> listBrowsingHistory(Long userId, int page, int size) {
        int offset = (page - 1) * size;
        List<Map<String, Object>> items = browsingHistoryMapper.findByUserId(userId, offset, size);
        int total = browsingHistoryMapper.countByUserId(userId);

        Map<String, Object> result = new HashMap<>();
        result.put("items", items);
        result.put("total", total);
        result.put("page", page);
        result.put("size", size);
        return result;
    }
}
