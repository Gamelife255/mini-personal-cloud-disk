<template>
  <div class="games-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>

    <!-- 顶部导航栏 -->
    <el-header class="games-header">
      <div class="header-left">
        <el-button link @click="goToPortal" class="back-btn">
          <el-icon><ArrowLeft /></el-icon>
          返回门户
        </el-button>
        <span class="title">🎮 小霸王游戏机</span>
      </div>
      <div class="header-right">
        <span v-if="gameName" class="game-name">{{ gameName }}</span>
        <span v-if="fps" class="fps">FPS: {{ fps }}</span>
        <el-button link @click="toggleTheme">
          <el-icon :size="18"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
        </el-button>
      </div>
    </el-header>

    <!-- 游戏区域 -->
    <div class="game-main">
      <div v-if="!loaded" class="drop-zone" @dragover.prevent @drop.prevent="onDrop">
        <div class="drop-content">
          <div class="drop-icon">🕹️</div>
          <h2>小霸王游戏机 (NES)</h2>
          <p>拖拽 .nes ROM 文件到此处，或点击下方按钮加载游戏</p>
          <div class="drop-actions">
            <el-button type="primary" size="large" @click="triggerFileInput">
              <el-icon><FolderOpened /></el-icon>
              选择 ROM 文件
            </el-button>
            <el-button size="large" @click="loadDemoROM" :loading="demoLoading">
              <el-icon><VideoPlay /></el-icon>
              加载示例游戏
            </el-button>
          </div>
          <input ref="fileInput" type="file" accept=".nes" @change="onFileChange" style="display:none" />
          <p class="hint">NES ROM 文件请自行准备（.nes 格式），支持大部分 Mapper</p>
        </div>
      </div>

      <div v-show="loaded" class="game-screen-wrapper">
        <div ref="nesContainer" class="nes-container"></div>
      </div>

      <!-- 控制面板 -->
      <div v-if="loaded" class="control-panel">
        <el-button-group>
          <el-button @click="resetGame" :disabled="!loaded">
            <el-icon><RefreshLeft /></el-icon>
            重置
          </el-button>
          <el-button @click="stopGame" :disabled="!loaded">
            <el-icon><VideoPause /></el-icon>
            停止
          </el-button>
        </el-button-group>
        <el-button @click="triggerFileInput" :disabled="!loaded">
          <el-icon><Switch /></el-icon>
          更换游戏
        </el-button>
      </div>

      <!-- 按键说明 -->
      <div v-if="loaded" class="keymap-panel">
        <h4>按键说明</h4>
        <div class="keymap-grid">
          <div class="keymap-item">
            <kbd>↑ ↓ ← →</kbd>
            <span>方向键</span>
          </div>
          <div class="keymap-item">
            <kbd>X</kbd><kbd>Z</kbd>
            <span>A / B 键</span>
          </div>
          <div class="keymap-item">
            <kbd>Enter</kbd>
            <span>Start</span>
          </div>
          <div class="keymap-item">
            <kbd>Ctrl</kbd>
            <span>Select</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { useDarkMode } from '../composables/useDarkMode'
import { useBackground } from '../composables/useBackground'
import { ArrowLeft, FolderOpened, VideoPlay, RefreshLeft, VideoPause, Switch, Sunny, Moon } from '@element-plus/icons-vue'

const { isDark, toggle: toggleTheme } = useDarkMode()
const { containerBackground, isCustom, bgLayerStyle } = useBackground('games')

const router = useRouter()
const loaded = ref(false)
const gameName = ref('')
const fps = ref(0)
const demoLoading = ref(false)

const nesContainer = ref(null)
const fileInput = ref(null)
let browser = null
let fpsInterval = null

const goToPortal = () => {
  router.push('/portal')
}

const triggerFileInput = () => {
  fileInput.value?.click()
}

const loadROM = (romData, name) => {
  stopEmulator()

  nextTick(() => {
    try {
      browser = new window.jsnes.Browser({
        container: nesContainer.value,
        romData,
        onError: (e) => {
          console.error('NES 模拟器错误:', e)
        }
      })
      loaded.value = true
      gameName.value = name || '未知游戏'

      fpsInterval = setInterval(() => {
        if (browser && browser.nes) {
          fps.value = browser.nes.getFPS()
        }
      }, 1000)
    } catch (e) {
      console.error('启动模拟器失败:', e)
      loaded.value = false
    }
  })
}

const stopEmulator = () => {
  if (fpsInterval) {
    clearInterval(fpsInterval)
    fpsInterval = null
  }
  if (browser) {
    browser.destroy()
    browser = null
  }
  loaded.value = false
  gameName.value = ''
  fps.value = 0
}

const onFileChange = (e) => {
  const file = e.target.files[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = () => {
    loadROM(reader.result, file.name.replace(/\.nes$/i, ''))
  }
  reader.readAsBinaryString(file)
  // Reset so same file can be selected again
  e.target.value = ''
}

const onDrop = (e) => {
  const file = e.dataTransfer.files[0]
  if (!file || !file.name.toLowerCase().endsWith('.nes')) return

  const reader = new FileReader()
  reader.onload = () => {
    loadROM(reader.result, file.name.replace(/\.nes$/i, ''))
  }
  reader.readAsBinaryString(file)
}

const resetGame = () => {
  if (browser && browser.nes) {
    browser.nes.reset()
  }
}

const stopGame = () => {
  stopEmulator()
}

// 加载示例 ROM（需自行准备）
const loadDemoROM = () => {
  // 提示用户需要自己准备 ROM
  triggerFileInput()
}

onUnmounted(() => {
  stopEmulator()
})
</script>

<style scoped>
.games-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
  overflow: auto;
}

.games-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 24px;
  height: 56px;
  background: rgba(0, 0, 0, 0.3);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  flex-shrink: 0;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.back-btn {
  color: rgba(255, 255, 255, 0.7);
  font-size: 14px;
}
.back-btn:hover {
  color: #667eea;
}

.title {
  color: #fff;
  font-size: 18px;
  font-weight: 600;
}

.game-name {
  color: rgba(255, 255, 255, 0.5);
  font-size: 13px;
}

.fps {
  color: #38ef7d;
  font-size: 12px;
  font-family: monospace;
}

.game-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 24px;
}

.drop-zone {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  max-width: 600px;
  margin: 40px auto;
  border: 2px dashed rgba(255, 255, 255, 0.2);
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.03);
  transition: all 0.3s ease;
  cursor: pointer;
}

.drop-zone:hover {
  border-color: rgba(102, 126, 234, 0.6);
  background: rgba(102, 126, 234, 0.08);
}

.drop-content {
  text-align: center;
  padding: 48px;
}

.drop-icon {
  font-size: 64px;
  margin-bottom: 16px;
}

.drop-content h2 {
  color: #fff;
  font-size: 24px;
  margin: 0 0 12px;
}

.drop-content p {
  color: rgba(255, 255, 255, 0.45);
  font-size: 14px;
  margin: 0 0 24px;
  line-height: 1.6;
}

.drop-actions {
  display: flex;
  gap: 12px;
  justify-content: center;
  margin-bottom: 20px;
}

.hint {
  color: rgba(255, 255, 255, 0.25) !important;
  font-size: 12px !important;
}

.game-screen-wrapper {
  display: flex;
  justify-content: center;
  width: 100%;
  max-width: 768px;
}

.nes-container {
  width: 100%;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 8px 40px rgba(0, 0, 0, 0.5);
}

.nes-container :deep(canvas) {
  display: block;
  width: 100% !important;
  height: auto !important;
  image-rendering: pixelated;
}

.control-panel {
  display: flex;
  gap: 12px;
  justify-content: center;
  margin-top: 16px;
  flex-wrap: wrap;
}

.control-panel .el-button {
  color: rgba(255, 255, 255, 0.7);
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.12);
}
.control-panel .el-button:hover:not(:disabled) {
  color: #fff;
  background: rgba(102, 126, 234, 0.25);
  border-color: rgba(102, 126, 234, 0.5);
}
.control-panel .el-button:disabled {
  opacity: 0.3;
}

.keymap-panel {
  margin-top: 20px;
  padding: 16px 24px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.keymap-panel h4 {
  color: rgba(255, 255, 255, 0.5);
  font-size: 13px;
  margin: 0 0 12px;
  text-align: center;
}

.keymap-grid {
  display: flex;
  gap: 24px;
  flex-wrap: wrap;
  justify-content: center;
}

.keymap-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.keymap-item kbd {
  display: inline-block;
  padding: 2px 8px;
  font-size: 12px;
  font-family: monospace;
  color: rgba(255, 255, 255, 0.8);
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 4px;
}

.keymap-item kbd + kbd {
  margin-left: 2px;
}

.keymap-item span {
  color: rgba(255, 255, 255, 0.4);
  font-size: 12px;
}
</style>
