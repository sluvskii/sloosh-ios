import { useEffect, useState, useCallback } from 'react'
import { favoritesCache, type FavoriteItem } from '../api'

interface UseFavoritesReturn {
  favorites: FavoriteItem[]
  isFavorite: (mediaId: number | string, mediaType: 'movie' | 'tv') => boolean
  addToFavorites: (mediaId: number | string, mediaType: 'movie' | 'tv', mediaInfo?: Partial<FavoriteItem>) => Promise<void>
  removeFromFavorites: (mediaId: number | string, mediaType: 'movie' | 'tv') => Promise<void>
  isLoading: boolean
  error: Error | null
  refetch: () => Promise<void>
}

/**
 * Хук для работы с избранным с кешированием
 */
export const useFavorites = (): UseFavoritesReturn => {
  const [favorites, setFavorites] = useState<FavoriteItem[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  // Инициализация кеша при монтировании
  useEffect(() => {
    const initCache = async () => {
      try {
        // Проверяем авторизацию
        const token = localStorage.getItem('token')
        if (!token) {
          setIsLoading(false)
          return
        }

        setIsLoading(true)
        setError(null)
        
        // Проверяем есть ли уже кеш
        let cached = favoritesCache.getCached()
        
        if (cached) {
          setFavorites(cached)
          setIsLoading(false)
        } else {
          await favoritesCache.initialize()
          const fav = favoritesCache.getCached()
          if (fav) {
            setFavorites(fav)
          } else {
            const fetched = await favoritesCache.getFavorites(true)
            setFavorites(fetched)
          }
          setIsLoading(false)
        }
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Failed to load favorites'))
        setIsLoading(false)
      }
    }

    initCache()

    // Подписываемся на изменения кеша
    const unsubscribe = favoritesCache.subscribe((fav) => {
      setFavorites(fav)
    })

    return () => {
      unsubscribe()
    }
  }, [])

  const isFavorite = useCallback(
    (mediaId: number | string, mediaType: 'movie' | 'tv') => {
      return favoritesCache.isFavorite(mediaId, mediaType)
    },
    []
  )

  const addToFavorites = useCallback(
    async (mediaId: number | string, mediaType: 'movie' | 'tv', mediaInfo?: Partial<FavoriteItem>) => {
      try {
        setError(null)
        await favoritesCache.addToFavorites(mediaId, mediaType, mediaInfo)
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to add to favorites')
        setError(error)
        throw error
      }
    },
    []
  )

  const removeFromFavorites = useCallback(
    async (mediaId: number | string, mediaType: 'movie' | 'tv') => {
      try {
        setError(null)
        await favoritesCache.removeFromFavorites(mediaId, mediaType)
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Failed to remove from favorites')
        setError(error)
        throw error
      }
    },
    []
  )

  const refetch = useCallback(async () => {
    try {
      setIsLoading(true)
      setError(null)
      const fav = await favoritesCache.getFavorites(true)
      setFavorites(fav)
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Failed to refetch favorites')
      setError(error)
      throw error
    } finally {
      setIsLoading(false)
    }
  }, [])

  return {
    favorites,
    isFavorite,
    addToFavorites,
    removeFromFavorites,
    isLoading,
    error,
    refetch,
  }
}
