<template>
  <div class="stats-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>

    <el-header class="stats-header">
      <div class="header-left">
        <el-button link @click="goBack">
          <el-icon :size="18"><ArrowLeft /></el-icon>
          <span>返回云盘</span>
        </el-button>
        <span class="logo">数据统计</span>
      </div>
      <div class="header-right">
        <el-button link class="theme-toggle" @click="toggleTheme">
          <el-icon :size="18"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
        </el-button>
      </div>
    </el-header>

    <el-main class="stats-content" :style="isCustom ? { backgroundColor: 'transparent' } : {}">
      <!-- Overview cards -->
      <div class="overview-cards">
        <el-card class="overview-card">
          <div class="card-icon card-files">
            <el-icon :size="28"><Document /></el-icon>
          </div>
          <div class="card-info">
            <div class="card-value">{{ overview.totalFiles ?? '-' }}</div>
            <div class="card-label">文件总数</div>
          </div>
        </el-card>
        <el-card class="overview-card">
          <div class="card-icon card-folders">
            <el-icon :size="28"><Folder /></el-icon>
          </div>
          <div class="card-info">
            <div class="card-value">{{ overview.totalFolders ?? '-' }}</div>
            <div class="card-label">文件夹数</div>
          </div>
        </el-card>
        <el-card class="overview-card">
          <div class="card-icon card-space">
            <el-icon :size="28"><PieChart /></el-icon>
          </div>
          <div class="card-info">
            <div class="card-value">{{ formatSize(overview.usedSpace) }}</div>
            <div class="card-label">已用空间</div>
          </div>
        </el-card>
      </div>

      <!-- Charts row -->
      <div class="charts-row">
        <el-card class="chart-card">
          <template #header><span>文件类型分布</span></template>
          <div ref="typeChartRef" class="chart-box"></div>
          <div v-if="typeChartEmpty" class="chart-empty">暂无数据</div>
        </el-card>
        <el-card class="chart-card">
          <template #header><span>上传趋势（近30天）</span></template>
          <div ref="historyChartRef" class="chart-box"></div>
          <div v-if="historyChartEmpty" class="chart-empty">暂无数据</div>
        </el-card>
      </div>
    </el-main>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { useDarkMode } from '../composables/useDarkMode'
import { useBackground } from '../composables/useBackground'
import { getStatisticsOverview, getFileTypeDistribution, getUploadHistory } from '../api/statistics'
import { ElMessage } from 'element-plus'
import { ArrowLeft, Document, Folder, PieChart, Sunny, Moon } from '@element-plus/icons-vue'
import * as echarts from 'echarts'

const { isDark, toggle: toggleTheme } = useDarkMode()
const { containerBackground, isCustom, bgLayerStyle } = useBackground('statistics')
const router = useRouter()

const overview = ref({})
const typeChartRef = ref(null)
const historyChartRef = ref(null)
const typeChartEmpty = ref(false)
const historyChartEmpty = ref(false)

let typeChart = null
let historyChart = null

function goBack() {
  router.push('/disk')
}

function formatSize(bytes) {
  if (!bytes || bytes === 0) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(1024))
  return (bytes / Math.pow(1024, i)).toFixed(i > 0 ? 1 : 0) + ' ' + units[i]
}

function getChartColors() {
  return isDark.value
    ? ['#5470c6', '#91cc75', '#fac858', '#ee6666', '#73c0de', '#fc8452']
    : ['#5470c6', '#91cc75', '#fac858', '#ee6666', '#73c0de', '#fc8452']
}

async function loadData() {
  try {
    const [overviewRes, typesRes, historyRes] = await Promise.all([
      getStatisticsOverview(),
      getFileTypeDistribution(),
      getUploadHistory()
    ])

    if (overviewRes.code === 200) {
      overview.value = overviewRes.data
    }

    if (typesRes.code === 200 && typesRes.data?.length > 0) {
      await nextTick()
      if (typeChartRef.value) initTypeChart(typesRes.data)
    } else {
      typeChartEmpty.value = true
    }

    if (historyRes.code === 200 && historyRes.data?.length > 0) {
      await nextTick()
      if (historyChartRef.value) initHistoryChart(historyRes.data)
    } else {
      historyChartEmpty.value = true
    }
  } catch (e) {
    console.error('Statistics load error:', e)
    const msg = e?.response?.status === 404
      ? '统计服务未启动，请重启后端服务'
      : (e?.response?.data?.message || e?.message || '加载统计数据失败')
    ElMessage.error(msg)
  }
}

function initTypeChart(data) {
  if (!typeChartRef.value) return
  if (typeChart) typeChart.dispose()

  typeChart = echarts.init(typeChartRef.value)
  typeChart.setOption({
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, textStyle: { color: isDark.value ? '#ccc' : '#666' } },
    series: [{
      type: 'pie',
      radius: ['45%', '70%'],
      center: ['50%', '45%'],
      avoidLabelOverlap: false,
      itemStyle: { borderRadius: 4, borderColor: isDark.value ? '#1e1e1e' : '#fff', borderWidth: 2 },
      label: { show: true, formatter: '{b}\n{d}%' },
      emphasis: { label: { fontSize: 16, fontWeight: 'bold' } },
      data
    }]
  })
}

function initHistoryChart(data) {
  if (!historyChartRef.value) return
  if (historyChart) historyChart.dispose()

  historyChart = echarts.init(historyChartRef.value)
  const dates = data.map(d => d.date)
  const counts = data.map(d => d.count)

  historyChart.setOption({
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '3%', top: '8%', containLabel: true },
    xAxis: {
      type: 'category',
      data: dates,
      axisLabel: { rotate: 45, fontSize: 11, color: isDark.value ? '#aaa' : '#666' },
      axisLine: { lineStyle: { color: isDark.value ? '#555' : '#ccc' } }
    },
    yAxis: {
      type: 'value',
      minInterval: 1,
      axisLabel: { color: isDark.value ? '#aaa' : '#666' },
      splitLine: { lineStyle: { color: isDark.value ? '#333' : '#eee' } }
    },
    series: [{
      type: 'bar',
      data: counts,
      itemStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: '#5470c6' },
          { offset: 1, color: '#91cc75' }
        ]),
        borderRadius: [4, 4, 0, 0]
      }
    }]
  })
}

function handleResize() {
  typeChart?.resize()
  historyChart?.resize()
}

onMounted(() => {
  loadData()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  typeChart?.dispose()
  historyChart?.dispose()
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
.stats-container {
  min-height: 100vh;
  background: var(--el-bg-color-page);
}

.stats-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: var(--el-bg-color);
  border-bottom: 1px solid var(--el-border-color-light);
  padding: 0 24px;
  height: 56px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logo {
  font-size: 18px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.header-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.stats-content {
  max-width: 1100px;
  margin: 0 auto;
  padding: 24px 20px;
}

.overview-cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.overview-card {
  display: flex;
  flex-direction: row;
}

.overview-card :deep(.el-card__body) {
  display: flex;
  align-items: center;
  gap: 16px;
  width: 100%;
}

.card-icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.card-files { background: rgba(84, 112, 198, 0.15); color: #5470c6; }
.card-folders { background: rgba(145, 204, 117, 0.15); color: #91cc75; }
.card-space { background: rgba(250, 200, 88, 0.15); color: #fac858; }

.card-value {
  font-size: 24px;
  font-weight: 700;
  color: var(--el-text-color-primary);
  line-height: 1.2;
}

.card-label {
  font-size: 13px;
  color: var(--el-text-color-secondary);
  margin-top: 2px;
}

.charts-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.chart-box {
  width: 100%;
  height: 360px;
}

.chart-empty {
  height: 360px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--el-text-color-placeholder);
  font-size: 14px;
}

@media (max-width: 768px) {
  .overview-cards { grid-template-columns: 1fr; }
  .charts-row { grid-template-columns: 1fr; }
}
</style>
