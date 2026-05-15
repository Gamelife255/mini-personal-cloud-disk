<template>
  <div class="topic-detail-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>

    <el-header class="topic-header">
      <div class="header-left">
        <el-button link @click="goBack" class="back-btn">
          <el-icon><ArrowLeft /></el-icon>
          返回论坛
        </el-button>
        <span class="title">{{ topic.title || '主题详情' }}</span>
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

    <div class="topic-main" v-loading="loading">
      <div v-if="topic.id" class="topic-body-card">
        <div class="topic-header-info">
          <h2>{{ topic.title }}</h2>
          <div class="topic-info-row">
            <span class="info-item"><a class="author-link" @click="goToUser(topic.userId)">作者: {{ topic.authorName }}</a></span>
            <span class="info-item">发布于 {{ formatTime(topic.createdAt) }}</span>
            <el-tag v-if="topic.categoryName" size="small" type="info">{{ topic.categoryName }}</el-tag>
            <el-tag v-for="tag in (topic.tags || [])" :key="tag.id" size="small">{{ tag.name }}</el-tag>
          </div>
        </div>
        <div class="topic-content" v-html="renderedContent"></div>
        <div class="topic-actions">
          <el-button
            :type="isLiked ? 'danger' : 'default'"
            size="small"
            @click="onToggleLike"
            :disabled="!isLoggedIn"
          >
            <el-icon><StarFilled v-if="isLiked" /><Star v-else /></el-icon>
            {{ topic.likeCount || 0 }}
          </el-button>
          <span class="stat-text">
            <el-icon><View /></el-icon> {{ topic.viewCount || 0 }} 浏览
          </span>
          <span class="stat-text">
            <el-icon><ChatDotRound /></el-icon> {{ topic.replyCount || 0 }} 回复
          </span>
          <el-button
            v-if="canModify"
            size="small"
            @click="goToEdit"
          >编辑</el-button>
          <el-button
            v-if="canModify"
            size="small"
            type="danger"
            @click="onDeleteTopic"
          >删除</el-button>
        </div>
      </div>

      <div class="replies-section">
        <h3>回复 ({{ replyTotal }})</h3>
        <div v-if="replies.length === 0 && !loadingReplies" class="empty-state">
          <el-empty description="暂无回复" :image-size="80" />
        </div>
        <div v-for="reply in replies" :key="reply.id" class="reply-card">
          <div class="reply-header">
            <span class="reply-author" @click="goToUser(reply.userId)">{{ reply.authorName }}</span>
            <span class="reply-time">{{ formatTime(reply.createdAt) }}</span>
            <span class="reply-floor">#{{ replyIndex(reply) }}</span>
          </div>
          <div class="reply-content">{{ reply.content }}</div>
          <div v-if="canDeleteReply(reply)" class="reply-actions">
            <el-button size="small" type="danger" link @click="onDeleteReply(reply.id)">删除</el-button>
          </div>
        </div>
        <div v-if="replyTotal > replyPageSize" class="reply-pagination">
          <el-pagination
            v-model:current-page="replyPage"
            :page-size="replyPageSize"
            :total="replyTotal"
            layout="prev, pager, next"
            @current-change="loadReplies"
            small
          />
        </div>
      </div>

      <div class="reply-form">
        <h3>{{ isLoggedIn ? '发表回复' : '请登录后回复' }}</h3>
        <el-input
          v-model="replyContent"
          type="textarea"
          :rows="4"
          placeholder="写下你的回复..."
          :disabled="!isLoggedIn"
        />
        <el-button
          type="primary"
          :disabled="!isLoggedIn || !replyContent.trim()"
          :loading="submitting"
          @click="onSubmitReply"
          style="margin-top: 10px"
        >
          提交回复
        </el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDarkMode } from '../composables/useDarkMode'
import { useBackground } from '../composables/useBackground'
import { ArrowLeft, ArrowDown, Sunny, Moon, Star, StarFilled, View, ChatDotRound, Avatar } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getTopic, getReplies, createReply, deleteReply, deleteTopic, toggleLike } from '../api/forum'

const { isDark, toggle: toggleTheme } = useDarkMode()
const { containerBackground, isCustom, bgLayerStyle } = useBackground('forum')

const route = useRoute()
const router = useRouter()
const topic = ref({})
const replies = ref([])
const replyContent = ref('')
const replyPage = ref(1)
const replyPageSize = 10
const replyTotal = ref(0)
const loading = ref(false)
const loadingReplies = ref(false)
const submitting = ref(false)
const isLiked = ref(false)

const user = computed(() => {
  try { return JSON.parse(localStorage.getItem('user') || '{}') } catch { return {} }
})
const username = computed(() => user.value.username || '游客')
const isLoggedIn = computed(() => !!localStorage.getItem('token'))
const canModify = computed(() => {
  return isLoggedIn.value && (user.value.role === 'admin' || user.value.id === topic.value.userId)
})

const renderedContent = computed(() => {
  if (!topic.value.content) return ''
  return topic.value.content.replace(/\n/g, '<br>')
})

const loadTopic = async () => {
  loading.value = true
  try {
    const res = await getTopic(route.params.id)
    if (res.code === 200) {
      topic.value = res.data || {}
      isLiked.value = res.data.isLiked || false
    }
  } catch {} finally { loading.value = false }
}

const loadReplies = async () => {
  loadingReplies.value = true
  try {
    const res = await getReplies(route.params.id, { page: replyPage.value, size: replyPageSize })
    if (res.code === 200) {
      replies.value = res.data.items || []
      replyTotal.value = res.data.total || 0
    }
  } catch {} finally { loadingReplies.value = false }
}

const replyIndex = (reply) => {
  const idx = replies.value.findIndex(r => r.id === reply.id)
  return idx >= 0 ? (replyPage.value - 1) * replyPageSize + idx + 1 : ''
}

const canDeleteReply = (reply) => {
  return isLoggedIn.value && (user.value.role === 'admin' || user.value.id === reply.userId)
}

const onToggleLike = async () => {
  if (!isLoggedIn.value) return
  try {
    const res = await toggleLike(topic.value.id)
    if (res.code === 200) {
      isLiked.value = res.data.liked
      topic.value.likeCount = res.data.likeCount
    }
  } catch {}
}

const onSubmitReply = async () => {
  if (!replyContent.value.trim()) return
  submitting.value = true
  try {
    const res = await createReply(topic.value.id, { content: replyContent.value.trim() })
    if (res.code === 200) {
      ElMessage.success('回复成功')
      replyContent.value = ''
      replyPage.value = 1
      await loadReplies()
      await loadTopic() // refresh reply count
    } else {
      ElMessage.error(res.message || '回复失败')
    }
  } catch { ElMessage.error('回复失败') } finally { submitting.value = false }
}

const onDeleteReply = async (replyId) => {
  try {
    await ElMessageBox.confirm('确定删除这条回复吗？', '确认', { type: 'warning' })
    const res = await deleteReply(replyId)
    if (res.code === 200) {
      ElMessage.success('删除成功')
      loadReplies()
      loadTopic()
    } else {
      ElMessage.error(res.message || '删除失败')
    }
  } catch {}
}

const onDeleteTopic = async () => {
  try {
    await ElMessageBox.confirm('确定删除这个主题吗？所有回复也将不可见。', '确认删除', { type: 'warning' })
    const res = await deleteTopic(topic.value.id)
    if (res.code === 200) {
      ElMessage.success('删除成功')
      router.push('/forum')
    } else {
      ElMessage.error(res.message || '删除失败')
    }
  } catch {}
}

const goToEdit = () => router.push(`/forum/edit/${topic.value.id}`)
const goToUser = (id) => id && router.push(`/forum/user/${id}`)
const goBack = () => router.push('/forum')

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
  loadTopic()
  loadReplies()
})
</script>

<style scoped>
.topic-detail-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  background: #f5f7fa;
}

.topic-header {
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
.header-left .title { font-size: 18px; font-weight: 600; max-width: 500px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.header-right { display: flex; align-items: center; gap: 8px; }
.user-name { color: #606266; font-size: 14px; }
.user-menu-btn { color: #606266; font-size: 20px; }
.back-btn { color: #606266; }

.topic-main {
  flex: 1;
  max-width: 900px;
  width: 100%;
  margin: 0 auto;
  padding: 16px;
}

.topic-body-card {
  background: #fff;
  border-radius: 8px;
  padding: 24px;
  margin-bottom: 16px;
}

.topic-header-info h2 {
  font-size: 22px;
  margin: 0 0 10px;
  color: #303133;
}

.topic-info-row {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  font-size: 13px;
  color: #909399;
  margin-bottom: 16px;
}

.author-link { color: #667eea; cursor: pointer; text-decoration: none; }
.author-link:hover { text-decoration: underline; }

.topic-content {
  font-size: 15px;
  line-height: 1.8;
  color: #303133;
  padding: 16px 0;
  border-top: 1px solid #ebeef5;
}

.topic-actions {
  display: flex;
  align-items: center;
  gap: 14px;
  padding-top: 16px;
  border-top: 1px solid #ebeef5;
}

.stat-text {
  font-size: 13px;
  color: #909399;
  display: flex;
  align-items: center;
  gap: 4px;
}

.replies-section {
  background: #fff;
  border-radius: 8px;
  padding: 20px 24px;
  margin-bottom: 16px;
}

.replies-section h3 {
  margin: 0 0 16px;
  font-size: 16px;
  color: #303133;
}

.reply-card {
  padding: 14px 0;
  border-bottom: 1px solid #f2f3f5;
}

.reply-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.reply-author { font-weight: 500; color: #667eea; font-size: 14px; cursor: pointer; }
.reply-author:hover { text-decoration: underline; }
.reply-time { font-size: 12px; color: #909399; }
.reply-floor { font-size: 12px; color: #c0c4cc; margin-left: auto; }

.reply-content {
  font-size: 14px;
  line-height: 1.7;
  color: #303133;
  white-space: pre-wrap;
}

.reply-actions { margin-top: 6px; }

.reply-pagination { display: flex; justify-content: center; padding: 12px 0; }

.reply-form {
  background: #fff;
  border-radius: 8px;
  padding: 20px 24px;
}

.reply-form h3 { margin: 0 0 10px; font-size: 15px; color: #303133; }

.empty-state { padding: 40px 0; }

/* Dark mode */
:global(.dark) .topic-detail-container { background: #1a1a2e; }
:global(.dark) .topic-header { background: #1e1e30; box-shadow: 0 1px 4px rgba(0,0,0,0.3); }
:global(.dark) .topic-header .title { color: #e0e0e0; }
:global(.dark) .topic-body-card,
:global(.dark) .replies-section,
:global(.dark) .reply-form { background: #1e1e30; }
:global(.dark) .topic-header-info h2 { color: #e0e0e0; }
:global(.dark) .topic-content { color: #d0d0d0; border-color: #333; }
:global(.dark) .reply-card { border-color: #333; }
:global(.dark) .reply-author { color: #e0e0e0; }
:global(.dark) .reply-content { color: #d0d0d0; }
:global(.dark) .replies-section h3,
:global(.dark) .reply-form h3 { color: #e0e0e0; }
</style>
