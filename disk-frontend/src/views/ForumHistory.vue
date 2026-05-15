<template>
  <div class="history-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>

    <el-header class="history-header">
      <div class="header-left">
        <el-button link @click="goBack" class="back-btn">
          <el-icon><ArrowLeft /></el-icon>
          返回论坛
        </el-button>
        <span class="title">浏览历史</span>
      </div>
      <div class="header-right">
        <span class="user-name">{{ username }}</span>
        <el-button link @click="toggleTheme">
          <el-icon :size="18"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
        </el-button>
      </div>
    </el-header>

    <div class="history-main" v-loading="loading">
      <div v-if="items.length === 0 && !loading" class="empty-state">
        <el-empty description="暂无浏览记录" />
        <el-button type="primary" @click="goToForum">去论坛看看</el-button>
      </div>

      <div v-for="item in items" :key="item.id" class="history-card" @click="goToTopic(item.topicId)">
        <div class="topic-main">
          <div class="topic-title">{{ item.title }}</div>
          <div class="topic-meta">
            <span class="topic-author">{{ item.authorName }}</span>
            <span class="topic-time">浏览于 {{ formatTime(item.viewedAt) }}</span>
            <el-tag v-if="item.categoryName" size="small" type="info">{{ item.categoryName }}</el-tag>
          </div>
        </div>
        <div class="topic-stats">
          <span class="stat-item"><el-icon><ChatDotRound /></el-icon> {{ item.replyCount || 0 }}</span>
          <span class="stat-item"><el-icon><View /></el-icon> {{ item.viewCount || 0 }}</span>
          <span class="stat-item"><el-icon><Star /></el-icon> {{ item.likeCount || 0 }}</span>
        </div>
      </div>

      <div v-if="total > pageSize" class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          :page-size="pageSize"
          :total="total"
          layout="prev, pager, next"
          @current-change="loadHistory"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useDarkMode } from '../composables/useDarkMode'
import { useBackground } from '../composables/useBackground'
import { ArrowLeft, Sunny, Moon, ChatDotRound, View, Star } from '@element-plus/icons-vue'
import { getHistory } from '../api/forum'

const { isDark, toggle: toggleTheme } = useDarkMode()
const { containerBackground, isCustom, bgLayerStyle } = useBackground('forum')

const router = useRouter()
const items = ref([])
const currentPage = ref(1)
const pageSize = 15
const total = ref(0)
const loading = ref(false)

const user = computed(() => {
  try { return JSON.parse(localStorage.getItem('user') || '{}') } catch { return {} }
})
const username = computed(() => user.value.username || '游客')

const loadHistory = async () => {
  loading.value = true
  try {
    const res = await getHistory({ page: currentPage.value, size: pageSize })
    if (res.code === 200) {
      items.value = res.data.items || []
      total.value = res.data.total || 0
    }
  } catch {} finally { loading.value = false }
}

const goToTopic = (id) => router.push(`/forum/topic/${id}`)
const goToForum = () => router.push('/forum')
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

onMounted(loadHistory)
</script>

<style scoped>
.history-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  background: #f5f7fa;
}

.history-header {
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
.user-name { color: #606266; font-size: 14px; }
.back-btn { color: #606266; }

.history-main {
  flex: 1;
  max-width: 900px;
  width: 100%;
  margin: 0 auto;
  padding: 16px;
}

.history-card {
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
.history-card:hover { box-shadow: 0 2px 12px rgba(0,0,0,0.1); }

.topic-main { flex: 1; min-width: 0; }
.topic-title { font-size: 16px; font-weight: 500; margin-bottom: 6px; color: #303133; }
.topic-meta { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; font-size: 13px; color: #909399; }

.topic-stats { display: flex; gap: 14px; flex-shrink: 0; }
.stat-item { display: flex; align-items: center; gap: 3px; font-size: 13px; color: #909399; }

.pagination { display: flex; justify-content: center; padding: 16px 0; }
.empty-state { padding: 80px 0; display: flex; flex-direction: column; align-items: center; gap: 16px; }

:global(.dark) .history-container { background: #1a1a2e; }
:global(.dark) .history-header { background: #1e1e30; box-shadow: 0 1px 4px rgba(0,0,0,0.3); }
:global(.dark) .history-header .title { color: #e0e0e0; }
:global(.dark) .history-card { background: #1e1e30; }
:global(.dark) .topic-title { color: #e0e0e0; }
</style>
