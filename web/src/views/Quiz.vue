<template>
  <div class="quiz-page">
    <el-container>
      <el-header class="quiz-header">
        <div class="header-content">
          <el-button type="text" @click="goBack" class="back-btn">
            ← 返回练习
          </el-button>
          <div class="quiz-info">
            <h2>{{ topicName }}</h2>
            <div class="progress-info">
              <span>题目 {{ currentQuestionIndex + 1 }} / {{ questions.length }}</span>
              <el-progress 
                :percentage="progressPercentage" 
                :color="progressColor"
                :show-text="false"
                :stroke-width="4"
                style="width: 200px; margin-left: 16px;"
              />
            </div>
          </div>
          <div class="timer">
            <el-icon><Timer /></el-icon>
            <span>{{ formatTime(remainingTime) }}</span>
          </div>
        </div>
      </el-header>

      <el-main class="quiz-main">
        <div v-if="loading" class="loading-container">
          <el-skeleton animated />
        </div>

        <div v-else-if="quizCompleted" class="quiz-completed">
          <el-card class="result-card">
            <div class="result-header">
              <div class="score-circle">
                <div class="score-content">
                  <div class="score-number">{{ score }}%</div>
                  <div class="score-label">得分</div>
                </div>
              </div>
              <h2>{{ getResultTitle() }}</h2>
              <p class="result-desc">{{ getResultDescription() }}</p>
            </div>

            <el-descriptions :column="2" border class="result-stats">
              <el-descriptions-item label="正确题数">
                <span class="correct">{{ correctAnswers }}</span> / {{ questions.length }}
              </el-descriptions-item>
              <el-descriptions-item label="用时">
                {{ formatTime(timeSpent) }}
              </el-descriptions-item>
              <el-descriptions-item label="正确率">
                {{ Math.round((correctAnswers / questions.length) * 100) }}%
              </el-descriptions-item>
              <el-descriptions-item label="题目难度">
                {{ getAverageDifficulty() }}
              </el-descriptions-item>
            </el-descriptions>

            <div class="answer-review">
              <h3>答题详情</h3>
              <el-collapse v-model="activeReviews">
                <el-collapse-item 
                  v-for="(question, index) in questions" 
                  :key="question.id"
                  :title="`题目 ${index + 1}: ${question.title}`"
                  :name="index"
                >
                  <div class="question-review">
                    <p class="question-text">{{ question.title }}</p>
                    <div class="options-review">
                      <div 
                        v-for="option in question.options" 
                        :key="option.id"
                        class="option-review"
                        :class="{
                          'correct': option.id === question.correctAnswer,
                          'wrong': option.id === selectedAnswers[index] && option.id !== question.correctAnswer,
                          'selected': option.id === selectedAnswers[index]
                        }"
                      >
                        <span class="option-label">{{ option.label }}</span>
                        <span class="option-text">{{ option.text }}</span>
                        <span class="option-status">
                          <el-icon v-if="option.id === question.correctAnswer" class="correct-icon"><Check /></el-icon>
                          <el-icon v-else-if="option.id === selectedAnswers[index]" class="wrong-icon"><Close /></el-icon>
                        </span>
                      </div>
                    </div>
                    <div v-if="question.explanation" class="explanation">
                      <strong>解析：</strong>{{ question.explanation }}
                    </div>
                  </div>
                </el-collapse-item>
              </el-collapse>
            </div>

            <div class="result-actions">
              <el-button size="large" @click="reviewAnswers">
                查看解析
              </el-button>
              <el-button type="primary" size="large" @click="restartQuiz">
                重新练习
              </el-button>
              <el-button type="success" size="large" @click="goToPractice">
                继续练习
              </el-button>
            </div>
          </el-card>
        </div>

        <div v-else class="quiz-content">
          <el-row :gutter="20">
            <el-col :xs="24" :lg="16">
              <el-card class="question-card">
                <div class="question-header">
                  <el-tag :type="getDifficultyType(currentQuestion.difficulty)" size="small">
                    {{ currentQuestion.difficulty }}
                  </el-tag>
                  <span class="question-type">{{ currentQuestion.type }}</span>
                </div>

                <div class="question-content">
                  <h3 class="question-title">{{ currentQuestion.title }}</h3>
                  <div v-if="currentQuestion.code" class="question-code">
                    <el-input 
                      :model-value="currentQuestion.code" 
                      type="textarea"
                      :rows="4"
                      readonly
                      class="code-display"
                    />
                  </div>
                </div>

                <div class="options-container">
                  <div 
                    v-for="option in currentQuestion.options" 
                    :key="option.id"
                    class="option-item"
                    :class="{ 
                      'selected': selectedAnswers[currentQuestionIndex] === option.id,
                      'disabled': answeredQuestions[currentQuestionIndex]
                    }"
                    @click="selectOption(option.id)"
                  >
                    <div class="option-radio">
                      <el-radio 
                        v-model="selectedAnswers[currentQuestionIndex]" 
                        :value="option.id"
                        :disabled="answeredQuestions[currentQuestionIndex]"
                      >
                        <span class="option-label">{{ option.label }}</span>
                      </el-radio>
                    </div>
                    <div class="option-content">
                      <span class="option-text">{{ option.text }}</span>
                    </div>
                  </div>
                </div>

                <div class="question-actions">
                  <el-button 
                    v-if="currentQuestionIndex > 0" 
                    @click="previousQuestion"
                    :disabled="quizCompleted"
                  >
                    上一题
                  </el-button>
                  <el-button 
                    v-if="currentQuestionIndex < questions.length - 1" 
                    type="primary"
                    @click="nextQuestion"
                    :disabled="!selectedAnswers[currentQuestionIndex]"
                  >
                    下一题
                  </el-button>
                  <el-button 
                    v-else-if="currentQuestionIndex === questions.length - 1"
                    type="success"
                    @click="submitQuiz"
                    :disabled="!selectedAnswers[currentQuestionIndex] || submitting"
                    :loading="submitting"
                  >
                    提交答卷
                  </el-button>
                </div>
              </el-card>
            </el-col>

            <el-col :xs="24" :lg="8">
              <el-card class="question-nav">
                <template #header>
                  <span>答题卡</span>
                </template>
                <div class="nav-grid">
                  <div 
                    v-for="(question, index) in questions" 
                    :key="question.id"
                    class="nav-item"
                    :class="{
                      'current': index === currentQuestionIndex,
                      'answered': selectedAnswers[index],
                      'unanswered': !selectedAnswers[index]
                    }"
                    @click="goToQuestion(index)"
                  >
                    {{ index + 1 }}
                  </div>
                </div>
                <div class="nav-legend">
                  <div class="legend-item">
                    <div class="legend-color current"></div>
                    <span>当前题目</span>
                  </div>
                  <div class="legend-item">
                    <div class="legend-color answered"></div>
                    <span>已答题</span>
                  </div>
                  <div class="legend-item">
                    <div class="legend-color unanswered"></div>
                    <span>未答题</span>
                  </div>
                </div>
              </el-card>

              <el-card class="quiz-summary">
                <template #header>
                  <span>答题统计</span>
                </template>
                <div class="summary-stats">
                  <div class="stat-item">
                    <span class="stat-label">已答题数</span>
                    <span class="stat-value">{{ answeredCount }}</span>
                  </div>
                  <div class="stat-item">
                    <span class="stat-label">未答题数</span>
                    <span class="stat-value">{{ unansweredCount }}</span>
                  </div>
                  <div class="stat-item">
                    <span class="stat-label">总题数</span>
                    <span class="stat-value">{{ questions.length }}</span>
                  </div>
                </div>
              </el-card>
            </el-col>
          </el-row>
        </div>
      </el-main>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Timer, Check, Close } from '@element-plus/icons-vue'

interface QuestionOption {
  id: string
  label: string
  text: string
}

interface Question {
  id: number
  title: string
  type: string
  difficulty: '初级' | '中级' | '高级'
  options: QuestionOption[]
  correctAnswer: string
  code?: string
  explanation?: string
}

const router = useRouter()
const route = useRoute()

const loading = ref(true)
const submitting = ref(false)
const quizCompleted = ref(false)
const topicName = ref('')
const questions = ref<Question[]>([])
const selectedAnswers = ref<string[]>([])
const answeredQuestions = ref<boolean[]>([])
const currentQuestionIndex = ref(0)
const remainingTime = ref(1800) // 30分钟
const timeSpent = ref(0)
const timer = ref<NodeJS.Timeout | null>(null)
const activeReviews = ref<number[]>([])

// 模拟题目数据
const mockQuestions: Question[] = [
  {
    id: 1,
    title: '以下哪个命令用于列出目录内容？',
    type: '单选题',
    difficulty: '初级',
    options: [
      { id: 'a', label: 'A', text: 'ls' },
      { id: 'b', label: 'B', text: 'cd' },
      { id: 'c', label: 'C', text: 'mkdir' },
      { id: 'd', label: 'D', text: 'rm' }
    ],
    correctAnswer: 'a',
    explanation: 'ls命令用于列出目录内容，cd用于切换目录，mkdir用于创建目录，rm用于删除文件。'
  },
  {
    id: 2,
    title: 'Docker中用于创建镜像的命令是什么？',
    type: '单选题',
    difficulty: '中级',
    options: [
      { id: 'a', label: 'A', text: 'docker run' },
      { id: 'b', label: 'B', text: 'docker build' },
      { id: 'c', label: 'C', text: 'docker pull' },
      { id: 'd', label: 'D', text: 'docker push' }
    ],
    correctAnswer: 'b',
    explanation: 'docker build命令用于从Dockerfile构建Docker镜像。'
  },
  {
    id: 3,
    title: '查看脚本执行结果：',
    type: '代码题',
    difficulty: '初级',
    code: '#!/bin/bash\nfor i in {1..5}\ndo\n  echo "Number: $i"\ndone',
    options: [
      { id: 'a', label: 'A', text: '输出1到5的数字' },
      { id: 'b', label: 'B', text: '输出5到1的数字' },
      { id: 'c', label: 'C', text: '语法错误' },
      { id: 'd', label: 'D', text: '输出Number: 1..5' }
    ],
    correctAnswer: 'a',
    explanation: '这个for循环会输出Number: 1到Number: 5。'
  },
  {
    id: 4,
    title: 'Linux中给文件添加执行权限的命令是？',
    type: '单选题',
    difficulty: '初级',
    options: [
      { id: 'a', label: 'A', text: 'chmod +x filename' },
      { id: 'b', label: 'B', text: 'chmod 777 filename' },
      { id: 'c', label: 'C', text: 'chmod +w filename' },
      { id: 'd', label: 'D', text: 'chmod -x filename' }
    ],
    correctAnswer: 'a',
    explanation: 'chmod +x filename给文件添加执行权限，777给所有权限，+w添加写权限，-x移除执行权限。'
  }
]

const currentQuestion = computed(() => {
  return questions.value[currentQuestionIndex.value] || {}
})

const progressPercentage = computed(() => {
  return Math.round(((currentQuestionIndex.value + 1) / questions.value.length) * 100)
})

const answeredCount = computed(() => {
  return selectedAnswers.value.filter(answer => answer).length
})

const unansweredCount = computed(() => {
  return questions.value.length - answeredCount.value
})

const score = computed(() => {
  if (!quizCompleted.value) return 0
  return Math.round((correctAnswers.value / questions.value.length) * 100)
})

const correctAnswers = computed(() => {
  if (!quizCompleted.value) return 0
  return questions.value.reduce((count, question, index) => {
    return count + (selectedAnswers.value[index] === question.correctAnswer ? 1 : 0)
  }, 0)
})

const progressColor = computed(() => {
  const percentage = progressPercentage.value
  if (percentage >= 80) return '#67c23a'
  if (percentage >= 50) return '#e6a23c'
  return '#f56c6c'
})

const selectOption = (optionId: string) => {
  if (answeredQuestions.value[currentQuestionIndex.value]) return
  
  selectedAnswers.value[currentQuestionIndex.value] = optionId
}

const nextQuestion = () => {
  if (currentQuestionIndex.value < questions.value.length - 1) {
    currentQuestionIndex.value++
  }
}

const previousQuestion = () => {
  if (currentQuestionIndex.value > 0) {
    currentQuestionIndex.value--
  }
}

const goToQuestion = (index: number) => {
  currentQuestionIndex.value = index
}

const submitQuiz = async () => {
  try {
    await ElMessageBox.confirm('确定要提交答卷吗？提交后无法修改答案。', '确认提交', {
      type: 'warning'
    })
    
    submitting.value = true
    
    // 模拟提交过程
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    quizCompleted.value = true
    answeredQuestions.value = new Array(questions.value.length).fill(true)
    
    ElMessage.success('答卷提交成功！')
  } catch (error) {
    // 用户取消提交
  } finally {
    submitting.value = false
  }
}

const getResultTitle = () => {
  const scoreValue = score.value
  if (scoreValue >= 90) return '🎉 优秀！'
  if (scoreValue >= 80) return '👏 良好！'
  if (scoreValue >= 60) return '👍 及格！'
  return '💪 继续加油！'
}

const getResultDescription = () => {
  const scoreValue = score.value
  if (scoreValue >= 90) return '你对这个知识点掌握得非常扎实！'
  if (scoreValue >= 80) return '你对这个知识点掌握得不错，继续努力！'
  if (scoreValue >= 60) return '基本掌握，建议多加练习巩固知识。'
  return '需要重新学习这个知识点，加油！'
}

const getAverageDifficulty = () => {
  const difficulties = questions.value.map(q => q.difficulty)
  const primary = difficulties.filter(d => d === '初级').length
  const intermediate = difficulties.filter(d => d === '中级').length
  const advanced = difficulties.filter(d => d === '高级').length
  
  if (advanced > intermediate && advanced > primary) return '高级'
  if (intermediate > primary) return '中级'
  return '初级'
}

const formatTime = (seconds: number) => {
  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = seconds % 60
  return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`
}

const getDifficultyType = (difficulty: string) => {
  switch (difficulty) {
    case '初级': return 'success'
    case '中级': return 'warning'
    case '高级': return 'danger'
    default: return 'info'
  }
}

const reviewAnswers = () => {
  activeReviews.value = questions.value.map((_, index) => index)
}

const restartQuiz = () => {
  selectedAnswers.value = []
  answeredQuestions.value = []
  currentQuestionIndex.value = 0
  remainingTime.value = 1800
  timeSpent.value = 0
  quizCompleted.value = false
}

const goToPractice = () => {
  router.push('/practice')
}

const goBack = () => {
  router.push('/practice')
}

// 计时器
const startTimer = () => {
  timer.value = setInterval(() => {
    if (remainingTime.value > 0 && !quizCompleted.value) {
      remainingTime.value--
      timeSpent.value++
    } else if (remainingTime.value === 0 && !quizCompleted.value) {
      // 时间到，自动提交
      submitQuiz()
    }
  }, 1000)
}

onMounted(() => {
  topicName.value = route.query.topicName as string || '未知主题'
  
  // 加载题目
  setTimeout(() => {
    questions.value = mockQuestions
    selectedAnswers.value = new Array(mockQuestions.length).fill('')
    answeredQuestions.value = new Array(mockQuestions.length).fill(false)
    loading.value = false
    startTimer()
  }, 1000)
})

onUnmounted(() => {
  if (timer.value) {
    clearInterval(timer.value)
  }
})
</script>

<style scoped>
.quiz-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.quiz-header {
  background: linear-gradient(135deg, #409eff 0%, #364d79 100%);
  color: white;
  padding: 16px 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.header-content {
  max-width: 1400px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.back-btn {
  color: white;
  font-size: 16px;
  padding: 8px 16px;
}

.back-btn:hover {
  background: rgba(255,255,255,0.1);
}

.quiz-info h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
}

.progress-info {
  display: flex;
  align-items: center;
  margin-top: 4px;
  font-size: 14px;
  opacity: 0.9;
}

.timer {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
  font-weight: 600;
}

.quiz-main {
  max-width: 1400px;
  margin: 0 auto;
  padding: 20px;
}

.loading-container {
  padding: 40px;
}

.quiz-completed {
  max-width: 900px;
  margin: 0 auto;
}

.result-card {
  border: none;
  border-radius: 16px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.15);
  overflow: hidden;
}

.result-header {
  text-align: center;
  padding: 40px 20px;
  background: linear-gradient(135deg, #f8f9ff 0%, #e8f4ff 100%);
}

.score-circle {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  background: linear-gradient(135deg, #409eff 0%, #364d79 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 24px;
  box-shadow: 0 8px 24px rgba(64, 158, 255, 0.3);
}

.score-content {
  text-align: center;
  color: white;
}

.score-number {
  font-size: 32px;
  font-weight: 700;
  line-height: 1;
}

.score-label {
  font-size: 14px;
  opacity: 0.9;
  margin-top: 4px;
}

.result-header h2 {
  margin: 0 0 12px 0;
  font-size: 28px;
  color: #333;
}

.result-desc {
  color: #666;
  font-size: 16px;
  line-height: 1.6;
}

.result-stats {
  margin: 30px 0;
}

.correct {
  color: #67c23a;
  font-weight: 600;
}

.answer-review {
  margin: 30px 0;
}

.answer-review h3 {
  margin-bottom: 20px;
  color: #333;
}

.question-review {
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
  margin-bottom: 16px;
}

.question-text {
  font-weight: 600;
  color: #333;
  margin-bottom: 16px;
}

.options-review {
  margin-bottom: 16px;
}

.option-review {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  border-radius: 6px;
  margin-bottom: 6px;
}

.option-review.correct {
  background: #f0f9ff;
  border: 1px solid #67c23a;
}

.option-review.wrong {
  background: #fef0f0;
  border: 1px solid #f56c6c;
}

.option-review.selected {
  background: #ecf5ff;
  border: 1px solid #409eff;
}

.option-label {
  font-weight: 600;
  margin-right: 8px;
  min-width: 20px;
}

.option-text {
  flex: 1;
}

.option-status {
  margin-left: 8px;
}

.correct-icon {
  color: #67c23a;
}

.wrong-icon {
  color: #f56c6c;
}

.explanation {
  padding: 12px;
  background: #fff;
  border: 1px solid #e9ecef;
  border-radius: 6px;
  font-size: 14px;
  line-height: 1.6;
}

.result-actions {
  display: flex;
  gap: 16px;
  justify-content: center;
  padding: 30px 0;
}

.quiz-content {
  min-height: 600px;
}

.question-card {
  border: none;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  margin-bottom: 20px;
}

.question-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.question-type {
  color: #666;
  font-size: 14px;
}

.question-content {
  margin-bottom: 24px;
}

.question-title {
  color: #333;
  font-size: 18px;
  line-height: 1.6;
  margin-bottom: 16px;
}

.question-code {
  margin: 16px 0;
}

.code-display {
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
}

.options-container {
  margin-bottom: 24px;
}

.option-item {
  display: flex;
  align-items: center;
  padding: 16px;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  margin-bottom: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.option-item:hover {
  border-color: #409eff;
  background: #f8f9ff;
}

.option-item.selected {
  border-color: #409eff;
  background: #ecf5ff;
}

.option-item.disabled {
  cursor: not-allowed;
  opacity: 0.7;
}

.option-radio {
  margin-right: 12px;
}

.option-content {
  flex: 1;
}

.option-text {
  font-size: 16px;
  line-height: 1.6;
}

.question-actions {
  display: flex;
  gap: 12px;
  justify-content: space-between;
}

.question-nav,
.quiz-summary {
  border: none;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  margin-bottom: 20px;
}

.nav-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 8px;
  margin-bottom: 20px;
}

.nav-item {
  aspect-ratio: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #e9ecef;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s ease;
}

.nav-item:hover {
  transform: translateY(-2px);
}

.nav-item.current {
  background: #409eff;
  color: white;
  border-color: #409eff;
}

.nav-item.answered {
  background: #f0f9ff;
  color: #409eff;
  border-color: #409eff;
}

.nav-item.unanswered {
  background: #fafafa;
  color: #999;
  border-color: #e9ecef;
}

.nav-legend {
  display: flex;
  justify-content: space-around;
  font-size: 12px;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
}

.legend-color {
  width: 12px;
  height: 12px;
  border-radius: 2px;
}

.legend-color.current {
  background: #409eff;
}

.legend-color.answered {
  background: #f0f9ff;
  border: 1px solid #409eff;
}

.legend-color.unanswered {
  background: #fafafa;
  border: 1px solid #e9ecef;
}

.summary-stats {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.stat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
}

.stat-label {
  color: #666;
  font-size: 14px;
}

.stat-value {
  font-weight: 600;
  font-size: 16px;
  color: #333;
}

@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    gap: 12px;
    align-items: flex-start;
  }
  
  .quiz-info h2 {
    font-size: 18px;
  }
  
  .progress-info {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  
  .progress-info .el-progress {
    width: 100% !important;
  }
  
  .quiz-main {
    padding: 15px;
  }
  
  .nav-grid {
    grid-template-columns: repeat(4, 1fr);
  }
  
  .result-actions {
    flex-direction: column;
  }
  
  .question-actions {
    flex-direction: column;
  }
}
</style>