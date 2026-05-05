import { apiClient } from './client'
import type { TVResponse, TVShow } from '../types'

const isTvItem = (item: any) =>
  item?.type === 'tv' ||
  item?.media_type === 'tv' ||
  item?.serial === true

const normalizeTvPaged = (raw: any, page: number): TVResponse => ({
  page,
  results: (raw?.results || []).filter(isTvItem),
  total_pages: raw?.pages || raw?.total_pages || 1,
  total_results: raw?.total || raw?.total_results || 0,
})

export const tvAPI = {
  // Получение популярных сериалов
  async getPopular(page = 1) {
    const res = await apiClient.get('/api/v1/movies/popular', {
      params: { page },
      timeout: 30000
    })
    return { ...res, data: normalizeTvPaged(res.data, page) }
  },

  // Получение сериалов с высоким рейтингом
  async getTopRated(page = 1) {
    const res = await apiClient.get('/api/v1/tv/top-rated', {
      params: { page },
      timeout: 30000
    })
    return { ...res, data: normalizeTvPaged(res.data, page) }
  },

  // Получение сериалов в эфире
  async getOnTheAir(page = 1) {
    return this.getPopular(page)
  },

  // Получение сериалов, которые выходят сегодня
  async getAiringToday(page = 1) {
    return this.getPopular(page)
  },

  // Получение данных о сериале по ID
  getTVById(id: string | number) {
    return apiClient.get<TVShow>(`/api/v1/movie/${id}`, { timeout: 30000 })
  },

  // Поиск сериалов
  async searchTVShows(query: string, page = 1) {
    const res = await apiClient.get('/api/v1/search', {
      params: {
        query,
        page
      },
      timeout: 30000
    })
    return { ...res, data: normalizeTvPaged(res.data, page) }
  },

  // Получение IMDB и других external ids
  async getExternalIds(id: string | number) {
    const res = await apiClient.get<TVShow>(`/api/v1/movie/${id}`, { timeout: 30000 })
    return (res.data as any)?.externalIds || null
  }
}
