import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/Home.vue')
  },
  {
    path: '/linux',
    name: 'Linux',
    component: () => import('@/views/Linux.vue')
  },
  {
    path: '/docker',
    name: 'Docker',
    component: () => import('@/views/Docker.vue')
  },
  {
    path: '/practice',
    name: 'Practice',
    component: () => import('@/views/Practice.vue')
  },
  {
    path: '/practice/quiz',
    name: 'Quiz',
    component: () => import('@/views/Quiz.vue')
  },
  {
    path: '/progress',
    name: 'Progress',
    component: () => import('@/views/Progress.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router