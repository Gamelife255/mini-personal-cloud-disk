<template>
  <div class="disk-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>
    <!-- 顶部导航栏 -->
    <el-header class="disk-header">
      <div class="header-left">
        <span class="logo">☁️ 个人云盘</span>
      </div>
      <div class="header-right">
        <el-button link class="theme-toggle" @click="toggleTheme">
          <el-icon :size="18"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
        </el-button>
        <el-button link class="bg-settings-btn" @click="showSettings = !showSettings" title="背景设置">
          <el-icon :size="18"><PictureFilled /></el-icon>
        </el-button>
        <span class="username">{{ user?.username }}</span>
        <el-button link @click="logout">退出登录</el-button>
      </div>
    </el-header>

    <!-- 主体内容区 -->
    <el-container class="disk-main">
      <!-- 左侧菜单 -->
      <el-aside width="200px" class="disk-sidebar">
        <el-menu :default-active="activeMenu" class="disk-menu">
          <el-menu-item index="all" @click="filterFiles('all')">
            <el-icon><Folder /></el-icon>
            <span>全部文件</span>
          </el-menu-item>
          <el-menu-item index="image" @click="filterFiles('image')">
            <el-icon><Picture /></el-icon>
            <span>图片</span>
          </el-menu-item>
          <el-menu-item index="video" @click="filterFiles('video')">
            <el-icon><VideoCamera /></el-icon>
            <span>视频</span>
          </el-menu-item>
          <el-menu-item index="document" @click="filterFiles('document')">
            <el-icon><Document /></el-icon>
            <span>文档</span>
          </el-menu-item>
          <el-menu-item index="other" @click="filterFiles('other')">
            <el-icon><More /></el-icon>
            <span>其他</span>
          </el-menu-item>
          <el-menu-item index="statistics" @click="goToStatistics">
            <el-icon><DataAnalysis /></el-icon>
            <span>数据统计</span>
          </el-menu-item>
          <template v-if="isAdmin">
            <el-menu-item index="admin" @click="goToAdmin">
              <el-icon><Setting /></el-icon>
              <span>管理后台</span>
            </el-menu-item>
          </template>
        </el-menu>

        <!-- 存储空间 -->
        <div class="storage-info">
          <div class="storage-title">存储空间</div>
          <el-progress :percentage="storagePercent" :color="storageColor" />
          <div class="storage-text">{{ usedStorage }} / {{ totalStorage }}</div>
        </div>
      </el-aside>

      <!-- 右侧文件区 -->
      <el-main class="disk-content" :style="isCustom ? { backgroundColor: 'transparent' } : {}">
        <!-- 工具栏 -->
        <div class="toolbar">
          <el-button type="primary" @click="showUpload = true">
            <el-icon><Upload /></el-icon>上传文件
          </el-button>
          <el-button @click="showNewFolder = true">
            <el-icon><FolderAdd /></el-icon>新建文件夹
          </el-button>
          <template v-if="selectedFiles.length > 0">
            <span class="selected-count">已选 {{ selectedFiles.length }} 项</span>
            <el-button type="success" @click="handleBatchDownload">
              <el-icon><Download /></el-icon>批量下载
            </el-button>
            <el-button type="warning" @click="showMoveDialog = true">
              <el-icon><Sort /></el-icon>批量移动
            </el-button>
            <el-button type="danger" @click="handleBatchDelete">
              <el-icon><Delete /></el-icon>批量删除
            </el-button>
          </template>
          <el-input
            v-model="searchKeyword"
            placeholder="搜索文件"
            class="search-input"
            clearable
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </div>

        <!-- 面包屑导航 -->
        <el-breadcrumb separator="/" class="breadcrumb">
          <el-breadcrumb-item @click="goToFolder(0)">全部文件</el-breadcrumb-item>
          <el-breadcrumb-item v-for="folder in breadcrumb" :key="folder.id">
            {{ folder.name }}
          </el-breadcrumb-item>
        </el-breadcrumb>

        <!-- 文件列表 -->
        <el-table :data="filteredFiles" style="width: 100%" v-loading="loading" @selection-change="handleSelectionChange" @sort-change="handleSortChange">
          <el-table-column type="selection" width="50" />
          <el-table-column label="文件名" min-width="300" sortable="custom" prop="fileName">
            <template #default="{ row }">
              <div class="file-name" @click="handleFileClick(row)">
                <el-icon :size="24" class="file-icon">
                  <Folder v-if="row.isFolder" color="#409EFF" />
                  <Document v-else-if="isDocument(row.fileType)" color="#67C23A" />
                  <Picture v-else-if="isImage(row.fileType, row.fileName)" color="#E6A23C" />
                  <VideoCamera v-else-if="isVideo(row.fileType)" color="#F56C6C" />
                  <Files v-else color="#909399" />
                </el-icon>
                <span>{{ row.fileName }}</span>
              </div>
            </template>
          </el-table-column>
          <el-table-column label="类型" width="100" sortable="custom" prop="fileType">
            <template #default="{ row }">
              {{ row.isFolder ? '文件夹' : (row.fileType || '未知') }}
            </template>
          </el-table-column>
          <el-table-column label="大小" width="120" sortable="custom" prop="fileSize">
            <template #default="{ row }">
              {{ row.isFolder ? '-' : formatFileSize(row.fileSize) }}
            </template>
          </el-table-column>
          <el-table-column label="修改时间" width="180" sortable="custom" prop="updatedAt">
            <template #default="{ row }">
              {{ formatDate(row.updatedAt) }}
            </template>
          </el-table-column>
          <el-table-column label="备注" width="160">
            <template #default="{ row }">
              <el-popover
                v-if="!row.isFolder"
                placement="bottom"
                :width="280"
                trigger="click"
                @show="editingRemark = { id: row.id, text: row.remark || '' }"
              >
                <template #reference>
                  <div class="remark-cell">
                    <span v-if="row.remark" class="remark-text">{{ row.remark }}</span>
                    <el-icon v-else class="remark-icon-empty"><EditPen /></el-icon>
                    <el-icon v-if="row.remark" class="remark-icon-edit"><EditPen /></el-icon>
                  </div>
                </template>
                <div class="remark-editor">
                  <el-input
                    v-model="editingRemark.text"
                    type="textarea"
                    :rows="3"
                    maxlength="500"
                    show-word-limit
                    placeholder="添加备注信息..."
                  />
                  <div class="remark-actions">
                    <el-button size="small" @click="saveRemark(row)">保存</el-button>
                  </div>
                </div>
              </el-popover>
              <span v-else class="remark-disabled">—</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="200" fixed="right">
            <template #default="{ row }">
              <el-button link @click="previewFile(row)" v-if="isPreviewable(row.fileType, row.fileName)">
                <el-icon><View /></el-icon>
              </el-button>
              <el-button link @click="downloadFile(row)" v-if="!row.isFolder">
                <el-icon><Download /></el-icon>
              </el-button>
              <el-button link @click="deleteFile(row)">
                <el-icon><Delete /></el-icon>
              </el-button>
            </template>
          </el-table-column>
        </el-table>

        <!-- 空状态 -->
        <el-empty v-if="filteredFiles.length === 0 && !loading" description="暂无文件" />
      </el-main>
    </el-container>

    <!-- 上传对话框 -->
    <el-dialog v-model="showUpload" title="上传文件" width="500px">
      <el-upload
        drag
        :auto-upload="false"
        :on-change="handleFileChange"
        :file-list="fileList"
        multiple
      >
        <el-icon class="el-icon--upload"><Upload /></el-icon>
        <div class="el-upload__text">
          拖拽文件到此处或 <em>点击上传</em>
        </div>
      </el-upload>
      <template #footer>
        <el-button @click="showUpload = false">取消</el-button>
        <el-button type="primary" @click="handleUpload" :loading="uploading">上传</el-button>
      </template>
    </el-dialog>

    <!-- 新建文件夹对话框 -->
    <el-dialog v-model="showNewFolder" title="新建文件夹" width="400px">
      <el-input v-model="newFolderName" placeholder="请输入文件夹名称" />
      <template #footer>
        <el-button @click="showNewFolder = false">取消</el-button>
        <el-button type="primary" @click="createFolder">确定</el-button>
      </template>
    </el-dialog>

    <!-- 文件预览对话框 -->
    <el-dialog v-model="showPreview" title="文件预览" width="800px" :close-on-click-modal="true">
      <div class="preview-content">
        <img v-if="previewFileInfo.isImage" :src="previewUrl" :alt="previewFileInfo.fileName" class="preview-image" />
        <video v-else-if="previewFileInfo.isVideo" :src="previewUrl" controls class="preview-video">
          您的浏览器不支持视频播放
        </video>
        <audio v-else-if="previewFileInfo.isAudio" :src="previewUrl" controls class="preview-audio">
          您的浏览器不支持音频播放
        </audio>
        <iframe v-else-if="previewFileInfo.isPdf" :src="previewUrl" class="preview-pdf"></iframe>
        <pre v-else-if="previewFileInfo.isText" class="preview-text">{{ previewTextContent }}</pre>
        <div v-else-if="previewFileInfo.isOffice" class="preview-not-supported">
          <el-icon :size="48" class="preview-icon"><Document /></el-icon>
          <p>此文件类型暂不支持在线预览</p>
          <p class="preview-hint">请下载后使用本地应用打开</p>
        </div>
        <div v-else class="preview-not-supported">
          <el-icon :size="48" class="preview-icon"><Document /></el-icon>
          <p>暂不支持此文件类型预览</p>
        </div>
      </div>
      <template #footer>
        <el-button @click="showPreview = false">关闭</el-button>
        <el-button type="primary" @click="downloadFile(previewFileInfo)">{{ previewFileInfo.isOffice ? '下载后查看' : '下载' }}</el-button>
      </template>
    </el-dialog>

    <!-- 批量移动对话框 -->
    <el-dialog v-model="showMoveDialog" title="移动到" width="450px">
      <p class="move-hint">将选中的 {{ selectedFiles.length }} 个项目移动到：</p>
      <el-radio-group v-model="moveTargetFolderId" class="move-folder-list">
        <el-radio :value="0" class="move-folder-item">根目录</el-radio>
        <el-radio v-for="folder in availableFolders" :key="folder.id" :value="folder.id" class="move-folder-item">
          {{ folder.fileName }}
        </el-radio>
      </el-radio-group>
      <p v-if="availableFolders.length === 0" class="no-folders">暂无可用文件夹（当前目录下没有子文件夹）</p>
      <template #footer>
        <el-button @click="showMoveDialog = false">取消</el-button>
        <el-button type="primary" @click="handleBatchMove" :disabled="moveTargetFolderId === null || moveTargetFolderId === undefined">确定</el-button>
      </template>
    </el-dialog>

    <!-- 背景设置 -->
    <BackgroundSettings context="disk" />

    <!-- 图片查看器 -->
    <teleport to="body">
      <div
        v-if="imgViewer.show"
        class="img-viewer-backdrop"
        :class="{ 'img-fullscreen': imgFullscreen }"
        @wheel.prevent="onWheel"
        @click.self="closeImageViewer"
        @keydown="onViewerKeydown"
        tabindex="0"
        ref="viewerBackdrop"
      >
        <!-- 浮动窗口模式（非全屏） -->
        <div
          v-if="!imgFullscreen"
          class="img-viewer-window"
          :style="{ left: imgWindow.x + 'px', top: imgWindow.y + 'px', width: imgWindow.width + 'px', height: imgWindow.height + 'px' }"
          @mousedown="onWindowDragStart"
        >
          <!-- 标题栏 -->
          <div class="img-viewer-titlebar">
            <span class="img-viewer-title">{{ imgViewer.fileName }}</span>
            <span class="img-viewer-zoom-label">{{ Math.round(imgScale * 100) }}%</span>
            <div class="img-viewer-actions">
              <el-button link @click="zoomOut" title="缩小"><el-icon :size="16"><ZoomOut /></el-icon></el-button>
              <el-button link @click="zoomIn" title="放大"><el-icon :size="16"><ZoomIn /></el-icon></el-button>
              <el-button link @click="fitImage" title="适应窗口"><el-icon :size="16"><Aim /></el-icon></el-button>
              <el-button link @click="toggleImgFullscreen" title="全屏"><el-icon :size="16"><FullScreen /></el-icon></el-button>
              <el-button link @click="closeImageViewer" title="关闭"><el-icon :size="16"><Close /></el-icon></el-button>
            </div>
          </div>
          <!-- 图片区域 -->
          <div class="img-viewer-body" @mousedown="onImagePanStart">
            <img
              :src="imgViewer.url"
              :alt="imgViewer.fileName"
              class="img-viewer-image"
              :style="{
                transform: `translate(${imgTranslateX}px, ${imgTranslateY}px) scale(${imgScale})`,
                cursor: imgScale > 1 ? (isPanning ? 'grabbing' : 'grab') : 'default'
              }"
              draggable="false"
            />
          </div>
          <!-- 调整大小手柄 -->
          <div class="resize-handle resize-se" @mousedown="onResizeStart($event, 'se')"></div>
          <div class="resize-handle resize-sw" @mousedown="onResizeStart($event, 'sw')"></div>
          <div class="resize-handle resize-ne" @mousedown="onResizeStart($event, 'ne')"></div>
          <div class="resize-handle resize-nw" @mousedown="onResizeStart($event, 'nw')"></div>
          <div class="resize-handle resize-e" @mousedown="onResizeStart($event, 'e')"></div>
          <div class="resize-handle resize-s" @mousedown="onResizeStart($event, 's')"></div>
          <div class="resize-handle resize-n" @mousedown="onResizeStart($event, 'n')"></div>
          <div class="resize-handle resize-w" @mousedown="onResizeStart($event, 'w')"></div>
        </div>

        <!-- 全屏模式 -->
        <template v-else>
          <div class="img-fullscreen-toolbar">
            <span class="img-viewer-title">{{ imgViewer.fileName }}</span>
            <span class="img-viewer-zoom-label">{{ Math.round(imgScale * 100) }}%</span>
            <div class="img-viewer-actions">
              <el-button link @click="zoomOut"><el-icon :size="18"><ZoomOut /></el-icon></el-button>
              <el-button link @click="zoomIn"><el-icon :size="18"><ZoomIn /></el-icon></el-button>
              <el-button link @click="fitImage"><el-icon :size="18"><Aim /></el-icon></el-button>
              <el-button link @click="toggleImgFullscreen"><el-icon :size="18"><FullScreen /></el-icon></el-button>
              <el-button link @click="closeImageViewer"><el-icon :size="18"><Close /></el-icon></el-button>
            </div>
          </div>
          <div class="img-fullscreen-body" @mousedown="onImagePanStart">
            <img
              :src="imgViewer.url"
              :alt="imgViewer.fileName"
              class="img-viewer-image"
              :style="{
                transform: `translate(${imgTranslateX}px, ${imgTranslateY}px) scale(${imgScale})`,
                cursor: imgScale > 1 ? (isPanning ? 'grabbing' : 'grab') : 'default'
              }"
              draggable="false"
            />
          </div>
        </template>
      </div>
    </teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import BackgroundSettings from '../components/BackgroundSettings.vue'
import { useBackground } from '../composables/useBackground'
import { uploadFile, createFolder as createFolderApi, getFileList, downloadFile as downloadFileApi, deleteFile as deleteFileApi, getSpaceUsage, previewFile as previewFileApi, batchDelete as batchDeleteApi, batchDownload as batchDownloadApi, batchMove as batchMoveApi, updateFileRemark } from '../api/file'
import { useDarkMode } from '../composables/useDarkMode'
import {
  Folder, Picture, VideoCamera, Document, More, Upload, Download, Delete, FolderAdd, Search, View, Sort, Sunny, Moon, Setting, PictureFilled, DataAnalysis, ZoomIn, ZoomOut, FullScreen, Aim, Close, EditPen
} from '@element-plus/icons-vue'

const { isDark, toggle: toggleTheme } = useDarkMode()
const { showSettings, containerBackground, isCustom, bgLayerStyle } = useBackground('disk')

const router = useRouter()
const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))
const isAdmin = computed(() => user.value?.role === 'admin')

// 状态
const loading = ref(false)
const files = ref([])
const currentFolder = ref(0)
const breadcrumb = ref([])
const searchKeyword = ref('')
const activeMenu = ref('all')
const showUpload = ref(false)
const showNewFolder = ref(false)
const newFolderName = ref('')
const fileList = ref([])
const uploading = ref(false)
const sortBy = ref('updatedAt')
const sortOrder = ref('DESC')

// 批量操作
const selectedFiles = ref([])
const showMoveDialog = ref(false)
const moveTargetFolderId = ref(null)

// 可用于移动的目标文件夹（排除选中的文件夹本身）
const availableFolders = computed(() => {
  const selectedIds = new Set(selectedFiles.value.map(f => f.id))
  return files.value.filter(f => f.isFolder && !selectedIds.has(f.id))
})

// 存储空间
const usedStorage = ref('0 B')
const totalStorage = ref('10 GB')
const storagePercent = ref(0)
const storageColor = ref('#409EFF')

// 预览相关
const showPreview = ref(false)
const previewUrl = ref('')
const previewTextContent = ref('')
const previewFileInfo = ref({
  id: null,
  fileName: '',
  fileType: '',
  isImage: false,
  isVideo: false,
  isPdf: false,
  isAudio: false,
  isText: false,
  isOffice: false
})

// 图片查看器
const viewerBackdrop = ref(null)
const imgViewer = ref({
  show: false,
  url: '',
  fileName: '',
  naturalWidth: 0,
  naturalHeight: 0
})
const imgScale = ref(1)
const imgTranslateX = ref(0)
const imgTranslateY = ref(0)
const imgFullscreen = ref(false)
const imgWindow = ref({ x: 80, y: 60, width: 900, height: 600 })
const isDragging = ref(false)
const isPanning = ref(false)
const dragStart = ref({ x: 0, y: 0 })
const panStart = ref({ x: 0, y: 0, tx: 0, ty: 0 })
const resizeDir = ref('')
const resizeStart = ref({ x: 0, y: 0, w: 0, h: 0 })

function openImageViewer(url, fileName) {
  imgViewer.value.show = true
  imgViewer.value.url = url
  imgViewer.value.fileName = fileName
  imgScale.value = 1
  imgTranslateX.value = 0
  imgTranslateY.value = 0
  imgFullscreen.value = false
  // Get natural image dimensions for fit calculation
  const img = new Image()
  img.onload = () => {
    imgViewer.value.naturalWidth = img.naturalWidth
    imgViewer.value.naturalHeight = img.naturalHeight
  }
  img.src = url
  nextTick(() => {
    viewerBackdrop.value?.focus()
  })
}

function onViewerKeydown(e) {
  if (e.key === 'Escape') closeImageViewer()
  if (e.key === '+' || e.key === '=') zoomIn()
  if (e.key === '-') zoomOut()
  if (e.key === '0') fitImage()
  if (e.key === 'f' || e.key === 'F') toggleImgFullscreen()
}

function closeImageViewer() {
  if (imgViewer.value.url) {
    URL.revokeObjectURL(imgViewer.value.url)
  }
  imgViewer.value.show = false
  imgViewer.value.url = ''
  imgScale.value = 1
  imgTranslateX.value = 0
  imgTranslateY.value = 0
}

function fitImage() {
  imgScale.value = 1
  imgTranslateX.value = 0
  imgTranslateY.value = 0
}

function zoomIn() {
  imgScale.value = Math.min(imgScale.value * 1.3, 10)
}

function zoomOut() {
  imgScale.value = Math.max(imgScale.value / 1.3, 0.1)
}

function zoomImage(delta) {
  const newScale = imgScale.value * (delta > 0 ? 1.15 : 1 / 1.15)
  imgScale.value = Math.max(0.1, Math.min(10, newScale))
}

function toggleImgFullscreen() {
  imgFullscreen.value = !imgFullscreen.value
  fitImage()
}

// Window drag
function onWindowDragStart(e) {
  // Only drag from titlebar, not from buttons
  if (e.target.closest('.img-viewer-titlebar') && !e.target.closest('.img-viewer-actions')) {
    isDragging.value = true
    dragStart.value = { x: e.clientX - imgWindow.value.x, y: e.clientY - imgWindow.value.y }
    document.addEventListener('mousemove', onWindowDrag)
    document.addEventListener('mouseup', onWindowDragEnd)
  }
}

function onWindowDrag(e) {
  if (!isDragging.value) return
  imgWindow.value.x = Math.max(0, e.clientX - dragStart.value.x)
  imgWindow.value.y = Math.max(0, e.clientY - dragStart.value.y)
}

function onWindowDragEnd() {
  isDragging.value = false
  document.removeEventListener('mousemove', onWindowDrag)
  document.removeEventListener('mouseup', onWindowDragEnd)
}

// Window resize
function onResizeStart(e, dir) {
  e.stopPropagation()
  resizeDir.value = dir
  resizeStart.value = { x: e.clientX, y: e.clientY, w: imgWindow.value.width, h: imgWindow.value.height }
  document.addEventListener('mousemove', onResize)
  document.addEventListener('mouseup', onResizeEnd)
}

function onResize(e) {
  if (!resizeDir.value) return
  const dx = e.clientX - resizeStart.value.x
  const dy = e.clientY - resizeStart.value.y
  if (resizeDir.value.includes('e')) imgWindow.value.width = Math.max(400, resizeStart.value.w + dx)
  if (resizeDir.value.includes('s')) imgWindow.value.height = Math.max(300, resizeStart.value.h + dy)
  if (resizeDir.value.includes('w')) {
    imgWindow.value.width = Math.max(400, resizeStart.value.w - dx)
    imgWindow.value.x = resizeStart.value.x + dx - (resizeStart.value.w - imgWindow.value.width)
  }
  if (resizeDir.value.includes('n')) {
    imgWindow.value.height = Math.max(300, resizeStart.value.h - dy)
    imgWindow.value.y = resizeStart.value.y + dy - (resizeStart.value.h - imgWindow.value.height)
  }
}

function onResizeEnd() {
  resizeDir.value = ''
  document.removeEventListener('mousemove', onResize)
  document.removeEventListener('mouseup', onResizeEnd)
}

// Image pan
function onImagePanStart(e) {
  if (imgScale.value <= 1) return
  e.preventDefault()
  isPanning.value = true
  panStart.value = { x: e.clientX, y: e.clientY, tx: imgTranslateX.value, ty: imgTranslateY.value }
  document.addEventListener('mousemove', onImagePan)
  document.addEventListener('mouseup', onImagePanEnd)
}

function onImagePan(e) {
  if (!isPanning.value) return
  imgTranslateX.value = panStart.value.tx + (e.clientX - panStart.value.x)
  imgTranslateY.value = panStart.value.ty + (e.clientY - panStart.value.y)
}

function onImagePanEnd() {
  isPanning.value = false
  document.removeEventListener('mousemove', onImagePan)
  document.removeEventListener('mouseup', onImagePanEnd)
}

function onWheel(e) {
  e.preventDefault()
  zoomImage(e.deltaY < 0 ? 1 : -1)
}

// 备注编辑
const editingRemark = ref({ id: null, text: '' })

async function saveRemark(row) {
  try {
    const response = await updateFileRemark(editingRemark.value.id, editingRemark.value.text || null)
    if (response.code === 200) {
      row.remark = editingRemark.value.text || null
      ElMessage.success('备注已保存')
    } else {
      ElMessage.error(response.message || '保存失败')
    }
  } catch (e) {
    ElMessage.error('保存备注失败')
  }
}

// 加载存储空间信息
const loadSpaceUsage = async () => {
  try {
    const response = await getSpaceUsage()
    if (response.code === 200) {
      const { usedSpace, totalSpace } = response.data
      usedStorage.value = formatFileSize(usedSpace)
      totalStorage.value = formatFileSize(totalSpace)
      storagePercent.value = Math.round((usedSpace / totalSpace) * 100)
      
      // 根据使用比例设置颜色
      if (storagePercent.value >= 90) {
        storageColor.value = '#F56C6C'
      } else if (storagePercent.value >= 70) {
        storageColor.value = '#E6A23C'
      } else {
        storageColor.value = '#67C23A'
      }
    } else {
      ElMessage.error(response.message || '加载存储空间信息失败')
    }
  } catch (error) {
    ElMessage.error('加载存储空间信息失败')
  }
}

// 过滤后的文件列表
const filteredFiles = computed(() => {
  let result = files.value
  
  // 按类型过滤
  if (activeMenu.value !== 'all') {
    result = result.filter(file => {
      if (activeMenu.value === 'image') return isImage(file.fileType, file.fileName)
      if (activeMenu.value === 'video') return isVideo(file.fileType)
      if (activeMenu.value === 'document') return isDocument(file.fileType)
      if (activeMenu.value === 'other') {
        return !isImage(file.fileType, file.fileName) && !isVideo(file.fileType) && !isDocument(file.fileType) && !file.isFolder
      }
      return true
    })
  }
  
  // 按关键词搜索
  if (searchKeyword.value) {
    result = result.filter(file => 
      file.fileName.toLowerCase().includes(searchKeyword.value.toLowerCase())
    )
  }
  
  return result
})

// 加载文件列表
const loadFiles = async () => {
  loading.value = true
  try {
    const response = await getFileList(currentFolder.value, sortBy.value, sortOrder.value)
    if (response.code === 200) {
      files.value = response.data.map(file => ({
        id: file.id,
        fileName: file.fileName,
        isFolder: file.isFolder === 1,
        fileSize: file.fileSize,
        fileType: file.fileType,
        updatedAt: file.updatedAt,
        parentId: file.parentId,
        remark: file.remark || null
      }))
    } else {
      ElMessage.error(response.message || '加载文件失败')
    }
  } catch (error) {
    ElMessage.error('加载文件失败')
  } finally {
    loading.value = false
  }
}

// 文件类型判断
// Client-side extension whitelist (keep in sync with FileValidationUtil.java)
const ALLOWED_EXTENSIONS = new Set([
  '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico',
  '.psd', '.tiff', '.tif', '.heic', '.heif',
  '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
  '.txt', '.csv', '.md', '.rtf', '.json', '.xml', '.yml', '.yaml',
  '.toml', '.ini', '.cfg', '.conf', '.properties', '.log',
  '.java', '.py', '.js', '.ts', '.jsx', '.tsx', '.vue',
  '.html', '.htm', '.css', '.scss', '.less',
  '.c', '.cpp', '.h', '.hpp', '.rs', '.go',
  '.sh', '.bat', '.ps1', '.sql',
  '.mp4', '.avi', '.mov', '.wmv', '.flv', '.mkv', '.webm', '.m4v',
  '.mp3', '.wav', '.ogg', '.flac', '.aac', '.wma', '.m4a', '.opus',
  '.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz'
])

const isImage = (type, fileName) => type?.startsWith('image/') || isPsd(fileName)
const isVideo = (type) => type?.startsWith('video/')
const isDocument = (type) => {
  const docTypes = ['application/pdf', 'text/plain', 'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
  return docTypes.includes(type)
}

const isPdf = (type) => type === 'application/pdf'
const isAudio = (type) => type?.startsWith('audio/')
const isText = (type) => type?.startsWith('text/')
const isOffice = (type) => {
  const officeTypes = [
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation'
  ]
  return officeTypes.includes(type)
}
const isPreviewable = (type, fileName) =>
  isImage(type, fileName) || isVideo(type) || isPdf(type) || isAudio(type) || isText(type) || isOffice(type)

// 格式化文件大小
const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

// 格式化日期
const formatDate = (timestamp) => {
  if (!timestamp) return ''
  const date = new Date(timestamp)
  return date.toLocaleString('zh-CN')
}

// 文件点击处理
const handleFileClick = (file) => {
  if (file.isFolder) {
    currentFolder.value = file.id
    breadcrumb.value.push({ id: file.id, name: file.fileName })
    loadFiles()
  }
}

// 返回文件夹
const goToFolder = (folderId) => {
  currentFolder.value = folderId
  if (folderId === 0) {
    breadcrumb.value = []
  } else {
    const index = breadcrumb.value.findIndex(item => item.id === folderId)
    if (index >= 0) {
      breadcrumb.value = breadcrumb.value.slice(0, index + 1)
    }
  }
  loadFiles()
}

// 过滤文件
const filterFiles = (type) => {
  activeMenu.value = type
}

// 下载文件
const downloadFile = async (file) => {
  try {
    const blob = await downloadFileApi(file.id)
    
    // 检查浏览器是否支持自定义保存路径
    if ('showSaveFilePicker' in window) {
      // 使用现代浏览器的文件保存 API
      const handle = await window.showSaveFilePicker({
        suggestedName: file.fileName,
        types: [{
          description: '文件',
          accept: { '*/*': [] }
        }]
      })
      const writable = await handle.createWritable()
      await writable.write(blob)
      await writable.close()
      ElMessage.success('下载成功')
    } else {
      // 传统下载方式
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = file.fileName
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      window.URL.revokeObjectURL(url)
      ElMessage.success('下载成功')
    }
  } catch (error) {
    // 用户取消选择时不报错
    if (error.name !== 'AbortError') {
      ElMessage.error('下载失败')
    }
  }
}

// 删除文件
const deleteFile = async (file) => {
  try {
    await ElMessageBox.confirm(`确定要删除 "${file.fileName}" 吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    const response = await deleteFileApi(file.id)
    if (response.code === 200) {
      ElMessage.success('删除成功')
      loadFiles()
      loadSpaceUsage()
    } else {
      ElMessage.error(response.message || '删除失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 判断是否是PSD文件
const isPsd = (fileName) => {
  if (!fileName) return false
  return fileName.toLowerCase().endsWith('.psd')
}

// 预览文件
const previewFile = async (file) => {
  const isPsdFile = isPsd(file.fileName)
  const fileIsPdf = isPdf(file.fileType)
  const fileIsAudio = isAudio(file.fileType)
  const fileIsText = isText(file.fileType)
  const fileIsOffice = isOffice(file.fileType)

  previewFileInfo.value = {
    id: file.id,
    fileName: file.fileName,
    fileType: file.fileType,
    isImage: isImage(file.fileType, file.fileName),
    isVideo: isVideo(file.fileType),
    isPdf: fileIsPdf,
    isAudio: fileIsAudio,
    isText: fileIsText,
    isOffice: fileIsOffice
  }

  // Image: use custom viewer
  const fileIsImage = isImage(file.fileType, file.fileName) && !isPsdFile
  if (fileIsImage) {
    try {
      const blob = await downloadFileApi(file.id)
      const url = window.URL.createObjectURL(blob)
      openImageViewer(url, file.fileName)
    } catch (error) {
      ElMessage.error('加载预览文件失败')
    }
    return
  }

  // Office files: no fetch needed, just show the dialog with download button
  if (fileIsOffice) {
    showPreview.value = true
    return
  }

  try {
    if (isPsdFile || fileIsPdf || fileIsAudio) {
      const blob = await previewFileApi(file.id)
      previewUrl.value = window.URL.createObjectURL(blob)
    } else if (fileIsText) {
      const blob = await downloadFileApi(file.id)
      previewTextContent.value = await blob.text()
    } else {
      const blob = await downloadFileApi(file.id)
      previewUrl.value = window.URL.createObjectURL(blob)
    }
    showPreview.value = true
  } catch (error) {
    ElMessage.error('加载预览文件失败')
  }
}

// 上传文件选择
const handleFileChange = (file) => {
  fileList.value.push(file)
}

// 上传文件
const handleUpload = async () => {
  if (fileList.value.length === 0) {
    ElMessage.warning('请选择要上传的文件')
    return
  }

  // Client-side extension check (defense-in-depth, backend does real validation)
  for (const fileItem of fileList.value) {
    const name = fileItem.name || ''
    const ext = name.substring(name.lastIndexOf('.')).toLowerCase()
    if (!ext || !ALLOWED_EXTENSIONS.has(ext)) {
      ElMessage.error(`不支持的文件类型: ${name}`)
      return
    }
  }

  uploading.value = true
  try {
    for (const file of fileList.value) {
      const response = await uploadFile(file.raw, currentFolder.value)
      if (response.code !== 200) {
        ElMessage.error(`${file.name} 上传失败`)
      }
    }
    ElMessage.success('上传成功')
    showUpload.value = false
    fileList.value = []
    loadFiles()
    loadSpaceUsage()
  } catch (error) {
    ElMessage.error('上传失败')
  } finally {
    uploading.value = false
  }
}

// 创建文件夹
const createFolder = async () => {
  if (!newFolderName.value.trim()) {
    ElMessage.warning('请输入文件夹名称')
    return
  }
  try {
    const response = await createFolderApi(newFolderName.value, currentFolder.value)
    if (response.code === 200) {
      ElMessage.success('创建文件夹成功')
      showNewFolder.value = false
      newFolderName.value = ''
      loadFiles()
    } else {
      ElMessage.error(response.message || '创建文件夹失败')
    }
  } catch (error) {
    ElMessage.error('创建文件夹失败')
  }
}

// 表格选择变化
const handleSelectionChange = (rows) => {
  selectedFiles.value = rows
}

// 排序变化
const handleSortChange = ({ prop, order }) => {
  if (prop) {
    sortBy.value = prop
    // order: 'ascending' | 'descending' | null
    sortOrder.value = order === 'ascending' ? 'ASC' : 'DESC'
    loadFiles()
  }
}

// 批量下载
const handleBatchDownload = async () => {
  try {
    const ids = selectedFiles.value.filter(f => !f.isFolder).map(f => f.id)
    if (ids.length === 0) {
      ElMessage.warning('没有可下载的文件（文件夹不支持批量下载）')
      return
    }
    const blob = await batchDownloadApi(ids)
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = 'files.zip'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    ElMessage.success('下载成功')
  } catch (error) {
    ElMessage.error('批量下载失败')
  }
}

// 批量删除
const handleBatchDelete = async () => {
  try {
    await ElMessageBox.confirm(`确定要删除选中的 ${selectedFiles.value.length} 个文件吗？`, '批量删除', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    const ids = selectedFiles.value.map(f => f.id)
    const response = await batchDeleteApi(ids)
    if (response.code === 200) {
      ElMessage.success(response.message || '删除成功')
      selectedFiles.value = []
      loadFiles()
      loadSpaceUsage()
    } else {
      ElMessage.error(response.message || '删除失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('批量删除失败')
    }
  }
}

// 批量移动
const handleBatchMove = async () => {
  if (moveTargetFolderId.value === null || moveTargetFolderId.value === undefined) {
    ElMessage.warning('请选择目标文件夹')
    return
  }
  try {
    const ids = selectedFiles.value.map(f => f.id)
    const response = await batchMoveApi(ids, moveTargetFolderId.value)
    if (response.code === 200) {
      ElMessage.success(response.message || '移动成功')
      showMoveDialog.value = false
      moveTargetFolderId.value = null
      selectedFiles.value = []
      loadFiles()
    } else {
      ElMessage.error(response.message || '移动失败')
    }
  } catch (error) {
    ElMessage.error('批量移动失败')
  }
}

const goToStatistics = () => {
  router.push('/statistics')
}

const goToAdmin = () => {
  router.push('/admin')
}

// 退出登录
const logout = () => {
  localStorage.removeItem('token')
  localStorage.removeItem('user')
  router.push('/login')
}

// 预览关闭时释放 blob URL
watch(showPreview, (newVal) => {
  if (!newVal) {
    if (previewUrl.value) {
      window.URL.revokeObjectURL(previewUrl.value)
      previewUrl.value = ''
    }
    previewTextContent.value = ''
  }
})

onMounted(() => {
  loadFiles()
  loadSpaceUsage()
})
</script>

<style scoped>
.disk-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.disk-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: var(--el-bg-color);
  border-bottom: 1px solid var(--el-border-color-lighter);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.header-left .logo {
  font-size: 20px;
  font-weight: bold;
  color: var(--el-color-primary);
}

.header-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.theme-toggle {
  font-size: 16px;
}

.username {
  color: var(--el-text-color-regular);
}

.disk-main {
  flex: 1;
  overflow: hidden;
}

.disk-sidebar {
  background-color: var(--el-bg-color);
  border-right: 1px solid var(--el-border-color-lighter);
  display: flex;
  flex-direction: column;
}

.disk-menu {
  border-right: none;
}

.storage-info {
  padding: 20px;
  border-top: 1px solid var(--el-border-color-lighter);
  margin-top: auto;
}

.storage-title {
  font-size: 14px;
  color: var(--el-text-color-regular);
  margin-bottom: 10px;
}

.storage-text {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  margin-top: 8px;
  text-align: center;
}

.disk-content {
  background-color: var(--el-bg-color-page);
  padding: 20px;
  overflow-y: auto;
}

.toolbar {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

.search-input {
  width: 250px;
  margin-left: auto;
}

.breadcrumb {
  margin-bottom: 20px;
}

.file-name {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
}

.file-name:hover {
  color: var(--el-color-primary);
}

.file-icon {
  font-size: 24px;
}

:deep(.el-breadcrumb__item) {
  cursor: pointer;
}

:deep(.el-breadcrumb__item:hover) {
  color: var(--el-color-primary);
}

/* 预览对话框样式 */
.preview-content {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
  background-color: var(--el-fill-color-lighter);
  border-radius: 8px;
  overflow: hidden;
}

.preview-image {
  max-width: 100%;
  max-height: 500px;
  object-fit: contain;
}

.preview-video {
  max-width: 100%;
  max-height: 500px;
  object-fit: contain;
}

.preview-audio {
  width: 100%;
  max-width: 500px;
}

.preview-pdf {
  width: 100%;
  height: 500px;
  border: none;
}

.preview-text {
  width: 100%;
  max-height: 500px;
  overflow: auto;
  padding: 16px;
  margin: 0;
  background-color: #1e1e1e;
  color: #d4d4d4;
  font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
  font-size: 13px;
  line-height: 1.5;
  white-space: pre-wrap;
  word-break: break-all;
  border-radius: 4px;
}

.preview-hint {
  margin-top: 8px;
  font-size: 14px;
  color: var(--el-text-color-secondary);
}

.preview-not-supported {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: var(--el-text-color-secondary);
}

.preview-icon {
  margin-bottom: 16px;
}

/* 批量操作 */
.selected-count {
  color: var(--el-color-primary);
  font-weight: bold;
  align-self: center;
}

.move-hint {
  color: var(--el-text-color-regular);
  margin-bottom: 16px;
}

.move-folder-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 300px;
  overflow-y: auto;
}

.move-folder-item {
  padding: 8px 12px;
  border: 1px solid var(--el-border-color-lighter);
  border-radius: 6px;
  width: 100%;
}

.no-folders {
  color: var(--el-text-color-secondary);
  text-align: center;
  padding: 24px 0;
}

/* 备注 */
.remark-cell {
  display: flex;
  align-items: center;
  gap: 4px;
  cursor: pointer;
  min-height: 24px;
}

.remark-text {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 120px;
  font-size: 13px;
  color: var(--el-text-color-regular);
}

.remark-icon-empty {
  color: var(--el-text-color-placeholder);
  font-size: 14px;
}

.remark-icon-edit {
  color: var(--el-text-color-placeholder);
  font-size: 12px;
  flex-shrink: 0;
  opacity: 0;
  transition: opacity 0.2s;
}

.remark-cell:hover .remark-icon-edit {
  opacity: 1;
}

.remark-disabled {
  color: var(--el-text-color-placeholder);
}

.remark-editor {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.remark-actions {
  display: flex;
  justify-content: flex-end;
}

/* 图片查看器 */
.img-viewer-backdrop {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background: rgba(0, 0, 0, 0.85);
  user-select: none;
}

.img-viewer-backdrop.img-fullscreen {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

/* 浮动窗口 */
.img-viewer-window {
  position: fixed;
  z-index: 10000;
  background: var(--el-bg-color);
  border-radius: 8px;
  box-shadow: 0 16px 48px rgba(0, 0, 0, 0.5);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  min-width: 400px;
  min-height: 300px;
}

.img-viewer-titlebar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background: var(--el-bg-color-overlay);
  border-bottom: 1px solid var(--el-border-color-lighter);
  cursor: move;
  flex-shrink: 0;
}

.img-viewer-title {
  flex: 1;
  font-size: 13px;
  font-weight: 500;
  color: var(--el-text-color-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.img-viewer-zoom-label {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  min-width: 40px;
  text-align: center;
}

.img-viewer-actions {
  display: flex;
  align-items: center;
  gap: 2px;
}

.img-viewer-body {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  background: #1a1a1a;
  position: relative;
}

.img-viewer-image {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
  transition: transform 0.1s ease;
  pointer-events: auto;
}

/* 调整大小手柄 */
.resize-handle {
  position: absolute;
  z-index: 10;
}

.resize-se { bottom: 0; right: 0; width: 16px; height: 16px; cursor: se-resize; }
.resize-sw { bottom: 0; left: 0; width: 16px; height: 16px; cursor: sw-resize; }
.resize-ne { top: 0; right: 0; width: 16px; height: 16px; cursor: ne-resize; }
.resize-nw { top: 0; left: 0; width: 16px; height: 16px; cursor: nw-resize; }
.resize-e { top: 0; right: 0; width: 6px; height: 100%; cursor: e-resize; }
.resize-s { bottom: 0; left: 0; width: 100%; height: 6px; cursor: s-resize; }
.resize-n { top: 0; left: 0; width: 100%; height: 6px; cursor: n-resize; }
.resize-w { top: 0; left: 0; width: 6px; height: 100%; cursor: w-resize; }

/* 全屏模式 */
.img-fullscreen-toolbar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 10001;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 20px;
  background: rgba(0, 0, 0, 0.65);
  backdrop-filter: blur(8px);
  color: #fff;
}

.img-fullscreen-toolbar .img-viewer-title {
  color: #fff;
}

.img-fullscreen-toolbar .img-viewer-zoom-label {
  color: rgba(255, 255, 255, 0.8);
}

.img-fullscreen-toolbar .img-viewer-actions .el-button {
  color: #fff;
}

.img-fullscreen-body {
  position: fixed;
  inset: 0;
  z-index: 10000;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}
</style>
