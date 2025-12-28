import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import './style.css'
import './styles/responsive.css'
import { initPerformanceOptimizations } from './utils/performance'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(ElementPlus)

app.mount('#app')

// 初始化性能优化
initPerformanceOptimizations()

console.log('App mounted successfully!')