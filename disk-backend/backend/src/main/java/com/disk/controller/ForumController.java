package com.disk.controller;

import com.disk.entity.*;
import com.disk.service.ForumService;
import com.disk.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/forum")
public class ForumController {

    @Autowired
    private ForumService forumService;

    private Long getUserId(HttpServletRequest request) {
        String token = request.getHeader("Authorization");
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
            if (JwtUtil.validateToken(token)) {
                return JwtUtil.getUserIdFromToken(token);
            }
        }
        return null;
    }

    private String getRole(HttpServletRequest request) {
        String token = request.getHeader("Authorization");
        if (token != null && token.startsWith("Bearer ")) {
            token = token.substring(7);
            if (JwtUtil.validateToken(token)) {
                return JwtUtil.getRoleFromToken(token);
            }
        }
        return null;
    }

    // ---- Categories ----

    @GetMapping("/categories")
    public Map<String, Object> listCategories() {
        Map<String, Object> result = new HashMap<>();
        try {
            List<Category> categories = forumService.listCategories();
            result.put("code", 200);
            result.put("data", categories);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "获取分类失败: " + e.getMessage());
        }
        return result;
    }

    // ---- Topics ----

    @GetMapping("/topics")
    public Map<String, Object> listTopics(@RequestParam(defaultValue = "0") Long categoryId,
                                          @RequestParam(defaultValue = "1") int page,
                                          @RequestParam(defaultValue = "15") int size,
                                          @RequestParam(defaultValue = "latest") String sortBy) {
        Map<String, Object> result = new HashMap<>();
        try {
            Map<String, Object> data = forumService.listTopics(categoryId, page, size, sortBy);
            result.put("code", 200);
            result.put("data", data);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "获取主题列表失败: " + e.getMessage());
        }
        return result;
    }

    @GetMapping("/topics/{id}")
    public Map<String, Object> getTopic(@PathVariable Long id, HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        try {
            Map<String, Object> topic = forumService.getTopic(id);
            if (topic == null) {
                result.put("code", 404);
                result.put("message", "主题不存在");
                return result;
            }
            Long userId = getUserId(request);
            boolean liked = userId != null && forumService.hasLiked(id, userId);
            topic.put("isLiked", liked);

            result.put("code", 200);
            result.put("data", topic);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "获取主题详情失败: " + e.getMessage());
        }
        return result;
    }

    @PostMapping("/topics")
    public Map<String, Object> createTopic(@RequestBody Map<String, Object> params,
                                            HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        try {
            Long userId = getUserId(request);
            if (userId == null) {
                result.put("code", 401);
                result.put("message", "请先登录");
                return result;
            }

            String title = (String) params.get("title");
            String content = (String) params.get("content");
            Object categoryIdObj = params.get("categoryId");

            if (title == null || title.trim().isEmpty()) {
                result.put("code", 400);
                result.put("message", "标题不能为空");
                return result;
            }
            if (content == null || content.trim().isEmpty()) {
                result.put("code", 400);
                result.put("message", "内容不能为空");
                return result;
            }
            if (categoryIdObj == null) {
                result.put("code", 400);
                result.put("message", "请选择分类");
                return result;
            }

            Topic topic = new Topic();
            topic.setTitle(title.trim());
            topic.setContent(content.trim());
            topic.setCategoryId(((Number) categoryIdObj).longValue());
            topic.setUserId(userId);

            @SuppressWarnings("unchecked")
            List<String> tagNames = (List<String>) params.get("tags");
            Topic created = forumService.createTopic(topic, tagNames != null ? tagNames : List.of());

            result.put("code", 200);
            result.put("message", "发布成功");
            result.put("data", created);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "发布失败: " + e.getMessage());
        }
        return result;
    }

    @PutMapping("/topics/{id}")
    public Map<String, Object> updateTopic(@PathVariable Long id,
                                            @RequestBody Map<String, Object> params,
                                            HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        try {
            Long userId = getUserId(request);
            if (userId == null) {
                result.put("code", 401);
                result.put("message", "请先登录");
                return result;
            }

            Map<String, Object> existing = forumService.getTopicRaw(id);
            if (existing == null) {
                result.put("code", 404);
                result.put("message", "主题不存在");
                return result;
            }

            boolean isAdmin = "admin".equals(getRole(request));
            Long authorId = ((Number) existing.get("userId")).longValue();
            if (!isAdmin && !authorId.equals(userId)) {
                result.put("code", 403);
                result.put("message", "无权限修改此主题");
                return result;
            }

            Topic topic = new Topic();
            topic.setId(id);
            topic.setTitle((String) params.getOrDefault("title", existing.get("title")));
            topic.setContent((String) params.getOrDefault("content", existing.get("content")));
            Object catIdObj = params.get("categoryId");
            topic.setCategoryId(catIdObj != null ? ((Number) catIdObj).longValue()
                    : ((Number) existing.get("categoryId")).longValue());

            @SuppressWarnings("unchecked")
            List<String> tagNames = (List<String>) params.get("tags");
            Topic updated = forumService.updateTopic(topic, tagNames);

            result.put("code", 200);
            result.put("message", "更新成功");
            result.put("data", updated);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "更新失败: " + e.getMessage());
        }
        return result;
    }

    @DeleteMapping("/topics/{id}")
    public Map<String, Object> deleteTopic(@PathVariable Long id, HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        try {
            Long userId = getUserId(request);
            if (userId == null) {
                result.put("code", 401);
                result.put("message", "请先登录");
                return result;
            }

            boolean isAdmin = "admin".equals(getRole(request));
            int deleted = forumService.deleteTopic(id, userId, isAdmin);
            if (deleted == 0) {
                result.put("code", 403);
                result.put("message", "无权限删除此主题");
                return result;
            }

            result.put("code", 200);
            result.put("message", "删除成功");
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "删除失败: " + e.getMessage());
        }
        return result;
    }

    // ---- Replies ----

    @GetMapping("/topics/{topicId}/replies")
    public Map<String, Object> listReplies(@PathVariable Long topicId,
                                           @RequestParam(defaultValue = "1") int page,
                                           @RequestParam(defaultValue = "10") int size) {
        Map<String, Object> result = new HashMap<>();
        try {
            Map<String, Object> data = forumService.listReplies(topicId, page, size);
            result.put("code", 200);
            result.put("data", data);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "获取回复失败: " + e.getMessage());
        }
        return result;
    }

    @PostMapping("/topics/{topicId}/replies")
    public Map<String, Object> createReply(@PathVariable Long topicId,
                                            @RequestBody Map<String, String> params,
                                            HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        try {
            Long userId = getUserId(request);
            if (userId == null) {
                result.put("code", 401);
                result.put("message", "请先登录");
                return result;
            }

            String content = params.get("content");
            if (content == null || content.trim().isEmpty()) {
                result.put("code", 400);
                result.put("message", "回复内容不能为空");
                return result;
            }

            Reply reply = new Reply();
            reply.setTopicId(topicId);
            reply.setUserId(userId);
            reply.setContent(content.trim());
            Reply created = forumService.createReply(reply);

            result.put("code", 200);
            result.put("message", "回复成功");
            result.put("data", created);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "回复失败: " + e.getMessage());
        }
        return result;
    }

    @DeleteMapping("/replies/{id}")
    public Map<String, Object> deleteReply(@PathVariable Long id, HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        try {
            Long userId = getUserId(request);
            if (userId == null) {
                result.put("code", 401);
                result.put("message", "请先登录");
                return result;
            }

            boolean isAdmin = "admin".equals(getRole(request));
            int deleted = forumService.deleteReply(id, userId, isAdmin);
            if (deleted == 0) {
                result.put("code", 403);
                result.put("message", "无权限删除此回复");
            } else {
                result.put("code", 200);
                result.put("message", "删除成功");
            }
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "删除失败: " + e.getMessage());
        }
        return result;
    }

    // ---- Likes ----

    @PostMapping("/topics/{id}/like")
    public Map<String, Object> toggleLike(@PathVariable Long id, HttpServletRequest request) {
        Map<String, Object> result = new HashMap<>();
        try {
            Long userId = getUserId(request);
            if (userId == null) {
                result.put("code", 401);
                result.put("message", "请先登录");
                return result;
            }
            Map<String, Object> likeResult = forumService.toggleLike(id, userId);
            result.put("code", 200);
            result.put("data", likeResult);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "操作失败: " + e.getMessage());
        }
        return result;
    }

    // ---- Tags ----

    @GetMapping("/tags")
    public Map<String, Object> listTags() {
        Map<String, Object> result = new HashMap<>();
        try {
            List<Tag> tags = forumService.listTags();
            result.put("code", 200);
            result.put("data", tags);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "获取标签失败: " + e.getMessage());
        }
        return result;
    }

    @GetMapping("/topics/{topicId}/tags")
    public Map<String, Object> getTopicTags(@PathVariable Long topicId) {
        Map<String, Object> result = new HashMap<>();
        try {
            List<Tag> tags = forumService.getTagsForTopic(topicId);
            result.put("code", 200);
            result.put("data", tags);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "获取标签失败: " + e.getMessage());
        }
        return result;
    }

    // ---- User Profile ----

    @GetMapping("/users/{userId}/topics")
    public Map<String, Object> listUserTopics(@PathVariable Long userId,
                                               @RequestParam(defaultValue = "1") int page,
                                               @RequestParam(defaultValue = "15") int size) {
        Map<String, Object> result = new HashMap<>();
        try {
            Map<String, Object> data = forumService.listUserTopics(userId, page, size);
            result.put("code", 200);
            result.put("data", data);
        } catch (Exception e) {
            result.put("code", 500);
            result.put("message", "获取用户主题失败: " + e.getMessage());
        }
        return result;
    }
}
