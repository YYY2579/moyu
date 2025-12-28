<template>
  <div class="linux-page">
    <el-container>
      <el-header class="page-header">
        <div class="header-content">
          <el-button type="text" @click="goBack" class="back-btn">
            ← 返回首页
          </el-button>
          <h1>🐧 Linux 命令学习</h1>
        </div>
      </el-header>

      <el-main class="main-content">
        <!-- 分类导航 -->
        <el-row :gutter="20" class="category-nav">
          <el-col :xs="24" :sm="12" :md="6" v-for="category in categories" :key="category.id">
            <el-card 
              class="category-card" 
              :class="{ active: selectedCategory === category.id }"
              @click="selectCategory(category.id)"
            >
              <div class="category-content">
                <span class="category-icon">{{ category.icon }}</span>
                <span class="category-name">{{ category.name }}</span>
                <el-badge :value="category.count" class="category-badge" />
              </div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 命令列表 -->
        <el-card class="commands-section">
          <template #header>
            <div class="section-header">
              <span>📋 {{ currentCategoryName }}命令列表</span>
              <div class="search-box">
                <el-input 
                  v-model="searchQuery" 
                  placeholder="搜索命令..." 
                  prefix-icon="Search"
                  clearable
                  @input="handleSearch"
                />
              </div>
            </div>
          </template>

          <div class="commands-grid">
            <div 
              v-for="command in filteredCommands" 
              :key="command.id"
              class="command-item"
              @click="showCommandDetail(command)"
            >
              <div class="command-header">
                <code class="command-name">{{ command.name }}</code>
                <el-tag :type="getDifficultyType(command.difficulty)" size="small">
                  {{ command.difficulty }}
                </el-tag>
              </div>
              <p class="command-desc">{{ command.description }}</p>
              <div class="command-tags">
                <el-tag v-for="tag in command.tags" :key="tag" size="small" plain>
                  {{ tag }}
                </el-tag>
              </div>
            </div>
          </div>

          <el-empty v-if="filteredCommands.length === 0" description="没有找到相关命令" />
        </el-card>

        <!-- 命令详情对话框 -->
        <el-dialog 
          v-model="detailVisible" 
          :title="selectedCommand?.name" 
          width="80%"
          class="command-dialog"
        >
          <div v-if="selectedCommand" class="command-detail">
            <el-descriptions :column="2" border>
              <el-descriptions-item label="命令名称">
                <code>{{ selectedCommand.name }}</code>
              </el-descriptions-item>
              <el-descriptions-item label="难度等级">
                <el-tag :type="getDifficultyType(selectedCommand.difficulty)">
                  {{ selectedCommand.difficulty }}
                </el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="功能描述" :span="2">
                {{ selectedCommand.description }}
              </el-descriptions-item>
              <el-descriptions-item label="语法格式" :span="2">
                <code class="syntax-code">{{ selectedCommand.syntax }}</code>
              </el-descriptions-item>
            </el-descriptions>

            <div class="usage-section">
              <h3>📖 使用示例</h3>
              <div v-for="(example, index) in selectedCommand.examples" :key="index" class="example-item">
                <p class="example-desc">{{ example.description }}</p>
                <el-input 
                  :model-value="example.command" 
                  readonly 
                  class="example-code"
                >
                  <template #append>
                    <el-button @click="copyCommand(example.command)">复制</el-button>
                  </template>
                </el-input>
              </div>
            </div>

            <div class="practice-section">
              <h3>🎯 相关练习</h3>
              <el-button type="primary" @click="startCommandPractice(selectedCommand)">
                开始 {{ selectedCommand.name }} 相关练习
              </el-button>
            </div>
          </div>
        </el-dialog>
      </el-main>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'

interface Category {
  id: string
  name: string
  icon: string
  count: number
}

interface CommandExample {
  description: string
  command: string
}

interface Command {
  id: number
  name: string
  description: string
  category: string
  difficulty: '初级' | '中级' | '高级'
  syntax: string
  examples: CommandExample[]
  tags: string[]
}

const router = useRouter()

const categories = ref<Category[]>([
  { id: 'file', name: '文件操作', icon: '📁', count: 45 },
  { id: 'system', name: '系统管理', icon: '⚙️', count: 38 },
  { id: 'network', name: '网络配置', icon: '🌐', count: 32 },
  { id: 'shell', name: 'Shell脚本', icon: '📜', count: 25 }
])

const selectedCategory = ref<string>('file')
const searchQuery = ref<string>('')
const detailVisible = ref<boolean>(false)
const selectedCommand = ref<Command | null>(null)

const commands = ref<Command[]>([
  {
    id: 1,
    name: 'ls',
    description: '列出目录内容',
    category: 'file',
    difficulty: '初级',
    syntax: 'ls [选项] [文件或目录]',
    examples: [
      { description: '列出当前目录内容', command: 'ls' },
      { description: '详细列出所有文件（包括隐藏文件）', command: 'ls -la' },
      { description: '按时间排序显示', command: 'ls -lt' }
    ],
    tags: ['文件', '目录', '常用']
  },
  {
    id: 2,
    name: 'cd',
    description: '切换工作目录',
    category: 'file',
    difficulty: '初级',
    syntax: 'cd [目录路径]',
    examples: [
      { description: '切换到用户主目录', command: 'cd ~' },
      { description: '切换到上级目录', command: 'cd ..' },
      { description: '切换到指定目录', command: 'cd /home/user/documents' }
    ],
    tags: ['目录', '导航', '基础']
  },
  {
    id: 3,
    name: 'grep',
    description: '文本搜索工具',
    category: 'file',
    difficulty: '中级',
    syntax: 'grep [选项] 模式 文件',
    examples: [
      { description: '在文件中搜索特定文本', command: 'grep "error" logfile.txt' },
      { description: '递归搜索目录', command: 'grep -r "function" /src/' },
      { description: '显示行号', command: 'grep -n "import" app.js' }
    ],
    tags: ['搜索', '文本', '正则']
  },
  {
    id: 4,
    name: 'chmod',
    description: '修改文件权限',
    category: 'system',
    difficulty: '中级',
    syntax: 'chmod [选项] 模式 文件',
    examples: [
      { description: '给文件添加执行权限', command: 'chmod +x script.sh' },
      { description: '设置权限为755', command: 'chmod 755 file.txt' },
      { description: '递归修改目录权限', command: 'chmod -R 644 /var/www/' }
    ],
    tags: ['权限', '安全', '文件']
  }
])

const currentCategoryName = computed(() => {
  const category = categories.value.find(cat => cat.id === selectedCategory.value)
  return category ? category.name : '全部'
})

const filteredCommands = computed(() => {
  let filtered = commands.value.filter(cmd => cmd.category === selectedCategory.value)
  
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(cmd => 
      cmd.name.toLowerCase().includes(query) ||
      cmd.description.toLowerCase().includes(query) ||
      cmd.tags.some(tag => tag.toLowerCase().includes(query))
    )
  }
  
  return filtered
})

const selectCategory = (categoryId: string) => {
  selectedCategory.value = categoryId
  ElMessage.success(`切换到${currentCategoryName.value}分类`)
}

const handleSearch = () => {
  // 搜索功能已在computed中实现
  console.log('搜索:', searchQuery.value)
}

const showCommandDetail = (command: Command) => {
  selectedCommand.value = command
  detailVisible.value = true
}

const getDifficultyType = (difficulty: string) => {
  switch (difficulty) {
    case '初级': return 'success'
    case '中级': return 'warning'
    case '高级': return 'danger'
    default: return 'info'
  }
}

const copyCommand = async (command: string) => {
  try {
    await navigator.clipboard.writeText(command)
    ElMessage.success('命令已复制到剪贴板')
  } catch (err) {
    ElMessage.error('复制失败，请手动复制')
  }
}

const startCommandPractice = (command: Command) => {
  router.push({
    path: '/practice',
    query: { command: command.name }
  })
}

const goBack = () => {
  router.push('/')
}

onMounted(() => {
  console.log('Linux learning page loaded')
})
</script>

<style scoped>
.linux-page {
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

.category-nav {
  margin-bottom: 30px;
}

.category-card {
  border: none;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transition: all 0.3s ease;
  cursor: pointer;
  margin-bottom: 20px;
}

.category-card:hover,
.category-card.active {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.15);
}

.category-card.active {
  background: linear-gradient(135deg, #409eff 0%, #364d79 100%);
  color: white;
}

.category-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
}

.category-icon {
  font-size: 24px;
  margin-right: 12px;
}

.category-name {
  flex: 1;
  font-weight: 600;
  font-size: 16px;
}

.commands-section {
  border: none;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 16px;
  font-weight: 600;
}

.search-box {
  width: 300px;
}

.commands-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.command-item {
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.command-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0,0,0,0.1);
  border-color: #409eff;
}

.command-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.command-name {
  font-size: 18px;
  font-weight: 600;
  color: #409eff;
  background: #f0f8ff;
  padding: 4px 8px;
  border-radius: 4px;
}

.command-desc {
  color: #666;
  line-height: 1.6;
  margin-bottom: 12px;
  font-size: 14px;
}

.command-tags {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.command-dialog .el-dialog__body {
  padding: 20px;
}

.command-detail {
  max-height: 70vh;
  overflow-y: auto;
}

.syntax-code {
  background: #f8f9fa;
  padding: 8px 12px;
  border-radius: 4px;
  border: 1px solid #e9ecef;
  display: inline-block;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
}

.usage-section,
.practice-section {
  margin-top: 24px;
}

.usage-section h3,
.practice-section h3 {
  margin-bottom: 16px;
  color: #333;
  font-size: 16px;
}

.example-item {
  margin-bottom: 16px;
}

.example-desc {
  color: #666;
  margin-bottom: 8px;
  font-size: 14px;
}

.example-code {
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
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
  
  .section-header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }
  
  .search-box {
    width: 100%;
  }
  
  .commands-grid {
    grid-template-columns: 1fr;
    gap: 16px;
  }
  
  .category-content {
    padding: 12px;
  }
}
</style>