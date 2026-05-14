<template>
  <div class="portal-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>

    <div class="decorations" v-if="!isCustom">
      <div class="blob blob-1"></div>
      <div class="blob blob-2"></div>
      <div class="blob blob-3"></div>
    </div>

    <div class="portal-card">
      <el-button link class="theme-toggle" @click="toggleTheme">
        <el-icon :size="20"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
      </el-button>

      <div class="header">
        <span class="avatar">{{ userInitial }}</span>
        <h2>欢迎，{{ username }}</h2>
        <p class="subtitle">选择你想进入的模块</p>
      </div>

      <el-tabs v-model="activeTab" class="portal-tabs">
        <el-tab-pane label="网盘" name="disk">
          <div class="tab-content">
            <div class="tab-icon">☁️</div>
            <h3>个人云盘</h3>
            <p>安全、便捷的个人文件存储与管理</p>
            <el-button type="primary" class="enter-btn" @click="goToDisk">
              进入网盘
            </el-button>
          </div>
        </el-tab-pane>

        <el-tab-pane label="论坛" name="forum">
          <div class="tab-content placeholder">
            <div class="tab-icon">💬</div>
            <h3>论坛</h3>
            <p>敬请期待</p>
          </div>
        </el-tab-pane>

        <el-tab-pane label="小游戏" name="games">
          <div class="tab-content">
            <div class="tab-icon">🎮</div>
            <h3>小霸王游戏机</h3>
            <p>NES 经典游戏模拟器</p>
            <el-button type="primary" class="enter-btn" @click="goToGames">
              进入游戏
            </el-button>
          </div>
        </el-tab-pane>
      </el-tabs>

      <div class="footer">
        <el-button link class="logout-btn" @click="handleLogout">
          <el-icon><SwitchButton /></el-icon>
          退出登录
        </el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useDarkMode } from '../composables/useDarkMode'
import { useBackground } from '../composables/useBackground'
import { Sunny, Moon, SwitchButton } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

const { isDark, toggle: toggleTheme } = useDarkMode()
const { containerBackground, isCustom, bgLayerStyle } = useBackground('auth')

const router = useRouter()
const activeTab = ref('disk')

const user = computed(() => JSON.parse(localStorage.getItem('user') || '{}'))
const username = computed(() => user.value.username || '用户')
const userInitial = computed(() => (username.value || 'U')[0].toUpperCase())

const goToDisk = () => {
  router.push('/disk')
}

const goToGames = () => {
  router.push('/games')
}

const handleLogout = () => {
  localStorage.removeItem('token')
  localStorage.removeItem('user')
  ElMessage.success('已退出登录')
  router.push('/login')
}
</script>

<style scoped>
.portal-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 25%, #0f3460 50%, #533483 75%, #1a1a2e 100%);
  background-size: 400% 400%;
  animation: gradientShift 15s ease infinite;
  overflow: hidden;
}

@keyframes gradientShift {
  0%, 100% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
}

.decorations {
  position: absolute;
  inset: 0;
  pointer-events: none;
  overflow: hidden;
}

.blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.3;
  animation: blobFloat 20s ease-in-out infinite;
}
.blob-1 {
  width: 400px; height: 400px;
  background: radial-gradient(circle, rgba(102,126,234,0.6), transparent);
  top: -10%; left: -5%;
}
.blob-2 {
  width: 350px; height: 350px;
  background: radial-gradient(circle, rgba(245,87,108,0.5), transparent);
  bottom: -10%; right: -5%;
  animation-delay: -7s; animation-duration: 23s;
}
.blob-3 {
  width: 300px; height: 300px;
  background: radial-gradient(circle, rgba(56,239,125,0.4), transparent);
  top: 40%; left: 60%;
  animation-delay: -14s; animation-duration: 18s;
}

@keyframes blobFloat {
  0%, 100% { transform: translate(0, 0) scale(1); }
  25% { transform: translate(40px, -30px) scale(1.1); }
  50% { transform: translate(-20px, 20px) scale(0.95); }
  75% { transform: translate(-30px, -15px) scale(1.05); }
}

.portal-card {
  position: relative;
  z-index: 1;
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  border: 1px solid rgba(255, 255, 255, 0.15);
  padding: 48px 40px 36px;
  border-radius: 20px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25), inset 0 1px 0 rgba(255, 255, 255, 0.1);
  width: 100%;
  max-width: 480px;
  animation: cardIn 0.8s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes cardIn {
  0% { opacity: 0; transform: translateY(30px) scale(0.96); }
  100% { opacity: 1; transform: translateY(0) scale(1); }
}

.theme-toggle {
  position: absolute;
  top: 16px; right: 16px;
  color: rgba(255, 255, 255, 0.7);
}
.theme-toggle:hover { color: #fff; }

.header {
  text-align: center;
  margin-bottom: 32px;
}

.avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 56px; height: 56px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: #fff;
  font-size: 24px;
  font-weight: 700;
  margin-bottom: 12px;
  box-shadow: 0 4px 16px rgba(102,126,234,0.4);
}

h2 {
  color: #fff;
  font-size: 22px;
  margin: 0 0 4px;
}

.subtitle {
  color: rgba(255, 255, 255, 0.5);
  font-size: 14px;
  margin: 0;
}

.portal-tabs {
  --el-tabs-header-height: 44px;
}

:deep(.portal-tabs .el-tabs__nav-wrap::after) {
  background-color: rgba(255, 255, 255, 0.08);
}

:deep(.portal-tabs .el-tabs__item) {
  color: rgba(255, 255, 255, 0.5);
  font-size: 15px;
  font-weight: 500;
  padding: 0 24px;
}
:deep(.portal-tabs .el-tabs__item.is-active) {
  color: #667eea;
}
:deep(.portal-tabs .el-tabs__item:hover) {
  color: rgba(255, 255, 255, 0.8);
}
:deep(.portal-tabs .el-tabs__active-bar) {
  background: linear-gradient(135deg, #667eea, #764ba2);
}

.tab-content {
  text-align: center;
  padding: 32px 16px 24px;
  animation: fadeIn 0.4s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}

.tab-icon {
  font-size: 56px;
  margin-bottom: 12px;
  display: inline-block;
  animation: iconFloat 3s ease-in-out infinite;
}

@keyframes iconFloat {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

.tab-content h3 {
  color: #fff;
  font-size: 20px;
  margin: 0 0 8px;
}

.tab-content p {
  color: rgba(255, 255, 255, 0.45);
  font-size: 14px;
  margin: 0;
}

.tab-content.placeholder .tab-icon {
  filter: grayscale(0.6);
  opacity: 0.6;
}

.tab-content.placeholder h3 {
  color: rgba(255, 255, 255, 0.6);
}

.tab-content.placeholder p {
  color: rgba(255, 255, 255, 0.3);
}

.enter-btn {
  margin-top: 20px;
  height: 44px;
  padding: 0 40px;
  font-size: 15px;
  border-radius: 12px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  border: none;
  font-weight: 600;
  letter-spacing: 2px;
  transition: all 0.3s ease;
}
.enter-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(102,126,234,0.45);
}

.footer {
  text-align: center;
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.06);
}

.logout-btn {
  color: rgba(255, 255, 255, 0.35);
  font-size: 13px;
}
.logout-btn:hover {
  color: #f5576c;
}
</style>
