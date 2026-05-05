export interface Genre {
  id: number
  name: string
}

export interface Movie {
  id: number | string
  title?: string
  name?: string
  original_title?: string
  original_name?: string
  originalTitle?: string
  overview?: string
  description?: string
  poster_path?: string | null
  backdrop_path?: string | null
  posterUrl?: string
  backdropUrl?: string
  release_date?: string
  releaseDate?: string
  first_air_date?: string
  endDate?: string
  vote_average?: number
  rating?: number
  vote_count?: number
  genre_ids?: number[]
  runtime?: number
  duration?: number
  genres?: Genre[]
  popularity?: number
  media_type?: string
  type?: string
  adult?: boolean
  original_language?: string
  origin_country?: string[]
  imdb_id?: string
  imdbId?: string
  kinopoisk_id?: number
  nameRu?: string
  nameEn?: string
  nameOriginal?: string
  posterUrlPreview?: string
  coverUrl?: string
  ratingKinopoisk?: number
  ratingImdb?: number
  shortDescription?: string
  filmLength?: number
  filmId?: number | string
  year?: string | number
  countries?: Array<{ country: string }>
  country?: string
  director?: string
  cast?: any[]
  budget?: number | null
  revenue?: number | null
  externalIds?: {
    kp?: number
    tmdb?: number | null
    imdb?: string
  }
  sourceId?: string
}

export interface MovieResponse {
  page: number
  results: Movie[]
  total_pages: number
  total_results: number
}

export interface TVShow extends Movie {
  name: string
  first_air_date: string
  last_air_date?: string
  number_of_seasons?: number
  number_of_episodes?: number
  episode_run_time?: number[]
  in_production?: boolean
  languages?: string[]
  networks?: Array<{
    id: number
    name: string
    logo_path: string | null
    origin_country: string
  }>
  production_companies?: Array<{
    id: number
    name: string
    logo_path: string | null
    origin_country: string
  }>
  status?: string
  serial?: boolean
  startYear?: number
  endYear?: number
  completed?: boolean
}

export interface TVResponse {
  page: number
  results: TVShow[]
  total_pages: number
  total_results: number
}

export interface TorrentResult {
  title: string
  tracker: string
  size: string
  seeders: number
  peers: number
  leechers: number
  quality: string
  voice?: string[]
  types?: string[]
  seasons?: number[]
  category: string
  magnet: string
  torrent_link?: string
  details?: string
  publish_date: string
  added_date?: string
  source: string
}

export interface TorrentSearchResponse {
  query: string
  results: TorrentResult[]
  total: number
}
