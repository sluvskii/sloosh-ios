import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Typography,
  Box,
  CircularProgress,
  Pagination,
  useMediaQuery,
  useTheme,
} from '@mui/material'
import { moviesAPI } from '../api'
import { MovieCard } from '../components/MovieCard'
import { filterValidMovies } from '../utils/filterMovies'
import type { Movie } from '../types'

export const Home = () => {
  const theme = useTheme()
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'))
  const [items, setItems] = useState<Movie[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const navigate = useNavigate()

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true)
        const res = await moviesAPI.getPopular(page)
        setItems(filterValidMovies(res.data.results || []))
        setTotalPages(res.data.total_pages || 1)
      } catch (error) {
        console.error('Error fetching data:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [page])

  const handleMovieClick = (movie: Movie) => {
    const id = movie.kinopoisk_id ? `kp_${movie.kinopoisk_id}` : movie.id
    navigate(`/${id}`)
  }

  return (
    <Box>
      <Box sx={{ mb: { xs: 2, sm: 4 } }}>
        <Typography variant="h4" component="h1" gutterBottom sx={{ mb: 2, fontSize: { xs: '1.5rem', sm: '2rem' } }}>
          Популярное
        </Typography>
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
            {items.map((item) => (
              <MovieCard key={item.id} movie={item} onClick={handleMovieClick} />
            ))}
          </Box>

          <Box sx={{ display: 'flex', justifyContent: 'center' }}>
            <Pagination
              count={Math.min(totalPages, 500)}
              page={page}
              onChange={(_, value) => setPage(value)}
              color="primary"
              size={isMobile ? 'small' : 'medium'}
              siblingCount={isMobile ? 0 : 1}
              boundaryCount={isMobile ? 1 : 2}
              sx={{ '& .MuiPagination-ul': { flexWrap: 'nowrap' } }}
            />
          </Box>
        </>
      )}
    </Box>
  )
}
