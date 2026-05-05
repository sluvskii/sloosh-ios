import { apiClient } from './client'
import type { MovieResponse, Movie } from '../types'

const normalizePaged = (raw: any, page: number): MovieResponse => ({
  page,
  results: raw?.results || [],
  total_pages: raw?.pages || raw?.total_pages || 1,
  total_results: raw?.total || raw?.total_results || 0,
})

export const moviesAPI = {
  // Получение популярных фильмов
  async getPopular(page = 1) {
    const res = await apiClient.get('/api/v1/movies/popular', {
      params: { page },
      timeout: 30000
    })
    return { ...res, data: normalizePaged(res.data, page) }
  },

  // Получение фильмов с высоким рейтингом
  async getTopRated(page = 1) {
    const res = await apiClient.get('/api/v1/movies/top-rated', {
      params: { page },
      timeout: 30000
    })
    return { ...res, data: normalizePaged(res.data, page) }
  },

  // Получение данных о фильме по ID
  getMovieById(id: string | number) {
    return apiClient.get<Movie>(`/api/v1/movie/${id}`, { timeout: 30000 })
  },

  // Поиск фильмов
  async searchMovies(query: string, page = 1) {
    const res = await apiClient.get('/api/v1/search', {
      params: {
        query,
        page
      },
      timeout: 30000
    })
    return { ...res, data: normalizePaged(res.data, page) }
  },

  // Получение IMDB и других external ids
  async getExternalIds(id: string | number) {
    const res = await apiClient.get<Movie>(`/api/v1/movie/${id}`, { timeout: 30000 })
    return (res.data as any)?.externalIds || null
  }
}
