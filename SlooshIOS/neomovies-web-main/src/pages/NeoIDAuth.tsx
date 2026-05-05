import { useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Box, Button, Chip, CircularProgress, Paper, Stack, Typography } from '@mui/material'
import SecurityRoundedIcon from '@mui/icons-material/SecurityRounded'
import ArrowOutwardRoundedIcon from '@mui/icons-material/ArrowOutwardRounded'
import ArrowBackRoundedIcon from '@mui/icons-material/ArrowBackRounded'
import { apiClient, setAuthTokens } from '../api/client'

const NEO_ID_URL = (import.meta.env.VITE_NEO_ID_URL || 'https://id.neomovies.ru').replace(/\/$/, '')

function storeTokens(token: string, refreshToken: string, user: any) {
  setAuthTokens(token, refreshToken)
  if (user?.email) localStorage.setItem('userEmail', user.email)
  if (user?.name) localStorage.setItem('userName', user.name)
  if (user?.avatar) localStorage.setItem('userAvatar', user.avatar)
  localStorage.setItem('acceptedTerms', 'true')
  window.dispatchEvent(new Event('auth-changed'))
}

const humanizeError = (err: any): string => {
  const serverMessage = err?.response?.data?.error || err?.response?.data?.message
  if (serverMessage) return String(serverMessage)

  if (err?.message === 'Network Error') {
    return 'Network Error: API is unreachable. If you test on mobile, set VITE_API_URL to your LAN host (example: http://192.168.1.50:3001) and make sure backend is running.'
  }

  return err?.message || 'Failed to complete Neo ID sign in'
}

async function exchangeNeoToken(neoToken: string, neoRefresh: string): Promise<void> {
  const resp = await apiClient.post('/api/v1/auth/neo-id/callback', {
    access_token: neoToken,
    refresh_token: neoRefresh || '',
  })
  const data = resp.data?.data || resp.data
  if (data.neoAccess) localStorage.setItem('neo_id_access_token', data.neoAccess)
  if (data.neoRefresh) localStorage.setItem('neo_id_refresh_token', data.neoRefresh)
  const accessToken = data.accessToken || data.token
  const refreshToken = data.refreshToken || data.refresh_token
  if (!accessToken || !refreshToken) throw new Error('Invalid token payload from API')
  storeTokens(accessToken, refreshToken, data.user)
}

export const NeoIDAuth = () => {
  const navigate = useNavigate()
  const [status, setStatus] = useState<'idle' | 'opening' | 'waiting' | 'error'>('idle')
  const [error, setError] = useState('')
  const popupRef = useRef<Window | null>(null)
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)

  useEffect(() => {
    if (localStorage.getItem('token')) navigate('/', { replace: true })
  }, [navigate])

  useEffect(() => {
    const onMessage = async (e: MessageEvent) => {
      if (e.data?.type !== 'neo_id_auth') return
      const { access_token, refresh_token } = e.data
      if (!access_token) {
        setError('No token received from Neo ID')
        setStatus('error')
        return
      }

      try {
        setStatus('idle')
        await exchangeNeoToken(access_token, refresh_token || '')
        navigate('/', { replace: true })
      } catch (err: any) {
        setError(humanizeError(err))
        setStatus('error')
      }
    }

    window.addEventListener('message', onMessage)
    return () => window.removeEventListener('message', onMessage)
  }, [navigate])

  useEffect(() => {
    const pending = localStorage.getItem('neo_id_pending_token')
    const pendingRefresh = localStorage.getItem('neo_id_pending_refresh')
    if (!pending) return

    localStorage.removeItem('neo_id_pending_token')
    localStorage.removeItem('neo_id_pending_refresh')
    exchangeNeoToken(pending, pendingRefresh || '')
      .then(() => navigate('/', { replace: true }))
      .catch((err: any) => {
        setError(humanizeError(err))
        setStatus('error')
      })
  }, [navigate])

  useEffect(() => {
    const hash = window.location.hash
    const search = window.location.search

    const fromHash = hash ? new URLSearchParams(hash.slice(1)) : null
    const fromQuery = search ? new URLSearchParams(search) : null

    const token =
      fromHash?.get('access_token') ||
      fromHash?.get('token') ||
      fromQuery?.get('access_token') ||
      fromQuery?.get('token')
    const refresh =
      fromHash?.get('refresh_token') ||
      fromQuery?.get('refresh_token') ||
      ''

    if (!token) return

    window.history.replaceState({}, '', window.location.pathname)
    exchangeNeoToken(token, refresh)
      .then(() => navigate('/', { replace: true }))
      .catch((err: any) => {
        setError(humanizeError(err))
        setStatus('error')
      })
  }, [navigate])

  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current)
    }
  }, [])

  const openPopup = async () => {
    setStatus('opening')
    setError('')

    try {
      const state = Math.random().toString(36).slice(2)
      localStorage.setItem('neo_id_state', state)
      const callbackURL = `${window.location.origin}/auth/neo-id/callback`

      const resp = await apiClient.post('/api/v1/auth/neo-id/login', {
        redirect_url: callbackURL,
        state,
        mode: 'popup',
      })
      const data = resp.data?.data || resp.data
      const rawURL: string = data.login_url || ''
      if (!rawURL) throw new Error('No login_url returned')

      const loginURL = rawURL.startsWith('/') ? `${NEO_ID_URL}${rawURL}` : rawURL

      const w = 480
      const h = 680
      const left = window.screenX + (window.outerWidth - w) / 2
      const top = window.screenY + (window.outerHeight - h) / 2

      const popup = window.open(
        loginURL,
        'neo_id_auth',
        `width=${w},height=${h},left=${left},top=${top},toolbar=no,menubar=no,scrollbars=yes`,
      )

      if (!popup) {
        window.location.href = loginURL
        return
      }

      popupRef.current = popup
      setStatus('waiting')

      timerRef.current = setInterval(() => {
        if (!popup.closed) return
        clearInterval(timerRef.current!)
        setStatus((s) => (s === 'waiting' ? 'idle' : s))
      }, 500)
    } catch (err: any) {
      setError(humanizeError(err))
      setStatus('error')
    }
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'grid',
        placeItems: 'center',
        px: 2,
        py: 6,
        background:
          'radial-gradient(1200px 500px at 20% -20%, rgba(229,57,53,0.16), transparent), radial-gradient(1000px 500px at 120% 0%, rgba(21,101,192,0.18), transparent), #06080e',
      }}
    >
      <Paper
        elevation={0}
        sx={{
          width: '100%',
          maxWidth: 460,
          borderRadius: 4,
          p: { xs: 3, sm: 4 },
          border: '1px solid rgba(148,163,184,0.2)',
          background: 'linear-gradient(180deg, rgba(10,14,22,0.94) 0%, rgba(8,12,19,0.9) 100%)',
          backdropFilter: 'blur(4px)',
        }}
      >
        <Stack spacing={2.2}>
          <Button
            variant="text"
            size="small"
            startIcon={<ArrowBackRoundedIcon />}
            onClick={() => navigate('/')}
            sx={{
              width: 'fit-content',
              color: '#cbd5e1',
              textTransform: 'none',
              px: 0.25,
              minWidth: 'auto',
            }}
          >
            Назад
          </Button>

          <Chip
            icon={<SecurityRoundedIcon />}
            label="Secure Neo ID"
            sx={{
              width: 'fit-content',
              height: 30,
              color: '#cbd5e1',
              borderColor: 'rgba(148,163,184,0.35)',
              bgcolor: 'rgba(15,23,42,0.45)',
            }}
            variant="outlined"
          />

          <Typography variant="h4" sx={{ color: '#f8fafc', fontWeight: 800, lineHeight: 1.1 }}>
            Sign in to NeoMovies
          </Typography>

          <Typography variant="body2" sx={{ color: '#94a3b8' }}>
            Use your Neo ID account to sync favorites, continue watching and access profile features.
          </Typography>

          {error && (
            <Box
              sx={{
                borderRadius: 2,
                px: 1.5,
                py: 1.1,
                fontSize: '0.88rem',
                color: '#e2e8f0',
                border: '1px solid rgba(148,163,184,0.35)',
                bgcolor: 'rgba(15,23,42,0.4)',
              }}
            >
              {error}
            </Box>
          )}

          {status === 'waiting' ? (
            <Stack spacing={1.5} alignItems="flex-start">
              <Stack direction="row" spacing={1.2} alignItems="center">
                <CircularProgress size={22} sx={{ color: '#e2e8f0' }} />
                <Typography sx={{ color: '#e2e8f0', fontSize: '0.95rem' }}>
                  Complete sign in in the popup window
                </Typography>
              </Stack>
              <Button
                variant="text"
                size="small"
                onClick={() => popupRef.current?.focus()}
                sx={{ color: '#93c5fd', textTransform: 'none', px: 0.25 }}
              >
                Focus popup
              </Button>
            </Stack>
          ) : (
            <Button
              variant="contained"
              fullWidth
              onClick={openPopup}
              disabled={status === 'opening'}
              endIcon={status === 'opening' ? undefined : <ArrowOutwardRoundedIcon />}
              sx={{
                mt: 0.5,
                height: 50,
                borderRadius: 2.5,
                textTransform: 'none',
                fontSize: '0.98rem',
                fontWeight: 700,
                color: '#0b0f17',
                bgcolor: '#e5e7eb',
                '&:hover': { bgcolor: '#d1d5db' },
              }}
            >
              {status === 'opening' ? <CircularProgress size={22} sx={{ color: '#fff' }} /> : 'Continue with Neo ID'}
            </Button>
          )}
        </Stack>
      </Paper>
    </Box>
  )
}
