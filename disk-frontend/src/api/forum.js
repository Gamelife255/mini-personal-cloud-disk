import request from '../utils/request'

// Categories
export function getCategories() {
  return request({ url: '/api/forum/categories', method: 'get' })
}

// Topics
export function getTopics(params) {
  return request({ url: '/api/forum/topics', method: 'get', params })
}

export function getTopic(id) {
  return request({ url: `/api/forum/topics/${id}`, method: 'get' })
}

export function createTopic(data) {
  return request({ url: '/api/forum/topics', method: 'post', data })
}

export function updateTopic(id, data) {
  return request({ url: `/api/forum/topics/${id}`, method: 'put', data })
}

export function deleteTopic(id) {
  return request({ url: `/api/forum/topics/${id}`, method: 'delete' })
}

// Replies
export function getReplies(topicId, params) {
  return request({ url: `/api/forum/topics/${topicId}/replies`, method: 'get', params })
}

export function createReply(topicId, data) {
  return request({ url: `/api/forum/topics/${topicId}/replies`, method: 'post', data })
}

export function deleteReply(id) {
  return request({ url: `/api/forum/replies/${id}`, method: 'delete' })
}

// Likes
export function toggleLike(topicId) {
  return request({ url: `/api/forum/topics/${topicId}/like`, method: 'post' })
}

// Tags
export function getTags() {
  return request({ url: '/api/forum/tags', method: 'get' })
}

// User
export function getUserTopics(userId, params) {
  return request({ url: `/api/forum/users/${userId}/topics`, method: 'get', params })
}

// Follow
export function toggleFollow(userId) {
  return request({ url: `/api/forum/users/${userId}/follow`, method: 'post' })
}

export function getFollowStatus(userId) {
  return request({ url: `/api/forum/users/${userId}/follow-status`, method: 'get' })
}

export function getFollowers(userId, params) {
  return request({ url: `/api/forum/users/${userId}/followers`, method: 'get', params })
}

export function getFollowing(userId, params) {
  return request({ url: `/api/forum/users/${userId}/following`, method: 'get', params })
}

// Favorites (liked posts)
export function getFavorites(params) {
  return request({ url: '/api/forum/favorites', method: 'get', params })
}

// Browsing history
export function getHistory(params) {
  return request({ url: '/api/forum/history', method: 'get', params })
}
