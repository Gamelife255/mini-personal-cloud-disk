<template>
  <div class="forgot-container" :style="containerBackground">
    <div v-if="isCustom" class="bg-layer" :style="bgLayerStyle"></div>
    <div class="forgot-box">
      <el-button link class="theme-toggle" @click="toggleTheme">
        <el-icon :size="20"><Sunny v-if="isDark" /><Moon v-else /></el-icon>
      </el-button>
      <div class="logo">
        <span class="icon">☁️</span>
        <h1>找回密码</h1>
      </div>

      <el-form ref="formRef" :model="form" :rules="rules" label-width="80px">
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="form.email" placeholder="请输入注册邮箱" />
        </el-form-item>

        <el-form-item label="验证码" prop="code">
          <div class="code-row">
            <el-input v-model="form.code" placeholder="请输入验证码" class="code-input" />
            <el-button :disabled="codeCountdown > 0" @click="sendCode" :loading="sending">
              {{ codeCountdown > 0 ? codeCountdown + 's 后重发' : '发送验证码' }}
            </el-button>
          </div>
        </el-form-item>

        <el-form-item label="新密码" prop="password">
          <el-input type="password" v-model="form.password" placeholder="请输入新密码" />
        </el-form-item>

        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input type="password" v-model="form.confirmPassword" placeholder="请再次输入新密码" />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="handleReset" class="reset-btn" :loading="loading">
            重置密码
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
    console.error('发送验证码失败:', error)
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
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.forgot-box {
  position: relative;
  background: var(--el-bg-color);
  padding: 40px;
  border-radius: 12px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
  width: 100%;
  max-width: 420px;
}

.theme-toggle {
  position: absolute;
  top: 12px;
  right: 12px;
}

.logo {
  text-align: center;
  margin-bottom: 30px;
}

.icon {
  font-size: 48px;
  display: block;
  margin-bottom: 10px;
}

h1 {
  font-size: 24px;
  color: var(--el-text-color-primary);
  margin: 0;
}

.reset-btn {
  width: 100%;
  height: 44px;
  font-size: 16px;
}

.login-link {
  text-align: center;
  margin-top: 20px;
  color: var(--el-text-color-secondary);
}

.code-row {
  display: flex;
  gap: 12px;
  width: 100%;
}

.code-input {
  flex: 1;
}

.code-row .el-button {
  white-space: nowrap;
}
</style>
