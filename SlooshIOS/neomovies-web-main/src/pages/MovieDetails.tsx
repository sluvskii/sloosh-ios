import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import {
  Typography,
  Box,
  CircularProgress,
  Button,
  Stack,
  Rating,
  Chip,
  IconButton,
} from '@mui/material'
import PlayArrowIcon from '@mui/icons-material/PlayArrow'
import FavoriteBorderIcon from '@mui/icons-material/FavoriteBorder'
import FavoriteIcon from '@mui/icons-material/Favorite'
import { moviesAPI, getImageUrl, playersAPI, favoritesAPI } from '../api'
import { TorrentSelector } from '../components/TorrentSelector'
import type { Movie } from '../types'

export const MovieDetails = () => {
  const { id } = useParams<{ id: string }>()
  const [movie, setMovie] = useState<Movie | null>(null)
  const [loading, setLoading] = useState(true)
  const [selectedPlayer, setSelectedPlayer] = useState<'cdn' | 'alloha' | 'lumex' | 'collaps'>('cdn')
  const [playerUrl, setPlayerUrl] = useState<string | null>(null)
  const [playerHtml, setPlayerHtml] = useState<string | null>(null)
  const [cdnAvailable, setCdnAvailable] = useState<boolean>(true)
  const [isFavorite, setIsFavorite] = useState(false)
  const [isLoggedIn, setIsLoggedIn] = useState(false)

  useEffect(() => {
    const token = localStorage.getItem('token')
    setIsLoggedIn(!!token)
  }, [])

  useEffect(() => {
    if (!movie) return

    const checkFavorite = () => {
      const favorite = favoritesAPI.checkIsFavorite(movie.id, 'movie')
      setIsFavorite(favorite)
    }

    checkFavorite()

    const unsubscribe = favoritesAPI.subscribe(() => {
      checkFavorite()
    })

    return () => unsubscribe()
  }, [movie])

  useEffect(() => {
    const fetchData = async () => {
      if (!id) return

      try {
        setLoading(true)
        const movieId = id.startsWith('kp_') ? id : `kp_${id}`
        const res = await moviesAPI.getMovieById(movieId)
        setMovie(res.data)
        
        // Автозагрузка CDN плеера по умолчанию
        setTimeout(() => {
          loadPlayer(res.data, 'cdn')
        }, 500)
      } catch (error) {
        // silent fail
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [id])

  const loadPlayer = async (movieData: any, player: 'cdn' | 'alloha' | 'lumex' | 'collaps') => {
    try {
      const kpId = movieData.externalIds?.kp || movieData.kinopoisk_id || movieData.filmId
      if (!kpId) return

      // CDN плеер — проверяем доступность, потом ставим src
      if (player === 'cdn') {
        const apiBase = import.meta.env.VITE_API_URL || ''
        const cdnUrl = `${apiBase}/api/v1/players/cdn/kp/${kpId}`
        try {
          const check = await fetch(cdnUrl)
          const ct = check.headers.get('content-type') || ''
          if (!check.ok || ct.includes('application/json')) {
            // CDN недоступен — скрываем кнопку и переключаемся на Alloha
            setCdnAvailable(false)
            setSelectedPlayer('alloha')
            loadPlayer(movieData, 'alloha')
            return
          }
        } catch {
          setCdnAvailable(false)
          setSelectedPlayer('alloha')
          loadPlayer(movieData, 'alloha')
          return
        }
        setPlayerUrl(cdnUrl)
        setPlayerHtml(null)
        return
      }

      let response = ''
      if (player === 'alloha') {
        const res = await playersAPI.getAllohaPlayer('kp', kpId)
        response = res.data
      } else if (player === 'lumex') {
        const res = await playersAPI.getLumexPlayer('kp', kpId)
        response = res.data
      } else if (player === 'collaps') {
        const res = await playersAPI.getCollapsPlayer('kp', kpId)
        response = res.data
      }

      if (response.startsWith('<')) {
        const srcMatch = response.match(/src="([^"]+)"/i)
        if (srcMatch && srcMatch[1]) {
          setPlayerUrl(srcMatch[1])
          setPlayerHtml(null)
        } else {
          const dataSrcMatch = response.match(/data-src="([^"]+)"/i)
          if (dataSrcMatch && dataSrcMatch[1]) {
            setPlayerUrl(dataSrcMatch[1])
            setPlayerHtml(null)
          } else {
            setPlayerHtml(response)
            setPlayerUrl(null)
          }
        }
      } else if (response && response.trim()) {
        setPlayerUrl(response)
        setPlayerHtml(null)
      }
    } catch (error) {
      // silent fail
    }
  }

  const handlePlayerChange = (player: 'cdn' | 'alloha' | 'lumex' | 'collaps') => {
    if (!movie) return
    setSelectedPlayer(player)
    loadPlayer(movie, player)
  }

  const handleFavoriteClick = async () => {
    if (!isLoggedIn) {
      alert('Пожалуйста, авторизуйтесь, чтобы добавить фильм в избранное')
      return
    }
    if (!movie) return

    try {
      const movieId = extractKpId(movie.externalIds?.kp || movie.kinopoisk_id || movie.id)
      if (!movieId) return
      if (isFavorite) {
        await favoritesAPI.removeFromFavorites(movieId, 'movie')
      } else {
        const title = movie.title || movie.nameRu || movie.nameOriginal || movie.name || 'Unknown'
        const posterPath = movie.poster_path || movie.posterUrlPreview || movie.posterUrl
        const year = movie.release_date ? new Date(movie.release_date).getFullYear() : movie.year || 0
        await favoritesAPI.addToFavorites(movieId, 'movie', {
          title,
          nameRu: title,
          nameEn: (movie as any).original_title || (movie as any).originalTitle || '',
          posterPath,
          year: typeof year === 'number' ? year : 0,
        })
      }
    } catch (error) {
      alert('Ошибка при обновлении избранного')
    }
  }

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
        <CircularProgress />
      </Box>
    )
  }

  if (!movie) {
    return (
      <Box sx={{ textAlign: 'center', py: 8 }}>
        <Typography variant="h6">Фильм не найден</Typography>
      </Box>
    )
  }

  const title = movie.title || movie.nameRu || movie.nameOriginal || 'Unknown'
  const rating = (movie as any).rating || movie.vote_average || movie.ratingKinopoisk || 0
  const posterPath = movie.poster_path || movie.posterUrlPreview || movie.posterUrl
  const year = movie.release_date ? new Date(movie.release_date).getFullYear() : movie.year

  return (
    <Box>
      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: { xs: '1fr', sm: '1fr 2fr', md: '1fr 3fr' },
          gap: { xs: 2, sm: 4 },
        }}
      >
        <Box>
          <Box
            component="img"
            src={getImageUrl(posterPath)}
            alt={title}
            sx={{
              width: '100%',
              aspectRatio: '2/3',
              objectFit: 'cover',
              borderRadius: '10px',
            }}
          />
        </Box>

        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
            <Typography variant="h4" component="h1">
              {title}
            </Typography>
            <IconButton
              onClick={handleFavoriteClick}
              sx={{
                color: isFavorite ? '#ff0000' : '#999',
                '&:hover': { color: '#ff0000' },
              }}
            >
              {isFavorite ? <FavoriteIcon /> : <FavoriteBorderIcon />}
            </IconButton>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
            <Rating value={rating / 2} readOnly />
            <Typography variant="body1">{rating.toFixed(1)}</Typography>
            {year && (
              <Typography variant="body2" color="text.secondary">
                {year}
              </Typography>
            )}
          </Box>

          {movie.genres && movie.genres.length > 0 && (
            <Box sx={{ mb: 2 }}>
              <Stack direction="row" spacing={1} sx={{ flexWrap: 'wrap' }}>
                {movie.genres.map((genre) => (
                  <Chip key={genre.id} label={genre.name} variant="outlined" size="small" />
                ))}
              </Stack>
            </Box>
          )}

          <Typography variant="body1" paragraph>
            {movie.overview || movie.description || 'Описание недоступно'}
          </Typography>

          {/* Кнопки плееров: Alloha -> Collaps -> Lumex */}
          <Box sx={{ mt: 4 }}>
            <Typography variant="h6" gutterBottom>
              Смотреть онлайн
            </Typography>
            <Stack direction={{ xs: 'column', sm: 'row' }} sx={{ mb: 3, gap: 2, alignItems: { xs: 'stretch', sm: 'center' } }}>
              <Stack direction="row" sx={{ gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
                {cdnAvailable && (
                  <Button
                    variant={selectedPlayer === 'cdn' ? 'contained' : 'outlined'}
                    startIcon={<PlayArrowIcon />}
                    onClick={() => handlePlayerChange('cdn')}
                    size="small"
                  >
                    Плеер 1
                  </Button>
                )}
                <Button
                  variant={selectedPlayer === 'alloha' ? 'contained' : 'outlined'}
                  startIcon={<PlayArrowIcon />}
                  onClick={() => handlePlayerChange('alloha')}
                  size="small"
                >
                  Alloha
                </Button>
                <Button
                  variant={selectedPlayer === 'collaps' ? 'contained' : 'outlined'}
                  startIcon={<PlayArrowIcon />}
                  onClick={() => handlePlayerChange('collaps')}
                  size="small"
                >
                  Collaps
                </Button>
                <Button
                  variant={selectedPlayer === 'lumex' ? 'contained' : 'outlined'}
                  startIcon={<PlayArrowIcon />}
                  onClick={() => handlePlayerChange('lumex')}
                  size="small"
                >
                  Lumex
                </Button>
              </Stack>
              <Box sx={{ display: { xs: 'block', sm: 'inline' } }}>
                <TorrentSelector
                  kpId={movie.externalIds?.kp || movie.kinopoisk_id || movie.id}
                  type={movie.type === 'tv' || movie.media_type === 'tv' ? 'tv' : 'movie'}
                  title={title}
                />
              </Box>
            </Stack>

            {playerUrl && !playerUrl.includes('blob:') && (
              <Box sx={{ borderRadius: '10px', backgroundColor: '#000' }}>
                <Box
                  component="iframe"
                  src={playerUrl}
                  allowFullScreen
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                  sx={{
                    width: '100%',
                    height: { xs: 320, sm: 420, md: 560 },
                    border: 'none',
                    display: 'block',
                    borderRadius: '10px',
                  }}
                />
              </Box>
            )}
            {playerHtml && (
              <Box sx={{ borderRadius: '10px', backgroundColor: '#000' }}>
                <iframe
                  srcDoc={playerHtml}
                  allowFullScreen
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                  style={{
                    width: '100%',
                    height: window.innerWidth < 600 ? 320 : window.innerWidth < 960 ? 420 : 560,
                    border: 'none',
                    backgroundColor: '#000',
                    display: 'block',
                    borderRadius: '10px',
                  }}
                />
              </Box>
            )}
          </Box>
        </Box>
      </Box>
    </Box>
  )
}
  const extractKpId = (value: unknown): string => {
    if (typeof value === 'number') return String(value)
    if (typeof value === 'string') return value.replace(/^kp_/, '')
    return ''
  }
