import { useState, useEffect } from 'react'
import { Card, CardMedia, Typography, Box, Rating, Skeleton, IconButton, useTheme } from '@mui/material'
import FavoriteBorderIcon from '@mui/icons-material/FavoriteBorder'
import FavoriteIcon from '@mui/icons-material/Favorite'
import { getImageUrl, favoritesAPI } from '../api'
import type { Movie } from '../types'

interface MovieCardProps {
  movie: Movie
  onClick?: (movie: Movie) => void
  hideFavoriteButton?: boolean
}

export const MovieCard = ({ movie, onClick, hideFavoriteButton = false }: MovieCardProps) => {
  const theme = useTheme()
  const dark = theme.palette.mode === 'dark'
  const [imageLoaded, setImageLoaded] = useState(false)
  const [isFavorite, setIsFavorite] = useState(false)
  const [isLoggedIn, setIsLoggedIn] = useState(false)
  const [isUpdating, setIsUpdating] = useState(false)
  const title = movie.title || movie.name || movie.nameRu || movie.nameOriginal || 'Unknown'
  const rating = (movie as any).rating || movie.vote_average || movie.ratingKinopoisk || 0
  const posterPath = movie.poster_path || movie.posterUrlPreview || movie.posterUrl
  const getKpId = (): string => {
    const src = movie.kinopoisk_id || movie.id
    if (typeof src === 'number') return String(src)
    if (typeof src === 'string') return src.replace(/^kp_/, '')
    return ''
  }

  useEffect(() => {
    const token = localStorage.getItem('token')
    setIsLoggedIn(!!token)
  }, [])

  // Проверяем статус избранного из кеша
  useEffect(() => {
    const checkFavorite = () => {
      const favorite = favoritesAPI.checkIsFavorite(movie.id, 'movie')
      setIsFavorite(favorite)
    }

    checkFavorite()

    // Подписываемся на изменения кеша
    const unsubscribe = favoritesAPI.subscribe(() => {
      checkFavorite()
    })

    return () => unsubscribe()
  }, [movie.id])

  const handleFavoriteClick = async (e: React.MouseEvent) => {
    e.stopPropagation()

    if (!isLoggedIn) {
      return
    }

    try {
      setIsUpdating(true)
    const movieIdNum = getKpId()
    if (!movieIdNum) return
    if (isFavorite) {
      await favoritesAPI.removeFromFavorites(movieIdNum, 'movie')
    } else {
      await favoritesAPI.addToFavorites(movieIdNum, 'movie', {
        title,
        nameRu: title,
        nameEn: movie.original_title || '',
        posterPath,
        year: movie.release_date ? new Date(movie.release_date).getFullYear() : 0,
        })
      }
      // Состояние обновится через подписку на кеш
    } catch (error) {
      console.error('Error updating favorite:', error)
      alert('Ошибка при обновлении избранного')
    } finally {
      setIsUpdating(false)
    }
  }

  return (
    <Card
      onClick={() => onClick?.(movie)}
      sx={{
        cursor: 'pointer',
        width: '100%',
        maxWidth: '100%',
        minWidth: 0,
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        transition: 'transform 0.2s, box-shadow 0.2s, border-color 0.2s',
        position: 'relative',
        zIndex: 0,
        overflow: 'hidden',
        borderRadius: 2.5,
        border: `1px solid ${dark ? '#2a2d33' : '#d9dde5'}`,
        backgroundColor: dark ? '#14161a' : '#ffffff',
        boxShadow: dark ? '0 10px 24px rgba(0,0,0,0.32)' : '0 8px 18px rgba(15,23,42,0.08)',
        '&:hover': {
          transform: 'translateY(-6px)',
          boxShadow: dark ? '0 14px 30px rgba(0,0,0,0.42)' : '0 12px 28px rgba(15,23,42,0.14)',
          borderColor: dark ? '#3c414a' : '#c9cfdb',
          zIndex: 1,
        },
      }}
    >
      <Box sx={{ position: 'relative', height: 410, width: '100%', overflow: 'hidden', backgroundColor: dark ? '#1b1e24' : '#eef0f5' }}>
        {!imageLoaded && (
          <Skeleton
            variant="rectangular"
            width="100%"
            height="100%"
            sx={{ position: 'absolute', top: 0, left: 0 }}
          />
        )}
        <CardMedia
          component="img"
          height="410"
          image={getImageUrl(posterPath)}
          alt={title}
          loading="lazy"
          onLoad={() => setImageLoaded(true)}
          onError={() => setImageLoaded(true)}
          sx={{
            display: 'block',
            width: '100%',
            objectFit: 'cover',
            opacity: imageLoaded ? 1 : 0,
            transition: 'opacity 0.3s ease-in-out',
          }}
        />

        <Box
          sx={{
            position: 'absolute',
            left: 0,
            right: 0,
            bottom: 0,
            p: 1.4,
            background: 'linear-gradient(180deg, rgba(5,8,14,0.0) 0%, rgba(5,8,14,0.72) 50%, rgba(5,8,14,0.92) 100%)',
          }}
        >
          <Typography
            sx={{
              fontWeight: 700,
              fontSize: '1.05rem',
              lineHeight: 1.2,
              color: '#f8fafc',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              display: '-webkit-box',
              WebkitLineClamp: 2,
              WebkitBoxOrient: 'vertical',
              minHeight: '2.4em',
              mb: 0.7,
            }}
          >
            {title}
          </Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Rating value={rating / 2} readOnly size="small" />
            <Typography variant="body2" sx={{ color: '#e5e7eb', fontWeight: 600 }}>
              {rating.toFixed(1)}
            </Typography>
            {(movie.release_date || movie.first_air_date) && (
              <Typography variant="caption" sx={{ color: '#9ca3af', ml: 0.4 }}>
                {new Date(movie.release_date || movie.first_air_date || '').getFullYear()}
              </Typography>
            )}
          </Box>
        </Box>

        {!hideFavoriteButton && (
          <IconButton
            onClick={handleFavoriteClick}
            disabled={isUpdating}
            sx={{
              position: 'absolute',
              top: 8,
              right: 8,
              backgroundColor: dark ? 'rgba(11,12,15,0.62)' : 'rgba(255,255,255,0.74)',
              color: isFavorite ? '#ef4444' : dark ? '#f3f4f6' : '#111827',
              border: `1px solid ${dark ? 'rgba(255,255,255,0.15)' : 'rgba(17,24,39,0.12)'}`,
              backdropFilter: 'blur(4px)',
              '&:hover': {
                backgroundColor: dark ? 'rgba(11,12,15,0.78)' : 'rgba(255,255,255,0.9)',
              },
              '&:disabled': {
                opacity: 0.6,
              },
            }}
          >
            {isFavorite ? <FavoriteIcon /> : <FavoriteBorderIcon />}
          </IconButton>
        )}
      </Box>
    </Card>
  )
}
