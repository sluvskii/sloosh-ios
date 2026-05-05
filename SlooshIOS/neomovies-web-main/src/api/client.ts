import axios from 'axios'

const resolveApiBaseUrl = (): string => {
  const raw = (import.meta.env.VITE_API_URL || '').trim()
  if (!raw) return ''

  try {
    const parsed = new URL(raw)
    const isLocalHost =
      parsed.hostname === 'localhost' ||
      parsed.hostname === '127.0.0.1' ||
      parsed.hostname === '::1'

    // If app is opened on mobile via LAN URL, but API env points to localhost,
    // use current device-accessible host with the same API port.
    if (
      typeof window !== 'undefined' &&
      isLocalHost &&
      window.location.hostname !== 'localhost' &&
      window.location.hostname !== '127.0.0.1'
    ) {
      const mobileUrl = new URL(parsed.toString())
      mobileUrl.hostname = window.location.hostname
      mobileUrl.protocol = window.location.protocol
      return mobileUrl.toString().replace(/\/$/, '')
    }

    return parsed.toString().replace(/\/$/, '')
  } catch {
    return raw.replace(/\/$/, '')
  }
}

export const API_BASE_URL = resolveApiBaseUrl()
const AUTH_REFRESH_INTERVAL_MS = 50 * 60 * 1000 // refresh every 50 min (access token TTL is 1h)

let refreshPromise: Promise<string | null> | null = null
let refreshTimer: number | null = null
let visibilityHandler: (() => void) | null = null

// Создание экземпляра Axios с базовыми настройками
export const apiClient = axios.create({
  baseURL: API_BASE_URL || undefined,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})

export const setAuthTokens = (accessToken: string, refreshToken: string) => {
  localStorage.setItem('token', accessToken)
  localStorage.setItem('refreshToken', refreshToken)

  const expiresIn = new Date()
  expiresIn.setDate(expiresIn.getDate() + 30)
  document.cookie = `token=${accessToken}; path=/; expires=${expiresIn.toUTCString()}; SameSite=Lax`
  document.cookie = `refreshToken=${refreshToken}; path=/; expires=${expiresIn.toUTCString()}; SameSite=Lax`
  apiClient.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`
}

export const clearAuthState = () => {
  localStorage.removeItem('token')
  localStorage.removeItem('refreshToken')
  localStorage.removeItem('userName')
  localStorage.removeItem('userEmail')
  localStorage.removeItem('userAvatar')
  localStorage.removeItem('neo_id_access_token')
  localStorage.removeItem('neo_id_refresh_token')
  document.cookie = 'token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 UTC; SameSite=Lax'
  document.cookie = 'refreshToken=; path=/; expires=Thu, 01 Jan 1970 00:00:00 UTC; SameSite=Lax'
  delete apiClient.defaults.headers.common['Authorization']
  window.dispatchEvent(new Event('auth-changed'))
}

// Функция для получения токена из cookies
const getTokenFromCookie = (): string | null => {
  try {
    const tokenName = 'token='
    const decodedCookie = decodeURIComponent(document.cookie)
    const cookieArray = decodedCookie.split(';')
    for (let cookie of cookieArray) {
      cookie = cookie.trim()
      if (cookie.indexOf(tokenName) === 0) {
        return cookie.substring(tokenName.length)
      }
    }
  } catch {
    return null
  }
  return null
}

// Перехватчик запросов
apiClient.interceptors.request.use(
  (config) => {
    // Получение токена сначала из cookies, потом из localStorage
    let token: string | null = null
    try {
      token = getTokenFromCookie() || localStorage.getItem('token')
    } catch {
      token = null
    }
    
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    
    // Добавляем язык по умолчанию (только русский)
    if (!config.params) {
      config.params = {}
    }
    if (!config.params.lang && !config.params.language) {
      config.params.lang = 'ru'
    }
    
    // Логика для пагинации
    if (config.params?.page) {
      const page = parseInt(config.params.page)
      if (isNaN(page) || page < 1) {
        config.params.page = 1
      }
    }
    
    return config
  },
  (error) => {
    if (import.meta.env.DEV) {
      console.error('❌ Request Error:', error)
    }
    return Promise.reject(error)
  }
)

// Функция для обновления токена
export const refreshToken = async (): Promise<string | null> => {
  if (refreshPromise) {
    return refreshPromise
  }

  refreshPromise = (async () => {
  try {
    const refreshTokenValue = localStorage.getItem('refreshToken')
    if (!refreshTokenValue) {
      return null
    }

    const response = await axios.post(`${API_BASE_URL}/api/v1/auth/refresh`, {
      refreshToken: refreshTokenValue
    })

    const data = response.data.data || response.data
    const newAccessToken = data.accessToken
    const newRefreshToken = data.refreshToken

    if (newAccessToken && newRefreshToken) {
      setAuthTokens(newAccessToken, newRefreshToken)
      return newAccessToken
    }

    return null
  } catch (err: any) {
    const status = err?.response?.status
    // Clear auth only when server says token is invalid/expired.
    // Keep current state on transient network failures.
    if (status === 400 || status === 401) {
      clearAuthState()
    }
    return null
  }
  })()

  const result = await refreshPromise
  refreshPromise = null
  return result
}

// Returns true if the stored access token is expired or will expire within the next `thresholdSec` seconds
const isAccessTokenExpiredOrExpiring = (thresholdSec = 120): boolean => {
  try {
    const token = localStorage.getItem('token')
    if (!token) return true
    const payload = JSON.parse(atob(token.split('.')[1]))
    const exp: number = payload.exp
    if (!exp) return true
    return Date.now() / 1000 >= exp - thresholdSec
  } catch {
    return true
  }
}

export const startAuthSessionKeepAlive = () => {
  if (refreshTimer !== null) {
    clearInterval(refreshTimer)
    refreshTimer = null
  }
  if (visibilityHandler) {
    document.removeEventListener('visibilitychange', visibilityHandler)
    visibilityHandler = null
  }

  // On app start: refresh only if access token is expired/expiring soon
  if (localStorage.getItem('refreshToken') && isAccessTokenExpiredOrExpiring()) {
    void refreshToken()
  }

  refreshTimer = window.setInterval(() => {
    if (document.visibilityState === 'visible' && localStorage.getItem('refreshToken')) {
      void refreshToken()
    }
  }, AUTH_REFRESH_INTERVAL_MS)

  visibilityHandler = () => {
    // On tab focus: refresh only if token is expired or expiring within 2 minutes
    if (document.visibilityState === 'visible' && localStorage.getItem('refreshToken') && isAccessTokenExpiredOrExpiring()) {
      void refreshToken()
    }
  }
  document.addEventListener('visibilitychange', visibilityHandler)

  return () => {
    if (refreshTimer !== null) {
      clearInterval(refreshTimer)
      refreshTimer = null
    }
    if (visibilityHandler) {
      document.removeEventListener('visibilitychange', visibilityHandler)
      visibilityHandler = null
    }
  }
}

// Перехватчик ответов
apiClient.interceptors.response.use(
  (response) => {
    // Не обрабатываем изображения и плееры
    const url = response.config?.url || ''
    const shouldUnwrap = !url.includes('/images/') &&
                        !url.includes('/players/')
    
    if (shouldUnwrap && response.data && response.data.success && response.data.data !== undefined) {
      response.data = response.data.data
    }
    return response
  },
  async (error) => {
    const originalRequest = error.config

    // Проверяем на 401 ошибку и что запрос еще не был повторен
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true

      const newToken = await refreshToken()
      if (newToken) {
        originalRequest.headers.Authorization = `Bearer ${newToken}`
        return apiClient(originalRequest)
      } else {
        if (!localStorage.getItem('token')) {
          // Tokens were invalid and have been cleared.
          window.dispatchEvent(new Event('auth-expired'))
        }
        return Promise.reject(error)
      }
    }

    return Promise.reject(error)
  }
)

export const getImageUrl = (path: string | null | undefined): string => {
  if (!path) return '/images/placeholder.jpg'

  const kpPattern = /kinopoiskapiunofficial\.tech\/images\/posters\/(kp|kp_small|kp_big)\/(\d+)\.jpg/i
  const kpMatch = path.match(kpPattern)
  if (kpMatch) {
    const kind = kpMatch[1].toLowerCase()
    const id = kpMatch[2]
    return `${API_BASE_URL}/api/v1/images/${kind}/${id}`
  }

  if (path.includes('/api/v1/images/')) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path
    return `${API_BASE_URL}${path}`
  }

  if (path.startsWith('/images/')) {
    const parts = path.split('/').filter(Boolean) // ["images", "kp_small", "123.jpg"]
    const kind = parts[1] || ''
    const rawId = parts.slice(2).join('/')
    const id = rawId.replace(/\.jpg$/i, '')
    if (kind && id) {
      return `${API_BASE_URL}/api/v1/images/${kind}/${id}`
    }
    return `${API_BASE_URL}/api/v1${path}`
  }

  if (path.startsWith('http://') || path.startsWith('https://')) return path

  return '/images/placeholder.jpg'
}
