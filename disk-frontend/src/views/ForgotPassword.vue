<template>
  <div class="forgot-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>

    <!-- 动态装饰元素 -->
    <div class="decorations" v-if="!isCustom">
      <div class="blob blob-1"></div>
      <div class="blob blob-2"></div>
      <div class="blob blob-3"></div>
      <div class="particle" v-for="i in 20" :key="i" :style="particleStyle(i)"></div>
    </div>

    <div class="forgot-box">
      <el-button link class="theme-toggle" @click="toggleTheme">
        <el-icon :size="20"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
      </el-button>
      <div class="logo">
        <span class="icon">🔑</span>
        <h1>找回密码</h1>
        <p class="subtitle">验证邮箱以重置密码</p>
      </div>

      <el-form ref="formRef" :model="form" :rules="rules" label-width="80px">
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="form.email" placeholder="请输入注册邮箱" prefix-icon="Message" />
        </el-form-item>

        <el-form-item label="验证码" prop="code">
          <div class="code-row">
            <el-input v-model="form.code" placeholder="请输入验证码" class="code-input" prefix-icon="Key" />
            <el-button :disabled="codeCountdown > 0" @click="sendCode" :loading="sending" class="code-btn">
              {{ codeCountdown > 0 ? codeCountdown + 's' : '获取验证码' }}
            </el-button>
          </div>
        </el-form-item>

        <el-form-item label="新密码" prop="password">
          <el-input type="password" v-model="form.password" placeholder="至少6个字符" prefix-icon="Lock" show-password />
        </el-form-item>

        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input type="password" v-model="form.confirmPassword" placeholder="请再次输入新密码" prefix-icon="Lock" show-password />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="handleReset" class="reset-btn" :loading="loading">
            <span v-if="!loading">重置密码</span>
          </el-button>
        </el-form-item>
      </el-form>

      <div class="login-link">
        想起密码了？
        <el-button link @click="goToLogin">返回登录</el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { sendResetCode, resetPassword } from '../api/user'
import { ElMessage } from 'element-plus'
import { useDarkMode } from '../composables/useDarkMode'
import { useBackground } from '../composables/useBackground'
import { Sunny, Moon } from '@element-plus/icons-vue'

const { isDark, toggle: toggleTheme } = useDarkMode()
const { containerBackground, isCustom, bgLayerStyle } = useBackground('auth')

const router = useRouter()
const loading = ref(false)
const sending = ref(false)
const codeCountdown = ref(0)
let countdownTimer = null

const form = reactive({
  email: '',
  code: '',
  password: '',
  confirmPassword: ''
})

const validateConfirmPassword = (rule, value, callback) => {
  if (value !== form.password) {
    callback(new Error('两次输入的密码不一致'))
  } else {
    callback()
  }
}

const rules = {
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱格式', trigger: 'blur' }
  ],
  code: [
    { required: true, message: '请输入验证码', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于6个字符', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    { validator: validateConfirmPassword, trigger: 'blur' }
  ]
}

const particleStyle = (i) => ({
  '--delay': `${Math.random() * 15}s`,
  '--size': `${Math.random() * 4 + 2}px`,
  '--left': `${Math.random() * 100}%`,
  '--duration': `${Math.random() * 10 + 10}s`,
  '--opacity': `${Math.random() * 0.4 + 0.1}`
})

const sendCode = async () => {
  if (!form.email) {
    ElMessage.warning('请先输入邮箱')
    return
  }
  sending.value = true
  try {
    const response = await sendResetCode(form.email)
    if (response.code === 200) {
      ElMessage.success('验证码已发送，请查收邮件')
      codeCountdown.value = 60
      countdownTimer = setInterval(() => {
        codeCountdown.value--
        if (codeCountdown.value <= 0) {
          clearInterval(countdownTimer)
        }
      }, 1000)
    } else {
      ElMessage.error(response.message || '发送失败')
    }
  } catch (error) {
    ElMessage.error('发送验证码失败')
  } finally {
    sending.value = false
  }
}

const handleReset = async () => {
  loading.value = true
  try {
    const response = await resetPassword({
      email: form.email,
      code: form.code,
      password: form.password
    })
    if (response.code === 200) {
      ElMessage.success('密码重置成功，请重新登录')
      router.push('/login')
    } else {
      ElMessage.error(response.message || '重置失败')
    }
  } catch (error) {
    ElMessage.error('重置密码失败')
  } finally {
    loading.value = false
  }
}

const goToLogin = () => {
  router.push('/login')
}
</script>

<style scoped>
.forgot-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #3a1c3d 0%, #5c1a2a 25%, #f093fb 50%, #f5576c 75%, #3a1c3d 100%);
  background-size: 400% 400%;
  animation: gradientShift 15s ease infinite;
  overflow: hidden;
}

@keyframes gradientShift {
  0%, 100% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
}

/* ---- 装饰 ---- */
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
  width: 380px; height: 380px;
  background: radial-gradient(circle, rgba(245,87,108,0.5), transparent);
  top: -8%; left: -5%;
}
.blob-2 {
  width: 340px; height: 340px;
  background: radial-gradient(circle, rgba(240,147,251,0.45), transparent);
  bottom: -8%; right: -5%;
  animation-delay: -7s; animation-duration: 23s;
}
.blob-3 {
  width: 280px; height: 280px;
  background: radial-gradient(circle, rgba(245,87,108,0.35), transparent);
  top: 45%; left: 55%;
  animation-delay: -14s; animation-duration: 18s;
}

@keyframes blobFloat {
  0%, 100% { transform: translate(0, 0) scale(1); }
  25% { transform: translate(40px, -30px) scale(1.1); }
  50% { transform: translate(-20px, 20px) scale(0.95); }
  75% { transform: translate(-30px, -15px) scale(1.05); }
}

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
  0% { transform: translateY(0) translateX(0); opacity: 0; }
  10% { opacity: var(--opacity); }
  90% { opacity: var(--opacity); }
  100% { transform: translateY(-105vh) translateX(calc(var(--size) * 5)); opacity: 0; }
}

/* ---- 卡片 ---- */
.forgot-box {
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
  max-width: 440px;
  animation: cardIn 0.8s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes cardIn {
  0% { opacity: 0; transform: translateY(30px) scale(0.96); }
  100% { opacity: 1; transform: translateY(0) scale(1); }
}

.theme-toggle {
  position: absolute;
  top: 16px; right: 16px;
  color: rgba(255, 255, 255, 0.7);
}
.theme-toggle:hover { color: #fff; }
:deep(.theme-toggle .el-icon) { filter: drop-shadow(0 0 6px rgba(255,255,255,0.4)); }

/* ---- Logo ---- */
.logo {
  text-align: center;
  margin-bottom: 36px;
}
.icon {
  font-size: 52px;
  display: inline-block;
  animation: iconFloat 3s ease-in-out infinite;
  filter: drop-shadow(0 4px 12px rgba(245,87,108,0.35));
}
@keyframes iconFloat {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}
h1 {
  font-size: 26px; color: #fff; margin: 8px 0 4px; font-weight: 700; letter-spacing: 2px;
}
.subtitle {
  color: rgba(255, 255, 255, 0.55); font-size: 14px; margin: 0;
}

/* ---- 表单 ---- */
:deep(.forgot-box .el-form-item__label) {
  color: rgba(255, 255, 255, 0.85); font-weight: 500;
}
:deep(.forgot-box .el-input__wrapper) {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.15);
  box-shadow: none; border-radius: 10px;
  transition: all 0.3s ease;
}
:deep(.forgot-box .el-input__wrapper:hover) {
  border-color: rgba(255, 255, 255, 0.35);
  background: rgba(255, 255, 255, 0.14);
}
:deep(.forgot-box .el-input__wrapper.is-focus) {
  border-color: #f093fb;
  background: rgba(255, 255, 255, 0.18);
  box-shadow: 0 0 0 3px rgba(240,147,251,0.25);
}
:deep(.forgot-box .el-input__inner) { color: #fff; }
:deep(.forgot-box .el-input__inner::placeholder) { color: rgba(255, 255, 255, 0.35); }
:deep(.forgot-box .el-input__prefix .el-icon) { color: rgba(255, 255, 255, 0.5); }
:deep(.forgot-box .el-input__suffix .el-icon) { color: rgba(255, 255, 255, 0.5); }

/* ---- 验证码 ---- */
.code-row { display: flex; gap: 10px; width: 100%; }
.code-input { flex: 1; }
.code-btn {
  white-space: nowrap;
  height: 40px;
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: rgba(255, 255, 255, 0.85);
  font-size: 13px;
  transition: all 0.3s;
}
.code-btn:hover:not(:disabled) {
  background: rgba(240,147,251,0.3);
  border-color: rgba(240,147,251,0.5);
  color: #fff;
}

/* ---- 按钮 ---- */
.reset-btn {
  width: 100%; height: 48px; font-size: 16px;
  border-radius: 12px;
  background: linear-gradient(135deg, #f093fb, #f5576c);
  border: none; position: relative; overflow: hidden;
  letter-spacing: 2px; font-weight: 600;
  transition: all 0.3s ease;
}
.reset-btn::after {
  content: ''; position: absolute; inset: 0;
  background: linear-gradient(135deg, rgba(255,255,255,0.2), transparent);
  opacity: 0; transition: opacity 0.3s;
}
.reset-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(245,87,108,0.45);
}
.reset-btn:hover::after { opacity: 1; }

/* ---- 底部 ---- */
.login-link {
  text-align: center; margin-top: 24px;
  color: rgba(255, 255, 255, 0.5); font-size: 14px;
}
.login-link .el-button {
  color: rgba(255, 255, 255, 0.7); font-size: 14px; padding: 0;
}
.login-link .el-button:hover { color: #f093fb; }
</style>
