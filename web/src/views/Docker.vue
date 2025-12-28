<template>
  <div class="docker-page">
    <el-container>
      <el-header class="page-header">
        <div class="header-content">
          <el-button type="text" @click="goBack" class="back-btn">
            ← 返回首页
          </el-button>
          <h1>🐳 Docker 容器技术</h1>
        </div>
      </el-header>

      <el-main class="main-content">
        <!-- 学习路径 -->
        <el-card class="learning-path">
          <template #header>
            <span>🎯 学习路径</span>
          </template>
          <el-steps :active="currentStep" finish-status="success" align-center>
            <el-step 
              v-for="(step, index) in learningSteps" 
              :key="index"
              :title="step.title" 
              :description="step.description"
              @click="setCurrentStep(index)"
              class="step-item"
            />
          </el-steps>
        </el-card>

        <!-- 知识模块 -->
        <el-row :gutter="20" class="modules-section">
          <el-col :xs="24" :sm="12" :md="8" v-for="module in dockerModules" :key="module.id">
            <el-card 
              class="module-card" 
              shadow="hover"
              @click="showModuleDetail(module)"
            >
              <template #header>
                <div class="module-header">
                  <span class="module-icon">{{ module.icon }}</span>
                  <span class="module-title">{{ module.title }}</span>
                  <el-tag :type="getLevelType(module.level)" size="small">
                    {{ module.level }}
                  </el-tag>
                </div>
              </template>
              <div class="module-content">
                <p class="module-desc">{{ module.description }}</p>
                <div class="module-stats">
                  <span class="stat-item">
                    📚 {{ module.topics.length }} 个知识点
                  </span>
                  <span class="stat-item">
                    ⏱️ {{ module.duration }}
                  </span>
                </div>
                <div class="module-progress">
                  <el-progress 
                    :percentage="module.progress" 
                    :color="getProgressColor(module.progress)"
                    :show-text="false"
                    :stroke-width="6"
                  />
                  <span class="progress-text">{{ module.progress }}% 完成</span>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 快速命令参考 -->
        <el-card class="quick-commands">
          <template #header>
            <div class="section-header">
              <span>⚡ 快速命令参考</span>
              <el-button type="primary" size="small" @click="showAllCommands">
                查看全部命令
              </el-button>
            </div>
          </template>

          <div class="command-categories">
            <el-tabs v-model="activeCommandTab" type="card">
              <el-tab-pane 
                v-for="category in commandCategories" 
                :key="category.id"
                :label="category.name" 
                :name="category.id"
              >
                <div class="command-list">
                  <div 
                    v-for="cmd in category.commands" 
                    :key="cmd.name"
                    class="command-card"
                    @click="showCommandDetail(cmd)"
                  >
                    <div class="command-info">
                      <code class="command-name">{{ cmd.name }}</code>
                      <p class="command-desc">{{ cmd.description }}</p>
                    </div>
                    <el-button size="small" type="primary" plain @click.stop="copyCommand(cmd.name)">
                      复制
                    </el-button>
                  </div>
                </div>
              </el-tab-pane>
            </el-tabs>
          </div>
        </el-card>

        <!-- 实践项目 -->
        <el-card class="practice-projects">
          <template #header>
            <span>🛠️ 实践项目</span>
          </template>
          
          <el-row :gutter="20">
            <el-col :xs="24" :md="12" v-for="project in practiceProjects" :key="project.id">
              <div class="project-card" @click="showProjectDetail(project)">
                <div class="project-header">
                  <h3>{{ project.title }}</h3>
                  <el-tag :type="getDifficultyType(project.difficulty)" size="small">
                    {{ project.difficulty }}
                  </el-tag>
                </div>
                <p class="project-desc">{{ project.description }}</p>
                <div class="project-tech">
                  <el-tag v-for="tech in project.technologies" :key="tech" size="small" plain>
                    {{ tech }}
                  </el-tag>
                </div>
                <div class="project-stats">
                  <span>⏱️ {{ project.duration }}</span>
                  <span>📋 {{ project.steps }} 步骤</span>
                </div>
              </div>
            </el-col>
          </el-row>
        </el-card>
      </el-main>
    </el-container>

    <!-- 模块详情对话框 -->
    <el-dialog v-model="moduleDetailVisible" :title="selectedModule?.title" width="70%">
      <div v-if="selectedModule" class="module-detail">
        <el-tabs v-model="activeModuleTab">
          <el-tab-pane label="知识点" name="topics">
            <div class="topics-list">
              <div 
                v-for="(topic, index) in selectedModule.topics" 
                :key="index"
                class="topic-item"
              >
                <h4>{{ topic.title }}</h4>
                <p>{{ topic.content }}</p>
                <div v-if="topic.example" class="topic-example">
                  <strong>示例：</strong>
                  <code>{{ topic.example }}</code>
                </div>
              </div>
            </div>
          </el-tab-pane>
          <el-tab-pane label="练习" name="practice">
            <div class="practice-content">
              <el-button type="primary" size="large" @click="startModulePractice">
                开始 {{ selectedModule.title }} 练习
              </el-button>
            </div>
          </el-tab-pane>
        </el-tabs>
      </div>
    </el-dialog>

    <!-- 命令详情对话框 -->
    <el-dialog v-model="commandDetailVisible" :title="selectedCommand?.name" width="60%">
      <div v-if="selectedCommand" class="command-detail">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="命令名称">
            <code>{{ selectedCommand.name }}</code>
          </el-descriptions-item>
          <el-descriptions-item label="功能描述">
            {{ selectedCommand.description }}
          </el-descriptions-item>
          <el-descriptions-item label="语法格式">
            <code class="syntax">{{ selectedCommand.syntax }}</code>
          </el-descriptions-item>
          <el-descriptions-item label="常用选项">
            <div v-for="option in selectedCommand.options" :key="option.flag">
              <code>{{ option.flag }}</code> - {{ option.description }}
            </div>
          </el-descriptions-item>
        </el-descriptions>

        <div class="command-examples">
          <h4>使用示例</h4>
          <div v-for="example in selectedCommand.examples" :key="example.command">
            <p>{{ example.description }}</p>
            <el-input :model-value="example.command" readonly>
              <template #append>
                <el-button @click="copyCommand(example.command)">复制</el-button>
              </template>
            </el-input>
          </div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'

interface Module {
  id: number
  title: string
  icon: string
  description: string
  level: '入门' | '进阶' | '高级'
  topics: Array<{
    title: string
    content: string
    example?: string
  }>
  duration: string
  progress: number
}

interface Command {
  name: string
  description: string
  syntax?: string
  options?: Array<{
    flag: string
    description: string
  }>
  examples?: Array<{
    description: string
    command: string
  }>
}

interface Project {
  id: number
  title: string
  description: string
  difficulty: '初级' | '中级' | '高级'
  technologies: string[]
  duration: string
  steps: number
}

const router = useRouter()

const currentStep = ref(1)
const moduleDetailVisible = ref(false)
const commandDetailVisible = ref(false)
const activeModuleTab = ref('topics')
const activeCommandTab = ref('basic')

const selectedModule = ref<Module | null>(null)
const selectedCommand = ref<Command | null>(null)

const learningSteps = [
  { title: '基础概念', description: '了解容器和Docker基本概念' },
  { title: '镜像管理', description: '学习Docker镜像的构建和管理' },
  { title: '容器操作', description: '掌握容器的创建和管理' },
  { title: '网络配置', description: '理解Docker网络和通信' },
  { title: '数据卷', description: '学习数据持久化和共享' }
]

const dockerModules: Module[] = [
  {
    id: 1,
    title: 'Docker 基础',
    icon: '🏠',
    description: 'Docker 核心概念和基础操作',
    level: '入门',
    topics: [
      { title: '什么是容器', content: '容器是一种轻量级的虚拟化技术，它将应用程序及其依赖打包在一起', example: 'docker --version' },
      { title: 'Docker 安装', content: '在不同操作系统上安装Docker的方法', example: 'curl -sSL https://get.docker.com/ | sh' },
      { title: '镜像与容器', content: '理解镜像和容器的关系', example: 'docker run hello-world' }
    ],
    duration: '2小时',
    progress: 80
  },
  {
    id: 2,
    title: '镜像管理',
    icon: '📦',
    description: '构建、推送和管理Docker镜像',
    level: '进阶',
    topics: [
      { title: '拉取镜像', content: '从Docker Hub拉取公共镜像', example: 'docker pull ubuntu:20.04' },
      { title: '构建镜像', content: '使用Dockerfile构建自定义镜像', example: 'docker build -t myapp .' },
      { title: '镜像优化', content: '减小镜像体积的最佳实践' }
    ],
    duration: '3小时',
    progress: 45
  },
  {
    id: 3,
    title: '容器编排',
    icon: '🎼',
    description: '使用Docker Compose管理多容器应用',
    level: '高级',
    topics: [
      { title: 'Docker Compose 基础', content: '编写docker-compose.yml文件', example: 'docker-compose up -d' },
      { title: '服务发现', content: '容器间的通信和服务发现机制' },
      { title: '负载均衡', content: '在Docker中实现负载均衡' }
    ],
    duration: '4小时',
    progress: 20
  }
]

const commandCategories = [
  {
    id: 'basic',
    name: '基础命令',
    commands: [
      { name: 'docker run', description: '创建并运行容器' },
      { name: 'docker ps', description: '查看运行的容器' },
      { name: 'docker images', description: '查看本地镜像' },
      { name: 'docker pull', description: '拉取镜像' }
    ]
  },
  {
    id: 'manage',
    name: '管理命令',
    commands: [
      { name: 'docker stop', description: '停止容器' },
      { name: 'docker start', description: '启动容器' },
      { name: 'docker restart', description: '重启容器' },
      { name: 'docker rm', description: '删除容器' }
    ]
  }
]

const practiceProjects: Project[] = [
  {
    id: 1,
    title: '构建Node.js Web应用',
    description: '使用Docker构建和部署一个Node.js Web应用，包含数据库连接',
    difficulty: '初级',
    technologies: ['Node.js', 'Express', 'MongoDB'],
    duration: '1小时',
    steps: 8
  },
  {
    id: 2,
    title: '微服务架构实践',
    description: '使用Docker Compose部署一个完整的微服务架构应用',
    difficulty: '高级',
    technologies: ['Docker Compose', 'Nginx', 'Redis', 'MySQL'],
    duration: '3小时',
    steps: 15
  }
]

const setCurrentStep = (index: number) => {
  currentStep.value = index
  ElMessage.info(`切换到${learningSteps[index].title}阶段`)
}

const showModuleDetail = (module: Module) => {
  selectedModule.value = module
  moduleDetailVisible.value = true
}

const showCommandDetail = (command: Command) => {
  selectedCommand.value = command
  commandDetailVisible.value = true
}

const showProjectDetail = (project: Project) => {
  ElMessage.info(`${project.title} 实践项目详情开发中...`)
}

const showAllCommands = () => {
  ElMessage.info('全部命令手册开发中...')
}

const copyCommand = async (command: string) => {
  try {
    await navigator.clipboard.writeText(command)
    ElMessage.success('命令已复制到剪贴板')
  } catch (err) {
    ElMessage.error('复制失败，请手动复制')
  }
}

const startModulePractice = () => {
  if (selectedModule.value) {
    router.push({
      path: '/practice',
      query: { module: selectedModule.value.title }
    })
  }
}

const getLevelType = (level: string) => {
  switch (level) {
    case '入门': return 'success'
    case '进阶': return 'warning'
    case '高级': return 'danger'
    default: return 'info'
  }
}

const getDifficultyType = (difficulty: string) => {
  switch (difficulty) {
    case '初级': return 'success'
    case '中级': return 'warning'
    case '高级': return 'danger'
    default: return 'info'
  }
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
  console.log('Docker learning page loaded')
})
</script>

<style scoped>
.docker-page {
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

.learning-path {
  margin-bottom: 30px;
  border: none;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.step-item {
  cursor: pointer;
}

.modules-section {
  margin-bottom: 30px;
}

.module-card {
  border: none;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transition: all 0.3s ease;
  cursor: pointer;
  margin-bottom: 20px;
  height: 100%;
}

.module-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.15);
}

.module-header {
  display: flex;
  align-items: center;
  gap: 12px;
}

.module-icon {
  font-size: 24px;
}

.module-title {
  flex: 1;
  font-weight: 600;
  font-size: 16px;
}

.module-desc {
  color: #666;
  line-height: 1.6;
  margin-bottom: 16px;
  font-size: 14px;
}

.module-stats {
  display: flex;
  justify-content: space-between;
  margin-bottom: 12px;
}

.stat-item {
  font-size: 12px;
  color: #999;
}

.module-progress {
  display: flex;
  align-items: center;
  gap: 12px;
}

.progress-text {
  font-size: 12px;
  color: #666;
  min-width: 50px;
}

.quick-commands,
.practice-projects {
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

.command-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
  margin-top: 20px;
}

.command-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #f8f9fa;
  padding: 16px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.command-card:hover {
  background: #e9ecef;
  transform: translateY(-2px);
}

.command-info {
  flex: 1;
}

.command-name {
  font-weight: 600;
  color: #409eff;
  background: #f0f8ff;
  padding: 4px 8px;
  border-radius: 4px;
  display: inline-block;
  margin-bottom: 8px;
}

.command-desc {
  color: #666;
  font-size: 14px;
  margin: 0;
}

.project-card {
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  height: 100%;
}

.project-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0,0,0,0.1);
  border-color: #409eff;
}

.project-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.project-header h3 {
  margin: 0;
  color: #333;
  font-size: 16px;
}

.project-desc {
  color: #666;
  line-height: 1.6;
  margin-bottom: 16px;
  font-size: 14px;
}

.project-tech {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  margin-bottom: 12px;
}

.project-stats {
  display: flex;
  gap: 20px;
  font-size: 12px;
  color: #999;
}

.module-detail,
.command-detail {
  max-height: 60vh;
  overflow-y: auto;
}

.syntax {
  background: #f8f9fa;
  padding: 8px 12px;
  border-radius: 4px;
  border: 1px solid #e9ecef;
  display: inline-block;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
}

.command-examples {
  margin-top: 20px;
}

.command-examples h4 {
  margin-bottom: 12px;
  color: #333;
}

.command-examples > div {
  margin-bottom: 16px;
}

.command-examples p {
  color: #666;
  margin-bottom: 8px;
  font-size: 14px;
}

.topics-list {
  max-height: 50vh;
  overflow-y: auto;
}

.topic-item {
  margin-bottom: 24px;
  padding-bottom: 24px;
  border-bottom: 1px solid #e9ecef;
}

.topic-item:last-child {
  border-bottom: none;
}

.topic-item h4 {
  color: #333;
  margin-bottom: 8px;
}

.topic-item p {
  color: #666;
  line-height: 1.6;
  margin-bottom: 12px;
}

.topic-example {
  background: #f8f9fa;
  padding: 12px;
  border-radius: 4px;
  border: 1px solid #e9ecef;
}

.topic-example strong {
  color: #333;
}

.practice-content {
  text-align: center;
  padding: 40px 0;
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
  
  .command-list {
    grid-template-columns: 1fr;
    gap: 12px;
  }
  
  .section-header {
    flex-direction: column;
    gap: 12px;
    align-items: stretch;
  }
}
</style>