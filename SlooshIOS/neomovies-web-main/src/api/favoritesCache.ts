import { apiClient } from './client'

type TimeoutId = ReturnType<typeof setTimeout>

export interface FavoriteItem {
  id: string
  mediaId: string
  mediaType: 'movie' | 'tv'
  title: string
  nameRu: string
  nameEn: string
  posterPath?: string
  posterUrl?: string
  year: number
  rating: number
  createdAt: string
}

interface CacheData {
  favorites: FavoriteItem[]
  timestamp: number
  hash: string
}

const CACHE_KEY = 'favorites_cache'
const CACHE_DURATION = 5 * 60 * 1000 // 5 минут
const SYNC_INTERVAL = 30 * 1000 // 30 секунд для проверки изменений

class FavoritesCache {
  private cache: CacheData | null = null
  private syncTimer: TimeoutId | null = null
  private lastSyncHash: string = ''
  private listeners: Set<(favorites: FavoriteItem[]) => void> = new Set()

  private normalizeRouteId(mediaId: number | string): string {
    const raw = String(mediaId).trim()
    return raw.replace(/^kp_/, '')
  }

  private canonicalMediaId(mediaId: number | string): string {
    const routeId = this.normalizeRouteId(mediaId)
    return routeId ? `kp_${routeId}` : ''
  }

  /**
   * Инициализирует кеш и запускает синхронизацию
   */
  async initialize(): Promise<void> {
    this.loadFromStorage()
    
    // Если кеш пуст, загружаем с сервера
    if (!this.cache) {
      await this.getFavorites(true)
    } else {
      await this.syncIfNeeded()
    }
    
    this.startAutoSync()
  }

  /**
   * Загружает кеш из localStorage
   */
  private loadFromStorage(): void {
    try {
      const stored = localStorage.getItem(CACHE_KEY)
      if (stored) {
        this.cache = JSON.parse(stored)
      }
    } catch (error) {
      this.cache = null
    }
  }

  /**
   * Сохраняет кеш в localStorage
   */
  private saveToStorage(): void {
    if (!this.cache) return
    try {
      localStorage.setItem(CACHE_KEY, JSON.stringify(this.cache))
    } catch (error) {
      // silent fail
    }
  }

  /**
   * Генерирует хеш для проверки изменений
   */
  private generateHash(favorites: FavoriteItem[]): string {
    const ids = favorites.map(f => `${f.mediaId}:${f.mediaType}`).sort().join(',')
    return btoa(ids) // простой хеш
  }

  /**
   * Получает список избранного с кешированием
   */
  async getFavorites(forceRefresh: boolean = false): Promise<FavoriteItem[]> {
    const now = Date.now()

    // Если кеш свежий и не требуется принудительное обновление
    if (
      !forceRefresh &&
      this.cache &&
      now - this.cache.timestamp < CACHE_DURATION
    ) {
      return this.cache.favorites
    }

    // Загружаем с сервера
    try {
      const response = await apiClient.get('/api/v1/favorites')
      const favorites = response.data as FavoriteItem[]

      const hash = this.generateHash(favorites)
      this.cache = {
        favorites,
        timestamp: now,
        hash,
      }

      this.lastSyncHash = hash
      this.saveToStorage()
      this.notifyListeners(favorites)

      return favorites
    } catch (error) {
      // Возвращаем кеш если есть, даже если он устарел
      if (this.cache) {
        return this.cache.favorites
      }
      throw error
    }
  }

  /**
   * Проверяет изменения на сервере без полной загрузки
   */
  async syncIfNeeded(): Promise<void> {
    try {
      const response = await apiClient.get('/api/v1/favorites')
      const favorites = response.data as FavoriteItem[]
      const hash = this.generateHash(favorites)

      // Если хеш изменился, обновляем кеш
      if (hash !== this.lastSyncHash) {
        this.cache = {
          favorites,
          timestamp: Date.now(),
          hash,
        }
        this.lastSyncHash = hash
        this.saveToStorage()
        this.notifyListeners(favorites)
      }
    } catch (error) {
      // silent fail
    }
  }

  /**
   * Запускает автоматическую синхронизацию
   */
  private startAutoSync(): void {
    if (this.syncTimer) {
      clearInterval(this.syncTimer)
    }

    this.syncTimer = setInterval(() => {
      this.syncIfNeeded()
    }, SYNC_INTERVAL)
  }

  /**
   * Останавливает автоматическую синхронизацию
   */
  stopAutoSync(): void {
    if (this.syncTimer) {
      clearInterval(this.syncTimer)
      this.syncTimer = null
    }
  }

  /**
   * Проверяет, находится ли элемент в избранном
   */
  isFavorite(mediaId: number | string, mediaType: 'movie' | 'tv'): boolean {
    if (!this.cache) return false
    const target = this.canonicalMediaId(mediaId)
    return this.cache.favorites.some(
      f => this.canonicalMediaId(f.mediaId) === target && f.mediaType === mediaType
    )
  }

  /**
   * Получает все ID избранного для быстрой проверки
   */
  getFavoriteIds(): Set<string> {
    if (!this.cache) return new Set()
    return new Set(
      this.cache.favorites.map(f => `${f.mediaId}:${f.mediaType}`)
    )
  }

  /**
   * Добавляет элемент в избранное (оптимистичное обновление)
   */
  async addToFavorites(
    mediaId: number | string,
    mediaType: 'movie' | 'tv',
    mediaInfo?: Partial<FavoriteItem>
  ): Promise<void> {
    const routeId = this.normalizeRouteId(mediaId)
    const mediaIdCanonical = this.canonicalMediaId(mediaId)
    if (!routeId || !mediaIdCanonical) return

    // Оптимистичное обновление кеша
    if (this.cache && mediaInfo) {
      const newFavorite: FavoriteItem = {
        id: `${mediaIdCanonical}:${mediaType}`,
        mediaId: mediaIdCanonical,
        mediaType,
        title: mediaInfo.title || '',
        nameRu: mediaInfo.nameRu || '',
        nameEn: mediaInfo.nameEn || '',
        posterPath: mediaInfo.posterPath || '',
        year: mediaInfo.year || 0,
        rating: mediaInfo.rating || 0,
        createdAt: new Date().toISOString(),
      }

      if (!this.cache.favorites.some(f => this.canonicalMediaId(f.mediaId) === mediaIdCanonical && f.mediaType === mediaType)) {
        this.cache.favorites.push(newFavorite)
        this.saveToStorage()
        this.notifyListeners(this.cache.favorites)
      }
    }

    // Отправляем на сервер
    try {
      await apiClient.post(`/api/v1/favorites/${routeId}`, {}, { params: { type: mediaType } })
      // После успеха синхронизируем
      await this.syncIfNeeded()
    } catch (error) {
      // Откатываем оптимистичное обновление
      if (this.cache && mediaInfo) {
        this.cache.favorites = this.cache.favorites.filter(
          f => !(this.canonicalMediaId(f.mediaId) === mediaIdCanonical && f.mediaType === mediaType)
        )
        this.saveToStorage()
        this.notifyListeners(this.cache.favorites)
      }
      throw error
    }
  }

  /**
   * Удаляет элемент из избранного (оптимистичное обновление)
   */
  async removeFromFavorites(
    mediaId: number | string,
    mediaType: 'movie' | 'tv'
  ): Promise<void> {
    const routeId = this.normalizeRouteId(mediaId)
    const mediaIdCanonical = this.canonicalMediaId(mediaId)
    if (!routeId || !mediaIdCanonical) return

    // Оптимистичное обновление кеша
    const hadItem = this.cache?.favorites.some(
      f => this.canonicalMediaId(f.mediaId) === mediaIdCanonical && f.mediaType === mediaType
    )

    if (this.cache && hadItem) {
      this.cache.favorites = this.cache.favorites.filter(
        f => !(this.canonicalMediaId(f.mediaId) === mediaIdCanonical && f.mediaType === mediaType)
      )
      this.saveToStorage()
      this.notifyListeners(this.cache.favorites)
    }

    // Отправляем на сервер
    try {
      await apiClient.delete(`/api/v1/favorites/${routeId}`, { params: { type: mediaType } })
      // После успеха синхронизируем
      await this.syncIfNeeded()
    } catch (error) {
      // Откатываем оптимистичное обновление
      await this.syncIfNeeded()
      throw error
    }
  }

  /**
   * Подписывается на изменения кеша
   */
  subscribe(listener: (favorites: FavoriteItem[]) => void): () => void {
    this.listeners.add(listener)
    return () => {
      this.listeners.delete(listener)
    }
  }

  /**
   * Уведомляет слушателей об изменениях
   */
  private notifyListeners(favorites: FavoriteItem[]): void {
    this.listeners.forEach(listener => {
      try {
        listener(favorites)
      } catch (error) {
        // silent fail
      }
    })
  }

  /**
   * Очищает кеш
   */
  clear(): void {
    this.cache = null
    this.lastSyncHash = ''
    localStorage.removeItem(CACHE_KEY)
    this.notifyListeners([])
  }

  /**
   * Получает текущий кеш без загрузки
   */
  getCached(): FavoriteItem[] | null {
    return this.cache?.favorites || null
  }
}

// Экспортируем синглтон
export const favoritesCache = new FavoritesCache()
