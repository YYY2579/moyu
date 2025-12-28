// 性能优化工具函数

// 防抖函数
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number,
  immediate = false
): (...args: Parameters<T>) => void {
  let timeout: NodeJS.Timeout | null = null
  
  return function executedFunction(...args: Parameters<T>) {
    const later = () => {
      timeout = null
      if (!immediate) func(...args)
    }
    
    const callNow = immediate && !timeout
    
    if (timeout) clearTimeout(timeout)
    timeout = setTimeout(later, wait)
    
    if (callNow) func(...args)
  }
}

// 节流函数
export function throttle<T extends (...args: any[]) => any>(
  func: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle: boolean
  
  return function executedFunction(...args: Parameters<T>) {
    if (!inThrottle) {
      func(...args)
      inThrottle = true
      setTimeout(() => inThrottle = false, limit)
    }
  }
}

// 懒加载图片
export function lazyLoadImages() {
  const images = document.querySelectorAll('img[data-src]')
  
  const imageObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const img = entry.target as HTMLImageElement
        img.src = img.dataset.src!
        img.removeAttribute('data-src')
        observer.unobserve(img)
      }
    })
  })
  
  images.forEach(img => imageObserver.observe(img))
}

// 虚拟滚动基础实现
export class VirtualScroll {
  private container: HTMLElement
  private items: any[]
  private itemHeight: number
  private visibleCount: number
  private scrollTop = 0
  private startIndex = 0
  private endIndex = 0

  constructor(
    container: HTMLElement,
    items: any[],
    itemHeight: number,
    containerHeight: number
  ) {
    this.container = container
    this.items = items
    this.itemHeight = itemHeight
    this.visibleCount = Math.ceil(containerHeight / itemHeight) + 2
    this.endIndex = this.visibleCount
    this.updateVisibleItems()
  }

  private updateVisibleItems() {
    this.startIndex = Math.floor(this.scrollTop / this.itemHeight)
    this.endIndex = Math.min(
      this.startIndex + this.visibleCount,
      this.items.length - 1
    )
  }

  public getVisibleItems() {
    return this.items.slice(this.startIndex, this.endIndex + 1)
  }

  public updateScrollTop(scrollTop: number) {
    this.scrollTop = scrollTop
    this.updateVisibleItems()
  }

  public getTotalHeight() {
    return this.items.length * this.itemHeight
  }

  public getOffsetY() {
    return this.startIndex * this.itemHeight
  }
}

// 图片预加载
export function preloadImages(urls: string[]): Promise<void[]> {
  const promises = urls.map(url => {
    return new Promise<void>((resolve, reject) => {
      const img = new Image()
      img.onload = () => resolve()
      img.onerror = reject
      img.src = url
    })
  })
  
  return Promise.all(promises)
}

// 内存使用监控
export function checkMemoryUsage() {
  if ('memory' in performance) {
    const memory = (performance as any).memory
    return {
      used: Math.round(memory.usedJSHeapSize / 1048576) + ' MB',
      total: Math.round(memory.totalJSHeapSize / 1048576) + ' MB',
      limit: Math.round(memory.jsHeapSizeLimit / 1048576) + ' MB'
    }
  }
  return null
}

// 网络状态检测
export function getNetworkInfo() {
  if ('connection' in navigator) {
    const connection = (navigator as any).connection
    return {
      effectiveType: connection.effectiveType,
      downlink: connection.downlink + ' Mbps',
      rtt: connection.rtt + ' ms',
      saveData: connection.saveData
    }
  }
  return null
}

// 页面可见性管理
export function usePageVisibility() {
  const isVisible = ref(!document.hidden)

  const handleVisibilityChange = () => {
    isVisible.value = !document.hidden
  }

  onMounted(() => {
    document.addEventListener('visibilitychange', handleVisibilityChange)
  })

  onUnmounted(() => {
    document.removeEventListener('visibilitychange', handleVisibilityChange)
  })

  return { isVisible }
}

// 移动设备检测
export function isMobileDevice() {
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
    navigator.userAgent
  )
}

// 触摸设备检测
export function isTouchDevice() {
  return 'ontouchstart' in window || navigator.maxTouchPoints > 0
}

// 屏幕方向管理
export function useScreenOrientation() {
  const orientation = ref(screen.orientation?.type || 'unknown')
  const isLandscape = ref(window.innerWidth > window.innerHeight)

  const handleOrientationChange = () => {
    orientation.value = screen.orientation?.type || 'unknown'
    isLandscape.value = window.innerWidth > window.innerHeight
  }

  onMounted(() => {
    window.addEventListener('orientationchange', handleOrientationChange)
    window.addEventListener('resize', handleOrientationChange)
  })

  onUnmounted(() => {
    window.removeEventListener('orientationchange', handleOrientationChange)
    window.removeEventListener('resize', handleOrientationChange)
  })

  return { orientation, isLandscape }
}

// 应用安装提示（PWA）
export function showInstallPrompt() {
  let deferredPrompt: any

  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault()
    deferredPrompt = e
    
    // 显示安装按钮
    const installButton = document.createElement('button')
    installButton.textContent = '安装应用'
    installButton.style.cssText = `
      position: fixed;
      bottom: 20px;
      right: 20px;
      background: #409eff;
      color: white;
      border: none;
      padding: 12px 20px;
      border-radius: 6px;
      cursor: pointer;
      z-index: 9999;
      font-size: 14px;
      box-shadow: 0 4px 12px rgba(64, 158, 255, 0.3);
    `
    
    installButton.onclick = async () => {
      if (deferredPrompt) {
        deferredPrompt.prompt()
        const { outcome } = await deferredPrompt.userChoice
        console.log(`用户${outcome === 'accepted' ? '接受' : '拒绝'}了安装提示`)
        deferredPrompt = null
        document.body.removeChild(installButton)
      }
    }
    
    document.body.appendChild(installButton)
  })
}

// 离线支持
export function setupOfflineSupport() {
  const isOnline = ref(navigator.onLine)

  const updateOnlineStatus = () => {
    isOnline.value = navigator.onLine
    
    if (navigator.onLine) {
      // 恢复在线状态
      console.log('网络连接已恢复')
    } else {
      // 进入离线状态
      console.log('网络连接已断开，进入离线模式')
    }
  }

  onMounted(() => {
    window.addEventListener('online', updateOnlineStatus)
    window.addEventListener('offline', updateOnlineStatus)
  })

  onUnmounted(() => {
    window.removeEventListener('online', updateOnlineStatus)
    window.removeEventListener('offline', updateOnlineStatus)
  })

  return { isOnline }
}

// 性能监控
export function setupPerformanceMonitoring() {
  // 监控页面加载时间
  window.addEventListener('load', () => {
    const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming
    const loadTime = navigation.loadEventEnd - navigation.loadEventStart
    console.log(`页面加载时间: ${loadTime}ms`)
  })

  // 监控长任务
  if ('PerformanceObserver' in window) {
    const observer = new PerformanceObserver((list) => {
      list.getEntries().forEach((entry) => {
        console.log(`检测到长任务: ${entry.duration}ms`)
      })
    })
    
    try {
      observer.observe({ entryTypes: ['longtask'] })
    } catch (e) {
      console.log('长任务监控不支持')
    }
  }
}

// 初始化性能优化
export function initPerformanceOptimizations() {
  // 启用图片懒加载
  lazyLoadImages()
  
  // 设置性能监控
  setupPerformanceMonitoring()
  
  // 设置离线支持
  setupOfflineSupport()
  
  // 设置应用安装提示
  showInstallPrompt()
  
  // 检查设备类型
  if (isMobileDevice()) {
    document.documentElement.classList.add('mobile-device')
  }
  
  if (isTouchDevice()) {
    document.documentElement.classList.add('touch-device')
  }
  
  console.log('性能优化初始化完成')
}

