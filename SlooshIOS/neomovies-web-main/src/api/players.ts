import { apiClient } from './client'

export const playersAPI = {
  // Alloha плеер
  getAllohaPlayer(idType: 'kp' | 'tmdb', id: string | number, season?: number, episode?: number) {
    if (idType !== 'kp') throw new Error('Only kp idType is supported by current API')
    return apiClient.get(`/api/v1/players/alloha/kp/${id}`, {
      params: { season, episode },
      timeout: 30000,
    })
  },

  // Lumex плеер
  getLumexPlayer(idType: 'kp' | 'tmdb', id: string | number, season?: number, episode?: number) {
    if (idType !== 'kp') throw new Error('Only kp idType is supported by current API')
    return apiClient.get(`/api/v1/players/lumex/kp/${id}`, {
      params: { season, episode },
      timeout: 30000,
    })
  },

  // HDVB плеер
  getHDVBPlayer(idType: 'kp' | 'tmdb', id: string | number, season?: number, episode?: number) {
    if (idType !== 'kp') throw new Error('Only kp idType is supported by current API')
    return apiClient.get(`/api/v1/players/hdvb/kp/${id}`, {
      params: { season, episode },
      timeout: 30000,
    })
  },

  // Торренты по KP ID
  getTorrents(kpId: string | number, season?: number, episode?: number) {
    return apiClient.get('/api/v1/torrents/search', {
      params: { kp_id: kpId, season, episode },
      timeout: 30000,
    })
  },

  // Collaps плеер
  getCollapsPlayer(idType: 'kp' | 'tmdb', id: string | number, season?: number, episode?: number) {
    if (idType !== 'kp') throw new Error('Only kp idType is supported by current API')
    return apiClient.get(`/api/v1/players/collaps/kp/${id}`, {
      params: { season, episode },
      timeout: 30000,
    })
  },

  // CDN плеер (Плеер 1) — наш собственный HLS плеер
  getCdnPlayer(kpId: string | number, season?: number, episode?: number) {
    return apiClient.get(`/api/v1/players/cdn/kp/${kpId}`, {
      params: { season, episode },
      timeout: 30000,
    })
  },
}
