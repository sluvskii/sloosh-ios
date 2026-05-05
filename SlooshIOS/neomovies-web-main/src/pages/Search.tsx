import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import {
  Typography,
  Box,
  CircularProgress,
  Pagination,
} from '@mui/material'
import { moviesAPI } from '../api'
import { MovieCard } from '../components/MovieCard'
import { filterValidMovies } from '../utils/filterMovies'
import type { Movie } from '../types'

export const Search = () => {
  const [searchParams] = useSearchParams()
  const [results, setResults] = useState<Movie[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const navigate = useNavigate()
  const query = searchParams.get('q') || ''

  useEffect(() => {
    const fetchData = async () => {
      if (!query.trim()) {
        setResults([])
        setLoading(false)
        return
      }

      try {
        setLoading(true)
        const res = await moviesAPI.searchMovies(query, page)
        setResults(filterValidMovies(res.data.results || []))
        setTotalPages(res.data.total_pages || 1)
      } catch (error) {
        console.error('Error searching:', error)
      } finally {
        setLoading(false)
      }
    }

    setPage(1)
    fetchData()
  }, [query])

  useEffect(() => {
    if (!query.trim()) return

    const fetchData = async () => {
      try {
        setLoading(true)
        const res = await moviesAPI.searchMovies(query, page)
        setResults(filterValidMovies(res.data.results || []))
        setTotalPages(res.data.total_pages || 1)
      } catch (error) {
        console.error('Error searching:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [page, query])

  const handleResultClick = (item: Movie) => {
    const id = item.kinopoisk_id ? `kp_${item.kinopoisk_id}` : item.id
    navigate(`/${id}`)
  }

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom sx={{ mb: 3 }}>
          Результаты поиска: "{query}"
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Найдено результатов: {results.length}
        </Typography>
      </Box>

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
          <CircularProgress />
        </Box>
      ) : results.length === 0 ? (
        <Box sx={{ textAlign: 'center', py: 8 }}>
          <Typography variant="body1" color="text.secondary">
            По вашему запросу ничего не найдено
          </Typography>
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
            {results.map((item) => (
              <MovieCard key={item.id} movie={item} onClick={handleResultClick} />
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
