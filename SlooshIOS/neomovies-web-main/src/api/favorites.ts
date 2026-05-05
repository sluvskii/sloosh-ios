import { favoritesCache } from './index'

export const favoritesAPI = {
  // Get all favorites (с кешированием)
  getFavorites: async (forceRefresh: boolean = false) => {
    return favoritesCache.getFavorites(forceRefresh)
  },

  // Add to favorites (с оптимистичным обновлением)
  addToFavorites: async (movieId: number | string, mediaType: string = 'movie', mediaInfo?: any) => {
    return favoritesCache.addToFavorites(movieId, mediaType as 'movie' | 'tv', mediaInfo)
  },

  // Remove from favorites (с оптимистичным обновлением)
  removeFromFavorites: async (movieId: number | string, mediaType: string = 'movie') => {
    return favoritesCache.removeFromFavorites(movieId, mediaType as 'movie' | 'tv')
  },

  // Check if movie is favorite (из кеша)
  checkIsFavorite: (movieId: number | string, mediaType: string = 'movie') => {
    return favoritesCache.isFavorite(movieId, mediaType as 'movie' | 'tv')
  },

  // Получить все ID избранного для быстрой проверки
  getFavoriteIds: () => {
    return favoritesCache.getFavoriteIds()
  },

  // Инициализировать кеш
  initialize: async () => {
    return favoritesCache.initialize()
  },

  // Подписаться на изменения
  subscribe: (listener: (favorites: any[]) => void) => {
    return favoritesCache.subscribe(listener)
  },

  // Очистить кеш
  clear: () => {
    favoritesCache.clear()
  },
}
