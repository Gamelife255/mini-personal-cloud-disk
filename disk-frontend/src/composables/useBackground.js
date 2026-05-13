import { ref, computed, watch } from 'vue'
import { useDarkMode } from './useDarkMode'
import { downloadFile } from '../api/file'

export const gradientPresets = [
  { name: 'Ocean', light: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)', dark: 'linear-gradient(135deg, #2d1b4e 0%, #1a237e 100%)' },
  { name: 'Forest', light: 'linear-gradient(135deg, #11998e 0%, #38ef7d 100%)', dark: 'linear-gradient(135deg, #0a3d2e 0%, #1b5e20 100%)' },
  { name: 'Sunset', light: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)', dark: 'linear-gradient(135deg, #4a0e3a 0%, #5c1a2a 100%)' },
  { name: 'Sky', light: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)', dark: 'linear-gradient(135deg, #0d3b66 0%, #1a5276 100%)' },
  { name: 'Lavender', light: 'linear-gradient(135deg, #e0c3fc 0%, #8ec5fc 100%)', dark: 'linear-gradient(135deg, #2c1e4a 0%, #1a3a5c 100%)' },
  { name: 'Cherry', light: 'linear-gradient(135deg, #f5af19 0%, #f12711 100%)', dark: 'linear-gradient(135deg, #5c1a0e 0%, #8b0000 100%)' },
  { name: 'Mint', light: 'linear-gradient(135deg, #a8e6cf 0%, #dcedc1 100%)', dark: 'linear-gradient(135deg, #1a3c2a 0%, #2e4a2e 100%)' },
  { name: 'Midnight', light: 'linear-gradient(135deg, #2c3e50 0%, #3498db 100%)', dark: 'linear-gradient(135deg, #0a0a2e 0%, #1a1a4e 100%)' }
]

export const colorPresets = [
  { name: 'Slate', light: '#e8edf2', dark: '#1e2329' },
  { name: 'Warm', light: '#fef9ef', dark: '#2a2520' },
  { name: 'Cool', light: '#f0f4f8', dark: '#1a2030' },
  { name: 'Rose', light: '#fef2f2', dark: '#2a1a1a' },
  { name: 'Mint', light: '#f0fdf4', dark: '#1a2a1e' },
  { name: 'Violet', light: '#f5f3ff', dark: '#1e1a2e' },
  { name: 'Amber', light: '#fffbeb', dark: '#2a2510' },
  { name: 'Teal', light: '#f0fdfa', dark: '#1a2a28' }
]

function loadConfig(storageKey) {
  try {
    const raw = localStorage.getItem(storageKey)
    if (raw) {
      const parsed = JSON.parse(raw)
      if (parsed && typeof parsed.type === 'string') {
        return { opacity: 1, ...parsed }
      }
    }
  } catch (e) {
    // corrupted data, fall through
  }
  return { type: 'none', opacity: 1 }
}

// Per-context module-level state
const stateMap = new Map()

function getOrCreateState(context) {
  if (!stateMap.has(context)) {
    const storageKey = `custom-background-${context}`
    const background = ref(loadConfig(storageKey))
    const showSettings = ref(false)

    const { isDark } = useDarkMode()

    const cloudBlobUrl = ref(null)

    async function loadCloudBlob(fileId) {
      try {
        if (cloudBlobUrl.value) {
          URL.revokeObjectURL(cloudBlobUrl.value)
          cloudBlobUrl.value = null
        }
        const blob = await downloadFile(fileId)
        cloudBlobUrl.value = URL.createObjectURL(blob)
      } catch (e) {
        console.error('Failed to load cloud background image:', e)
        cloudBlobUrl.value = null
      }
    }

    // Load cloud image blob on init if saved config references one
    if (background.value.type === 'cloudImage' && background.value.fileId) {
      loadCloudBlob(background.value.fileId)
    }

    const containerBackground = computed(() => {
      const config = background.value
      if (!config || config.type === 'none') return {}
      return { position: 'relative' }
    })

    const bgLayerStyle = computed(() => {
      const config = background.value
      if (!config || config.type === 'none') return { display: 'none' }

      const isDarkVal = isDark.value
      const value = (isDarkVal && config.darkValue) ? config.darkValue : config.value
      const opacity = config.opacity ?? 1

      const base = {
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        zIndex: -1,
        pointerEvents: 'none',
        opacity
      }

      switch (config.type) {
        case 'gradient':
          return { ...base, background: value }
        case 'color':
          return { ...base, backgroundColor: value }
        case 'image':
          return {
            ...base,
            backgroundImage: `url(${value})`,
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            backgroundColor: isDarkVal ? '#1a1a1a' : '#f0f0f0'
          }
        case 'cloudImage':
          if (!cloudBlobUrl.value) {
            return { ...base, backgroundColor: isDarkVal ? '#1a1a1a' : '#f0f0f0' }
          }
          return {
            ...base,
            backgroundImage: `url(${cloudBlobUrl.value})`,
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            backgroundColor: isDarkVal ? '#1a1a1a' : '#f0f0f0'
          }
        default:
          return { display: 'none' }
      }
    })

    const isCustom = computed(() => background.value.type !== 'none')

    function setBackground(config) {
      // If switching away from cloudImage, revoke old blob URL
      if (background.value.type === 'cloudImage' && config.type !== 'cloudImage' && cloudBlobUrl.value) {
        URL.revokeObjectURL(cloudBlobUrl.value)
        cloudBlobUrl.value = null
      }
      background.value = config
      // Trigger blob fetch for cloudImage, or reuse pre-fetched blob URL
      if (config.type === 'cloudImage' && config.fileId) {
        if (config.blobUrl) {
          if (cloudBlobUrl.value) URL.revokeObjectURL(cloudBlobUrl.value)
          cloudBlobUrl.value = config.blobUrl
        } else {
          loadCloudBlob(config.fileId)
        }
      }
      // Persist without blob URL (it's in-memory only)
      const { blobUrl, ...persistable } = config
      localStorage.setItem(storageKey, JSON.stringify(persistable))
    }

    function resetBackground() {
      if (cloudBlobUrl.value) {
        URL.revokeObjectURL(cloudBlobUrl.value)
        cloudBlobUrl.value = null
      }
      background.value = { type: 'none' }
      localStorage.removeItem(storageKey)
    }

    stateMap.set(context, {
      background,
      showSettings,
      containerBackground,
      bgLayerStyle,
      isCustom,
      setBackground,
      resetBackground
    })
  }
  return stateMap.get(context)
}

export function useBackground(context = 'disk') {
  return getOrCreateState(context)
}
