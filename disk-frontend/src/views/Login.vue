<template>
  <div class="login-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>

    <!-- 动态装饰元素 -->
    <div class="decorations" v-if="!isCustom">
      <div class="blob blob-1"></div>
      <div class="blob blob-2"></div>
      <div class="blob blob-3"></div>
      <div class="particle" v-for="i in 20" :key="i" :style="particleStyle(i)"></div>
    </div>

    <div class="login-box">
      <el-button link class="theme-toggle" @click="toggleTheme">
        <el-icon :size="20"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
      </el-button>
      <div class="logo">
        <span class="icon">☁️</span>
        <h1>个人云盘</h1>
        <p class="subtitle">安全、便捷的个人文件管理</p>
      </div>

      <el-form ref="loginFormRef" :model="loginForm" :rules="rules" label-width="80px">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="loginForm.username" placeholder="请输入用户名" prefix-icon="User" />
        </el-form-item>

        <el-form-item label="密码" prop="password">
          <el-input type="password" v-model="loginForm.password" placeholder="请输入密码" prefix-icon="Lock" show-password />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="handleLogin" class="login-btn" :loading="loading">
            <span v-if="!loading">登 录</span>
          </el-button>
        </el-form-item>
      </el-form>

      <div class="links">
        <span class="register-link">
          还没有账号？
          <el-button link @click="goToRegister">立即注册</el-button>
        </span>
        <span class="divider">|</span>
        <el-button link class="forgot-link-btn" @click="goToForgot">忘记密码？</el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { login } from '../api/user'
import { ElMessage } from 'element-plus'
import { useDarkMode } from '../composables/useDarkMode'
import { useBackground } from '../composables/useBackground'
import { Sunny, Moon } from '@element-plus/icons-vue'

const { isDark, toggle: toggleTheme } = useDarkMode()
const { containerBackground, isCustom, bgLayerStyle } = useBackground('auth')

const router = useRouter()
const loading = ref(false)

const loginForm = reactive({
  username: '',
  password: ''
})

const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' }
  ]
}

const particleStyle = (i) => ({
  '--delay': `${Math.random() * 15}s`,
  '--size': `${Math.random() * 4 + 2}px`,
  '--left': `${Math.random() * 100}%`,
  '--duration': `${Math.random() * 10 + 10}s`,
  '--opacity': `${Math.random() * 0.4 + 0.1}`
})

const handleLogin = async () => {
  loading.value = true
  try {
    const response = await login(loginForm)
    if (response.token) {
      localStorage.setItem('token', response.token)
      localStorage.setItem('user', JSON.stringify(response.user))
      ElMessage.success('登录成功')
      router.push('/')
    } else {
      ElMessage.error(response.message || '登录失败')
    }
  } catch (error) {
    ElMessage.error('登录失败，请检查网络连接')
  } finally {
    loading.value = false
  }
}

const goToRegister = () => {
  router.push('/register')
}

const goToForgot = () => {
  router.push('/forgot-password')
}
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 25%, #0f3460 50%, #533483 75%, #1a1a2e 100%);
  background-size: 400% 400%;
  animation: gradientShift 15s ease infinite;
  overflow: hidden;
}

/* ---- 动态渐变 ---- */
@keyframes gradientShift {
  0%, 100% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
}

/* ---- 装饰浮动气泡 ---- */
.decorations {
  position: absolute;
  inset: 0;
  pointer-events: none;
  overflow: hidden;
}

.blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.3;
  animation: blobFloat 20s ease-in-out infinite;
}
.blob-1 {
  width: 400px;
  height: 400px;
  background: radial-gradient(circle, rgba(102,126,234,0.6), transparent);
  top: -10%;
  left: -5%;
  animation-delay: 0s;
}
.blob-2 {
  width: 350px;
  height: 350px;
  background: radial-gradient(circle, rgba(245,87,108,0.5), transparent);
  bottom: -10%;
  right: -5%;
  animation-delay: -7s;
  animation-duration: 23s;
}
.blob-3 {
  width: 300px;
  height: 300px;
  background: radial-gradient(circle, rgba(56,239,125,0.4), transparent);
  top: 40%;
  left: 60%;
  animation-delay: -14s;
  animation-duration: 18s;
}

@keyframes blobFloat {
  0%, 100% { transform: translate(0, 0) scale(1); }
  25% { transform: translate(40px, -30px) scale(1.1); }
  50% { transform: translate(-20px, 20px) scale(0.95); }
  75% { transform: translate(-30px, -15px) scale(1.05); }
}

/* ---- 浮动粒子 ---- */
.particle {
  position: absolute;
  bottom: -10px;
  left: var(--left);
  width: var(--size);
  height: var(--size);
  background: rgba(255, 255, 255, var(--opacity));
  border-radius: 50%;
  animation: particleRise var(--duration) var(--delay) linear infinite;
}

@keyframes particleRise {
  0% {
    transform: translateY(0) translateX(0);
    opacity: 0;
  }
  10% { opacity: var(--opacity); }
  90% { opacity: var(--opacity); }
  100% {
    transform: translateY(-105vh) translateX(calc(var(--size) * 5));
    opacity: 0;
  }
}

/* ---- 卡片 ---- */
.login-box {
  position: relative;
  z-index: 1;
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  border: 1px solid rgba(255, 255, 255, 0.15);
  padding: 48px 40px 36px;
  border-radius: 20px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25), inset 0 1px 0 rgba(255, 255, 255, 0.1);
  width: 100%;
  max-width: 420px;
  animation: cardIn 0.8s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes cardIn {
  0% { opacity: 0; transform: translateY(30px) scale(0.96); }
  100% { opacity: 1; transform: translateY(0) scale(1); }
}

.theme-toggle {
  position: absolute;
  top: 16px;
  right: 16px;
  color: rgba(255, 255, 255, 0.7);
}
.theme-toggle:hover {
  color: #fff;
}
:deep(.theme-toggle .el-icon) {
  filter: drop-shadow(0 0 6px rgba(255,255,255,0.4));
}

/* ---- Logo ---- */
.logo {
  text-align: center;
  margin-bottom: 36px;
}

.icon {
  font-size: 56px;
  display: inline-block;
  animation: iconFloat 3s ease-in-out infinite;
  filter: drop-shadow(0 4px 12px rgba(102,126,234,0.4));
}

@keyframes iconFloat {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

h1 {
  font-size: 28px;
  color: #fff;
  margin: 8px 0 4px;
  font-weight: 700;
  letter-spacing: 2px;
}

.subtitle {
  color: rgba(255, 255, 255, 0.55);
  font-size: 14px;
  margin: 0;
}

/* ---- 表单 ---- */
:deep(.login-box .el-form-item__label) {
  color: rgba(255, 255, 255, 0.85);
  font-weight: 500;
}

:deep(.login-box .el-input__wrapper) {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.15);
  box-shadow: none;
  border-radius: 10px;
  transition: all 0.3s ease;
}
:deep(.login-box .el-input__wrapper:hover) {
  border-color: rgba(255, 255, 255, 0.35);
  background: rgba(255, 255, 255, 0.14);
}
:deep(.login-box .el-input__wrapper.is-focus) {
  border-color: #667eea;
  background: rgba(255, 255, 255, 0.18);
  box-shadow: 0 0 0 3px rgba(102,126,234,0.25);
}
:deep(.login-box .el-input__inner) {
  color: #fff;
}
:deep(.login-box .el-input__inner::placeholder) {
  color: rgba(255, 255, 255, 0.35);
}
:deep(.login-box .el-input__prefix .el-icon) {
  color: rgba(255, 255, 255, 0.5);
}
:deep(.login-box .el-input__suffix .el-icon) {
  color: rgba(255, 255, 255, 0.5);
}

/* ---- 按钮 ---- */
.login-btn {
  width: 100%;
  height: 48px;
  font-size: 16px;
  border-radius: 12px;
  background: linear-gradient(135deg, #667eea, #764ba2);
  border: none;
  position: relative;
  overflow: hidden;
  letter-spacing: 4px;
  font-weight: 600;
  transition: all 0.3s ease;
}
.login-btn::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(255,255,255,0.2), transparent);
  opacity: 0;
  transition: opacity 0.3s;
}
.login-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(102,126,234,0.45);
}
.login-btn:hover::after {
  opacity: 1;
}

/* ---- 底部链接 ---- */
.links {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
  margin-top: 24px;
  font-size: 14px;
  color: rgba(255, 255, 255, 0.5);
}
.register-link {
  display: flex;
  align-items: center;
  gap: 2px;
}
.register-link .el-button {
  color: rgba(255, 255, 255, 0.7);
  font-size: 14px;
  padding: 0;
}
.register-link .el-button:hover {
  color: #667eea;
}
.divider {
  color: rgba(255, 255, 255, 0.2);
}
.forgot-link-btn {
  color: rgba(255, 255, 255, 0.5);
  font-size: 14px;
  padding: 0;
}
.forgot-link-btn:hover {
  color: #f5576c;
}
</style>
