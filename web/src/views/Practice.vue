<template>
  <div class="practice-page">
    <el-container>
      <el-header class="page-header">
        <div class="header-content">
          <el-button type="text" @click="goBack" class="back-btn">
            ← 返回首页
          </el-button>
          <h1>✏️ 题库练习</h1>
        </div>
      </el-header>

      <el-main class="main-content">
        <!-- 练习模式选择 -->
        <el-row :gutter="20" class="practice-modes">
          <el-col :xs="24" :md="8" v-for="mode in practiceModes" :key="mode.id">
            <el-card 
              class="mode-card" 
              shadow="hover"
              @click="selectPracticeMode(mode)"
            >
              <div class="mode-content">
                <div class="mode-icon">{{ mode.icon }}</div>
                <h3>{{ mode.title }}</h3>
                <p>{{ mode.description }}</p>
                <div class="mode-stats">
                  <span class="stat">{{ mode.questionsCount }} 道题</span>
                  <span class="stat">⏱️ {{ mode.estimatedTime }}</span>
                </div>
                <el-button 
                  :type="mode.type" 
                  size="large" 
                  class="mode-btn"
                  @click.stop="selectPracticeMode(mode)"
                >
                  {{ mode.buttonText }}
                </el-button>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 题库分类 -->
        <el-card class="question-categories">
          <template #header>
            <div class="section-header">
              <span>📚 题库分类</span>
              <el-input 
                v-model="searchQuery" 
                placeholder="搜索题目..." 
                prefix-icon="Search"
                clearable
                style="width: 250px;"
                @input="handleSearch"
              />
            </div>
          </template>

          <el-tabs v-model="activeCategory" type="card" @tab-click="handleCategoryChange">
            <el-tab-pane 
              v-for="category in categories" 
              :key="category.id"
              :label="`${category.icon} ${category.name} (${category.count})`" 
              :name="category.id"
            >
              <div class="category-content">
                <el-row :gutter="16">
                  <el-col 
                    :xs="24" :sm="12" :md="8"
                    v-for="topic in filteredTopics" 
                    :key="topic.id"
                  >
                    <div class="topic-card" @click="startTopicPractice(topic)">
                      <div class="topic-header">
                        <h4>{{ topic.title }}</h4>
                        <el-tag :type="getDifficultyType(topic.difficulty)" size="small">
                          {{ topic.difficulty }}
                        </el-tag>
                      </div>
                      <p class="topic-desc">{{ topic.description }}</p>
                      <div class="topic-stats">
                        <span class="topic-stat">{{ topic.questionsCount }} 题</span>
                        <span class="topic-stat">✅ {{ topic.completedCount }} 已完成</span>
                      </div>
                      <el-progress 
                        :percentage="topic.progress" 
                        :color="getProgressColor(topic.progress)"
                        :show-text="false"
                        :stroke-width="4"
                      />
                    </div>
                  </el-col>
                </el-row>
              </div>
            </el-tab-pane>
          </el-tabs>
        </el-card>

        <!-- 练习历史 -->
        <el-card class="practice-history">
          <template #header>
            <div class="section-header">
              <span>📖 练习历史</span>
              <el-link type="primary" @click="viewAllHistory">查看全部</el-link>
            </div>
          </template>

          <el-empty v-if="!practiceHistory.length" description="暂无练习记录" />
          <el-timeline v-else>
            <el-timeline-item
              v-for="(record, index) in practiceHistory.slice(0, 5)"
              :key="index"
              :timestamp="record.time"
              placement="top"
            >
              <el-card class="history-item">
                <div class="history-header">
                  <span class="history-title">{{ record.topic }}</span>
                  <el-tag :type="getScoreType(record.score)" size="small">
                    {{ record.score }}%
                  </el-tag>
                </div>
                <p class="history-desc">{{ record.description }}</p>
                <div class="history-stats">
                  <span>✅ {{ record.correct }}/{{ record.total }} 正确</span>
                  <span>⏱️ {{ record.duration }}</span>
                </div>
              </el-card>
            </el-timeline-item>
          </el-timeline>
        </el-card>
      </el-main>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'

interface PracticeMode {
  id: string
  title: string
  description: string
  icon: string
  questionsCount: number
  estimatedTime: string
  buttonText: string
  type: 'primary' | 'success' | 'warning'
}

interface Category {
  id: string
  name: string
  icon: string
  count: number
}

interface Topic {
  id: number
  title: string
  description: string
  category: string
  difficulty: '初级' | '中级' | '高级'
  questionsCount: number
  completedCount: number
  progress: number
}

interface HistoryRecord {
  topic: string
  time: string
  score: number
  correct: number
  total: number
  duration: string
  description: string
}

const router = useRouter()

const activeCategory = ref('linux')
const searchQuery = ref('')

const practiceModes: PracticeMode[] = [
  {
    id: 'random',
    title: '随机练习',
    description: '随机选择题目进行练习，适合日常复习',
    icon: '🎲',
    questionsCount: 50,
    estimatedTime: '30分钟',
    buttonText: '开始随机练习',
    type: 'primary'
  },
  {
    id: 'daily',
    title: '每日挑战',
    description: '每天精选题目，提升技术水平',
    icon: '📅',
    questionsCount: 20,
    estimatedTime: '15分钟',
    buttonText: '开始今日挑战',
    type: 'success'
  },
  {
    id: 'exam',
    title: '模拟考试',
    description: '完整模拟考试，检验学习成果',
    icon: '📝',
    questionsCount: 100,
    estimatedTime: '60分钟',
    buttonText: '开始模拟考试',
    type: 'warning'
  }
]

const categories: Category[] = [
  { id: 'linux', name: 'Linux命令', icon: '🐧', count: 150 },
  { id: 'docker', name: 'Docker技术', icon: '🐳', count: 80 },
  { id: 'shell', name: 'Shell脚本', icon: '📜', count: 60 },
  { id: 'network', name: '网络知识', icon: '🌐', count: 45 }
]

const topics: Topic[] = [
  {
    id: 1,
    title: 'Linux文件操作基础',
    description: 'ls, cd, cp, mv, rm等基础文件操作命令',
    category: 'linux',
    difficulty: '初级',
    questionsCount: 25,
    completedCount: 15,
    progress: 60
  },
  {
    id: 2,
    title: 'Linux权限管理',
    description: 'chmod, chown, chgrp等权限相关命令',
    category: 'linux',
    difficulty: '中级',
    questionsCount: 20,
    completedCount: 8,
    progress: 40
  },
  {
    id: 3,
    title: 'Docker基础概念',
    description: '镜像、容器、仓库等Docker核心概念',
    category: 'docker',
    difficulty: '初级',
    questionsCount: 18,
    completedCount: 18,
    progress: 100
  },
  {
    id: 4,
    title: 'Dockerfile编写',
    description: 'Dockerfile指令和最佳实践',
    category: 'docker',
    difficulty: '中级',
    questionsCount: 22,
    completedCount: 5,
    progress: 23
  },
  {
    id: 5,
    title: 'Shell脚本基础语法',
    description: '变量、条件判断、循环等Shell脚本基础',
    category: 'shell',
    difficulty: '初级',
    questionsCount: 20,
    completedCount: 12,
    progress: 60
  }
]

const practiceHistory: HistoryRecord[] = [
  {
    topic: 'Linux文件操作基础',
    time: '2023-12-28 14:30',
    score: 88,
    correct: 22,
    total: 25,
    duration: '15分钟',
    description: '表现优秀，继续加油！'
  },
  {
    topic: 'Docker基础概念',
    time: '2023-12-28 10:15',
    score: 100,
    correct: 18,
    total: 18,
    duration: '12分钟',
    description: '完美通过！掌握得很扎实。'
  },
  {
    topic: 'Shell脚本基础语法',
    time: '2023-12-27 19:45',
    score: 75,
    correct: 15,
    total: 20,
    duration: '18分钟',
    description: '还需加强练习，加油！'
  }
]

const filteredTopics = computed(() => {
  let filtered = topics.filter(topic => topic.category === activeCategory.value)
  
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(topic => 
      topic.title.toLowerCase().includes(query) ||
      topic.description.toLowerCase().includes(query)
    )
  }
  
  return filtered
})

const selectPracticeMode = (mode: PracticeMode) => {
  ElMessage.info(`${mode.title}功能开发中...`)
  // router.push(`/practice/${mode.id}`)
}

const handleCategoryChange = () => {
  console.log('切换到分类:', activeCategory.value)
}

const handleSearch = () => {
  console.log('搜索题目:', searchQuery.value)
}

const startTopicPractice = (topic: Topic) => {
  router.push({
    path: '/practice/quiz',
    query: { topicId: topic.id, topicName: topic.title }
  })
}

const viewAllHistory = () => {
  ElMessage.info('练习历史详情页面开发中...')
}

const getDifficultyType = (difficulty: string) => {
  switch (difficulty) {
    case '初级': return 'success'
    case '中级': return 'warning'
    case '高级': return 'danger'
    default: return 'info'
  }
}

const getScoreType = (score: number) => {
  if (score >= 90) return 'success'
  if (score >= 80) return 'warning'
  return 'danger'
}

const getProgressColor = (progress: number) => {
  if (progress >= 80) return '#67c23a'
  if (progress >= 50) return '#e6a23c'
  return '#f56c6c'
}

const goBack = () => {
  router.push('/')
}

onMounted(() => {
  console.log('Practice page loaded')
})
</script>

<style scoped>
.practice-page {
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

.practice-modes {
  margin-bottom: 30px;
}

.mode-card {
  border: none;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 6px 20px rgba(0,0,0,0.12);
  transition: all 0.3s ease;
  cursor: pointer;
  height: 100%;
}

.mode-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 12px 40px rgba(0,0,0,0.2);
}

.mode-content {
  text-align: center;
  padding: 30px 20px;
}

.mode-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.mode-content h3 {
  margin: 16px 0 12px 0;
  font-size: 20px;
  color: #333;
}

.mode-content p {
  color: #666;
  line-height: 1.6;
  margin-bottom: 20px;
  font-size: 14px;
}

.mode-stats {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-bottom: 24px;
}

.stat {
  font-size: 14px;
  color: #999;
}

.mode-btn {
  width: 100%;
}

.question-categories,
.practice-history {
  border: none;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  margin-bottom: 30px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 16px;
  font-weight: 600;
}

.category-content {
  margin-top: 20px;
}

.topic-card {
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 12px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-bottom: 16px;
}

.topic-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.15);
  border-color: #409eff;
  background: white;
}

.topic-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.topic-header h4 {
  margin: 0;
  font-size: 16px;
  color: #333;
  font-weight: 600;
}

.topic-desc {
  color: #666;
  line-height: 1.6;
  margin-bottom: 16px;
  font-size: 14px;
}

.topic-stats {
  display: flex;
  justify-content: space-between;
  margin-bottom: 12px;
}

.topic-stat {
  font-size: 12px;
  color: #999;
}

.history-item {
  border: none;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.history-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.history-title {
  font-weight: 600;
  color: #333;
}

.history-desc {
  color: #666;
  margin: 8px 0;
  font-size: 14px;
}

.history-stats {
  display: flex;
  gap: 20px;
  font-size: 12px;
  color: #999;
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
  
  .mode-content {
    padding: 20px 15px;
  }
  
  .mode-icon {
    font-size: 36px;
  }
  
  .section-header {
    flex-direction: column;
    gap: 12px;
    align-items: stretch;
  }
  
  .section-header .el-input {
    width: 100% !important;
  }
  
  .topic-stats {
    flex-direction: column;
    gap: 4px;
  }
  
  .history-stats {
    flex-direction: column;
    gap: 4px;
  }
}
</style>