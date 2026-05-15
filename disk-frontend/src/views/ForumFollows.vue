<template>
  <div class="follows-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>

    <el-header class="follows-header">
      <div class="header-left">
        <el-button link @click="goBack" class="back-btn">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
        <span class="title">{{ isFollowingTab ? '正在关注' : '粉丝' }}</span>
      </div>
      <div class="header-right">
        <el-button link @click="toggleTheme">
          <el-icon :size="18"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
        </el-button>
      </div>
    </el-header>

    <div class="follows-main">
      <el-tabs v-model="activeTab" @tab-change="onTabChange">
        <el-tab-pane label="关注" name="following" />
        <el-tab-pane label="粉丝" name="followers" />
      </el-tabs>

      <div v-loading="loading">
        <div v-if="users.length === 0 && !loading" class="empty-state">
          <el-empty :description="isFollowingTab ? '暂未关注任何人' : '暂无粉丝'" :image-size="80" />
        </div>

        <div v-for="user in users" :key="user.id" class="user-card">
          <div class="user-info" @click="goToUserProfile(user.id)">
            <div class="avatar">{{ (user.username || 'U')[0].toUpperCase() }}</div>
            <span class="username">{{ user.username }}</span>
            <span class="follow-time">{{ formatTime(user.followedAt) }}</span>
          </div>
          <div v-if="isFollowingTab && isOwnProfile">
            <el-button size="small" type="default" @click.stop="onUnfollow(user)">取消关注</el-button>
          </div>
        </div>
      </div>

      <div v-if="total > pageSize" class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          :page-size="pageSize"
          :total="total"
          layout="prev, pager, next"
          @current-change="loadData"
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
import { ArrowLeft, Sunny, Moon } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { getFollowers, getFollowing, toggleFollow } from '../api/forum'

const { isDark, toggle: toggleTheme } = useDarkMode()
const { containerBackground, isCustom, bgLayerStyle } = useBackground('forum')

const route = useRoute()
const router = useRouter()
const userId = computed(() => route.params.id)
const currentUser = computed(() => {
  try { return JSON.parse(localStorage.getItem('user') || '{}') } catch { return {} }
})
const isOwnProfile = computed(() => currentUser.value.id == userId.value)

const activeTab = ref(route.query.tab || 'following')
const users = ref([])
const currentPage = ref(1)
const pageSize = 15
const total = ref(0)
const loading = ref(false)

const isFollowingTab = computed(() => activeTab.value === 'following')

const loadData = async () => {
  loading.value = true
  try {
    const fetchFn = isFollowingTab.value ? getFollowing : getFollowers
    const res = await fetchFn(userId.value, { page: currentPage.value, size: pageSize })
    if (res.code === 200) {
      users.value = res.data.items || []
      total.value = res.data.total || 0
    }
  } catch {} finally { loading.value = false }
}

const onTabChange = (tab) => {
  currentPage.value = 1
  loadData()
}

const onUnfollow = async (user) => {
  try {
    const res = await toggleFollow(user.id)
    if (res.code === 200) {
      ElMessage.success('已取消关注')
      loadData()
    }
  } catch {}
}

const goToUserProfile = (id) => router.push(`/forum/user/${id}`)
const goBack = () => {
  if (isOwnProfile.value) {
    router.push('/forum')
  } else {
    router.push(`/forum/user/${userId.value}`)
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

onMounted(loadData)
</script>

<style scoped>
.follows-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  background: #f5f7fa;
}

.follows-header {
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

.follows-main {
  flex: 1;
  max-width: 700px;
  width: 100%;
  margin: 0 auto;
  padding: 16px;
}

.user-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 14px 16px;
  background: #fff;
  border-radius: 8px;
  margin-bottom: 8px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  flex: 1;
}

.avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 18px;
  font-weight: 700;
  flex-shrink: 0;
}

.username { font-weight: 500; color: #303133; font-size: 14px; }
.follow-time { font-size: 12px; color: #c0c4cc; margin-left: auto; }

.pagination { display: flex; justify-content: center; padding: 16px 0; }
.empty-state { padding: 60px 0; }

:global(.dark) .follows-container { background: #1a1a2e; }
:global(.dark) .follows-header { background: #1e1e30; box-shadow: 0 1px 4px rgba(0,0,0,0.3); }
:global(.dark) .follows-header .title { color: #e0e0e0; }
:global(.dark) .user-card { background: #1e1e30; }
:global(.dark) .username { color: #e0e0e0; }
</style>
