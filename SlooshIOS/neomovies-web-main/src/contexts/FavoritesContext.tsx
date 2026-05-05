import React, { createContext, useContext, useEffect, type ReactNode } from 'react'
import { useFavorites } from '../hooks/useFavorites'
import { favoritesCache, type FavoriteItem } from '../api'

interface FavoritesContextType {
  favorites: FavoriteItem[]
  isFavorite: (mediaId: number | string, mediaType: 'movie' | 'tv') => boolean
  addToFavorites: (mediaId: number | string, mediaType: 'movie' | 'tv', mediaInfo?: Partial<FavoriteItem>) => Promise<void>
  removeFromFavorites: (mediaId: number | string, mediaType: 'movie' | 'tv') => Promise<void>
  isLoading: boolean
  error: Error | null
  refetch: () => Promise<void>
}

const FavoritesContext = createContext<FavoritesContextType | undefined>(undefined)

interface FavoritesProviderProps {
  children: ReactNode
}

export const FavoritesProvider: React.FC<FavoritesProviderProps> = ({ children }) => {
  const favorites = useFavorites()

  // Убедимся, что кеш инициализирован при монтировании провайдера
  useEffect(() => {
    const initCache = async () => {
      try {
        const token = localStorage.getItem('token')
        if (token && !favoritesCache.getCached()) {
          console.log('[FavoritesProvider] Initializing cache...')
          await favoritesCache.initialize()
        }
      } catch (error) {
        console.error('[FavoritesProvider] Failed to initialize cache:', error)
      }
    }

    initCache()
  }, [])

  // Re-init cache on auth changes (login/logout)
  useEffect(() => {
    const onAuthChanged = async () => {
      try {
        const token = localStorage.getItem('token')
        if (token) {
          await favoritesCache.initialize()
        } else {
          favoritesCache.clear()
        }
      } catch (error) {
        console.error('[FavoritesProvider] Failed to handle auth change:', error)
      }
    }

    window.addEventListener('auth-changed', onAuthChanged)
    return () => window.removeEventListener('auth-changed', onAuthChanged)
  }, [])

  return (
    <FavoritesContext.Provider value={favorites}>
      {children}
    </FavoritesContext.Provider>
  )
}

export const useFavoritesContext = (): FavoritesContextType => {
  const context = useContext(FavoritesContext)
  if (!context) {
    throw new Error('useFavoritesContext must be used within FavoritesProvider')
  }
  return context
}
