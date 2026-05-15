<template>
  <div class="user-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>

    <el-header class="user-header">
      <div class="header-left">
        <el-button link @click="goBack" class="back-btn">
          <el-icon><ArrowLeft /></el-icon>
          返回论坛
        </el-button>
        <span class="title">用户主页</span>
      </div>
      <div class="header-right">
        <el-button link @click="toggleTheme">
          <el-icon :size="18"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
        </el-button>
      </div>
    </el-header>

    <div class="user-main" v-loading="loading">
      <div class="user-card">
        <div class="avatar">{{ initial }}</div>
        <h2>{{ profileName }}</h2>
        <div class="user-stats">
          <span class="stat-link" @click="goToFollows('following')">关注 {{ followingCount }}</span>
          <span class="stat-link" @click="goToFollows('followers')">粉丝 {{ followersCount }}</span>
          <span>主题 {{ total }}</span>
        </div>
        <div class="user-actions" v-if="!isSelf && isLoggedIn">
          <el-button
            :type="isFollowing ? 'default' : 'primary'"
            size="small"
            :loading="followLoading"
            @click="onToggleFollow"
          >
            {{ isFollowing ? '已关注' : '关注' }}
          </el-button>
        </div>
      </div>

      <h3 class="section-title">发布的主题</h3>

      <div class="topic-list">
        <div v-if="topics.length === 0 && !loading" class="empty-state">
          <el-empty description="暂无主题" :image-size="80" />
        </div>
        <div v-for="topic in topics" :key="topic.id" class="topic-card" @click="goToTopic(topic.id)">
          <div class="topic-main">
            <div class="topic-title">{{ topic.title }}</div>
            <div class="topic-meta">
              <el-tag v-if="topic.categoryName" size="small" type="info">{{ topic.categoryName }}</el-tag>
              <el-tag v-for="tag in (topic.tags || [])" :key="tag.id" size="small" class="tag-item">{{ tag.name }}</el-tag>
              <span class="topic-time">{{ formatTime(topic.createdAt) }}</span>
            </div>
          </div>
          <div class="topic-stats">
            <span><el-icon><ChatDotRound /></el-icon> {{ topic.replyCount || 0 }}</span>
            <span><el-icon><View /></el-icon> {{ topic.viewCount || 0 }}</span>
            <span><el-icon><Star /></el-icon> {{ topic.likeCount || 0 }}</span>
          </div>
        </div>
      </div>

      <div v-if="total > pageSize" class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          :page-size="pageSize"
          :total="total"
          layout="prev, pager, next"
          @current-change="loadTopics"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDarkMode } from '../composables/useDarkMode'
import { useBackground } from '../composables/useBackground'
import { ArrowLeft, Sunny, Moon, ChatDotRound, View, Star } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { getUserTopics, getFollowStatus, toggleFollow } from '../api/forum'

const { isDark, toggle: toggleTheme } = useDarkMode()
const { containerBackground, isCustom, bgLayerStyle } = useBackground('forum')

const route = useRoute()
const router = useRouter()
const userId = computed(() => route.params.id)
const topics = ref([])
const currentPage = ref(1)
const pageSize = 15
const total = ref(0)
const loading = ref(false)
const profileName = ref('')

const currentUser = computed(() => {
  try { return JSON.parse(localStorage.getItem('user') || '{}') } catch { return {} }
})
const isLoggedIn = computed(() => !!localStorage.getItem('token'))
const isSelf = computed(() => currentUser.value.id == userId.value)

const isFollowing = ref(false)
const followersCount = ref(0)
const followingCount = ref(0)
const followLoading = ref(false)

const initial = computed(() => (profileName.value || 'U')[0].toUpperCase())

const loadFollowStatus = async () => {
  try {
    const res = await getFollowStatus(userId.value)
    if (res.code === 200) {
      isFollowing.value = res.data.following
      followersCount.value = res.data.followersCount || 0
      followingCount.value = res.data.followingCount || 0
    }
  } catch {}
}

const loadTopics = async () => {
  loading.value = true
  try {
    const res = await getUserTopics(userId.value, { page: currentPage.value, size: pageSize })
    if (res.code === 200) {
      topics.value = res.data.items || []
      total.value = res.data.total || 0
      if (topics.value.length > 0 && !profileName.value) {
        profileName.value = topics.value[0].authorName || ''
      }
    }
  } catch {} finally { loading.value = false }
}

const onToggleFollow = async () => {
  followLoading.value = true
  try {
    const res = await toggleFollow(userId.value)
    if (res.code === 200) {
      isFollowing.value = res.data.following
      followersCount.value += res.data.following ? 1 : -1
      ElMessage.success(res.data.following ? '已关注' : '已取消关注')
    }
  } catch {} finally { followLoading.value = false }
}

const goToTopic = (id) => router.push(`/forum/topic/${id}`)
const goToFollows = (tab) => router.push(`/forum/user/${userId.value}/follows?tab=${tab}`)
const goBack = () => router.push('/forum')

const formatTime = (ts) => {
  if (!ts) return ''
  const d = new Date(ts)
  const now = new Date()
  const diff = now - d
  if (diff < 60000) return '刚刚'
  if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前'
  if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前'
  if (diff < 604800000) return Math.floor(diff / 86400000) + '天前'
  return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0')
}

onMounted(() => {
  loadTopics()
  loadFollowStatus()
})
</script>

<style scoped>
.user-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  background: #f5f7fa;
}

.user-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 56px;
  padding: 0 20px;
  background: #fff;
  box-shadow: 0 1px 4px rgba(0,0,0,0.08);
  flex-shrink: 0;
}

.header-left { display: flex; align-items: center; gap: 12px; }
.header-left .title { font-size: 18px; font-weight: 600; }
.header-right { display: flex; align-items: center; gap: 12px; }
.back-btn { color: #606266; }

.user-main {
  flex: 1;
  max-width: 800px;
  width: 100%;
  margin: 0 auto;
  padding: 24px 16px;
}

.user-card {
  background: #fff;
  border-radius: 8px;
  padding: 32px;
  text-align: center;
  margin-bottom: 20px;
}

.avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 28px;
  font-weight: 700;
  margin-bottom: 12px;
}

.user-card h2 { margin: 0; font-size: 20px; color: #303133; }

.user-stats {
  display: flex;
  gap: 24px;
  justify-content: center;
  margin-top: 12px;
  font-size: 14px;
  color: #606266;
}
.stat-link { cursor: pointer; color: #667eea; font-weight: 500; }
.stat-link:hover { text-decoration: underline; }

.user-actions { margin-top: 16px; }

.section-title { font-size: 16px; color: #303133; margin: 0 0 12px; }

.topic-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 14px 16px;
  background: #fff;
  border-radius: 8px;
  margin-bottom: 8px;
  cursor: pointer;
  transition: box-shadow 0.2s;
}
.topic-card:hover { box-shadow: 0 2px 12px rgba(0,0,0,0.1); }

.topic-main { flex: 1; min-width: 0; }
.topic-title { font-size: 15px; font-weight: 500; margin-bottom: 6px; color: #303133; }
.topic-meta { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; font-size: 13px; color: #909399; }
.topic-time { margin-left: auto; }

.topic-stats { display: flex; gap: 12px; font-size: 13px; color: #909399; }
.topic-stats span { display: flex; align-items: center; gap: 2px; }

.tag-item { margin-left: 2px; }

.pagination { display: flex; justify-content: center; padding: 16px 0; }
.empty-state { padding: 60px 0; }

/* Dark mode */
:global(.dark) .user-container { background: #1a1a2e; }
:global(.dark) .user-header { background: #1e1e30; box-shadow: 0 1px 4px rgba(0,0,0,0.3); }
:global(.dark) .user-header .title { color: #e0e0e0; }
:global(.dark) .user-card,
:global(.dark) .topic-card { background: #1e1e30; }
:global(.dark) .user-card h2 { color: #e0e0e0; }
:global(.dark) .section-title { color: #e0e0e0; }
:global(.dark) .topic-title { color: #e0e0e0; }
</style>
