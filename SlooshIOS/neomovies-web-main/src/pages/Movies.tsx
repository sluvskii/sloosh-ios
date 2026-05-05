import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Typography,
  Box,
  CircularProgress,
  Button,
  Stack,
  Pagination,
} from '@mui/material'
import { moviesAPI } from '../api'
import { MovieCard } from '../components/MovieCard'
import type { Movie } from '../types'

export const Movies = () => {
  const [movies, setMovies] = useState<Movie[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [sortBy, setSortBy] = useState<'popular' | 'top-rated'>('popular')
  const navigate = useNavigate()

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true)
        const res =
          sortBy === 'popular'
            ? await moviesAPI.getPopular(page)
            : await moviesAPI.getTopRated(page)
        setMovies(res.data.results || [])
        setTotalPages(res.data.total_pages || 1)
      } catch (error) {
        console.error('Error fetching movies:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [page, sortBy])

  const handleMovieClick = (movie: Movie) => {
    const id = movie.kinopoisk_id ? `kp_${movie.kinopoisk_id}` : movie.id
    navigate(`/${id}`)
  }

  const handleSortChange = (newSort: 'popular' | 'top-rated') => {
    setSortBy(newSort)
    setPage(1)
  }

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom sx={{ mb: 3 }}>
          Фильмы
        </Typography>
        <Stack direction="row" spacing={2} sx={{ mb: 3 }}>
          <Button
            variant={sortBy === 'popular' ? 'contained' : 'outlined'}
            onClick={() => handleSortChange('popular')}
          >
            Популярные
          </Button>
          <Button
            variant={sortBy === 'top-rated' ? 'contained' : 'outlined'}
            onClick={() => handleSortChange('top-rated')}
          >
            Лучшие
          </Button>
        </Stack>
      </Box>

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
          <CircularProgress />
        </Box>
      ) : (
        <>
          <Box
            sx={{
              display: 'grid',
              gridTemplateColumns: {
                xs: '1fr',
                sm: 'repeat(2, 1fr)',
                md: 'repeat(3, 1fr)',
                lg: 'repeat(4, 1fr)',
              },
              gap: 2,
              mb: 4,
            }}
          >
            {movies.map((movie) => (
              <MovieCard key={movie.id} movie={movie} onClick={handleMovieClick} />
            ))}
          </Box>

          <Box sx={{ display: 'flex', justifyContent: 'center' }}>
            <Pagination
              count={Math.min(totalPages, 500)}
              page={page}
              onChange={(_, value) => setPage(value)}
              color="primary"
            />
          </Box>
        </>
      )}
    </Box>
  )
}
