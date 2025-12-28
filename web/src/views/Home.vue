<template>
  <div class="home">
    <!-- 主导航区域 -->
    <div class="hero-section">
      <div class="hero-content">
        <h1 class="site-title">摸鱼学习站</h1>
        <p class="site-desc">Linux & Docker 技术学习平台</p>
        <div class="hero-stats">
          <span class="stat-item">150+ Linux命令</span>
          <span class="stat-divider">|</span>
          <span class="stat-item">80+ Docker知识点</span>
          <span class="stat-divider">|</span>
          <span class="stat-item">500+ 练习题</span>
        </div>
      </div>
    </div>

    <!-- 主要内容区域 -->
    <div class="main-content">
      <!-- 学习模块 -->
      <div class="modules-section">
        <h2 class="section-title">学习模块</h2>
        <div class="modules-grid">
          <div class="module-item" @click="goToLinux">
            <div class="module-icon">🐧</div>
            <h3 class="module-name">Linux 命令</h3>
            <p class="module-desc">系统学习Linux常用命令</p>
            <div class="module-tags">
              <span class="tag">文件操作</span>
              <span class="tag">系统管理</span>
              <span class="tag">网络配置</span>
            </div>
          </div>
          
          <div class="module-item" @click="goToDocker">
            <div class="module-icon">🐳</div>
            <h3 class="module-name">Docker 技术</h3>
            <p class="module-desc">掌握容器化部署技术</p>
            <div class="module-tags">
              <span class="tag">基础概念</span>
              <span class="tag">镜像管理</span>
              <span class="tag">容器编排</span>
            </div>
          </div>
        </div>
      </div>

        <!-- 快速功能 -->
        <div class="actions-section">
          <h2 class="section-title">快速功能</h2>
          <div class="actions-grid">
            <div class="action-item" @click="startPractice">
              <div class="action-icon">✏️</div>
              <span class="action-name">每日练习</span>
            </div>
            <div class="action-item" @click="viewProgress">
              <div class="action-icon">📊</div>
              <span class="action-name">学习进度</span>
            </div>
            <div class="action-item" @click="openTools">
              <div class="action-icon">🛠️</div>
              <span class="action-name">学习工具</span>
            </div>
            <div class="action-item" @click="openShortcuts">
              <div class="action-icon">⌨️</div>
              <span class="action-name">快捷键参考</span>
            </div>
            <div class="action-item" @click="showBookmarks">
              <div class="action-icon">🔖</div>
              <span class="action-name">我的收藏</span>
            </div>
          </div>
        </div>

      <!-- 最近学习 -->
      <div class="recent-section">
        <div class="section-header">
          <h2 class="section-title">最近学习</h2>
          <a href="#" class="view-all" @click="viewAllHistory">查看全部</a>
        </div>
        <div v-if="!recentLearning.length" class="empty-state">
          <p>暂无学习记录</p>
        </div>
        <div v-else class="recent-list">
          <div v-for="item in recentLearning" :key="item.id" class="recent-item">
            <span class="recent-category">{{ item.category }}</span>
            <span class="recent-title">{{ item.title }}</span>
            <span class="recent-time">{{ item.time }}</span>
          </div>
        </div>
      </div>
    </div>
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

// 打开学习工具
const openTools = () => {
  router.push('/tools')
}

// 打开快捷键参考
const openShortcuts = () => {
  router.push('/shortcuts')
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
  background: #f8f9fa;
}

/* Hero区域 */
.hero-section {
  background: #fff;
  border-bottom: 1px solid #e9ecef;
  padding: 40px 0;
}

.hero-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  text-align: center;
}

.site-title {
  font-size: 32px;
  font-weight: 600;
  color: #2c3e50;
  margin: 0 0 8px 0;
}

.site-desc {
  font-size: 16px;
  color: #6c757d;
  margin: 0 0 20px 0;
}

.hero-stats {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 12px;
  font-size: 14px;
  color: #6c757d;
}

.stat-item {
  color: #007bff;
}

.stat-divider {
  color: #dee2e6;
}

/* 主内容区域 */
.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 40px 20px;
}

/* 通用样式 */
.section-title {
  font-size: 20px;
  font-weight: 600;
  color: #2c3e50;
  margin: 0 0 20px 0;
  border-bottom: 2px solid #007bff;
  padding-bottom: 8px;
  display: inline-block;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.view-all {
  color: #007bff;
  text-decoration: none;
  font-size: 14px;
  transition: color 0.3s;
}

.view-all:hover {
  color: #0056b3;
  text-decoration: underline;
}

/* 学习模块 */
.modules-section {
  margin-bottom: 40px;
}

.modules-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.module-item {
  background: #fff;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  padding: 24px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.module-item:hover {
  border-color: #007bff;
  box-shadow: 0 4px 12px rgba(0,123,255,0.15);
  transform: translateY(-2px);
}

.module-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.module-name {
  font-size: 18px;
  font-weight: 600;
  color: #2c3e50;
  margin: 0 0 8px 0;
}

.module-desc {
  font-size: 14px;
  color: #6c757d;
  margin: 0 0 16px 0;
  line-height: 1.5;
}

.module-tags {
  display: flex;
  justify-content: center;
  gap: 8px;
  flex-wrap: wrap;
}

.tag {
  background: #e9ecef;
  color: #495057;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
}

/* 快速功能 */
.actions-section {
  margin-bottom: 40px;
}

.actions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 16px;
}

.action-item {
  background: #fff;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  padding: 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.action-item:hover {
  border-color: #007bff;
  background: #f8f9ff;
}

.action-icon {
  font-size: 32px;
  margin-bottom: 8px;
}

.action-name {
  font-size: 14px;
  color: #2c3e50;
  font-weight: 500;
}

/* 最近学习 */
.recent-section {
  margin-bottom: 40px;
}

.empty-state {
  background: #fff;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  padding: 40px;
  text-align: center;
  color: #6c757d;
}

.recent-list {
  background: #fff;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  overflow: hidden;
}

.recent-item {
  display: flex;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #f1f3f4;
  transition: background 0.3s ease;
}

.recent-item:last-child {
  border-bottom: none;
}

.recent-item:hover {
  background: #f8f9fa;
}

.recent-category {
  background: #007bff;
  color: #fff;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
  margin-right: 12px;
  min-width: 60px;
  text-align: center;
}

.recent-title {
  flex: 1;
  color: #2c3e50;
  font-size: 14px;
  margin-right: 12px;
}

.recent-time {
  color: #6c757d;
  font-size: 12px;
  white-space: nowrap;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .hero-section {
    padding: 30px 0;
  }
  
  .site-title {
    font-size: 24px;
  }
  
  .site-desc {
    font-size: 14px;
  }
  
  .hero-stats {
    font-size: 12px;
    flex-wrap: wrap;
    gap: 8px;
  }
  
  .stat-divider {
    display: none;
  }
  
  .main-content {
    padding: 30px 15px;
  }
  
  .modules-grid {
    grid-template-columns: 1fr;
    gap: 16px;
  }
  
  .module-item {
    padding: 20px;
  }
  
  .module-icon {
    font-size: 40px;
  }
  
  .module-name {
    font-size: 16px;
  }
  
  .module-desc {
    font-size: 13px;
  }
  
  .actions-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
  }
  
  .action-item {
    padding: 16px 12px;
  }
  
  .action-icon {
    font-size: 28px;
  }
  
  .action-name {
    font-size: 12px;
  }
  
  .recent-item {
    padding: 12px 16px;
  }
  
  .recent-category {
    min-width: 50px;
    margin-right: 8px;
  }
  
  .recent-title {
    font-size: 13px;
    margin-right: 8px;
  }
  
  .recent-time {
    font-size: 11px;
  }
}

@media (max-width: 480px) {
  .hero-content {
    padding: 0 15px;
  }
  
  .main-content {
    padding: 20px 10px;
  }
  
  .module-item {
    padding: 16px;
  }
  
  .actions-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .recent-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  
  .recent-category {
    margin-right: 0;
  }
  
  .recent-title {
    margin-right: 0;
  }
}
</style>