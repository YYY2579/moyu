<template>
  <div class="home">
    <el-container>
      <el-header class="header">
        <div class="header-content">
          <h1>🐟 摸鱼学习站</h1>
          <p class="subtitle">专注 Linux & Docker 技术学习平台</p>
        </div>
      </el-header>
      
      <el-main class="main">
        <!-- 学习统计卡片 -->
        <el-row :gutter="20" class="stats-row">
          <el-col :xs="24" :sm="8">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon">📚</div>
                <div class="stat-info">
                  <div class="stat-number">150+</div>
                  <div class="stat-label">Linux 命令</div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :xs="24" :sm="8">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon">🐳</div>
                <div class="stat-info">
                  <div class="stat-number">80+</div>
                  <div class="stat-label">Docker 知识点</div>
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :xs="24" :sm="8">
            <el-card class="stat-card">
              <div class="stat-content">
                <div class="stat-icon">✅</div>
                <div class="stat-info">
                  <div class="stat-number">500+</div>
                  <div class="stat-label">练习题目</div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 主要学习模块 -->
        <el-row :gutter="20" class="modules-row">
          <el-col :xs="24" :md="12">
            <el-card class="module-card" shadow="hover" @click="goToLinux">
              <template #header>
                <div class="module-header">
                  <span class="module-icon">🐧</span>
                  <span class="module-title">Linux 命令学习</span>
                </div>
              </template>
              <div class="module-content">
                <p>系统学习 Linux 常用命令，从基础到进阶</p>
                <div class="module-features">
                  <el-tag size="small">文件操作</el-tag>
                  <el-tag size="small" type="success">系统管理</el-tag>
                  <el-tag size="small" type="warning">网络配置</el-tag>
                  <el-tag size="small" type="danger">Shell 脚本</el-tag>
                </div>
                <el-button type="primary" class="module-btn" @click.stop="goToLinux">
                  开始学习
                </el-button>
              </div>
            </el-card>
          </el-col>
          
          <el-col :xs="24" :md="12">
            <el-card class="module-card" shadow="hover" @click="goToDocker">
              <template #header>
                <div class="module-header">
                  <span class="module-icon">🐳</span>
                  <span class="module-title">Docker 容器技术</span>
                </div>
              </template>
              <div class="module-content">
                <p>掌握 Docker 容器化技术，提升部署效率</p>
                <div class="module-features">
                  <el-tag size="small">基础概念</el-tag>
                  <el-tag size="small" type="success">镜像管理</el-tag>
                  <el-tag size="small" type="warning">容器编排</el-tag>
                  <el-tag size="small" type="danger">实践项目</el-tag>
                </div>
                <el-button type="primary" class="module-btn" @click.stop="goToDocker">
                  开始学习
                </el-button>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 快速功能区 -->
        <el-row :gutter="20" class="quick-actions">
          <el-col :xs="24" :sm="8">
            <el-card class="action-card" shadow="hover" @click="startPractice">
              <div class="action-content">
                <div class="action-icon">✏️</div>
                <div class="action-info">
                  <h3>每日练习</h3>
                  <p>随机练习题目，巩固知识</p>
                </div>
              </div>
            </el-card>
          </el-col>
          
          <el-col :xs="24" :sm="8">
            <el-card class="action-card" shadow="hover" @click="viewProgress">
              <div class="action-content">
                <div class="action-icon">📊</div>
                <div class="action-info">
                  <h3>学习进度</h3>
                  <p>查看学习统计和成就</p>
                </div>
              </div>
            </el-card>
          </el-col>
          
          <el-col :xs="24" :sm="8">
            <el-card class="action-card" shadow="hover" @click="showBookmarks">
              <div class="action-content">
                <div class="action-icon">🔖</div>
                <div class="action-info">
                  <h3>我的收藏</h3>
                  <p>收藏重要的学习内容</p>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 最近学习 -->
        <el-card class="recent-card">
          <template #header>
            <div class="recent-header">
              <span>🕒 最近学习</span>
              <el-link type="primary" @click="viewAllHistory">查看全部</el-link>
            </div>
          </template>
          <el-empty v-if="!recentLearning.length" description="暂无学习记录" />
          <div v-else class="recent-list">
            <div v-for="item in recentLearning" :key="item.id" class="recent-item">
              <el-tag :type="item.type" size="small">{{ item.category }}</el-tag>
              <span class="recent-title">{{ item.title }}</span>
              <span class="recent-time">{{ item.time }}</span>
            </div>
          </div>
        </el-card>
      </el-main>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'

interface RecentItem {
  id: number
  category: string
  title: string
  time: string
  type: 'primary' | 'success' | 'warning' | 'danger'
}

const router = useRouter()
const recentLearning = ref<RecentItem[]>([])

onMounted(() => {
  // 模拟最近学习数据
  recentLearning.value = [
    { id: 1, category: 'Linux', title: '文件权限管理', time: '2小时前', type: 'primary' },
    { id: 2, category: 'Docker', title: 'Dockerfile 编写', time: '1天前', type: 'success' },
    { id: 3, category: 'Linux', title: 'Shell 脚本基础', time: '2天前', type: 'warning' }
  ]
})

// 跳转到 Linux 学习页面
const goToLinux = () => {
  router.push('/linux')
}

// 跳转到 Docker 学习页面
const goToDocker = () => {
  router.push('/docker')
}

// 开始练习
const startPractice = () => {
  router.push('/practice')
}

// 查看学习进度
const viewProgress = () => {
  router.push('/progress')
}

// 查看收藏
const showBookmarks = () => {
  ElMessage.info('收藏功能开发中...')
  console.log('Show bookmarks')
  // router.push('/bookmarks')
}

// 查看全部历史
const viewAllHistory = () => {
  ElMessage.info('学习历史功能开发中...')
  console.log('View all history')
  // router.push('/history')
}
</script>

<style scoped>
.home {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.header {
  background: linear-gradient(135deg, #409eff 0%, #364d79 100%);
  color: white;
  padding: 40px 20px;
  text-align: center;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.header-content h1 {
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 8px;
  text-shadow: 0 2px 4px rgba(0,0,0,0.3);
}

.subtitle {
  font-size: 18px;
  opacity: 0.9;
  margin: 0;
  font-weight: 300;
}

.main {
  padding: 30px 20px;
  max-width: 1400px;
  margin: 0 auto;
}

/* 统计卡片 */
.stats-row {
  margin-bottom: 30px;
}

.stat-card {
  border: none;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.15);
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

/* 学习模块卡片 */
.modules-row {
  margin-bottom: 30px;
}

.module-card {
  border: none;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 6px 16px rgba(0,0,0,0.12);
  transition: all 0.3s ease;
  cursor: pointer;
  height: 100%;
}

.module-card:hover {
  transform: translateY(-6px);
  box-shadow: 0 12px 32px rgba(0,0,0,0.18);
}

.module-header {
  display: flex;
  align-items: center;
  font-size: 18px;
  font-weight: 600;
}

.module-icon {
  font-size: 24px;
  margin-right: 12px;
}

.module-content {
  padding: 0;
}

.module-content p {
  color: #666;
  line-height: 1.6;
  margin-bottom: 16px;
}

.module-features {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 20px;
}

.module-btn {
  width: 100%;
  margin-top: 12px;
}

/* 快速功能区 */
.quick-actions {
  margin-bottom: 30px;
}

.action-card {
  border: none;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transition: all 0.3s ease;
  cursor: pointer;
  height: 100%;
}

.action-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.15);
}

.action-content {
  display: flex;
  align-items: center;
  padding: 20px;
}

.action-icon {
  font-size: 32px;
  margin-right: 16px;
}

.action-info h3 {
  margin: 0 0 8px 0;
  font-size: 16px;
  font-weight: 600;
  color: #333;
}

.action-info p {
  margin: 0;
  font-size: 14px;
  color: #666;
  line-height: 1.4;
}

/* 最近学习 */
.recent-card {
  border: none;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.recent-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 16px;
  font-weight: 600;
}

.recent-list {
  max-height: 300px;
  overflow-y: auto;
}

.recent-item {
  display: flex;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.recent-item:last-child {
  border-bottom: none;
}

.recent-title {
  flex: 1;
  margin: 0 12px;
  color: #333;
  font-size: 14px;
}

.recent-time {
  color: #999;
  font-size: 12px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  /* 首页在移动端隐藏header，使用移动端导航 */
  .header {
    display: none;
  }
  
  .main {
    padding: 30px 15px 20px; /* 顶部留出空间给移动端菜单按钮 */
  }
  
  /* 统计卡片优化 */
  .stats-row {
    margin-bottom: 20px;
  }
  
  .stat-content {
    padding: 16px;
    justify-content: center;
    text-align: center;
  }
  
  .stat-icon {
    font-size: 28px;
    margin-right: 0;
    margin-bottom: 8px;
  }
  
  .stat-number {
    font-size: 24px;
  }
  
  .stat-label {
    font-size: 12px;
  }
  
  /* 学习模块卡片优化 */
  .modules-row {
    margin-bottom: 20px;
  }
  
  .module-card {
    margin-bottom: 16px;
  }
  
  .module-header {
    font-size: 16px;
  }
  
  .module-icon {
    font-size: 20px;
  }
  
  .module-content p {
    font-size: 13px;
    margin-bottom: 12px;
  }
  
  .module-features {
    margin-bottom: 16px;
  }
  
  .module-btn {
    padding: 8px 16px;
    font-size: 14px;
  }
  
  /* 快速功能区优化 */
  .quick-actions {
    margin-bottom: 20px;
  }
  
  .action-content {
    padding: 16px;
  }
  
  .action-icon {
    font-size: 28px;
    margin-right: 12px;
  }
  
  .action-info h3 {
    font-size: 14px;
  }
  
  .action-info p {
    font-size: 12px;
  }
  
  /* 最近学习优化 */
  .recent-card {
    margin-bottom: 20px;
  }
  
  .recent-header {
    font-size: 14px;
  }
  
  .recent-item {
    padding: 10px 0;
  }
  
  .recent-title {
    font-size: 13px;
  }
  
  .recent-time {
    font-size: 11px;
  }
}

@media (max-width: 480px) {
  .header {
    padding: 30px 15px;
  }
  
  .main {
    padding: 15px 10px;
  }
  
  .stats-row,
  .modules-row,
  .quick-actions {
    margin-bottom: 20px;
  }
}
</style>