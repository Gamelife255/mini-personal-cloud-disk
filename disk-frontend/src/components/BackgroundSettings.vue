<template>
  <el-dialog v-model="show" title="背景设置" width="620px" :close-on-click-modal="true">
    <div class="bg-settings">
      <el-radio-group v-model="selectedType" class="type-selector">
        <el-radio-button value="none">默认</el-radio-button>
        <el-radio-button value="gradient">渐变色</el-radio-button>
        <el-radio-button value="color">纯色</el-radio-button>
        <el-radio-button value="image">图片链接</el-radio-button>
        <el-radio-button value="cloudImage">云盘图片</el-radio-button>
      </el-radio-group>

      <!-- Gradient grid -->
      <div v-if="selectedType === 'gradient'" class="preset-grid">
        <div
          v-for="preset in gradientPresets"
          :key="preset.name"
          class="preset-item"
          :class="{ active: isSelected('gradient', preset) }"
          :style="{ background: isDark ? preset.dark : preset.light }"
          @click="selectGradient(preset)"
        >
          <span class="preset-name">{{ preset.name }}</span>
        </div>
      </div>

      <!-- Color grid -->
      <div v-if="selectedType === 'color'" class="preset-grid">
        <div
          v-for="preset in colorPresets"
          :key="preset.name"
          class="preset-item preset-color"
          :class="{ active: isSelected('color', preset) }"
          :style="{ backgroundColor: isDark ? preset.dark : preset.light }"
          @click="selectColor(preset)"
        >
          <span class="preset-name">{{ preset.name }}</span>
        </div>
      </div>

      <!-- Image URL input -->
      <div v-if="selectedType === 'image'" class="image-inputs">
        <el-input v-model="imageUrl" placeholder="输入图片URL，例如 https://example.com/bg.jpg" clearable />
        <el-input v-model="imageUrlDark" placeholder="暗色模式图片URL（可选）" clearable style="margin-top: 12px" />
        <el-button type="primary" @click="applyImage" style="margin-top: 12px" :disabled="!imageUrl">应用</el-button>
        <p class="image-hint">建议使用 1920x1080 或更大尺寸的图片，支持 JPG/PNG/WebP 格式</p>
      </div>

      <!-- Cloud image grid -->
      <div v-if="selectedType === 'cloudImage'" class="cloud-image-section">
        <div v-if="loadingCloudImages" class="cloud-loading">
          <el-icon class="is-loading" :size="24"><Loading /></el-icon>
          <span>加载云盘图片...</span>
        </div>
        <div v-else-if="cloudImages.length === 0" class="cloud-empty">
          <el-icon :size="32"><Picture /></el-icon>
          <p>云盘根目录暂无可用图片</p>
          <p class="cloud-hint">支持的格式：JPG、PNG、GIF、WebP、SVG 等（PSD 除外）</p>
        </div>
        <div v-else class="preset-grid">
          <div
            v-for="img in cloudImages"
            :key="img.id"
            class="preset-item cloud-image-item"
            :class="{ active: isCloudSelected(img) }"
            @click="selectCloudImage(img)"
          >
            <img v-if="img.thumbUrl" :src="img.thumbUrl" class="cloud-thumb" />
            <el-icon v-else :size="24"><Picture /></el-icon>
            <span class="cloud-filename">{{ img.fileName }}</span>
          </div>
        </div>
      </div>

      <!-- Opacity slider -->
      <div v-if="selectedType !== 'none'" class="opacity-section">
        <span class="opacity-label">背景透明度：{{ Math.round(opacity * 100) }}%</span>
        <el-slider v-model="opacity" :min="0.1" :max="1" :step="0.05" @input="updateOpacity" />
      </div>
    </div>

    <template #footer>
      <el-button @click="show = false">关闭</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, watch, computed, onUnmounted } from 'vue'
import { useBackground, gradientPresets, colorPresets } from '../composables/useBackground'
import { useDarkMode } from '../composables/useDarkMode'
import { getFileList, downloadFile } from '../api/file'
import { ElMessage } from 'element-plus'
import { Loading, Picture } from '@element-plus/icons-vue'

const props = defineProps({
  context: { type: String, default: 'disk' }
})

const { background, showSettings, setBackground, resetBackground } = useBackground(props.context)
const { isDark } = useDarkMode()

const show = computed({
  get: () => showSettings.value,
  set: (val) => { showSettings.value = val }
})

const selectedType = ref(background.value.type || 'none')
const imageUrl = ref(background.value.type === 'image' ? background.value.value : '')
const imageUrlDark = ref(background.value.type === 'image' ? (background.value.darkValue || '') : '')
const opacity = ref(background.value.opacity ?? 1)

const cloudImages = ref([])
const loadingCloudImages = ref(false)

async function fetchCloudImages() {
  // Revoke old thumbnail blob URLs
  cloudImages.value.forEach(img => {
    if (img.thumbUrl) URL.revokeObjectURL(img.thumbUrl)
  })
  loadingCloudImages.value = true
  cloudImages.value = []
  try {
    const response = await getFileList(0)
    if (response.code === 200) {
      const imageFiles = (response.data || []).filter(f =>
        !f.isFolder &&
        f.fileType?.startsWith('image/') &&
        !f.fileName?.toLowerCase().endsWith('.psd')
      )
      for (const file of imageFiles) {
        try {
          const blob = await downloadFile(file.id)
          file.thumbUrl = URL.createObjectURL(blob)
        } catch (e) {
          // skip images that can't be loaded
        }
      }
      cloudImages.value = imageFiles
    }
  } catch (e) {
    console.error('Failed to fetch cloud images:', e)
  } finally {
    loadingCloudImages.value = false
  }
}

function isCloudSelected(img) {
  const bg = background.value
  return bg.type === 'cloudImage' && bg.fileId === img.id
}

function selectCloudImage(img) {
  setBackground({
    type: 'cloudImage',
    fileId: img.id,
    fileName: img.fileName,
    blobUrl: img.thumbUrl,
    opacity: opacity.value
  })
  // Transfer ownership of the blob URL to the composable; don't revoke it on unmount
  img.thumbUrl = null
}

watch(() => background.value.type, (t) => {
  selectedType.value = t || 'none'
})

watch(selectedType, (t) => {
  if (t === 'none') {
    resetBackground()
  } else if (t === 'cloudImage') {
    fetchCloudImages()
  }
})

function isSelected(type, preset) {
  const bg = background.value
  if (bg.type !== type) return false
  return bg.value === preset.light && bg.name === preset.name
}

function selectGradient(preset) {
  setBackground({
    type: 'gradient',
    value: preset.light,
    darkValue: preset.dark,
    name: preset.name,
    opacity: opacity.value
  })
}

function selectColor(preset) {
  setBackground({
    type: 'color',
    value: preset.light,
    darkValue: preset.dark,
    name: preset.name,
    opacity: opacity.value
  })
}

function applyImage() {
  const url = imageUrl.value.trim()
  if (!url) return
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    ElMessage.warning('图片URL必须以 http:// 或 https:// 开头')
    return
  }
  setBackground({
    type: 'image',
    value: url,
    darkValue: imageUrlDark.value.trim() || undefined,
    name: 'Custom',
    opacity: opacity.value
  })
  ElMessage.success('背景已应用')
}

function updateOpacity() {
  const bg = background.value
  if (!bg || bg.type === 'none') return
  setBackground({ ...bg, opacity: opacity.value })
}

onUnmounted(() => {
  cloudImages.value.forEach(img => {
    if (img.thumbUrl) URL.revokeObjectURL(img.thumbUrl)
  })
})
</script>

<style scoped>
.bg-settings {
  min-height: 200px;
}

.type-selector {
  margin-bottom: 20px;
}

.preset-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}

.preset-item {
  height: 80px;
  border-radius: 8px;
  cursor: pointer;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 3px solid transparent;
  transition: border-color 0.2s, transform 0.15s;
  overflow: hidden;
}

.preset-item:hover {
  transform: scale(1.03);
}

.preset-item.active {
  border-color: var(--el-color-primary);
}

.preset-color {
  box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.1);
}

.preset-name {
  font-size: 13px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.9);
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.5);
  pointer-events: none;
}

.preset-color .preset-name {
  color: rgba(0, 0, 0, 0.6);
  text-shadow: 0 1px 2px rgba(255, 255, 255, 0.5);
}

.image-inputs {
  padding: 8px 0;
}

.image-hint {
  color: var(--el-text-color-secondary);
  font-size: 12px;
  margin-top: 8px;
}

.opacity-section {
  margin-top: 16px;
  padding: 0 4px;
}

.opacity-label {
  font-size: 13px;
  color: var(--el-text-color-secondary);
  margin-bottom: 8px;
  display: block;
}

.cloud-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 32px 0;
  color: var(--el-text-color-secondary);
  font-size: 14px;
}

.cloud-empty {
  text-align: center;
  padding: 32px 0;
  color: var(--el-text-color-secondary);
}

.cloud-empty p {
  margin: 8px 0 0;
}

.cloud-hint {
  font-size: 12px;
  color: var(--el-text-color-disabled);
  margin-top: 4px !important;
}

.cloud-image-item {
  flex-direction: column;
}

.cloud-thumb {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.cloud-filename {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  font-size: 10px;
  color: #fff;
  background: rgba(0, 0, 0, 0.55);
  padding: 2px 4px;
  text-align: center;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  z-index: 1;
}
</style>
