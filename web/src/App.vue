<template>
  <div id="app">
    <!-- 移动端导航 -->
    <MobileNavigation />
    
    <!-- 主要内容 -->
    <router-view />
  </div>
</template>

<script setup lang="ts">
import MobileNavigation from '@/components/MobileNavigation.vue'
</script>

<style>
#app {
  min-height: 100vh;
  position: relative;
}

/* 移动端适配 */
@media (max-width: 768px) {
  #app {
    padding-bottom: 60px; /* 为底部导航留出空间 */
  }
  
  /* 隐藏桌面端header */
  .page-header {
    display: none;
  }
  
  /* 移动端页面布局调整 */
  .main-content {
    padding-top: 80px !important; /* 为移动端菜单按钮留出空间 */
  }
}

/* 平板适配 */
@media (min-width: 769px) and (max-width: 1024px) {
  #app {
    padding-bottom: 0;
  }
}

/* 确保内容在移动端不被导航遮挡 */
@media (max-width: 768px) {
  .mobile-header-space {
    height: 60px;
  }
  
  .mobile-content-padding {
    padding-top: 70px;
  }
}
</style>