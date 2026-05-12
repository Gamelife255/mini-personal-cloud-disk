import { ref, watch } from 'vue'

const isDark = ref(false)

export function useDarkMode() {
  // 初始化：从 localStorage 读取偏好
  const saved = localStorage.getItem('theme')
  if (saved === 'dark') {
    isDark.value = true
    document.documentElement.classList.add('dark')
  }

  function toggle() {
    isDark.value = !isDark.value
  }

  watch(isDark, (val) => {
    if (val) {
      document.documentElement.classList.add('dark')
      localStorage.setItem('theme', 'dark')
    } else {
      document.documentElement.classList.remove('dark')
      localStorage.setItem('theme', 'light')
    }
  })

  return { isDark, toggle }
}
