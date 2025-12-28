<template>
  <div class="tools-page">
    <el-container>
      <el-header class="page-header">
        <div class="header-content">
          <el-button type="text" @click="goBack" class="back-btn">
            ← 返回首页
          </el-button>
          <h1>🛠️ 学习工具</h1>
        </div>
      </el-header>

      <el-main class="main-content">
        <!-- 工具分类 -->
        <el-row :gutter="20" class="tools-categories">
          <el-col :xs="24" :sm="12" :md="6" v-for="category in toolCategories" :key="category.id">
            <el-card 
              class="category-card" 
              :class="{ active: selectedCategory === category.id }"
              @click="selectCategory(category.id)"
            >
              <div class="category-content">
                <span class="category-icon">{{ category.icon }}</span>
                <span class="category-name">{{ category.name }}</span>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 工具列表 -->
        <div class="tools-section">
          <div v-if="selectedCategory === 'linux'" class="tools-grid">
            <el-card v-for="tool in linuxTools" :key="tool.id" class="tool-card" @click="openTool(tool)">
              <div class="tool-content">
                <div class="tool-header">
                  <span class="tool-icon">{{ tool.icon }}</span>
                  <h3 class="tool-name">{{ tool.name }}</h3>
                </div>
                <p class="tool-description">{{ tool.description }}</p>
                <div class="tool-tags">
                  <el-tag v-for="tag in tool.tags" :key="tag" size="small">{{ tag }}</el-tag>
                </div>
              </div>
            </el-card>
          </div>

          <div v-else-if="selectedCategory === 'docker'" class="tools-grid">
            <el-card v-for="tool in dockerTools" :key="tool.id" class="tool-card" @click="openTool(tool)">
              <div class="tool-content">
                <div class="tool-header">
                  <span class="tool-icon">{{ tool.icon }}</span>
                  <h3 class="tool-name">{{ tool.name }}</h3>
                </div>
                <p class="tool-description">{{ tool.description }}</p>
                <div class="tool-tags">
                  <el-tag v-for="tag in tool.tags" :key="tag" size="small">{{ tag }}</el-tag>
                </div>
              </div>
            </el-card>
          </div>

          <div v-else-if="selectedCategory === 'network'" class="tools-grid">
            <el-card v-for="tool in networkTools" :key="tool.id" class="tool-card" @click="openTool(tool)">
              <div class="tool-content">
                <div class="tool-header">
                  <span class="tool-icon">{{ tool.icon }}</span>
                  <h3 class="tool-name">{{ tool.name }}</h3>
                </div>
                <p class="tool-description">{{ tool.description }}</p>
                <div class="tool-tags">
                  <el-tag v-for="tag in tool.tags" :key="tag" size="small">{{ tag }}</el-tag>
                </div>
              </div>
            </el-card>
          </div>
        </div>

        <!-- 工具对话框 -->
        <el-dialog 
          v-model="toolVisible" 
          :title="selectedTool?.name" 
          width="90%"
          class="tool-dialog"
        >
          <div v-if="selectedTool" class="tool-detail">
            <!-- Linux命令工具 -->
            <div v-if="selectedTool.type === 'linux-command'">
              <div class="tool-interface">
                <el-input 
                  v-model="commandInput" 
                  placeholder="输入Linux命令..." 
                  class="command-input"
                  @keyup.enter="executeCommand"
                >
                  <template #append>
                    <el-button type="primary" @click="executeCommand">执行</el-button>
                  </template>
                </el-input>
                
                <div class="command-output" v-if="commandOutput">
                  <h4>输出结果:</h4>
                  <pre>{{ commandOutput }}</pre>
                </div>
                
                <div class="command-history" v-if="commandHistory.length">
                  <h4>命令历史:</h4>
                  <div class="history-list">
                    <el-tag 
                      v-for="(cmd, index) in commandHistory" 
                      :key="index"
                      class="history-item"
                      @click="commandInput = cmd"
                    >
                      {{ cmd }}
                    </el-tag>
                  </div>
                </div>
              </div>
            </div>

            <!-- Docker命令工具 -->
            <div v-else-if="selectedTool.type === 'docker-command'">
              <div class="tool-interface">
                <el-input 
                  v-model="commandInput" 
                  placeholder="输入Docker命令..." 
                  class="command-input"
                  @keyup.enter="executeCommand"
                >
                  <template #append>
                    <el-button type="primary" @click="executeCommand">执行</el-button>
                  </template>
                </el-input>
                
                <div class="command-output" v-if="commandOutput">
                  <h4>输出结果:</h4>
                  <pre>{{ commandOutput }}</pre>
                </div>
              </div>
            </div>

            <!-- 文本处理工具 -->
            <div v-else-if="selectedTool.type === 'text-processor'">
              <div class="tool-interface">
                <el-input 
                  v-model="textInput" 
                  type="textarea" 
                  :rows="4" 
                  placeholder="输入要处理的文本..." 
                />
                
                <div class="text-actions">
                  <el-button @click="countLines">统计行数</el-button>
                  <el-button @click="countWords">统计单词</el-button>
                  <el-button @click="countChars">统计字符</el-button>
                  <el-button @click="sortLines">排序</el-button>
                  <el-button @click="uniqueLines">去重</el-button>
                </div>
                
                <div class="text-result" v-if="textResult">
                  <h4>处理结果:</h4>
                  <pre>{{ textResult }}</pre>
                </div>
              </div>
            </div>

            <!-- 编码转换工具 -->
            <div v-else-if="selectedTool.type === 'encoder'">
              <div class="tool-interface">
                <el-input 
                  v-model="encodeInput" 
                  type="textarea" 
                  :rows="4" 
                  placeholder="输入要编码/解码的内容..." 
                />
                
                <div class="encode-actions">
                  <el-button @click="encodeBase64">Base64编码</el-button>
                  <el-button @click="decodeBase64">Base64解码</el-button>
                  <el-button @click="encodeUrl">URL编码</el-button>
                  <el-button @click="decodeUrl">URL解码</el-button>
                </div>
                
                <div class="encode-result" v-if="encodeResult">
                  <h4>处理结果:</h4>
                  <pre>{{ encodeResult }}</pre>
                </div>
              </div>
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

interface ToolCategory {
  id: string
  name: string
  icon: string
}

interface Tool {
  id: string
  name: string
  description: string
  icon: string
  type: string
  tags: string[]
}

const router = useRouter()
const selectedCategory = ref('linux')
const toolVisible = ref(false)
const selectedTool = ref<Tool | null>(null)

// 工具输入状态
const commandInput = ref('')
const commandOutput = ref('')
const commandHistory = ref<string[]>([])

const textInput = ref('')
const textResult = ref('')

const encodeInput = ref('')
const encodeResult = ref('')

const toolCategories: ToolCategory[] = [
  { id: 'linux', name: 'Linux工具', icon: '🐧' },
  { id: 'docker', name: 'Docker工具', icon: '🐳' },
  { id: 'network', name: '网络工具', icon: '🌐' },
  { id: 'utility', name: '实用工具', icon: '🛠️' }
]

const linuxTools: Tool[] = [
  {
    id: 'linux-cmd',
    name: 'Linux命令模拟器',
    description: '在线执行和测试Linux命令',
    icon: '💻',
    type: 'linux-command',
    tags: ['模拟', '命令行', '学习']
  },
  {
    id: 'text-processor',
    name: '文本处理器',
    description: '文本统计、排序、去重等处理',
    icon: '📝',
    type: 'text-processor',
    tags: ['文本', '处理', '统计']
  },
  {
    id: 'file-permission',
    name: '文件权限计算器',
    description: '计算和转换Linux文件权限',
    icon: '🔐',
    type: 'file-permission',
    tags: ['权限', '计算', '转换']
  }
]

const dockerTools: Tool[] = [
  {
    id: 'docker-cmd',
    name: 'Docker命令助手',
    description: 'Docker命令生成和执行',
    icon: '🐳',
    type: 'docker-command',
    tags: ['Docker', '命令', '容器']
  },
  {
    id: 'dockerfile-gen',
    name: 'Dockerfile生成器',
    description: '快速生成Dockerfile配置',
    icon: '📄',
    type: 'dockerfile-generator',
    tags: ['Dockerfile', '生成器', '配置']
  },
  {
    id: 'compose-gen',
    name: 'Docker Compose生成器',
    description: '生成docker-compose.yml配置',
    icon: '🔧',
    type: 'compose-generator',
    tags: ['Compose', 'YAML', '编排']
  }
]

const networkTools: Tool[] = [
  {
    id: 'port-check',
    name: '端口检查工具',
    description: '检查端口连通性和状态',
    icon: '🔌',
    type: 'port-checker',
    tags: ['端口', '网络', '检查']
  },
  {
    id: 'encoder',
    name: '编码转换工具',
    description: 'Base64、URL编码转换',
    icon: '🔤',
    type: 'encoder',
    tags: ['编码', '转换', '加密']
  },
  {
    id: 'ip-calculator',
    name: 'IP地址计算器',
    description: 'IP网段和子网掩码计算',
    icon: '🌍',
    type: 'ip-calculator',
    tags: ['IP', '网络', '计算']
  }
]

onMounted(() => {
  // 初始化
})

const selectCategory = (categoryId: string) => {
  selectedCategory.value = categoryId
}

const openTool = (tool: Tool) => {
  selectedTool.value = tool
  toolVisible.value = true
  
  // 重置工具状态
  commandInput.value = ''
  commandOutput.value = ''
  textInput.value = ''
  textResult.value = ''
  encodeInput.value = ''
  encodeResult.value = ''
}

const goBack = () => {
  router.push('/')
}

// Linux命令模拟
const executeCommand = () => {
  if (!commandInput.value.trim()) {
    ElMessage.warning('请输入命令')
    return
  }
  
  // 添加到历史记录
  if (!commandHistory.value.includes(commandInput.value)) {
    commandHistory.value.unshift(commandInput.value)
    if (commandHistory.value.length > 10) {
      commandHistory.value.pop()
    }
  }
  
  // 模拟命令执行
  const cmd = commandInput.value.toLowerCase().trim()
  let output = ''
  
  if (cmd === 'ls') {
    output = 'Documents  Downloads  Music  Pictures  Videos  Desktop'
  } else if (cmd.startsWith('ls -la')) {
    output = `drwxr-xr-x  2 user user 4096 Dec 28 10:00 .
drwxr-xr-x 15 user user 4096 Dec 28 09:00 ..
-rw-r--r--  1 user user  220 Dec 28 08:00 .bash_logout
-rw-r--r--  1 user user 3771 Dec 28 08:00 .bashrc
drwxr-xr-x  2 user user 4096 Dec 28 10:00 Documents`
  } else if (cmd === 'pwd') {
    output = '/home/user'
  } else if (cmd === 'whoami') {
    output = 'user'
  } else if (cmd.startsWith('echo ')) {
    output = cmd.substring(5)
  } else if (cmd === 'date') {
    output = new Date().toString()
  } else if (cmd === 'uname -a') {
    output = 'Linux moyu-study 5.4.0 #1 SMP Thu Dec 28 10:00:00 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux'
  } else if (cmd === 'df -h') {
    output = `Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G   5G   15G  25% /
tmpfs           1.9G     0  1.9G   0% /dev/shm`
  } else {
    output = `bash: ${cmd.split(' ')[0]}: command not found\n提示: 这是一个模拟环境，仅支持部分基本命令`
  }
  
  commandOutput.value = output
  ElMessage.success('命令执行完成')
}

// 文本处理功能
const countLines = () => {
  if (!textInput.value) {
    ElMessage.warning('请输入文本')
    return
  }
  const lines = textInput.value.split('\n').length
  textResult.value = `行数: ${lines}`
}

const countWords = () => {
  if (!textInput.value) {
    ElMessage.warning('请输入文本')
    return
  }
  const words = textInput.value.trim().split(/\s+/).filter(word => word.length > 0).length
  textResult.value = `单词数: ${words}`
}

const countChars = () => {
  if (!textInput.value) {
    ElMessage.warning('请输入文本')
    return
  }
  const chars = textInput.value.length
  const charsNoSpace = textInput.value.replace(/\s/g, '').length
  textResult.value = `字符数 (含空格): ${chars}\n字符数 (不含空格): ${charsNoSpace}`
}

const sortLines = () => {
  if (!textInput.value) {
    ElMessage.warning('请输入文本')
    return
  }
  const lines = textInput.value.split('\n').sort()
  textResult.value = lines.join('\n')
}

const uniqueLines = () => {
  if (!textInput.value) {
    ElMessage.warning('请输入文本')
    return
  }
  const lines = Array.from(new Set(textInput.value.split('\n')))
  textResult.value = lines.join('\n')
}

// 编码转换功能
const encodeBase64 = () => {
  if (!encodeInput.value) {
    ElMessage.warning('请输入内容')
    return
  }
  try {
    encodeResult.value = btoa(unescape(encodeURIComponent(encodeInput.value)))
    ElMessage.success('Base64编码完成')
  } catch (error) {
    ElMessage.error('编码失败')
  }
}

const decodeBase64 = () => {
  if (!encodeInput.value) {
    ElMessage.warning('请输入内容')
    return
  }
  try {
    encodeResult.value = decodeURIComponent(escape(atob(encodeInput.value)))
    ElMessage.success('Base64解码完成')
  } catch (error) {
    ElMessage.error('解码失败，请检查输入格式')
  }
}

const encodeUrl = () => {
  if (!encodeInput.value) {
    ElMessage.warning('请输入内容')
    return
  }
  encodeResult.value = encodeURIComponent(encodeInput.value)
  ElMessage.success('URL编码完成')
}

const decodeUrl = () => {
  if (!encodeInput.value) {
    ElMessage.warning('请输入内容')
    return
  }
  try {
    encodeResult.value = decodeURIComponent(encodeInput.value)
    ElMessage.success('URL解码完成')
  } catch (error) {
    ElMessage.error('解码失败，请检查输入格式')
  }
}
</script>

<style scoped>
.tools-page {
  min-height: 100vh;
  background: #f8f9fa;
}

.page-header {
  background: #fff;
  border-bottom: 1px solid #e9ecef;
  padding: 20px 0;
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  display: flex;
  align-items: center;
}

.back-btn {
  margin-right: 20px;
  font-size: 16px;
  color: #007bff;
}

.header-content h1 {
  margin: 0;
  font-size: 24px;
  color: #2c3e50;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 30px 20px;
}

/* 分类导航 */
.tools-categories {
  margin-bottom: 30px;
}

.category-card {
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: center;
  border: 1px solid #e9ecef;
}

.category-card:hover {
  border-color: #007bff;
  transform: translateY(-2px);
}

.category-card.active {
  border-color: #007bff;
  background: #f8f9ff;
}

.category-content {
  padding: 20px;
}

.category-icon {
  font-size: 32px;
  display: block;
  margin-bottom: 8px;
}

.category-name {
  font-size: 14px;
  font-weight: 500;
  color: #495057;
}

/* 工具网格 */
.tools-section {
  margin-top: 20px;
}

.tools-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.tool-card {
  cursor: pointer;
  transition: all 0.3s ease;
  height: 100%;
}

.tool-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
}

.tool-content {
  padding: 20px;
}

.tool-header {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
}

.tool-icon {
  font-size: 28px;
  margin-right: 12px;
}

.tool-name {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #2c3e50;
}

.tool-description {
  color: #6c757d;
  margin: 0 0 12px 0;
  line-height: 1.5;
}

.tool-tags {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

/* 工具对话框 */
.tool-interface {
  max-height: 60vh;
  overflow-y: auto;
}

.command-input,
.text-input {
  margin-bottom: 20px;
}

.command-output,
.text-result,
.encode-result {
  margin-top: 20px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 6px;
  border-left: 4px solid #007bff;
}

.command-output h4,
.text-result h4,
.encode-result h4 {
  margin: 0 0 10px 0;
  font-size: 14px;
  color: #495057;
}

.command-output pre,
.text-result pre,
.encode-result pre {
  margin: 0;
  font-family: 'Courier New', monospace;
  font-size: 13px;
  line-height: 1.5;
  white-space: pre-wrap;
  word-break: break-word;
}

.text-actions,
.encode-actions {
  margin: 15px 0;
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.command-history {
  margin-top: 20px;
}

.command-history h4 {
  margin: 0 0 10px 0;
  font-size: 14px;
  color: #495057;
}

.history-list {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.history-item {
  cursor: pointer;
  transition: all 0.3s ease;
}

.history-item:hover {
  background: #e9ecef;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .header-content {
    padding: 0 15px;
  }
  
  .main-content {
    padding: 20px 15px;
  }
  
  .tools-grid {
    grid-template-columns: 1fr;
  }
  
  .tool-content {
    padding: 15px;
  }
  
  .text-actions,
  .encode-actions {
    flex-direction: column;
  }
  
  .tool-interface {
    max-height: 70vh;
  }
}
</style>