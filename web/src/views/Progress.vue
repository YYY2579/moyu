<template>
  <div class="progress-page">
    <el-container>
      <el-header class="page-header">
        <div class="header-content">
          <el-button type="text" @click="goBack" class="back-btn">
            ← 返回首页
          </el-button>
          <h1>📊 学习进度</h1>
        </div>
      </el-header>

      <el-main class="main-content">
        <!-- 学习概览 -->
        <el-row :gutter="20" class="overview-stats">
          <el-col :xs="12" :sm="6">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon">📚</div>
                <div class="stat-info">
                  <div class="stat-number">{{ totalQuestions }}</div>
                  <div class="stat-label">总答题数</div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :xs="12" :sm="6">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon">✅</div>
                <div class="stat-info">
                  <div class="stat-number">{{ correctAnswers }}</div>
                  <div class="stat-label">正确题数</div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :xs="12" :sm="6">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon">🎯</div>
                <div class="stat-info">
                  <div class="stat-number">{{ accuracy }}%</div>
                  <div class="stat-label">正确率</div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :xs="12" :sm="6">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon">🔥</div>
                <div class="stat-info">
                  <div class="stat-number">{{ studyDays }}</div>
                  <div class="stat-label">连续天数</div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 学习进度图表 -->
        <el-row :gutter="20" class="charts-section">
          <el-col :xs="24" :md="16">
            <el-card class="chart-card">
              <template #header>
                <div class="chart-header">
                  <span>📈 学习趋势</span>
                  <el-radio-group v-model="chartPeriod" size="small">
                    <el-radio-button label="7天" />
                    <el-radio-button label="30天" />
                    <el-radio-button label="全部" />
                  </el-radio-group>
                </div>
              </template>
              <div class="chart-container">
                <div class="chart-placeholder">
                  <el-icon size="48px" color="#ddd"><TrendCharts /></el-icon>
                  <p>学习趋势图表</p>
                  <p class="chart-desc">显示不同时间段的学习进度和答题情况</p>
                </div>
              </div>
            </el-card>
          </el-col>
          
          <el-col :xs="24" :md="8">
            <el-card class="chart-card">
              <template #header>
                <span>🏆 成就徽章</span>
              </template>
              <div class="achievements-grid">
                <div 
                  v-for="achievement in achievements" 
                  :key="achievement.id"
                  class="achievement-item"
                  :class="{ 'unlocked': achievement.unlocked }"
                >
                  <div class="achievement-icon">{{ achievement.icon }}</div>
                  <div class="achievement-info">
                    <div class="achievement-title">{{ achievement.title }}</div>
                    <div class="achievement-desc">{{ achievement.description }}</div>
                  </div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 分类进度 -->
        <el-card class="category-progress">
          <template #header>
            <span>📋 分类学习进度</span>
          </template>
          
          <el-row :gutter="20">
            <el-col :xs="24" :md="12" :lg="6" v-for="category in categoryProgress" :key="category.id">
              <div class="category-item">
                <div class="category-header">
                  <span class="category-icon">{{ category.icon }}</span>
                  <span class="category-name">{{ category.name }}</span>
                </div>
                <div class="category-stats">
                  <div class="progress-info">
                    <span class="progress-text">{{ category.completed }}/{{ category.total }} 完成</span>
                    <span class="progress-percentage">{{ category.percentage }}%</span>
                  </div>
                  <el-progress 
                    :percentage="category.percentage" 
                    :color="getProgressColor(category.percentage)"
                    :show-text="false"
                    :stroke-width="6"
                  />
                </div>
                <div class="category-details">
                  <div class="detail-item">
                    <span>最近学习：</span>
                    <span>{{ category.lastStudy }}</span>
                  </div>
                  <div class="detail-item">
                    <span>掌握程度：</span>
                    <el-tag :type="getMasteryType(category.mastery)" size="small">
                      {{ category.mastery }}
                    </el-tag>
                  </div>
                </div>
              </div>
            </el-col>
          </el-row>
        </el-card>

        <!-- 详细学习记录 -->
        <el-card class="study-records">
          <template #header>
            <div class="records-header">
              <span>📖 学习记录</span>
              <div class="filter-controls">
                <el-select v-model="recordFilter" placeholder="筛选类型" size="small" style="width: 120px;">
                  <el-option label="全部" value="all" />
                  <el-option label="Linux" value="linux" />
                  <el-option label="Docker" value="docker" />
                  <el-option label="Shell" value="shell" />
                </el-select>
                <el-date-picker
                  v-model="dateRange"
                  type="daterange"
                  range-separator="至"
                  start-placeholder="开始日期"
                  end-placeholder="结束日期"
                  size="small"
                  style="width: 240px;"
                />
              </div>
            </div>
          </template>

          <el-table :data="filteredRecords" stripe style="width: 100%">
            <el-table-column prop="time" label="时间" width="180">
              <template #default="{ row }">
                <div class="time-info">
                  <div>{{ formatDate(row.date) }}</div>
                  <div class="time-detail">{{ row.time }}</div>
                </div>
              </template>
            </el-table-column>
            <el-table-column prop="category" label="分类" width="120">
              <template #default="{ row }">
                <el-tag :type="getCategoryType(row.category)" size="small">
                  {{ getCategoryName(row.category) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="topic" label="学习主题" min-width="200" />
            <el-table-column prop="type" label="类型" width="100">
              <template #default="{ row }">
                <el-tag :type="getTypeColor(row.type)" size="small" plain>
                  {{ row.type }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="result" label="结果" width="120">
              <template #default="{ row }">
                <div v-if="row.type === '练习'" class="result-info">
                  <span>{{ row.correct }}/{{ row.total }}</span>
                  <el-progress 
                    :percentage="Math.round((row.correct / row.total) * 100)" 
                    :color="getScoreColor(row.correct, row.total)"
                    :show-text="false"
                    :stroke-width="4"
                    style="width: 40px; margin-left: 8px;"
                  />
                </div>
                <span v-else>✅ 已完成</span>
              </template>
            </el-table-column>
            <el-table-column prop="duration" label="用时" width="80" />
            <el-table-column label="操作" width="100">
              <template #default="{ row }">
                <el-button type="text" size="small" @click="viewDetail(row)">
                  详情
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>

        <!-- 学习建议 -->
        <el-card class="study-suggestions">
          <template #header>
            <span>💡 学习建议</span>
          </template>
          
          <div class="suggestions-grid">
            <div v-for="suggestion in suggestions" :key="suggestion.id" class="suggestion-item">
              <div class="suggestion-icon">{{ suggestion.icon }}</div>
              <div class="suggestion-content">
                <h4>{{ suggestion.title }}</h4>
                <p>{{ suggestion.description }}</p>
                <el-button type="primary" size="small" @click="applySuggestion(suggestion)">
                  {{ suggestion.action }}
                </el-button>
              </div>
            </div>
          </div>
        </el-card>
      </el-main>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { TrendCharts } from '@element-plus/icons-vue'

interface CategoryProgress {
  id: string
  name: string
  icon: string
  completed: number
  total: number
  percentage: number
  lastStudy: string
  mastery: '入门' | '掌握' | '熟练' | '精通'
}

interface Achievement {
  id: number
  title: string
  description: string
  icon: string
  unlocked: boolean
}

interface StudyRecord {
  id: number
  date: string
  time: string
  category: string
  topic: string
  type: string
  correct?: number
  total?: number
  duration: string
}

interface Suggestion {
  id: number
  title: string
  description: string
  icon: string
  action: string
  link?: string
}

const router = useRouter()

const chartPeriod = ref('7天')
const recordFilter = ref('all')
const dateRange = ref<[Date, Date] | null>(null)

const totalQuestions = ref(156)
const correctAnswers = ref(132)
const accuracy = computed(() => Math.round((correctAnswers.value / totalQuestions.value) * 100))
const studyDays = ref(15)

const achievements: Achievement[] = [
  {
    id: 1,
    title: '初学者',
    description: '完成10道题',
    icon: '🌟',
    unlocked: true
  },
  {
    id: 2,
    title: '坚持者',
    description: '连续学习7天',
    icon: '🔥',
    unlocked: true
  },
  {
    id: 3,
    title: '知识达人',
    description: '完成100道题',
    icon: '🎓',
    unlocked: true
  },
  {
    id: 4,
    title: '完美主义者',
    description: '单次练习满分',
    icon: '💯',
    unlocked: false
  },
  {
    id: 5,
    title: 'Linux专家',
    description: '掌握所有Linux命令',
    icon: '🐧',
    unlocked: false
  },
  {
    id: 6,
    title: 'Docker大师',
    description: '完成所有Docker题目',
    icon: '🐳',
    unlocked: false
  }
]

const categoryProgress: CategoryProgress[] = [
  {
    id: 'linux',
    name: 'Linux命令',
    icon: '🐧',
    completed: 45,
    total: 60,
    percentage: 75,
    lastStudy: '2小时前',
    mastery: '掌握'
  },
  {
    id: 'docker',
    name: 'Docker技术',
    icon: '🐳',
    completed: 28,
    total: 40,
    percentage: 70,
    lastStudy: '1天前',
    mastery: '掌握'
  },
  {
    id: 'shell',
    name: 'Shell脚本',
    icon: '📜',
    completed: 18,
    total: 30,
    percentage: 60,
    lastStudy: '3天前',
    mastery: '入门'
  },
  {
    id: 'network',
    name: '网络知识',
    icon: '🌐',
    completed: 12,
    total: 25,
    percentage: 48,
    lastStudy: '1周前',
    mastery: '入门'
  }
]

const studyRecords: StudyRecord[] = [
  {
    id: 1,
    date: '2023-12-28',
    time: '14:30',
    category: 'linux',
    topic: 'Linux文件操作基础',
    type: '练习',
    correct: 22,
    total: 25,
    duration: '15分钟'
  },
  {
    id: 2,
    date: '2023-12-28',
    time: '10:15',
    category: 'docker',
    topic: 'Docker基础概念',
    type: '练习',
    correct: 18,
    total: 18,
    duration: '12分钟'
  },
  {
    id: 3,
    date: '2023-12-27',
    time: '19:45',
    category: 'shell',
    topic: 'Shell脚本基础语法',
    type: '学习',
    duration: '25分钟'
  },
  {
    id: 4,
    date: '2023-12-27',
    time: '15:20',
    category: 'linux',
    topic: 'Linux权限管理',
    type: '练习',
    correct: 15,
    total: 20,
    duration: '18分钟'
  }
]

const suggestions: Suggestion[] = [
  {
    id: 1,
    title: '加强Shell脚本学习',
    description: '您的Shell脚本掌握程度相对较弱，建议多加练习',
    icon: '📝',
    action: '开始练习',
    link: '/practice'
  },
  {
    id: 2,
    title: '复习网络知识',
    description: '已经有一周没有学习网络知识了，该复习一下了',
    icon: '🔄',
    action: '开始复习',
    link: '/linux'
  },
  {
    id: 3,
    title: '尝试模拟考试',
    description: '基础知识已经掌握得不错，可以挑战模拟考试',
    icon: '🎯',
    action: '开始考试',
    link: '/practice'
  }
]

const filteredRecords = computed(() => {
  let records = [...studyRecords]
  
  if (recordFilter.value !== 'all') {
    records = records.filter(record => record.category === recordFilter.value)
  }
  
  if (dateRange.value) {
    const [start, end] = dateRange.value
    records = records.filter(record => {
      const recordDate = new Date(record.date)
      return recordDate >= start && recordDate <= end
    })
  }
  
  return records
})

const getProgressColor = (percentage: number) => {
  if (percentage >= 80) return '#67c23a'
  if (percentage >= 60) return '#e6a23c'
  return '#f56c6c'
}

const getMasteryType = (mastery: string) => {
  switch (mastery) {
    case '精通': return 'danger'
    case '熟练': return 'warning'
    case '掌握': return 'primary'
    case '入门': return 'info'
    default: return 'info'
  }
}

const getCategoryType = (category: string) => {
  switch (category) {
    case 'linux': return 'primary'
    case 'docker': return 'success'
    case 'shell': return 'warning'
    case 'network': return 'danger'
    default: return 'info'
  }
}

const getCategoryName = (category: string) => {
  switch (category) {
    case 'linux': return 'Linux'
    case 'docker': return 'Docker'
    case 'shell': return 'Shell'
    case 'network': return '网络'
    default: return category
  }
}

const getTypeColor = (type: string) => {
  return type === '练习' ? 'primary' : 'success'
}

const getScoreColor = (correct: number, total: number) => {
  const percentage = (correct / total) * 100
  if (percentage >= 80) return '#67c23a'
  if (percentage >= 60) return '#e6a23c'
  return '#f56c6c'
}

const formatDate = (dateStr: string) => {
  const date = new Date(dateStr)
  return `${date.getMonth() + 1}月${date.getDate()}日`
}

const viewDetail = (record: StudyRecord) => {
  ElMessage.info(`查看${record.topic}的详细记录`)
}

const applySuggestion = (suggestion: Suggestion) => {
  if (suggestion.link) {
    router.push(suggestion.link)
  } else {
    ElMessage.info(`应用建议：${suggestion.title}`)
  }
}

const goBack = () => {
  router.push('/')
}

onMounted(() => {
  console.log('Progress page loaded')
})
</script>

<style scoped>
.progress-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.page-header {
  background: linear-gradient(135deg, #409eff 0%, #364d79 100%);
  color: white;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.header-content {
  max-width: 1400px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  gap: 20px;
}

.back-btn {
  color: white;
  font-size: 16px;
  padding: 8px 16px;
}

.back-btn:hover {
  background: rgba(255,255,255,0.1);
}

.header-content h1 {
  margin: 0;
  font-size: 28px;
  font-weight: 600;
}

.main-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 30px 20px;
}

.overview-stats {
  margin-bottom: 30px;
}

.stat-card {
  border: none;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transition: transform 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-4px);
}

.stat-content {
  display: flex;
  align-items: center;
  padding: 20px;
}

.stat-icon {
  font-size: 36px;
  margin-right: 16px;
}

.stat-number {
  font-size: 28px;
  font-weight: 700;
  color: #409eff;
  line-height: 1;
}

.stat-label {
  font-size: 14px;
  color: #666;
  margin-top: 4px;
}

.charts-section {
  margin-bottom: 30px;
}

.chart-card {
  border: none;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  height: 400px;
}

.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chart-container {
  height: 320px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.chart-placeholder {
  text-align: center;
  color: #999;
}

.chart-placeholder p {
  margin: 8px 0;
}

.chart-desc {
  font-size: 12px;
  color: #ccc;
}

.achievements-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 16px;
  max-height: 320px;
  overflow-y: auto;
}

.achievement-item {
  text-align: center;
  padding: 16px;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.achievement-item.unlocked {
  background: linear-gradient(135deg, #f0f9ff 0%, #e8f4ff 100%);
  border: 1px solid #409eff;
}

.achievement-item:not(.unlocked) {
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  opacity: 0.6;
}

.achievement-icon {
  font-size: 32px;
  margin-bottom: 8px;
}

.achievement-title {
  font-size: 14px;
  font-weight: 600;
  color: #333;
  margin-bottom: 4px;
}

.achievement-desc {
  font-size: 12px;
  color: #666;
  line-height: 1.4;
}

.category-progress,
.study-records,
.study-suggestions {
  border: none;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  margin-bottom: 30px;
}

.category-item {
  padding: 20px;
  border: 1px solid #e9ecef;
  border-radius: 12px;
  background: white;
  margin-bottom: 16px;
}

.category-header {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
}

.category-icon {
  font-size: 24px;
  margin-right: 12px;
}

.category-name {
  font-size: 16px;
  font-weight: 600;
  color: #333;
}

.category-stats {
  margin-bottom: 16px;
}

.progress-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.progress-text {
  font-size: 14px;
  color: #666;
}

.progress-percentage {
  font-size: 14px;
  font-weight: 600;
  color: #409eff;
}

.category-details {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #999;
}

.records-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.filter-controls {
  display: flex;
  gap: 12px;
  align-items: center;
}

.time-info {
  line-height: 1.4;
}

.time-detail {
  font-size: 12px;
  color: #999;
}

.result-info {
  display: flex;
  align-items: center;
}

.suggestions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.suggestion-item {
  display: flex;
  align-items: flex-start;
  padding: 20px;
  background: linear-gradient(135deg, #f8f9ff 0%, #f0f9ff 100%);
  border: 1px solid #e3f2fd;
  border-radius: 12px;
}

.suggestion-icon {
  font-size: 32px;
  margin-right: 16px;
  margin-top: 4px;
}

.suggestion-content {
  flex: 1;
}

.suggestion-content h4 {
  margin: 0 0 8px 0;
  font-size: 16px;
  color: #333;
}

.suggestion-content p {
  margin: 0 0 16px 0;
  color: #666;
  line-height: 1.6;
  font-size: 14px;
}

@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }
  
  .header-content h1 {
    font-size: 24px;
  }
  
  .main-content {
    padding: 20px 15px;
  }
  
  .chart-card {
    height: 300px;
  }
  
  .chart-container {
    height: 220px;
  }
  
  .achievements-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .records-header {
    flex-direction: column;
    gap: 12px;
    align-items: stretch;
  }
  
  .filter-controls {
    justify-content: space-between;
  }
  
  .category-details {
    flex-direction: column;
    gap: 4px;
  }
  
  .suggestions-grid {
    grid-template-columns: 1fr;
  }
}
</style>