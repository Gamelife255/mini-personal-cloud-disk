import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'
import Register from '../views/Register.vue'
import ForgotPassword from '../views/ForgotPassword.vue'
import Portal from '../views/Portal.vue'
import Disk from '../views/Disk.vue'
import Admin from '../views/Admin.vue'
import Statistics from '../views/Statistics.vue'
import Games from '../views/Games.vue'
import Forum from '../views/Forum.vue'
import ForumTopic from '../views/ForumTopic.vue'
import ForumCreate from '../views/ForumCreate.vue'
import ForumUser from '../views/ForumUser.vue'
import ForumFavorites from '../views/ForumFavorites.vue'
import ForumHistory from '../views/ForumHistory.vue'
import ForumFollows from '../views/ForumFollows.vue'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { public: true }
  },
  {
    path: '/register',
    name: 'Register',
    component: Register,
    meta: { public: true }
  },
  {
    path: '/forgot-password',
    name: 'ForgotPassword',
    component: ForgotPassword,
    meta: { public: true }
  },
  {
    path: '/portal',
    name: 'Portal',
    component: Portal,
    meta: { requiresAuth: true }
  },
  {
    path: '/disk',
    name: 'Disk',
    component: Disk,
    meta: { requiresAuth: true }
  },
  {
    path: '/statistics',
    name: 'Statistics',
    component: Statistics,
    meta: { requiresAuth: true }
  },
  {
    path: '/games',
    name: 'Games',
    component: Games,
    meta: { requiresAuth: true }
  },
  {
    path: '/admin',
    name: 'Admin',
    component: Admin,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/forum',
    name: 'Forum',
    component: Forum
  },
  {
    path: '/forum/topic/:id',
    name: 'ForumTopic',
    component: ForumTopic
  },
  {
    path: '/forum/create',
    name: 'ForumCreate',
    component: ForumCreate,
    meta: { requiresAuth: true }
  },
  {
    path: '/forum/edit/:id',
    name: 'ForumEdit',
    component: ForumCreate,
    meta: { requiresAuth: true }
  },
  {
    path: '/forum/user/:id',
    name: 'ForumUser',
    component: ForumUser
  },
  {
    path: '/forum/user/:id/follows',
    name: 'ForumFollows',
    component: ForumFollows,
    meta: { requiresAuth: true }
  },
  {
    path: '/forum/favorites',
    name: 'ForumFavorites',
    component: ForumFavorites,
    meta: { requiresAuth: true }
  },
  {
    path: '/forum/history',
    name: 'ForumHistory',
    component: ForumHistory,
    meta: { requiresAuth: true }
  },
  {
    path: '/',
    redirect: '/portal'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  const user = JSON.parse(localStorage.getItem('user') || '{}')

  if (to.meta.requiresAuth && !token) {
    next('/login')
  } else if (to.meta.requiresAdmin && user.role !== 'admin') {
    next('/portal')
  } else if ((to.path === '/login' || to.path === '/register' || to.path === '/forgot-password') && token) {
    next('/portal')
  } else {
    next()
  }
})

export default router
