import { useMemo, useEffect } from 'react'
import { ThemeProvider, createTheme } from '@mui/material/styles'
import CssBaseline from '@mui/material/CssBaseline'
import { BrowserRouter, Routes, Route, useNavigate } from 'react-router-dom'
import { Layout } from './components/Layout'
import { TermsGuard } from './components/TermsGuard'
import { Home, Search, MovieDetails, MoviesTop, TVTop, NeoIDAuth, NeoIDCallback, Profile, Favorites, Terms } from './pages'
import { FavoritesProvider } from './contexts/FavoritesContext'
import { ThemeModeProvider, useThemeMode } from './contexts/ThemeModeContext'
import { startAuthSessionKeepAlive } from './api/client'
import './App.css'

function makeTheme(mode: 'light' | 'dark') {
  const dark = mode === 'dark'
  return createTheme({
    palette: {
      mode,
      primary: { main: dark ? '#f5f5f5' : '#111111', contrastText: dark ? '#111111' : '#ffffff' },
      secondary: { main: dark ? '#9ca3af' : '#4b5563' },
      error: { main: '#dc2626' },
      background: {
        default: dark ? '#0b0b0d' : '#f4f5f7',
        paper: dark ? '#121316' : '#ffffff',
      },
      text: {
        primary: dark ? '#f5f6f7' : '#111827',
        secondary: dark ? '#9ca3af' : '#6b7280',
      },
      divider: dark ? '#26282d' : '#e5e7eb',
    },
    typography: {
      fontFamily: 'Inter, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif',
      h4: { fontWeight: 800, letterSpacing: -0.5 },
      h5: { fontWeight: 750, letterSpacing: -0.3 },
      h6: { fontWeight: 700, letterSpacing: -0.2 },
      button: { textTransform: 'none', fontWeight: 600 },
    },
    shape: { borderRadius: 10 },
    components: {
      MuiCssBaseline: {
        styleOverrides: {
          body: {
            backgroundColor: dark ? '#0b0b0d' : '#f4f5f7',
          },
        },
      },
      MuiAppBar: {
        styleOverrides: {
          root: {
            backgroundImage: 'none',
            backgroundColor: dark ? '#111216' : '#ffffff',
            borderBottom: `1px solid ${dark ? '#26282d' : '#e5e7eb'}`,
          },
        },
      },
      MuiButton: {
        styleOverrides: {
          root: { borderRadius: 10, fontWeight: 650 },
          containedPrimary: {
            backgroundColor: dark ? '#f5f6f7' : '#111827',
            color: dark ? '#111827' : '#ffffff',
          },
        },
      },
      MuiIconButton: {
        defaultProps: {
          disableRipple: true,
          disableFocusRipple: true,
        },
        styleOverrides: {
          root: {
            outline: 'none',
            '&:focus': { outline: 'none' },
            '&:focus-visible': {
              outline: 'none',
              boxShadow: 'none',
            },
          },
        },
      },
      MuiOutlinedInput: {
        styleOverrides: {
          root: {
            borderRadius: 10,
            backgroundColor: dark ? '#17181c' : '#ffffff',
          },
          notchedOutline: {
            borderColor: dark ? '#2e3138' : '#d1d5db',
          },
        },
      },
      MuiPaper: {
        styleOverrides: {
          root: {
            backgroundImage: 'none',
          },
        },
      },
    },
  })
}

// Редирект на /auth при истечении сессии (токены уже очищены в client.ts)
function AuthHandler() {
  const navigate = useNavigate()

  useEffect(() => {
    const handleAuthExpired = () => navigate('/auth')
    window.addEventListener('auth-expired', handleAuthExpired)
    const stopKeepAlive = startAuthSessionKeepAlive()
    return () => {
      window.removeEventListener('auth-expired', handleAuthExpired)
      stopKeepAlive()
    }
  }, [navigate])

  return null
}

function AppRoutes() {
  const { mode } = useThemeMode()
  const theme = useMemo(() => makeTheme(mode), [mode])

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <BrowserRouter>
        <TermsGuard>
          <FavoritesProvider>
            <AuthHandler />
            <Routes>
              <Route path="/auth" element={<NeoIDAuth />} />
              <Route path="/auth/neo-id/callback" element={<NeoIDCallback />} />
              <Route path="/auth/callback" element={<NeoIDCallback />} />
              <Route path="/terms" element={<Terms />} />
              <Route
                path="*"
                element={
                  <Layout>
                    <Routes>
                      <Route path="/" element={<Home />} />
                      <Route path="/movies-top" element={<MoviesTop />} />
                      <Route path="/tv-top" element={<TVTop />} />
                      <Route path="/search" element={<Search />} />
                      <Route path="/:id" element={<MovieDetails />} />
                      <Route path="/profile" element={<Profile />} />
                      <Route path="/favorites" element={<Favorites />} />
                    </Routes>
                  </Layout>
                }
              />
            </Routes>
          </FavoritesProvider>
        </TermsGuard>
      </BrowserRouter>
    </ThemeProvider>
  )
}

function App() {
  return (
    <ThemeModeProvider>
      <AppRoutes />
    </ThemeModeProvider>
  )
}

export default App
