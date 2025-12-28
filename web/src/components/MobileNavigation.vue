<template>
  <div class="mobile-navigation" :class="{ 'is-active': isActive }">
    <!-- 移动端菜单按钮 -->
    <div class="mobile-menu-btn" @click="toggleMenu">
      <div class="hamburger" :class="{ 'is-active': isActive }">
        <span></span>
        <span></span>
        <span></span>
      </div>
    </div>

    <!-- 遮罩层 -->
    <div 
      v-if="isActive" 
      class="mobile-overlay" 
      @click="closeMenu"
    ></div>

    <!-- 侧边栏菜单 -->
    <transition name="slide">
      <div v-if="isActive" class="mobile-sidebar">
        <div class="sidebar-header">
          <h3>🐟 摸鱼学习站</h3>
          <el-button type="text" @click="closeMenu" class="close-btn">
            <el-icon size="24px"><Close /></el-icon>
          </el-button>
        </div>

        <div class="sidebar-content">
          <nav class="mobile-nav">
            <div 
              v-for="item in navItems" 
              :key="item.path"
              class="nav-item"
              :class="{ 'is-active': currentRoute === item.path }"
              @click="navigateTo(item.path)"
            >
              <span class="nav-icon">{{ item.icon }}</span>
              <span class="nav-text">{{ item.name }}</span>
              <el-icon v-if="item.badge" class="nav-badge"><Bell /></el-icon>
            </div>
          </nav>

          <div class="sidebar-footer">
            <div class="user-info" v-if="userInfo">
              <el-avatar :size="40">{{ userInfo.name.charAt(0) }}</el-avatar>
              <div class="user-details">
                <div class="user-name">{{ userInfo.name }}</div>
                <div class="user-level">{{ userInfo.level }}</div>
              </div>
            </div>
            <div class="sidebar-actions">
              <el-button type="text" @click="showSettings">
                <el-icon><Setting /></el-icon>
                设置
              </el-button>
              <el-button type="text" @click="showHelp">
                <el-icon><QuestionFilled /></el-icon>
                帮助
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- 底部导航栏 -->
    <div class="bottom-nav">
      <div 
        v-for="item in bottomNavItems" 
        :key="item.path"
        class="bottom-nav-item"
        :class="{ 'is-active': currentRoute === item.path }"
        @click="navigateTo(item.path)"
      >
        <div class="bottom-nav-icon">{{ item.icon }}</div>
        <span class="bottom-nav-text">{{ item.name }}</span>
        <div v-if="item.badge" class="bottom-nav-badge">{{ item.badge }}</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Close, Bell, Setting, QuestionFilled } from '@element-plus/icons-vue'

interface NavItem {
  path: string
  name: string
  icon: string
  badge?: number | boolean
}

interface UserInfo {
  name: string
  level: string
  avatar?: string
}

const router = useRouter()
const route = useRoute()

const isActive = ref(false)
const isMobile = ref(false)

const userInfo = ref<UserInfo>({
  name: '学习用户',
  level: '初级'
})

const navItems: NavItem[] = [
  { path: '/', name: '首页', icon: '🏠' },
  { path: '/linux', name: 'Linux学习', icon: '🐧' },
  { path: '/docker', name: 'Docker技术', icon: '🐳' },
  { path: '/practice', name: '题库练习', icon: '✏️' },
  { path: '/progress', name: '学习进度', icon: '📊', badge: true }
]

const bottomNavItems: NavItem[] = [
  { path: '/', name: '首页', icon: '🏠' },
  { path: '/practice', name: '练习', icon: '✏️' },
  { path: '/linux', name: 'Linux', icon: '🐧' },
  { path: '/progress', name: '进度', icon: '📊' }
]

const currentRoute = computed(() => route.path)

const toggleMenu = () => {
  isActive.value = !isActive.value
  // 防止背景滚动
  if (isActive.value) {
    document.body.style.overflow = 'hidden'
  } else {
    document.body.style.overflow = ''
  }
}

const closeMenu = () => {
  isActive.value = false
  document.body.style.overflow = ''
}

const navigateTo = (path: string) => {
  if (currentRoute.value !== path) {
    router.push(path)
  }
  closeMenu()
}

const showSettings = () => {
  ElMessage.info('设置功能开发中...')
  closeMenu()
}

const showHelp = () => {
  ElMessage.info('帮助功能开发中...')
  closeMenu()
}

const checkMobile = () => {
  isMobile.value = window.innerWidth <= 768
  // 在桌面端自动关闭菜单
  if (!isMobile.value && isActive.value) {
    closeMenu()
  }
}

const handleResize = () => {
  checkMobile()
}

onMounted(() => {
  checkMobile()
  window.addEventListener('resize', handleResize)
  
  // 监听ESC键关闭菜单
  const handleEsc = (e: KeyboardEvent) => {
    if (e.key === 'Escape' && isActive.value) {
      closeMenu()
    }
  }
  document.addEventListener('keydown', handleEsc)
  
  onUnmounted(() => {
    document.removeEventListener('keydown', handleEsc)
  })
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  document.body.style.overflow = ''
})
</script>

<style scoped>
.mobile-navigation {
  display: none;
}

/* 只在移动端显示导航 */
@media (max-width: 768px) {
  .mobile-navigation {
    display: block;
  }
}

/* 移动端菜单按钮 */
.mobile-menu-btn {
  position: fixed;
  top: 16px;
  left: 16px;
  z-index: 1001;
  padding: 8px;
  cursor: pointer;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(10px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.hamburger {
  width: 24px;
  height: 24px;
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.hamburger span {
  display: block;
  height: 3px;
  width: 100%;
  background: #333;
  border-radius: 3px;
  transition: all 0.3s ease;
}

.hamburger.is-active span:nth-child(1) {
  transform: rotate(45deg) translate(6px, 6px);
}

.hamburger.is-active span:nth-child(2) {
  opacity: 0;
}

.hamburger.is-active span:nth-child(3) {
  transform: rotate(-45deg) translate(6px, -6px);
}

/* 遮罩层 */
.mobile-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  z-index: 1002;
  backdrop-filter: blur(4px);
}

/* 侧边栏 */
.mobile-sidebar {
  position: fixed;
  top: 0;
  left: 0;
  width: 280px;
  height: 100%;
  background: white;
  z-index: 1003;
  box-shadow: 2px 0 12px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
}

.sidebar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #e9ecef;
  background: linear-gradient(135deg, #409eff 0%, #364d79 100%);
  color: white;
}

.sidebar-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
}

.close-btn {
  color: white;
  padding: 4px;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.1);
}

.sidebar-content {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.mobile-nav {
  flex: 1;
  padding: 20px 0;
}

.nav-item {
  display: flex;
  align-items: center;
  padding: 16px 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
}

.nav-item:hover {
  background: #f8f9fa;
}

.nav-item.is-active {
  background: #ecf5ff;
  color: #409eff;
  border-left: 4px solid #409eff;
}

.nav-icon {
  font-size: 20px;
  margin-right: 12px;
  min-width: 24px;
  text-align: center;
}

.nav-text {
  flex: 1;
  font-size: 16px;
  font-weight: 500;
}

.nav-badge {
  color: #f56c6c;
  font-size: 16px;
}

.sidebar-footer {
  border-top: 1px solid #e9ecef;
  padding: 20px;
}

.user-info {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
}

.user-details {
  margin-left: 12px;
}

.user-name {
  font-size: 16px;
  font-weight: 600;
  color: #333;
}

.user-level {
  font-size: 12px;
  color: #666;
  margin-top: 2px;
}

.sidebar-actions {
  display: flex;
  gap: 16px;
}

.sidebar-actions .el-button {
  flex: 1;
  justify-content: flex-start;
  color: #666;
  font-size: 14px;
}

.sidebar-actions .el-button:hover {
  color: #409eff;
}

/* 底部导航 */
.bottom-nav {
  display: none;
  position: fixed;
  bottom: 0;
  left: 0;
  width: 100%;
  background: white;
  border-top: 1px solid #e9ecef;
  z-index: 1000;
  box-shadow: 0 -2px 8px rgba(0, 0, 0, 0.1);
}

@media (max-width: 768px) {
  .bottom-nav {
    display: flex;
  }
}

.bottom-nav-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px 4px;
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
  min-height: 60px;
  justify-content: center;
}

.bottom-nav-item:hover {
  background: #f8f9fa;
}

.bottom-nav-item.is-active {
  color: #409eff;
}

.bottom-nav-icon {
  font-size: 20px;
  margin-bottom: 2px;
}

.bottom-nav-text {
  font-size: 11px;
  line-height: 1.2;
  text-align: center;
  font-weight: 500;
}

.bottom-nav-badge {
  position: absolute;
  top: 6px;
  right: 20%;
  background: #f56c6c;
  color: white;
  border-radius: 10px;
  padding: 2px 6px;
  font-size: 10px;
  font-weight: 600;
  min-width: 16px;
  text-align: center;
}

/* 动画 */
.slide-enter-active,
.slide-leave-active {
  transition: transform 0.3s ease;
}

.slide-enter-from {
  transform: translateX(-100%);
}

.slide-leave-to {
  transform: translateX(-100%);
}

/* 安全区域适配 */
@supports (padding: max(0px)) {
  .mobile-sidebar {
    padding-left: max(20px, env(safe-area-inset-left));
  }
  
  .bottom-nav {
    padding-bottom: max(0px, env(safe-area-inset-bottom));
  }
}

/* 横屏适配 */
@media screen and (orientation: landscape) and (max-height: 500px) {
  .mobile-sidebar {
    width: 320px;
  }
  
  .sidebar-header {
    padding: 15px 20px;
  }
  
  .nav-item {
    padding: 12px 20px;
  }
  
  .bottom-nav {
    display: none;
  }
}
</style>