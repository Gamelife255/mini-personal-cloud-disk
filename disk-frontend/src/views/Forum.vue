<template>
  <div class="forum-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>

    <el-header class="forum-header">
      <div class="header-left">
        <el-button link @click="goToPortal" class="back-btn">
          <el-icon><ArrowLeft /></el-icon>
          返回门户
        </el-button>
        <span class="title">💬 论坛</span>
      </div>
      <div class="header-right">
        <span class="user-name">{{ username }}</span>
        <el-dropdown v-if="isLoggedIn" trigger="click" @command="handleCommand">
          <el-button link class="user-menu-btn">
            <el-icon :size="20"><Avatar /></el-icon>
            <el-icon><ArrowDown /></el-icon>
          </el-button>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="profile">我的主页</el-dropdown-item>
              <el-dropdown-item command="favorites">我的收藏</el-dropdown-item>
              <el-dropdown-item command="history">浏览历史</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
        <el-button link @click="toggleTheme">
          <el-icon :size="18"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
        </el-button>
      </div>
    </el-header>

    <div class="forum-main">
      <div class="forum-sidebar">
        <el-menu :default-active="String(activeCategory)" @select="onCategorySelect">
          <el-menu-item index="0">
            <el-icon><Grid /></el-icon>
            <span>全部</span>
          </el-menu-item>
          <el-menu-item v-for="cat in categories" :key="cat.id" :index="String(cat.id)">
            <el-icon><Folder /></el-icon>
            <span>{{ cat.name }}</span>
          </el-menu-item>
        </el-menu>
      </div>

      <div class="forum-content">
        <div class="forum-toolbar">
          <el-radio-group v-model="sortBy" size="small" @change="loadTopics">
            <el-radio-button value="latest">最新</el-radio-button>
            <el-radio-button value="popular">热门</el-radio-button>
          </el-radio-group>
          <el-button type="primary" @click="goToCreate" :disabled="!isLoggedIn">
            <el-icon><Edit /></el-icon>
            发布新帖
          </el-button>
        </div>

        <div v-loading="loading" class="topic-list">
          <div v-if="topics.length === 0 && !loading" class="empty-state">
            <el-empty description="暂无主题" />
          </div>
          <div v-for="topic in topics" :key="topic.id" class="topic-card" @click="goToTopic(topic.id)">
            <div class="topic-main">
              <div class="topic-title">{{ topic.title }}</div>
              <div class="topic-meta">
                <span class="topic-author" @click.stop="goToUser(topic.userId)">{{ topic.authorName }}</span>
                <span class="topic-time">{{ formatTime(topic.createdAt) }}</span>
                <el-tag v-if="topic.categoryName" size="small" type="info">{{ topic.categoryName }}</el-tag>
                <el-tag v-for="tag in (topic.tags || [])" :key="tag.id" size="small" class="tag-item">
                  {{ tag.name }}
                </el-tag>
              </div>
            </div>
            <div class="topic-stats">
              <span class="stat-item" title="回复数">
                <el-icon><ChatDotRound /></el-icon> {{ topic.replyCount || 0 }}
              </span>
              <span class="stat-item" title="浏览数">
                <el-icon><View /></el-icon> {{ topic.viewCount || 0 }}
              </span>
              <span class="stat-item" title="点赞数">
                <el-icon><Star /></el-icon> {{ topic.likeCount || 0 }}
              </span>
            </div>
            <div v-if="topic.lastReplyAt" class="topic-last-reply">
              <span class="last-reply-label">最后回复</span>
              <span>{{ topic.lastReplyByName || '未知' }}</span>
              <span>{{ formatTime(topic.lastReplyAt) }}</span>
            </div>
          </div>
        </div>

        <div v-if="total > pageSize" class="forum-pagination">
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
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useDarkMode } from '../composables/useDarkMode'
import { useBackground } from '../composables/useBackground'
import { ArrowLeft, ArrowDown, Sunny, Moon, Grid, Folder, Edit, ChatDotRound, View, Star, Avatar } from '@element-plus/icons-vue'
import { getCategories, getTopics } from '../api/forum'

const { isDark, toggle: toggleTheme } = useDarkMode()
const { containerBackground, isCustom, bgLayerStyle } = useBackground('forum')

const router = useRouter()
const categories = ref([])
const topics = ref([])
const activeCategory = ref('0')
const sortBy = ref('latest')
const currentPage = ref(1)
const pageSize = 15
const total = ref(0)
const loading = ref(false)

const user = computed(() => {
  try { return JSON.parse(localStorage.getItem('user') || '{}') } catch { return {} }
})
const username = computed(() => user.value.username || '游客')
const isLoggedIn = computed(() => !!localStorage.getItem('token'))

const loadCategories = async () => {
  try {
    const res = await getCategories()
    if (res.code === 200) categories.value = res.data || []
  } catch {}
}

const loadTopics = async () => {
  loading.value = true
  try {
    const params = {
      categoryId: activeCategory.value === '0' ? 0 : Number(activeCategory.value),
      page: currentPage.value,
      size: pageSize,
      sortBy: sortBy.value
    }
    const res = await getTopics(params)
    if (res.code === 200) {
      topics.value = res.data.items || []
      total.value = res.data.total || 0
    }
  } catch {} finally {
    loading.value = false
  }
}

const onCategorySelect = (index) => {
  activeCategory.value = index
  currentPage.value = 1
  loadTopics()
}

const goToTopic = (id) => router.push(`/forum/topic/${id}`)
const goToCreate = () => router.push('/forum/create')
const goToPortal = () => router.push('/portal')
const goToUser = (id) => id && router.push(`/forum/user/${id}`)

const handleCommand = (cmd) => {
  if (cmd === 'profile') {
    router.push(`/forum/user/${user.value.id}`)
  } else if (cmd === 'favorites') {
    router.push('/forum/favorites')
  } else if (cmd === 'history') {
    router.push('/forum/history')
  }
}

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
  loadCategories()
  loadTopics()
})
</script>

<style scoped>
.forum-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  background: #f5f7fa;
}

.forum-header {
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
.header-right { display: flex; align-items: center; gap: 8px; }
.user-name { color: #606266; font-size: 14px; }
.user-menu-btn { color: #606266; font-size: 20px; }
.back-btn { color: #606266; }

.forum-main {
  display: flex;
  flex: 1;
  overflow: hidden;
  max-width: 1200px;
  width: 100%;
  margin: 0 auto;
  padding: 16px;
  gap: 16px;
}

.forum-sidebar {
  width: 180px;
  flex-shrink: 0;
}

.forum-sidebar .el-menu {
  border-radius: 8px;
  border-right: none;
}

.forum-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.forum-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  padding: 12px 16px;
  background: #fff;
  border-radius: 8px;
}

.topic-list {
  flex: 1;
}

.topic-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  background: #fff;
  border-radius: 8px;
  margin-bottom: 8px;
  cursor: pointer;
  transition: box-shadow 0.2s;
}
.topic-card:hover { box-shadow: 0 2px 12px rgba(0,0,0,0.1); }

.topic-main { flex: 1; min-width: 0; }
.topic-title { font-size: 16px; font-weight: 500; margin-bottom: 6px; color: #303133; }
.topic-meta { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; font-size: 13px; color: #909399; }
.topic-author { cursor: pointer; color: #667eea; }
.topic-author:hover { text-decoration: underline; }

.topic-stats { display: flex; gap: 14px; flex-shrink: 0; }
.stat-item { display: flex; align-items: center; gap: 3px; font-size: 13px; color: #909399; }

.topic-last-reply {
  display: flex; flex-direction: column; align-items: flex-end;
  font-size: 12px; color: #909399; flex-shrink: 0; min-width: 100px;
}
.last-reply-label { font-size: 11px; color: #c0c4cc; }

.tag-item { margin-left: 2px; }

.forum-pagination { display: flex; justify-content: center; padding: 16px 0; }

.empty-state { padding: 80px 0; }

/* Dark mode */
:global(.dark) .forum-container { background: #1a1a2e; }
:global(.dark) .forum-header { background: #1e1e30; box-shadow: 0 1px 4px rgba(0,0,0,0.3); }
:global(.dark) .forum-header .title { color: #e0e0e0; }
:global(.dark) .forum-toolbar,
:global(.dark) .topic-card,
:global(.dark) .forum-sidebar .el-menu { background: #1e1e30; }
:global(.dark) .topic-title { color: #e0e0e0; }
</style>
