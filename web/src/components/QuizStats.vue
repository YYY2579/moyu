<template>
  <div class="quiz-stats">
    <el-card class="stats-card">
      <template #header>
        <div class="stats-header">
          <span class="stats-title">{{ title }}</span>
          <el-tag :type="getScoreType(score)" size="large">
            {{ score }}分
          </el-tag>
        </div>
      </template>
      
      <div class="stats-content">
        <div class="score-circle">
          <svg viewBox="0 0 100 100" class="progress-svg">
            <circle
              cx="50"
              cy="50"
              r="45"
              fill="none"
              stroke="#e9ecef"
              stroke-width="8"
            />
            <circle
              cx="50"
              cy="50"
              r="45"
              fill="none"
              :stroke="progressColor"
              stroke-width="8"
              :stroke-dasharray="circumference"
              :stroke-dashoffset="dashOffset"
              transform="rotate(-90 50 50)"
              class="progress-circle"
            />
          </svg>
          <div class="score-text">
            <div class="score-number">{{ score }}</div>
            <div class="score-label">分数</div>
          </div>
        </div>

        <div class="stats-details">
          <div class="stat-item">
            <span class="stat-label">正确题数</span>
            <span class="stat-value correct">{{ correct }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">错误题数</span>
            <span class="stat-value wrong">{{ wrong }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">正确率</span>
            <span class="stat-value">{{ accuracy }}%</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">用时</span>
            <span class="stat-value">{{ duration }}</span>
          </div>
        </div>
      </div>

      <div class="stats-footer">
        <el-button type="primary" @click="$emit('review')">
          查看解析
        </el-button>
        <el-button @click="$emit('retry')">
          重新练习
        </el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  title: string
  score: number
  correct: number
  wrong: number
  total: number
  duration: string
}

const props = defineProps<Props>()

defineEmits<{
  review: []
  retry: []
}>()

const circumference = 2 * Math.PI * 45
const accuracy = computed(() => Math.round((props.correct / props.total) * 100))

const progressColor = computed(() => {
  if (props.score >= 90) return '#67c23a'
  if (props.score >= 80) return '#e6a23c'
  if (props.score >= 60) return '#409eff'
  return '#f56c6c'
})

const dashOffset = computed(() => {
  return circumference - (props.score / 100) * circumference
})

const getScoreType = (score: number) => {
  if (score >= 90) return 'success'
  if (score >= 80) return 'warning'
  if (score >= 60) return 'primary'
  return 'danger'
}
</script>

<style scoped>
.quiz-stats {
  max-width: 400px;
  margin: 0 auto;
}

.stats-card {
  border: none;
  border-radius: 16px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.15);
  overflow: hidden;
}

.stats-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.stats-title {
  font-size: 18px;
  font-weight: 600;
  color: #333;
}

.stats-content {
  padding: 20px 0;
  text-align: center;
}

.score-circle {
  position: relative;
  width: 120px;
  height: 120px;
  margin: 0 auto 30px;
}

.progress-svg {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}

.progress-circle {
  transition: stroke-dashoffset 1s ease-in-out;
}

.score-text {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}

.score-number {
  font-size: 28px;
  font-weight: 700;
  color: #333;
  line-height: 1;
}

.score-label {
  font-size: 14px;
  color: #666;
  margin-top: 4px;
}

.stats-details {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-bottom: 30px;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 12px;
  background: #f8f9fa;
  border-radius: 8px;
}

.stat-label {
  font-size: 12px;
  color: #666;
  margin-bottom: 4px;
}

.stat-value {
  font-size: 18px;
  font-weight: 600;
  color: #333;
}

.stat-value.correct {
  color: #67c23a;
}

.stat-value.wrong {
  color: #f56c6c;
}

.stats-footer {
  display: flex;
  gap: 12px;
  justify-content: center;
}
</style>