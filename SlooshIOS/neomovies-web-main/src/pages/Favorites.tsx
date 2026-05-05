import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Box,
  Container,
  Typography,
  Button,
  Alert,
  CircularProgress,
} from '@mui/material'
import { MovieCard } from '../components/MovieCard'
import { useFavoritesContext } from '../contexts/FavoritesContext'
import type { Movie } from '../types'

export const Favorites = () => {
  const navigate = useNavigate()
  const [isLoggedIn, setIsLoggedIn] = useState(false)
  const { favorites, isLoading, error, removeFromFavorites, refetch } = useFavoritesContext()

  useEffect(() => {
    const token = localStorage.getItem('token')
    setIsLoggedIn(!!token)
  }, [])

  // Listen for auth changes
  useEffect(() => {
    const handleAuthChange = () => {
      const token = localStorage.getItem('token')
      setIsLoggedIn(!!token)
    }

    window.addEventListener('auth-changed', handleAuthChange)
    return () => window.removeEventListener('auth-changed', handleAuthChange)
  }, [])

  useEffect(() => {
    if (isLoggedIn) {
      void refetch()
    }
  }, [isLoggedIn, refetch])

  const handleMovieClick = (movie: Movie) => {
    const id = movie.kinopoisk_id ? `kp_${movie.kinopoisk_id}` : movie.id
    navigate(`/${id}`)
  }

  const handleRemoveFavorite = async (mediaId: string) => {
    try {
      await removeFromFavorites(mediaId, 'movie')
    } catch (error) {
      console.error('Error removing favorite:', error)
      alert('Ошибка при удалении из избранного')
    }
  }

  if (!isLoggedIn) {
    return (
      <Container maxWidth="lg">
        <Box sx={{ py: 8, textAlign: 'center' }}>
          <Alert severity="warning" sx={{ mb: 3 }}>
            <Typography variant="h6" sx={{ mb: 2 }}>
              Требуется авторизация
            </Typography>
            <Typography sx={{ mb: 3 }}>
              Пожалуйста, авторизуйтесь, чтобы просмотреть ваши избранные фильмы
            </Typography>
            <Button
              variant="contained"
              onClick={() => navigate('/auth')}
              sx={{
                backgroundColor: '#1976d2',
                '&:hover': { backgroundColor: '#1565c0' },
              }}
            >
              Перейти к авторизации
            </Button>
          </Alert>
        </Box>
      </Container>
    )
  }

  if (isLoading) {
    return (
      <Container maxWidth="lg">
        <Box sx={{ py: 8, display: 'flex', justifyContent: 'center' }}>
          <CircularProgress />
        </Box>
      </Container>
    )
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom sx={{ mb: 4 }}>
          Избранное ({favorites.length})
        </Typography>

        {error && (
          <Alert severity="error" sx={{ mb: 3 }}>
            <Typography>{error.message}</Typography>
          </Alert>
        )}
      </Box>

      {favorites.length === 0 ? (
        <Box>
          <Alert severity="info">
            <Typography>
              У вас пока нет избранных фильмов. Добавьте фильмы в избранное, нажав на иконку сердца на странице фильма.
            </Typography>
          </Alert>
        </Box>
      ) : (
        <Box
          sx={{
            display: 'grid',
            gridTemplateColumns: {
              xs: '1fr',
              sm: 'repeat(2, 1fr)',
              md: 'repeat(3, 1fr)',
              lg: 'repeat(4, 1fr)',
            },
            gap: { xs: 2, sm: 2.5 },
            alignItems: 'stretch',
            justifyItems: 'stretch',
            overflow: 'visible',
          }}
        >
            {favorites.map((favorite) => {
              const rawId = String(favorite.mediaId || '')
              const kpNumericId = Number(rawId.replace(/^kp_/, ''))

              // Преобразуем FavoriteItem в Movie для совместимости с MovieCard
              const movie: Movie = {
                id: rawId || favorite.id,
                kinopoisk_id: Number.isFinite(kpNumericId) ? kpNumericId : undefined,
                title: favorite.title,
                name: favorite.title,
                nameRu: favorite.nameRu,
                nameEn: favorite.nameEn,
                poster_path: favorite.posterPath || favorite.posterUrl,
                posterUrl: favorite.posterUrl || favorite.posterPath,
                posterUrlPreview: favorite.posterUrl || favorite.posterPath,
                release_date: `${favorite.year}-01-01`,
                first_air_date: `${favorite.year}-01-01`,
                vote_average: favorite.rating,
                ratingKinopoisk: favorite.rating,
              } as Movie

              return (
                <Box
                  key={favorite.id}
                  sx={{
                    position: 'relative',
                    width: '100%',
                    maxWidth: '100%',
                    minWidth: 0,
                    overflow: 'visible',
                    zIndex: 0,
                    '&:hover': { zIndex: 2 },
                  }}
                >
                  <MovieCard movie={movie} onClick={handleMovieClick} hideFavoriteButton={true} />
                  <Button
                    size="small"
                    variant="contained"
                    color="error"
                    onClick={() => handleRemoveFavorite(favorite.mediaId)}
                    sx={{
                      position: 'absolute',
                      top: 8,
                      right: 8,
                      zIndex: 10,
                      minWidth: 0,
                      whiteSpace: 'nowrap',
                      px: 1,
                      py: 0.5,
                    }}
                  >
                    Удалить
                  </Button>
                </Box>
              )
            })}
        </Box>
      )}
    </Container>
  )
}
