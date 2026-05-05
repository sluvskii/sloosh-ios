import { useState, useEffect, useRef, type UIEvent } from 'react'
import {
  AppBar,
  Toolbar,
  Box,
  Container,
  TextField,
  InputAdornment,
  Button,
  Stack,
  Menu,
  MenuItem,
  Divider,
  Paper,
  CircularProgress,
  IconButton,
  Alert,
  useMediaQuery,
  useTheme,
} from '@mui/material'
import SearchIcon from '@mui/icons-material/Search'
import PersonIcon from '@mui/icons-material/Person'
import CloseIcon from '@mui/icons-material/Close'
import LightModeOutlinedIcon from '@mui/icons-material/LightModeOutlined'
import DarkModeOutlinedIcon from '@mui/icons-material/DarkModeOutlined'
import { useLocation, useNavigate } from 'react-router-dom'
import { getImageUrl, moviesAPI } from '../api'
import { apiClient } from '../api/client'
import { clearAuthState } from '../api/client'
import { filterValidMovies } from '../utils/filterMovies'
import { useThemeMode } from '../contexts/ThemeModeContext'
import type { Movie } from '../types'

interface LayoutProps {
  children: React.ReactNode
}

export const Layout = ({ children }: LayoutProps) => {
  const theme = useTheme()
  const dark = theme.palette.mode === 'dark'
  const { toggleMode } = useThemeMode()

  const colors = {
    header: dark ? '#111216' : '#ffffff',
    bg: dark ? '#0b0b0d' : '#f4f5f7',
    surface: dark ? '#17181c' : '#ffffff',
    border: dark ? '#26282d' : '#e5e7eb',
    text: dark ? '#f5f6f7' : '#111827',
    muted: dark ? '#9ca3af' : '#6b7280',
    hover: dark ? '#21232a' : '#f3f4f6',
  }

  const [searchQuery, setSearchQuery] = useState('')
  const [userName, setUserName] = useState<string | null>(null)
  const [userEmail, setUserEmail] = useState<string | null>(null)
  const [userAvatar, setUserAvatar] = useState<string | null>(null)
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)
  const [searchResults, setSearchResults] = useState<Movie[]>([])
  const [searchLoading, setSearchLoading] = useState(false)
  const [searchLoadingMore, setSearchLoadingMore] = useState(false)
  const [showSearchResults, setShowSearchResults] = useState(false)
  const [searchPage, setSearchPage] = useState(1)
  const [searchTotalPages, setSearchTotalPages] = useState(1)
  const searchRequestIdRef = useRef(0)
  const searchCommittedRef = useRef(false)
  const searchBoxRef = useRef<HTMLFormElement | null>(null)
  const navigate = useNavigate()
  const location = useLocation()

  const navItems = [
    { label: 'Популярное', path: '/' },
    { label: 'Топ Фильмов', path: '/movies-top' },
    { label: 'Топ Сериалов', path: '/tv-top' },
    { label: 'Избранное', path: '/favorites' },
  ]

  const handleNavClick = (path: string) => {
    if (path === '/favorites') {
      const token = localStorage.getItem('token')
      if (!token) {
        navigate('/auth')
        return
      }
    }
    navigate(path)
  }

  const isMobile = useMediaQuery('(max-width:600px)')
  const [mobileAppBannerDismissed, setMobileAppBannerDismissed] = useState(true)

  useEffect(() => {
    try {
      const dismissed = localStorage.getItem('mobile_app_banner_dismissed')
      setMobileAppBannerDismissed(dismissed === '1')
    } catch {
      setMobileAppBannerDismissed(false)
    }
  }, [])

  useEffect(() => {
    const onPointerDown = (event: MouseEvent) => {
      if (!showSearchResults) return
      const target = event.target as Node | null
      if (searchBoxRef.current && target && !searchBoxRef.current.contains(target)) {
        setShowSearchResults(false)
      }
    }

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setShowSearchResults(false)
      }
    }

    document.addEventListener('mousedown', onPointerDown)
    document.addEventListener('keydown', onKeyDown)
    return () => {
      document.removeEventListener('mousedown', onPointerDown)
      document.removeEventListener('keydown', onKeyDown)
    }
  }, [showSearchResults])

  useEffect(() => {
    // Check if user is logged in
    const token = localStorage.getItem('token')
    const email = localStorage.getItem('userEmail')
    const name = localStorage.getItem('userName')
    const avatar = localStorage.getItem('userAvatar')

    if (token && email) {
      setUserEmail(email)
      setUserName(name || email.split('@')[0])
      setUserAvatar(avatar || '')
    } else if (token) {
      void apiClient.get('/api/v1/auth/profile')
        .then((resp: any) => {
          const user = resp.data
          if (user?.email) {
            localStorage.setItem('userEmail', user.email)
            setUserEmail(user.email)
          }
          if (user?.name) {
            localStorage.setItem('userName', user.name)
            setUserName(user.name)
          } else if (user?.email) {
            setUserName(user.email.split('@')[0])
          }
          if (user?.avatar) {
            localStorage.setItem('userAvatar', user.avatar)
            setUserAvatar(user.avatar)
          }
        })
        .catch(() => {})
    }

    // Listen for auth changes
    const onAuthChanged = () => {
      const t = localStorage.getItem('token')
      const e = localStorage.getItem('userEmail')
      const n = localStorage.getItem('userName')
      const a = localStorage.getItem('userAvatar')
      if (t && e) {
        setUserEmail(e); setUserName(n || e.split('@')[0]); setUserAvatar(a || '')
      } else {
        setUserEmail(null); setUserName(null); setUserAvatar(null)
      }
    }
    window.addEventListener('auth-changed', onAuthChanged)
    return () => window.removeEventListener('auth-changed', onAuthChanged)
  }, [])

  const handleSearchInput = async (value: string) => {
    searchCommittedRef.current = false
    setSearchQuery(value)

    if (value.length >= 3) {
      setSearchLoading(true)
      setSearchLoadingMore(false)
      const requestId = ++searchRequestIdRef.current
      try {
        const res = await moviesAPI.searchMovies(value, 1)
        if (requestId !== searchRequestIdRef.current || searchCommittedRef.current) {
          return
        }
        const allResults = res.data.results || []
        const validMovies = filterValidMovies(allResults)
        setSearchResults(validMovies)
        setSearchPage(res.data.page || 1)
        setSearchTotalPages(res.data.total_pages || 1)
        setShowSearchResults(true)
      } catch (error) {
        console.error('Search error:', error)
        if (requestId !== searchRequestIdRef.current || searchCommittedRef.current) {
          return
        }
        setSearchResults([])
        setSearchPage(1)
        setSearchTotalPages(1)
      } finally {
        if (requestId === searchRequestIdRef.current && !searchCommittedRef.current) {
          setSearchLoading(false)
        }
      }
    } else {
      setShowSearchResults(false)
      setSearchResults([])
      setSearchPage(1)
      setSearchTotalPages(1)
      setSearchLoadingMore(false)
    }
  }

  const loadMoreSearchResults = async () => {
    if (searchLoading || searchLoadingMore) return
    if (!showSearchResults) return
    if (searchQuery.trim().length < 3) return
    if (searchPage >= searchTotalPages) return

    const nextPage = searchPage + 1
    const requestId = searchRequestIdRef.current
    setSearchLoadingMore(true)
    try {
      const res = await moviesAPI.searchMovies(searchQuery.trim(), nextPage)
      if (requestId !== searchRequestIdRef.current || searchCommittedRef.current) {
        return
      }
      const nextValid = filterValidMovies(res.data.results || [])
      setSearchResults((prev) => {
        const seen = new Set(prev.map((m) => String((m as any).id)))
        const merged = [...prev]
        for (const item of nextValid) {
          const key = String((item as any).id)
          if (!seen.has(key)) {
            seen.add(key)
            merged.push(item)
          }
        }
        return merged
      })
      setSearchPage(res.data.page || nextPage)
      setSearchTotalPages(res.data.total_pages || searchTotalPages)
    } catch (error) {
      console.error('Search load more error:', error)
    } finally {
      setSearchLoadingMore(false)
    }
  }

  const handleSearchFocus = () => {
    const value = searchQuery.trim()
    if (value.length < 3) return

    if (searchResults.length > 0) {
      setShowSearchResults(true)
      return
    }

    void handleSearchInput(value)
  }

  const handleSearchResultsScroll = (event: UIEvent<HTMLDivElement>) => {
    const el = event.currentTarget
    const nearBottom = el.scrollTop + el.clientHeight >= el.scrollHeight - 80
    if (nearBottom) {
      void loadMoreSearchResults()
    }
  }

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    if (searchQuery.trim()) {
      searchCommittedRef.current = true
      searchRequestIdRef.current++
      navigate(`/search?q=${encodeURIComponent(searchQuery)}`)
      setSearchQuery('')
      setShowSearchResults(false)
      setSearchResults([])
    }
  }

  const handleSelectMovie = (movie: Movie) => {
    const id = movie.kinopoisk_id ? `kp_${movie.kinopoisk_id}` : movie.id
    searchCommittedRef.current = true
    searchRequestIdRef.current++
    navigate(`/${id}`)
    setSearchQuery('')
    setShowSearchResults(false)
    setSearchResults([])
  }

  const getSearchPosterUrl = (movie: Movie) => {
    const movieAny = movie as any
    const raw =
      movieAny.posterUrlPreview ||
      movieAny.posterUrl ||
      movieAny.poster_url ||
      movieAny.poster_path ||
      ''
    const optimized = typeof raw === 'string' ? raw.replace('/kp_big/', '/kp_small/') : raw
    return getImageUrl(optimized)
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      {isMobile && !mobileAppBannerDismissed && (
        <Box sx={{ px: 1, pt: 1, backgroundColor: colors.bg }}>
          <Alert
            severity="info"
            sx={{
              backgroundColor: colors.surface,
              color: colors.text,
              border: `1px solid ${colors.border}`,
              '& .MuiAlert-icon': { color: '#1976d2' },
              '& a': { color: '#90caf9', fontWeight: 700, textDecoration: 'none' },
            }}
            action={
              <IconButton
                aria-label="close"
                size="small"
                onClick={() => {
                  try {
                    localStorage.setItem('mobile_app_banner_dismissed', '1')
                  } catch {}
                  setMobileAppBannerDismissed(true)
                }}
              >
                <CloseIcon fontSize="inherit" sx={{ color: colors.muted }} />
              </IconButton>
            }
          >
            Доступно мобильное приложение —{' '}
            <a href="https://app.neomovies.ru" target="_blank" rel="noreferrer">app.neomovies.ru</a>
          </Alert>
        </Box>
      )}

      {/* Top Header */}
      <AppBar position="sticky" elevation={0} sx={{ backgroundColor: colors.header, borderBottom: `1px solid ${colors.border}` }}>
        <Container maxWidth="xl">
        <Toolbar sx={{ justifyContent: 'space-between', py: 0.35, px: { xs: 0.2, sm: 0.6 }, gap: 1, minHeight: 54 }}>
          {/* Logo */}
          <Box
            onClick={() => navigate('/')}
            sx={{
              cursor: 'pointer',
              fontSize: { xs: '0.95rem', sm: '1.15rem' },
              fontWeight: 700,
              letterSpacing: '0em',
              color: colors.text,
              transition: 'opacity 0.2s',
              fontFamily: '"Inter", sans-serif',
              flexShrink: 0,
              '&:hover': {
                opacity: 0.8,
              },
              '& .neo-text': {
                color: colors.text,
              },
              '& .movies-text': {
                color: colors.text,
              },
            }}
          >
            <span className="neo-text">Neo</span><span className="movies-text">Movies</span>
          </Box>

          <Stack
            direction="row"
            spacing={1.6}
            sx={{
              display: { xs: 'none', md: 'flex' },
              mr: 0.5,
              ml: 0.5,
              flexShrink: 0,
            }}
          >
            {navItems.map((item) => (
              <Button
                key={item.path}
                onClick={() => handleNavClick(item.path)}
                sx={{
                  color: location.pathname === item.path ? colors.text : colors.muted,
                  p: 0,
                  minWidth: 0,
                  fontSize: '0.9rem',
                  fontWeight: location.pathname === item.path ? 650 : 560,
                  '&:hover': { color: colors.text, backgroundColor: 'transparent' },
                }}
              >
                {item.label}
              </Button>
            ))}
          </Stack>

          {/* Search Bar - Center */}
          <Box ref={searchBoxRef} component="form" onSubmit={handleSearch} sx={{ position: 'relative', flex: 1, mx: { xs: 0.5, sm: 1.1 }, minWidth: 0, maxWidth: 460 }}>
            <TextField
              fullWidth
              size="small"
              placeholder="Поиск..."
              value={searchQuery}
              onChange={(e) => handleSearchInput(e.target.value)}
              onFocus={handleSearchFocus}
              sx={{
                '& .MuiOutlinedInput-root': {
                  color: colors.text,
                  backgroundColor: colors.surface,
                  borderRadius: '10px',
                  fontSize: { xs: '0.78rem', sm: '0.9rem' },
                  height: 36,
                  '& fieldset': {
                    borderColor: colors.border,
                  },
                  '&:hover fieldset': {
                    borderColor: dark ? '#4b5563' : '#9ca3af',
                  },
                  '&.Mui-focused fieldset': {
                    borderColor: '#1976d2',
                  },
                },
              }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon sx={{ color: colors.muted, mr: 0.5, fontSize: '1.1rem' }} />
                  </InputAdornment>
                ),
              }}
            />
            
            {/* Search Results Dropdown */}
            {showSearchResults && (
              <Paper
                onScroll={handleSearchResultsScroll}
                sx={{
                  position: 'absolute',
                  top: '100%',
                  left: 0,
                  right: 0,
                  backgroundColor: colors.surface,
                  border: `1px solid ${colors.border}`,
                  borderTop: 'none',
                  borderRadius: '0 0 10px 10px',
                  maxHeight: 300,
                  overflowY: 'auto',
                  zIndex: 1000,
                }}
              >
                {searchLoading ? (
                  <Box sx={{ display: 'flex', justifyContent: 'center', p: 2 }}>
                    <CircularProgress size={24} />
                  </Box>
                ) : searchResults.length > 0 ? (
                  <>
                  {searchResults.map((movie) => {
                    const rating = (movie as any).rating || movie.vote_average || movie.ratingKinopoisk || 0
                    const year = movie.release_date ? new Date(movie.release_date).getFullYear() : movie.year
                    return (
                      <Box
                        key={movie.id}
                        onClick={() => handleSelectMovie(movie)}
                        sx={{
                          display: 'flex',
                          gap: 1.5,
                          p: 1.5,
                          borderBottom: `1px solid ${colors.border}`,
                          cursor: 'pointer',
                          '&:hover': {
                            backgroundColor: colors.hover,
                          },
                          '&:last-child': {
                            borderBottom: 'none',
                          },
                        }}
                      >
                        <Box
                          component="img"
                          src={getSearchPosterUrl(movie)}
                          alt={movie.title}
                          loading="lazy"
                          decoding="async"
                          sx={{
                            width: 45,
                            height: 65,
                            objectFit: 'cover',
                            borderRadius: '2px',
                            flexShrink: 0,
                          }}
                        />
                        <Box sx={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
                          <Box>
                            <Box sx={{ color: colors.text, fontSize: '0.9rem', fontWeight: 500, overflow: 'hidden', textOverflow: 'ellipsis', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' }}>
                              {movie.title || movie.nameRu || movie.nameOriginal}
                            </Box>
                          </Box>
                          <Box sx={{ display: 'flex', gap: 1, alignItems: 'center', mt: 0.5 }}>
                            <Box sx={{ color: colors.muted, fontSize: '0.75rem' }}>
                              {year}
                            </Box>
                            {rating > 0 && (
                              <Box sx={{ color: '#ffd700', fontSize: '0.75rem', fontWeight: 500 }}>
                                ★ {rating.toFixed(1)}
                              </Box>
                            )}
                          </Box>
                        </Box>
                      </Box>
                    )
                  })}
                  {searchLoadingMore && (
                    <Box sx={{ display: 'flex', justifyContent: 'center', p: 1.5 }}>
                      <CircularProgress size={18} />
                    </Box>
                  )}
                  </>
                ) : (
                  <Box sx={{ p: 2, textAlign: 'center', color: colors.muted, fontSize: '0.85rem' }}>
                    Ничего не найдено
                  </Box>
                )}
              </Paper>
            )}
          </Box>

          {/* Right Actions */}
          <IconButton
            onClick={toggleMode}
            size="small"
            disableRipple
            sx={{
              color: colors.text,
              border: `1px solid ${colors.border}`,
              backgroundColor: colors.surface,
              mr: 0.45,
              width: 34,
              height: 34,
              '&:hover': { backgroundColor: colors.hover },
              '&.Mui-focusVisible': {
                outline: 'none',
                boxShadow: 'none',
                borderColor: colors.border,
                },
              '&:focus-visible': {
                outline: 'none',
              },
              '& .MuiTouchRipple-root': { display: 'none' },
              WebkitTapHighlightColor: 'transparent',
            }}
          >
            {dark ? <LightModeOutlinedIcon fontSize="small" /> : <DarkModeOutlinedIcon fontSize="small" />}
          </IconButton>

          {userName ? (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexShrink: 0 }}>
              <Button
                onClick={(e: any) => setAnchorEl(e.currentTarget)}
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 0.75,
                  color: colors.text,
                  textTransform: 'none',
                  fontSize: { xs: '0.68rem', sm: '0.82rem' },
                  p: { xs: 0.2, sm: 0.3 },
                  borderRadius: 999,
                  '&:hover': { backgroundColor: colors.hover },
                }}
              >
                {userAvatar ? (
                  <Box
                    component="img"
                    src={userAvatar}
                    referrerPolicy="no-referrer"
                    sx={{ width: { xs: 24, sm: 28 }, height: { xs: 24, sm: 28 }, borderRadius: '50%', objectFit: 'cover', border: `1px solid ${colors.border}` }}
                  />
                ) : (
                  <PersonIcon sx={{ width: { xs: 22, sm: 24 }, height: { xs: 22, sm: 24 }, color: colors.muted }} />
                )}
                <Box sx={{ display: { xs: 'none', sm: 'block' } }}>{userName}</Box>
              </Button>
              <Menu
                anchorEl={anchorEl}
                open={Boolean(anchorEl)}
                onClose={() => setAnchorEl(null)}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
                transformOrigin={{ vertical: 'top', horizontal: 'right' }}
                sx={{
                  '& .MuiPaper-root': {
                    backgroundColor: colors.surface,
                    color: colors.text,
                    minWidth: 230,
                    border: `1px solid ${colors.border}`,
                    borderRadius: 2.6,
                    mt: 0.6,
                    boxShadow: dark
                      ? '0 14px 30px rgba(0,0,0,0.4)'
                      : '0 10px 24px rgba(2,8,20,0.12)',
                  },
                }}
              >
                <Box sx={{ px: 1.6, pt: 1.1, pb: 0.85 }}>
                  <Box sx={{ fontSize: '0.8rem', color: colors.muted, lineHeight: 1.3, wordBreak: 'break-all' }}>
                  {userEmail}
                  </Box>
                </Box>
                <Divider sx={{ borderColor: colors.border }} />
                <MenuItem
                  sx={{
                    py: 1,
                    px: 1.6,
                    fontSize: '0.98rem',
                    '&:hover': { backgroundColor: colors.hover },
                  }}
                  onClick={() => {
                    navigate('/profile')
                    setAnchorEl(null)
                  }}
                >
                  Профиль
                </MenuItem>
                <MenuItem
                  sx={{
                    py: 1,
                    px: 1.6,
                    fontSize: '0.98rem',
                    color: '#ef4444',
                    '&:hover': { backgroundColor: colors.hover },
                  }}
                  onClick={() => {
                    clearAuthState()
                    setUserName(null)
                    setUserEmail(null)
                    setUserAvatar(null)
                    setAnchorEl(null)
                    navigate('/')
                  }}
                >
                  Выход
                </MenuItem>
              </Menu>
            </Box>
          ) : (
            <Button
              variant="contained"
              onClick={() => navigate('/auth')}
              sx={{
                backgroundColor: '#1976d2',
                color: '#fff',
                textTransform: 'none',
                fontWeight: 'bold',
                fontSize: { xs: '0.7rem', sm: '0.85rem' },
                px: { xs: 1, sm: 1.5 },
                py: { xs: 0.3, sm: 0.5 },
                flexShrink: 0,
                '&:hover': { backgroundColor: '#1565c0' },
              }}
            >
              Войти
            </Button>
          )}
        </Toolbar>
        <Box
          sx={{
            display: { xs: 'grid', md: 'none' },
            gridTemplateColumns: 'repeat(4, minmax(0, 1fr))',
            gap: 0.6,
            px: 0.2,
            pb: 0.7,
          }}
        >
          {navItems.map((item) => (
            <Button
              key={`mobile-${item.path}`}
              onClick={() => handleNavClick(item.path)}
              sx={{
                color: location.pathname === item.path ? colors.text : colors.muted,
                minWidth: 0,
                px: 0,
                py: 0.2,
                fontSize: '0.73rem',
                fontWeight: location.pathname === item.path ? 650 : 560,
                textTransform: 'none',
                whiteSpace: 'normal',
                lineHeight: 1.15,
                '&:hover': { color: colors.text, backgroundColor: 'transparent' },
              }}
            >
              {item.label}
            </Button>
          ))}
        </Box>
        </Container>
      </AppBar>

      {/* Main Content */}
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          py: { xs: 2, sm: 4 },
          px: { xs: 1, sm: 0 },
          backgroundColor: colors.bg,
          minHeight: '100%'
        }}
      >
        <Container maxWidth="lg">{children}</Container>
      </Box>
    </Box>
  )
}
