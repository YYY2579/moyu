<template>
  <div class="home">
    <el-container>
      <el-header class="header">
        <h1>🐟 摸鱼学习站</h1>
      </el-header>
      <el-main class="main">
        <el-row :gutter="20">
          <el-col :xs="24" :sm="12" :md="8">
            <el-card class="card" shadow="hover">
              <template #header>
                <div class="card-header">
                  <span>📚 题库管理</span>
                </div>
              </template>
              <div class="card-content">
                <p>管理各类题目，支持批量导入导出</p>
                <el-button type="primary" plain>查看题库</el-button>
              </div>
            </el-card>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8">
            <el-card class="card" shadow="hover">
              <template #header>
                <div class="card-header">
                  <span>✏️ 每日练习</span>
                </div>
              </template>
              <div class="card-content">
                <p>每日智能推荐练习题目</p>
                <el-button type="success" plain>开始练习</el-button>
              </div>
            </el-card>
          </el-col>
          <el-col :xs="24" :sm="12" :md="8">
            <el-card class="card" shadow="hover">
              <template #header>
                <div class="card-header">
                  <span>📊 学习统计</span>
                </div>
              </template>
              <div class="card-content">
                <p>查看学习进度和统计数据</p>
                <el-button type="warning" plain>查看统计</el-button>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <el-divider />

        <el-card class="welcome-card">
          <h2>🎉 欢迎使用摸鱼学习站</h2>
          <p class="welcome-text">一个优雅的在线学习管理系统，助您高效学习</p>
          <div class="features">
            <el-tag type="success">响应式设计</el-tag>
            <el-tag type="primary">题库管理</el-tag>
            <el-tag type="warning">数据统计</el-tag>
            <el-tag type="danger">老板模式</el-tag>
          </div>
        </el-card>
      </el-main>
    </el-container>
  </div>
</template>

<script setup lang="ts">
// Home page component
console.log('Home component loaded')
</script>

<style scoped>
.home {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.header {
  background: #409eff;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.header h1 {
  font-size: 24px;
  font-weight: 600;
}

.main {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.card {
  margin-bottom: 20px;
  height: 100%;
}

.card-header {
  font-size: 16px;
  font-weight: 600;
}

.card-content {
  padding: 20px 0;
}

.card-content p {
  color: #666;
  margin-bottom: 15px;
  line-height: 1.6;
}

.welcome-card {
  background: white;
  margin-bottom: 20px;
}

.welcome-card h2 {
  color: #333;
  margin-bottom: 15px;
}

.welcome-text {
  color: #666;
  font-size: 16px;
  margin-bottom: 20px;
  line-height: 1.6;
}

.features {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.el-divider {
  margin: 30px 0;
}

@media (max-width: 768px) {
  .header h1 {
    font-size: 20px;
  }

  .main {
    padding: 15px;
  }
}
</style>