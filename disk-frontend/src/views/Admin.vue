<template>
  <div class="admin-container">
    <el-header class="admin-header">
      <div class="header-left">
        <span class="logo">☁️ 管理后台</span>
      </div>
      <div class="header-right">
        <el-button link class="theme-toggle" @click="toggleTheme">
          <el-icon :size="18"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
        </el-button>
        <span class="username">{{ user?.username }}</span>
        <el-button link @click="goToDisk">返回云盘</el-button>
        <el-button link @click="logout">退出登录</el-button>
      </div>
    </el-header>

    <el-container class="admin-main">
      <el-main>
        <el-tabs v-model="activeTab">
          <el-tab-pane label="用户管理" name="users">
            <el-table :data="users" v-loading="loadingUsers" style="width: 100%">
              <el-table-column prop="id" label="ID" width="80" />
              <el-table-column prop="username" label="用户名" width="150" />
              <el-table-column prop="email" label="邮箱" width="200" />
              <el-table-column label="角色" width="100">
                <template #default="{ row }">
                  <el-tag :type="row.role === 'admin' ? 'danger' : 'info'" size="small">
                    {{ row.role === 'admin' ? '管理员' : '普通用户' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="状态" width="100">
                <template #default="{ row }">
                  <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
                    {{ row.status === 1 ? '正常' : '已禁用' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="注册时间" min-width="160">
                <template #default="{ row }">
                  {{ formatDate(row.createdAt) }}
                </template>
              </el-table-column>
              <el-table-column label="操作" width="250" fixed="right">
                <template #default="{ row }">
                  <el-button
                    link
                    :type="row.status === 1 ? 'warning' : 'success'"
                    @click="toggleUserStatus(row)"
                    :disabled="row.id === user?.id"
                  >
                    {{ row.status === 1 ? '禁用' : '启用' }}
                  </el-button>
                  <el-button link type="primary" @click="showResetDialog(row)">重置密码</el-button>
                  <el-button link type="primary" @click="viewUserFiles(row)">查看文件</el-button>
                </template>
              </el-table-column>
            </el-table>
          </el-tab-pane>

          <el-tab-pane label="文件浏览" name="files">
            <div class="file-browser-top">
              <el-select v-model="selectedUserId" placeholder="选择用户" @change="loadUserFiles" style="width: 240px">
                <el-option
                  v-for="u in users"
                  :key="u.id"
                  :label="`${u.username} (${u.email || '无邮箱'})`"
                  :value="u.id"
                />
              </el-select>
            </div>
            <el-table :data="userFiles" v-loading="loadingFiles" style="width: 100%; margin-top: 16px">
              <el-table-column label="文件名" min-width="300">
                <template #default="{ row }">
                  <div class="file-name-cell">
                    <el-icon :size="20">
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
              <el-table-column label="类型" width="120">
                <template #default="{ row }">
                  {{ row.isFolder ? '文件夹' : (row.fileType || '未知') }}
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
            </el-table>
            <el-empty v-if="selectedUserId && userFiles.length === 0 && !loadingFiles" description="该用户暂无文件" />
          </el-tab-pane>
        </el-tabs>
      </el-main>
    </el-container>

    <!-- 重置密码对话框 -->
    <el-dialog v-model="showReset" title="重置密码" width="400px">
      <el-input v-model="newPassword" type="password" placeholder="请输入新密码（至少6位）" />
      <p class="reset-hint">正在为用户 <strong>{{ resetTarget?.username }}</strong> 重置密码</p>
      <template #footer>
        <el-button @click="showReset = false">取消</el-button>
        <el-button type="primary" @click="handleResetPassword" :loading="resetting">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getUsers, updateUserStatus, resetUserPassword, getUserFiles } from '../api/admin'
import { useDarkMode } from '../composables/useDarkMode'
import {
  Folder, Document, Picture, VideoCamera, Files, Sunny, Moon
} from '@element-plus/icons-vue'

const router = useRouter()
const { isDark, toggle: toggleTheme } = useDarkMode()
const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))

const activeTab = ref('users')
const loadingUsers = ref(false)
const loadingFiles = ref(false)
const users = ref([])
const selectedUserId = ref(null)
const userFiles = ref([])

// 重置密码
const showReset = ref(false)
const resetTarget = ref(null)
const newPassword = ref('')
const resetting = ref(false)

const isImage = (type, fileName) => type?.startsWith('image/') || fileName?.toLowerCase()?.endsWith('.psd')
const isVideo = (type) => type?.startsWith('video/')
const isDocument = (type) => {
  const docTypes = ['application/pdf', 'text/plain', 'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
  return docTypes.includes(type)
}

const formatFileSize = (bytes) => {
  if (!bytes || bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const formatDate = (timestamp) => {
  if (!timestamp) return ''
  return new Date(timestamp).toLocaleString('zh-CN')
}

const loadUsers = async () => {
  loadingUsers.value = true
  try {
    const response = await getUsers()
    if (response.code === 200) {
      users.value = response.data
    } else {
      ElMessage.error(response.message || '加载用户列表失败')
    }
  } catch (error) {
    ElMessage.error('加载用户列表失败')
  } finally {
    loadingUsers.value = false
  }
}

const toggleUserStatus = async (row) => {
  const newStatus = row.status === 1 ? 0 : 1
  const action = newStatus === 0 ? '禁用' : '启用'
  try {
    await ElMessageBox.confirm(`确定要${action}用户 "${row.username}" 吗？`, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    const response = await updateUserStatus(row.id, newStatus)
    if (response.code === 200) {
      ElMessage.success(response.message)
      row.status = newStatus
    } else {
      ElMessage.error(response.message || '操作失败')
    }
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('操作失败')
    }
  }
}

const showResetDialog = (row) => {
  resetTarget.value = row
  newPassword.value = ''
  showReset.value = true
}

const handleResetPassword = async () => {
  if (!newPassword.value || newPassword.value.length < 6) {
    ElMessage.warning('密码不能少于6位')
    return
  }
  resetting.value = true
  try {
    const response = await resetUserPassword(resetTarget.value.id, newPassword.value)
    if (response.code === 200) {
      ElMessage.success('密码重置成功')
      showReset.value = false
    } else {
      ElMessage.error(response.message || '重置失败')
    }
  } catch (error) {
    ElMessage.error('重置失败')
  } finally {
    resetting.value = false
  }
}

const viewUserFiles = (row) => {
  selectedUserId.value = row.id
  activeTab.value = 'files'
  loadUserFiles()
}

const loadUserFiles = async () => {
  if (!selectedUserId.value) return
  loadingFiles.value = true
  try {
    const response = await getUserFiles(selectedUserId.value)
    if (response.code === 200) {
      userFiles.value = response.data.map(file => ({
        id: file.id,
        fileName: file.fileName,
        isFolder: file.isFolder === 1,
        fileSize: file.fileSize,
        fileType: file.fileType,
        updatedAt: file.updatedAt
      }))
    } else {
      ElMessage.error(response.message || '加载文件失败')
    }
  } catch (error) {
    ElMessage.error('加载文件失败')
  } finally {
    loadingFiles.value = false
  }
}

const goToDisk = () => {
  router.push('/disk')
}

const logout = () => {
  localStorage.removeItem('token')
  localStorage.removeItem('user')
  router.push('/login')
}

onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
.admin-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.admin-header {
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

.username {
  color: var(--el-text-color-regular);
}

.admin-main {
  flex: 1;
  overflow: hidden;
}

.admin-main .el-main {
  padding: 20px;
  overflow-y: auto;
}

.file-browser-top {
  display: flex;
  align-items: center;
  gap: 12px;
}

.file-name-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.reset-hint {
  color: var(--el-text-color-secondary);
  font-size: 13px;
  margin-top: 12px;
}
</style>
