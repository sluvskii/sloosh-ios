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
import { tvAPI } from '../api'
import { MovieCard } from '../components/MovieCard'
import type { Movie } from '../types'

export const TV = () => {
  const [shows, setShows] = useState<Movie[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [sortBy, setSortBy] = useState<'popular' | 'top-rated' | 'on-the-air'>('popular')
  const navigate = useNavigate()

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true)
        let res
        if (sortBy === 'popular') {
          res = await tvAPI.getPopular(page)
        } else if (sortBy === 'top-rated') {
          res = await tvAPI.getTopRated(page)
        } else {
          res = await tvAPI.getOnTheAir(page)
        }
        setShows(res.data.results || [])
        setTotalPages(res.data.total_pages || 1)
      } catch (error) {
        console.error('Error fetching TV shows:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [page, sortBy])

  const handleShowClick = (show: Movie) => {
    const id = show.kinopoisk_id ? `kp_${show.kinopoisk_id}` : show.id
    navigate(`/${id}`)
  }

  const handleSortChange = (newSort: 'popular' | 'top-rated' | 'on-the-air') => {
    setSortBy(newSort)
    setPage(1)
  }

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom sx={{ mb: 3 }}>
          Сериалы
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
          <Button
            variant={sortBy === 'on-the-air' ? 'contained' : 'outlined'}
            onClick={() => handleSortChange('on-the-air')}
          >
            В эфире
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
            {shows.map((show) => (
              <MovieCard key={show.id} movie={show} onClick={handleShowClick} />
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
