<template>
  <div class="disk-container">
    <!-- 顶部导航栏 -->
    <el-header class="disk-header">
      <div class="header-left">
        <span class="logo">☁️ 个人云盘</span>
      </div>
      <div class="header-right">
        <span class="username">{{ user?.username }}</span>
        <el-button type="text" @click="logout">退出登录</el-button>
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
        </el-menu>

        <!-- 存储空间 -->
        <div class="storage-info">
          <div class="storage-title">存储空间</div>
          <el-progress :percentage="storagePercent" :color="storageColor" />
          <div class="storage-text">{{ usedStorage }} / {{ totalStorage }}</div>
        </div>
      </el-aside>

      <!-- 右侧文件区 -->
      <el-main class="disk-content">
        <!-- 工具栏 -->
        <div class="toolbar">
          <el-button type="primary" @click="showUpload = true">
            <el-icon><Upload /></el-icon>上传文件
          </el-button>
          <el-button @click="showNewFolder = true">
            <el-icon><FolderAdd /></el-icon>新建文件夹
          </el-button>
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
        <el-table :data="filteredFiles" style="width: 100%" v-loading="loading">
          <el-table-column label="文件名" min-width="300">
            <template #default="{ row }">
              <div class="file-name" @click="handleFileClick(row)">
                <el-icon :size="24" class="file-icon">
                  <Folder v-if="row.isFolder" color="#409EFF" />
                  <Document v-else-if="isDocument(row.fileType)" color="#67C23A" />
                  <Picture v-else-if="isImage(row.fileType)" color="#E6A23C" />
                  <VideoCamera v-else-if="isVideo(row.fileType)" color="#F56C6C" />
                  <Files v-else color="#909399" />
                </el-icon>
                <span>{{ row.fileName }}</span>
              </div>
            </template>
          </el-table-column>
          <el-table-column label="大小" width="120">
            <template #default="{ row }">
              {{ row.isFolder ? '-' : formatFileSize(row.fileSize) }}
            </template>
          </el-table-column>
          <el-table-column label="修改时间" width="180">
            <template #default="{ row }">
              {{ formatDate(row.updatedAt) }}
            </template>
          </el-table-column>
          <el-table-column label="操作" width="150" fixed="right">
            <template #default="{ row }">
              <el-button type="text" @click="downloadFile(row)" v-if="!row.isFolder">
                <el-icon><Download /></el-icon>
              </el-button>
              <el-button type="text" @click="deleteFile(row)">
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
        action="/api/file/upload"
        :headers="uploadHeaders"
        :data="{ parentId: currentFolder }"
        :on-success="handleUploadSuccess"
        :on-error="handleUploadError"
        multiple
      >
        <el-icon class="el-icon--upload"><Upload /></el-icon>
        <div class="el-upload__text">
          拖拽文件到此处或 <em>点击上传</em>
        </div>
      </el-upload>
    </el-dialog>

    <!-- 新建文件夹对话框 -->
    <el-dialog v-model="showNewFolder" title="新建文件夹" width="400px">
      <el-input v-model="newFolderName" placeholder="请输入文件夹名称" />
      <template #footer>
        <el-button @click="showNewFolder = false">取消</el-button>
        <el-button type="primary" @click="createFolder">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'

const router = useRouter()
const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))

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

// 存储空间（模拟数据）
const usedStorage = ref('2.5GB')
const totalStorage = ref('10GB')
const storagePercent = ref(25)
const storageColor = ref('#409EFF')

// 上传请求头
const uploadHeaders = computed(() => ({
  Authorization: `Bearer ${localStorage.getItem('token')}`
}))

// 过滤后的文件列表
const filteredFiles = computed(() => {
  let result = files.value
  
  // 按类型过滤
  if (activeMenu.value !== 'all') {
    result = result.filter(file => {
      if (activeMenu.value === 'image') return isImage(file.fileType)
      if (activeMenu.value === 'video') return isVideo(file.fileType)
      if (activeMenu.value === 'document') return isDocument(file.fileType)
      if (activeMenu.value === 'other') {
        return !isImage(file.fileType) && !isVideo(file.fileType) && !isDocument(file.fileType) && !file.isFolder
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
    // 模拟数据，实际项目中调用API
    await new Promise(resolve => setTimeout(resolve, 500))
    files.value = [
      {
        id: 1,
        fileName: '文档',
        isFolder: true,
        fileSize: 0,
        fileType: 'folder',
        updatedAt: Date.now(),
        parentId: 0
      },
      {
        id: 2,
        fileName: '图片',
        isFolder: true,
        fileSize: 0,
        fileType: 'folder',
        updatedAt: Date.now(),
        parentId: 0
      },
      {
        id: 3,
        fileName: '测试文档.txt',
        isFolder: false,
        fileSize: 1024,
        fileType: 'text/plain',
        updatedAt: Date.now() - 86400000,
        parentId: 0
      },
      {
        id: 4,
        fileName: '示例图片.jpg',
        isFolder: false,
        fileSize: 2048000,
        fileType: 'image/jpeg',
        updatedAt: Date.now() - 172800000,
        parentId: 0
      },
      {
        id: 5,
        fileName: '演示视频.mp4',
        isFolder: false,
        fileSize: 52428800,
        fileType: 'video/mp4',
        updatedAt: Date.now() - 259200000,
        parentId: 0
      }
    ]
  } catch (error) {
    ElMessage.error('加载文件失败')
  } finally {
    loading.value = false
  }
}

// 文件类型判断
const isImage = (type) => type?.startsWith('image/')
const isVideo = (type) => type?.startsWith('video/')
const isDocument = (type) => {
  const docTypes = ['application/pdf', 'text/plain', 'application/msword', 
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
  return docTypes.includes(type)
}

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
const downloadFile = (file) => {
  ElMessage.success(`开始下载: ${file.fileName}`)
  // 实际项目中调用下载API
}

// 删除文件
const deleteFile = async (file) => {
  try {
    await ElMessageBox.confirm(`确定要删除 "${file.fileName}" 吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    ElMessage.success('删除成功')
    loadFiles()
  } catch {
    // 取消删除
  }
}

// 上传成功
const handleUploadSuccess = () => {
  ElMessage.success('上传成功')
  showUpload.value = false
  loadFiles()
}

// 上传失败
const handleUploadError = () => {
  ElMessage.error('上传失败')
}

// 创建文件夹
const createFolder = () => {
  if (!newFolderName.value.trim()) {
    ElMessage.warning('请输入文件夹名称')
    return
  }
  ElMessage.success(`创建文件夹: ${newFolderName.value}`)
  showNewFolder.value = false
  newFolderName.value = ''
  loadFiles()
}

// 退出登录
const logout = () => {
  localStorage.removeItem('token')
  localStorage.removeItem('user')
  router.push('/login')
}

onMounted(() => {
  loadFiles()
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
  background-color: #fff;
  border-bottom: 1px solid #e4e7ed;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.header-left .logo {
  font-size: 20px;
  font-weight: bold;
  color: #409EFF;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.username {
  color: #606266;
}

.disk-main {
  flex: 1;
  overflow: hidden;
}

.disk-sidebar {
  background-color: #fff;
  border-right: 1px solid #e4e7ed;
  display: flex;
  flex-direction: column;
}

.disk-menu {
  border-right: none;
}

.storage-info {
  padding: 20px;
  border-top: 1px solid #e4e7ed;
  margin-top: auto;
}

.storage-title {
  font-size: 14px;
  color: #606266;
  margin-bottom: 10px;
}

.storage-text {
  font-size: 12px;
  color: #909399;
  margin-top: 8px;
  text-align: center;
}

.disk-content {
  background-color: #f5f7fa;
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
  color: #409EFF;
}

.file-icon {
  font-size: 24px;
}

:deep(.el-breadcrumb__item) {
  cursor: pointer;
}

:deep(.el-breadcrumb__item:hover) {
  color: #409EFF;
}
</style>
