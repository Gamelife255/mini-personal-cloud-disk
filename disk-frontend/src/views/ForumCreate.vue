<template>
  <div class="create-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>

    <el-header class="create-header">
      <div class="header-left">
        <el-button link @click="goBack" class="back-btn">
          <el-icon><ArrowLeft /></el-icon>
          {{ isEdit ? '返回主题' : '返回论坛' }}
        </el-button>
        <span class="title">{{ isEdit ? '编辑主题' : '发布新帖' }}</span>
      </div>
      <div class="header-right">
        <el-button link @click="toggleTheme">
          <el-icon :size="18"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
        </el-button>
      </div>
    </el-header>

    <div class="create-main" v-loading="loading">
      <el-form ref="formRef" :model="form" label-width="80px" class="create-form">
        <el-form-item label="分类" required>
          <el-select v-model="form.categoryId" placeholder="请选择分类" style="width: 100%">
            <el-option v-for="cat in categories" :key="cat.id" :label="cat.name" :value="cat.id" />
          </el-select>
        </el-form-item>

        <el-form-item label="标题" required>
          <el-input v-model="form.title" placeholder="输入标题" maxlength="200" show-word-limit />
        </el-form-item>

        <el-form-item label="标签">
          <el-select
            v-model="form.tags"
            multiple
            filterable
            allow-create
            default-first-option
            placeholder="选择或创建标签"
            style="width: 100%"
          >
            <el-option v-for="tag in allTags" :key="tag.id" :label="tag.name" :value="tag.name" />
          </el-select>
        </el-form-item>

        <el-form-item label="内容" required>
          <el-input
            v-model="form.content"
            type="textarea"
            :rows="12"
            placeholder="写下你的内容..."
          />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" :loading="submitting" @click="onSubmit">
            {{ isEdit ? '保存修改' : '发布' }}
          </el-button>
          <el-button @click="goBack">取消</el-button>
        </el-form-item>
      </el-form>
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
import { getCategories, getTags, getTopic, createTopic, updateTopic } from '../api/forum'

const { isDark, toggle: toggleTheme } = useDarkMode()
const { containerBackground, isCustom, bgLayerStyle } = useBackground('forum')

const route = useRoute()
const router = useRouter()
const isEdit = computed(() => route.name === 'ForumEdit')
const topicId = computed(() => route.params.id)

const categories = ref([])
const allTags = ref([])
const loading = ref(false)
const submitting = ref(false)

const form = ref({
  categoryId: null,
  title: '',
  content: '',
  tags: []
})

const loadData = async () => {
  loading.value = true
  try {
    const [catRes, tagRes] = await Promise.all([getCategories(), getTags()])
    if (catRes.code === 200) categories.value = catRes.data || []
    if (tagRes.code === 200) allTags.value = tagRes.data || []

    if (isEdit.value && topicId.value) {
      const topicRes = await getTopic(topicId.value)
      if (topicRes.code === 200) {
        const t = topicRes.data
        form.value.title = t.title || ''
        form.value.content = t.content || ''
        form.value.categoryId = t.categoryId || null
        form.value.tags = (t.tags || []).map(tag => tag.name)
      }
    }
  } catch {} finally { loading.value = false }
}

const onSubmit = async () => {
  if (!form.value.title.trim()) { ElMessage.warning('请输入标题'); return }
  if (!form.value.content.trim()) { ElMessage.warning('请输入内容'); return }
  if (!form.value.categoryId) { ElMessage.warning('请选择分类'); return }

  submitting.value = true
  try {
    const data = {
      title: form.value.title.trim(),
      content: form.value.content.trim(),
      categoryId: form.value.categoryId,
      tags: form.value.tags
    }
    if (isEdit.value) {
      const res = await updateTopic(topicId.value, data)
      if (res.code === 200) {
        ElMessage.success('更新成功')
        router.push(`/forum/topic/${topicId.value}`)
      } else {
        ElMessage.error(res.message || '更新失败')
      }
    } else {
      const res = await createTopic(data)
      if (res.code === 200) {
        ElMessage.success('发布成功')
        router.push(`/forum/topic/${res.data.id}`)
      } else {
        ElMessage.error(res.message || '发布失败')
      }
    }
  } catch { ElMessage.error('操作失败') } finally { submitting.value = false }
}

const goBack = () => {
  if (isEdit.value) {
    router.push(`/forum/topic/${topicId.value}`)
  } else {
    router.push('/forum')
  }
}

onMounted(loadData)
</script>

<style scoped>
.create-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  background: #f5f7fa;
}

.create-header {
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

.create-main {
  flex: 1;
  max-width: 800px;
  width: 100%;
  margin: 0 auto;
  padding: 24px 16px;
}

.create-form {
  background: #fff;
  border-radius: 8px;
  padding: 32px;
}

/* Dark mode */
:global(.dark) .create-container { background: #1a1a2e; }
:global(.dark) .create-header { background: #1e1e30; box-shadow: 0 1px 4px rgba(0,0,0,0.3); }
:global(.dark) .create-header .title { color: #e0e0e0; }
:global(.dark) .create-form { background: #1e1e30; }
</style>
