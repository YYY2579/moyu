<template>
  <div class="shortcuts-page">
    <el-container>
      <el-header class="page-header">
        <div class="header-content">
          <el-button type="text" @click="goBack" class="back-btn">
            ← 返回首页
          </el-button>
          <h1>⌨️ 快捷键参考</h1>
        </div>
      </el-header>

      <el-main class="main-content">
        <!-- 搜索框 -->
        <div class="search-section">
          <el-input 
            v-model="searchQuery" 
            placeholder="搜索快捷键..." 
            prefix-icon="Search"
            clearable
            class="search-input"
          />
        </div>

        <!-- 快捷键分类 -->
        <el-tabs v-model="activeTab" class="shortcuts-tabs">
          <el-tab-pane label="Linux 终端" name="linux">
            <div class="shortcuts-grid">
              <el-card 
                v-for="shortcut in filteredLinuxShortcuts" 
                :key="shortcut.id"
                class="shortcut-card"
              >
                <div class="shortcut-content">
                  <div class="shortcut-header">
                    <kbd class="shortcut-keys">{{ shortcut.keys }}</kbd>
                    <span class="shortcut-category">{{ shortcut.category }}</span>
                  </div>
                  <h4 class="shortcut-title">{{ shortcut.title }}</h4>
                  <p class="shortcut-description">{{ shortcut.description }}</p>
                  <div class="shortcut-example" v-if="shortcut.example">
                    <strong>示例:</strong> {{ shortcut.example }}
                  </div>
                </div>
              </el-card>
            </div>
          </el-tab-pane>

          <el-tab-pane label="Vim 编辑器" name="vim">
            <div class="shortcuts-grid">
              <el-card 
                v-for="shortcut in filteredVimShortcuts" 
                :key="shortcut.id"
                class="shortcut-card"
              >
                <div class="shortcut-content">
                  <div class="shortcut-header">
                    <kbd class="shortcut-keys">{{ shortcut.keys }}</kbd>
                    <span class="shortcut-category">{{ shortcut.mode }}</span>
                  </div>
                  <h4 class="shortcut-title">{{ shortcut.title }}</h4>
                  <p class="shortcut-description">{{ shortcut.description }}</p>
                  <div class="shortcut-example" v-if="shortcut.example">
                    <strong>示例:</strong> {{ shortcut.example }}
                  </div>
                </div>
              </el-card>
            </div>
          </el-tab-pane>

          <el-tab-pane label="Git 版本控制" name="git">
            <div class="shortcuts-grid">
              <el-card 
                v-for="shortcut in filteredGitShortcuts" 
                :key="shortcut.id"
                class="shortcut-card"
              >
                <div class="shortcut-content">
                  <div class="shortcut-header">
                    <kbd class="shortcut-keys">{{ shortcut.keys }}</kbd>
                    <span class="shortcut-category">{{ shortcut.category }}</span>
                  </div>
                  <h4 class="shortcut-title">{{ shortcut.title }}</h4>
                  <p class="shortcut-description">{{ shortcut.description }}</p>
                  <div class="shortcut-example" v-if="shortcut.example">
                    <strong>示例:</strong> {{ shortcut.example }}
                  </div>
                </div>
              </el-card>
            </div>
          </el-tab-pane>

          <el-tab-pane label="Docker 命令" name="docker">
            <div class="shortcuts-grid">
              <el-card 
                v-for="shortcut in filteredDockerShortcuts" 
                :key="shortcut.id"
                class="shortcut-card"
              >
                <div class="shortcut-content">
                  <div class="shortcut-header">
                    <kbd class="shortcut-keys">{{ shortcut.keys }}</kbd>
                    <span class="shortcut-category">{{ shortcut.category }}</span>
                  </div>
                  <h4 class="shortcut-title">{{ shortcut.title }}</h4>
                  <p class="shortcut-description">{{ shortcut.description }}</p>
                  <div class="shortcut-example" v-if="shortcut.example">
                    <strong>示例:</strong> {{ shortcut.example }}
                  </div>
                </div>
              </el-card>
            </div>
          </el-tab-pane>

          <el-tab-pane label="浏览器开发者工具" name="browser">
            <div class="shortcuts-grid">
              <el-card 
                v-for="shortcut in filteredBrowserShortcuts" 
                :key="shortcut.id"
                class="shortcut-card"
              >
                <div class="shortcut-content">
                  <div class="shortcut-header">
                    <kbd class="shortcut-keys">{{ shortcut.keys }}</kbd>
                    <span class="shortcut-category">{{ shortcut.category }}</span>
                  </div>
                  <h4 class="shortcut-title">{{ shortcut.title }}</h4>
                  <p class="shortcut-description">{{ shortcut.description }}</p>
                  <div class="shortcut-example" v-if="shortcut.example">
                    <strong>示例:</strong> {{ shortcut.example }}
                  </div>
                </div>
              </el-card>
            </div>
          </el-tab-pane>
        </el-tabs>

        <!-- 快捷键统计 -->
        <el-card class="stats-card">
          <template #header>
            <span>📊 快捷键统计</span>
          </template>
          <el-row :gutter="20">
            <el-col :xs="12" :sm="6">
              <div class="stat-item">
                <div class="stat-number">{{ linuxShortcuts.length }}</div>
                <div class="stat-label">Linux 终端</div>
              </div>
            </el-col>
            <el-col :xs="12" :sm="6">
              <div class="stat-item">
                <div class="stat-number">{{ vimShortcuts.length }}</div>
                <div class="stat-label">Vim 编辑器</div>
              </div>
            </el-col>
            <el-col :xs="12" :sm="6">
              <div class="stat-item">
                <div class="stat-number">{{ gitShortcuts.length }}</div>
                <div class="stat-label">Git 版本控制</div>
              </div>
            </el-col>
            <el-col :xs="12" :sm="6">
              <div class="stat-item">
                <div class="stat-number">{{ dockerShortcuts.length }}</div>
                <div class="stat-label">Docker 命令</div>
              </div>
            </el-col>
          </el-row>
        </el-card>
      </el-main>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'

interface Shortcut {
  id: string
  keys: string
  title: string
  description: string
  category: string
  example?: string
}

const router = useRouter()
const activeTab = ref('linux')
const searchQuery = ref('')

// Linux 终端快捷键
const linuxShortcuts: Shortcut[] = [
  {
    id: 'linux-1',
    keys: 'Ctrl + C',
    title: '终止进程',
    description: '立即终止当前正在运行的命令',
    category: '进程控制',
    example: 'ping google.com (按 Ctrl+C 停止)'
  },
  {
    id: 'linux-2',
    keys: 'Ctrl + Z',
    title: '暂停进程',
    description: '将当前进程暂停并放入后台',
    category: '进程控制',
    example: '运行长时间命令后按 Ctrl+Z 暂停'
  },
  {
    id: 'linux-3',
    keys: 'Ctrl + D',
    title: '退出/EOF',
    description: '退出当前shell或发送EOF信号',
    category: '退出控制',
    example: '在终端中按 Ctrl+D 退出'
  },
  {
    id: 'linux-4',
    keys: 'Ctrl + L',
    title: '清屏',
    description: '清除终端屏幕内容',
    category: '屏幕控制',
    example: '终端内容太多时按 Ctrl+L 清屏'
  },
  {
    id: 'linux-5',
    keys: 'Ctrl + A',
    title: '行首',
    description: '将光标移动到行首',
    category: '光标控制',
    example: '编辑长命令时快速跳到行首'
  },
  {
    id: 'linux-6',
    keys: 'Ctrl + E',
    title: '行尾',
    description: '将光标移动到行尾',
    category: '光标控制',
    example: '编辑命令时快速跳到行尾'
  },
  {
    id: 'linux-7',
    keys: 'Ctrl + U',
    title: '删除到行首',
    description: '删除从光标到行首的内容',
    category: '文本编辑',
    example: '命令输入错误时快速删除重新输入'
  },
  {
    id: 'linux-8',
    keys: 'Ctrl + K',
    title: '删除到行尾',
    description: '删除从光标到行尾的内容',
    category: '文本编辑',
    example: '删除命令末尾部分'
  },
  {
    id: 'linux-9',
    keys: 'Ctrl + W',
    title: '删除前一个单词',
    description: '删除光标前的一个单词',
    category: '文本编辑',
    example: '快速删除错误的单词'
  },
  {
    id: 'linux-10',
    keys: 'Ctrl + R',
    title: '历史搜索',
    description: '搜索命令历史记录',
    category: '历史控制',
    example: '按 Ctrl+R 输入命令关键词搜索'
  },
  {
    id: 'linux-11',
    keys: '!!',
    title: '上一条命令',
    description: '执行上一条命令',
    category: '历史控制',
    example: 'sudo !!  用sudo执行上一条命令'
  },
  {
    id: 'linux-12',
    keys: '!$',
    title: '上一个参数',
    description: '使用上一条命令的最后一个参数',
    category: '历史控制',
    example: 'cd !$  进入上一条命令的最后一个参数目录'
  }
]

// Vim 编辑器快捷键
const vimShortcuts: Shortcut[] = [
  {
    id: 'vim-1',
    keys: 'i',
    title: '插入模式',
    description: '进入插入模式，可以编辑文本',
    category: '模式切换',
    example: '按 i 进入编辑模式'
  },
  {
    id: 'vim-2',
    keys: 'Esc',
    title: '普通模式',
    description: '从插入模式返回普通模式',
    category: '模式切换',
    example: '编辑完成后按 Esc 返回普通模式'
  },
  {
    id: 'vim-3',
    keys: ':w',
    title: '保存',
    description: '保存当前文件',
    category: '文件操作',
    example: ':w 保存文件'
  },
  {
    id: 'vim-4',
    keys: ':q',
    title: '退出',
    description: '退出vim编辑器',
    category: '文件操作',
    example: ':q 退出vim'
  },
  {
    id: 'vim-5',
    keys: ':wq',
    title: '保存并退出',
    description: '保存文件并退出vim',
    category: '文件操作',
    example: ':wq 保存并退出'
  },
  {
    id: 'vim-6',
    keys: ':q!',
    title: '强制退出',
    description: '不保存强制退出vim',
    category: '文件操作',
    example: ':q! 强制退出不保存'
  },
  {
    id: 'vim-7',
    keys: 'dd',
    title: '删除行',
    description: '删除当前行',
    category: '文本编辑',
    example: 'dd 删除当前行'
  },
  {
    id: 'vim-8',
    keys: 'yy',
    title: '复制行',
    description: '复制当前行',
    category: '文本编辑',
    example: 'yy 复制当前行'
  },
  {
    id: 'vim-9',
    keys: 'p',
    title: '粘贴',
    description: '在光标后粘贴',
    category: '文本编辑',
    example: 'p 在光标后粘贴'
  },
  {
    id: 'vim-10',
    keys: 'G',
    title: '跳到文件尾',
    description: '跳转到文件末尾',
    category: '导航',
    example: 'G 跳到文件最后一行'
  },
  {
    id: 'vim-11',
    keys: 'gg',
    title: '跳到文件头',
    description: '跳转到文件开头',
    category: '导航',
    example: 'gg 跳到文件第一行'
  },
  {
    id: 'vim-12',
    keys: '/pattern',
    title: '搜索',
    description: '向前搜索模式',
    category: '搜索',
    example: '/error 搜索error字符串'
  }
]

// Git 快捷键
const gitShortcuts: Shortcut[] = [
  {
    id: 'git-1',
    keys: 'git status',
    title: '查看状态',
    description: '查看工作区状态',
    category: '状态查询',
    example: 'git status 查看文件变更状态'
  },
  {
    id: 'git-2',
    keys: 'git add .',
    title: '添加所有变更',
    description: '添加所有变更到暂存区',
    category: '暂存操作',
    example: 'git add . 添加所有文件'
  },
  {
    id: 'git-3',
    keys: 'git commit -m',
    title: '提交变更',
    description: '提交暂存区的变更',
    category: '提交操作',
    example: 'git commit -m "fix bug"'
  },
  {
    id: 'git-4',
    keys: 'git push',
    title: '推送远程',
    description: '推送到远程仓库',
    category: '远程操作',
    example: 'git push origin main'
  },
  {
    id: 'git-5',
    keys: 'git pull',
    title: '拉取远程',
    description: '拉取远程仓库更新',
    category: '远程操作',
    example: 'git pull origin main'
  },
  {
    id: 'git-6',
    keys: 'git log',
    title: '查看日志',
    description: '查看提交历史',
    category: '日志查询',
    example: 'git log --oneline 简洁日志'
  },
  {
    id: 'git-7',
    keys: 'git branch',
    title: '查看分支',
    description: '查看所有分支',
    category: '分支操作',
    example: 'git branch 查看本地分支'
  },
  {
    id: 'git-8',
    keys: 'git checkout',
    title: '切换分支',
    description: '切换到指定分支',
    category: '分支操作',
    example: 'git checkout dev'
  },
  {
    id: 'git-9',
    keys: 'git merge',
    title: '合并分支',
    description: '合并指定分支',
    category: '分支操作',
    example: 'git merge feature-branch'
  },
  {
    id: 'git-10',
    keys: 'git stash',
    title: '暂存变更',
    description: '临时保存工作区变更',
    category: '暂存操作',
    example: 'git stash save "work in progress"'
  }
]

// Docker 命令快捷键
const dockerShortcuts: Shortcut[] = [
  {
    id: 'docker-1',
    keys: 'docker ps',
    title: '运行容器',
    description: '查看正在运行的容器',
    category: '容器查看',
    example: 'docker ps 查看运行中容器'
  },
  {
    id: 'docker-2',
    keys: 'docker ps -a',
    title: '所有容器',
    description: '查看所有容器（包括停止的）',
    category: '容器查看',
    example: 'docker ps -a 查看所有容器'
  },
  {
    id: 'docker-3',
    keys: 'docker images',
    title: '镜像列表',
    description: '查看本地镜像列表',
    category: '镜像查看',
    example: 'docker images 查看所有镜像'
  },
  {
    id: 'docker-4',
    keys: 'docker run',
    title: '运行容器',
    description: '创建并运行容器',
    category: '容器操作',
    example: 'docker run -d nginx'
  },
  {
    id: 'docker-5',
    keys: 'docker stop',
    title: '停止容器',
    description: '停止运行中的容器',
    category: '容器操作',
    example: 'docker stop container-id'
  },
  {
    id: 'docker-6',
    keys: 'docker start',
    title: '启动容器',
    description: '启动已停止的容器',
    category: '容器操作',
    example: 'docker start container-id'
  },
  {
    id: 'docker-7',
    keys: 'docker rm',
    title: '删除容器',
    description: '删除指定容器',
    category: '容器操作',
    example: 'docker rm container-id'
  },
  {
    id: 'docker-8',
    keys: 'docker rmi',
    title: '删除镜像',
    description: '删除指定镜像',
    category: '镜像操作',
    example: 'docker rmi image-id'
  },
  {
    id: 'docker-9',
    keys: 'docker logs',
    title: '查看日志',
    description: '查看容器日志',
    category: '日志查看',
    example: 'docker logs -f container-id'
  },
  {
    id: 'docker-10',
    keys: 'docker exec',
    title: '执行命令',
    description: '在容器中执行命令',
    category: '容器操作',
    example: 'docker exec -it container-id bash'
  }
]

// 浏览器开发者工具快捷键
const browserShortcuts: Shortcut[] = [
  {
    id: 'browser-1',
    keys: 'F12',
    title: '开发者工具',
    description: '打开/关闭开发者工具',
    category: '工具控制',
    example: '按 F12 打开开发者工具'
  },
  {
    id: 'browser-2',
    keys: 'Ctrl + Shift + I',
    title: '开发者工具',
    description: '打开开发者工具（备选）',
    category: '工具控制',
    example: 'Ctrl+Shift+I 打开开发者工具'
  },
  {
    id: 'browser-3',
    keys: 'Ctrl + Shift + C',
    title: '元素选择',
    description: '选择页面元素进行审查',
    category: '元素审查',
    example: 'Ctrl+Shift+C 选择元素'
  },
  {
    id: 'browser-4',
    keys: 'Ctrl + Shift + J',
    title: '控制台',
    description: '打开控制台面板',
    category: '控制台',
    example: 'Ctrl+Shift+J 打开控制台'
  },
  {
    id: 'browser-5',
    keys: 'Ctrl + R',
    title: '刷新',
    description: '刷新页面',
    category: '页面控制',
    example: 'Ctrl+R 刷新页面'
  },
  {
    id: 'browser-6',
    keys: 'Ctrl + Shift + R',
    title: '强制刷新',
    description: '强制刷新（清除缓存）',
    category: '页面控制',
    example: 'Ctrl+Shift+R 强制刷新'
  },
  {
    id: 'browser-7',
    keys: 'Ctrl + F',
    title: '查找',
    description: '在页面中查找文本',
    category: '搜索',
    example: 'Ctrl+F 查找文本'
  },
  {
    id: 'browser-8',
    keys: 'Ctrl + U',
    title: '查看源码',
    description: '查看页面源代码',
    category: '源码查看',
    example: 'Ctrl+U 查看页面源码'
  }
]

// 计算属性
const filteredLinuxShortcuts = computed(() => {
  return linuxShortcuts.filter(shortcut => 
    shortcut.title.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    shortcut.description.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    shortcut.keys.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

const filteredVimShortcuts = computed(() => {
  return vimShortcuts.filter(shortcut => 
    shortcut.title.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    shortcut.description.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    shortcut.keys.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

const filteredGitShortcuts = computed(() => {
  return gitShortcuts.filter(shortcut => 
    shortcut.title.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    shortcut.description.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    shortcut.keys.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

const filteredDockerShortcuts = computed(() => {
  return dockerShortcuts.filter(shortcut => 
    shortcut.title.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    shortcut.description.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    shortcut.keys.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

const filteredBrowserShortcuts = computed(() => {
  return browserShortcuts.filter(shortcut => 
    shortcut.title.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    shortcut.description.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    shortcut.keys.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

onMounted(() => {
  // 初始化
})

const goBack = () => {
  router.push('/')
}
</script>

<style scoped>
.shortcuts-page {
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

/* 搜索区域 */
.search-section {
  margin-bottom: 30px;
}

.search-input {
  max-width: 500px;
}

/* 快捷键标签页 */
.shortcuts-tabs {
  background: #fff;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 30px;
}

/* 快捷键网格 */
.shortcuts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.shortcut-card {
  transition: all 0.3s ease;
  height: 100%;
}

.shortcut-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
}

.shortcut-content {
  padding: 20px;
}

.shortcut-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.shortcut-keys {
  background: #2c3e50;
  color: #fff;
  padding: 6px 12px;
  border-radius: 4px;
  font-family: 'Courier New', monospace;
  font-size: 14px;
  font-weight: 500;
}

.shortcut-category {
  background: #e9ecef;
  color: #495057;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;
}

.shortcut-title {
  margin: 0 0 8px 0;
  font-size: 16px;
  font-weight: 600;
  color: #2c3e50;
}

.shortcut-description {
  margin: 0 0 12px 0;
  color: #6c757d;
  line-height: 1.5;
  font-size: 14px;
}

.shortcut-example {
  background: #f8f9fa;
  padding: 10px;
  border-radius: 4px;
  font-size: 13px;
  color: #495057;
  border-left: 3px solid #007bff;
}

.shortcut-example strong {
  color: #2c3e50;
}

/* 统计卡片 */
.stats-card {
  background: #fff;
  border-radius: 8px;
  padding: 20px;
}

.stat-item {
  text-align: center;
  padding: 20px;
  border-radius: 8px;
  background: #f8f9fa;
  transition: all 0.3s ease;
}

.stat-item:hover {
  background: #e9ecef;
  transform: translateY(-2px);
}

.stat-number {
  font-size: 32px;
  font-weight: 700;
  color: #007bff;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  color: #495057;
  font-weight: 500;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .header-content {
    padding: 0 15px;
  }
  
  .main-content {
    padding: 20px 15px;
  }
  
  .shortcuts-grid {
    grid-template-columns: 1fr;
  }
  
  .shortcut-content {
    padding: 15px;
  }
  
  .shortcut-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  
  .shortcut-keys {
    align-self: flex-start;
  }
  
  .stat-number {
    font-size: 24px;
  }
  
  .stat-label {
    font-size: 12px;
  }
}

@media (max-width: 480px) {
  .search-input {
    max-width: 100%;
  }
  
  .shortcuts-tabs {
    padding: 15px;
  }
  
  .stat-item {
    padding: 15px 10px;
  }
}
</style>