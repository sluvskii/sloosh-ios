import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Box,
  Container,
  Card,
  Typography,
  Button,
  Avatar,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  Alert,
  Skeleton,
  Chip,
  Divider,
  useTheme,
} from '@mui/material'
import { apiClient } from '../api'
import { clearAuthState } from '../api/client'

interface UserProfile {
  id: string
  name: string
  email: string
  avatar: string
  neo_id?: string
  is_admin?: boolean
  created_at?: string
}

export const Profile = () => {
  const theme = useTheme()
  const dark = theme.palette.mode === 'dark'
  const navigate = useNavigate()

  const colors = {
    pageBg: dark ? '#0b0b0d' : '#f4f5f7',
    cardBg: dark ? '#111318' : '#ffffff',
    border: dark ? '#242830' : '#dce1ea',
    text: dark ? '#f5f6f7' : '#111827',
    muted: dark ? '#98a1b3' : '#6b7280',
    line: dark ? '#22262f' : '#e6e9f0',
    danger: '#ef4444',
  }

  const [profile, setProfile] = useState<UserProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [deleting, setDeleting] = useState(false)

  useEffect(() => {
    const token = localStorage.getItem('token')
    if (!token) {
      navigate('/auth')
      return
    }
    void loadProfile()
  }, [navigate])

  const loadProfile = async () => {
    setLoading(true)
    try {
      const resp = await apiClient.get('/api/v1/auth/profile')
      const user = resp.data
      setProfile(user)
      if (user.name) localStorage.setItem('userName', user.name)
      if (user.email) localStorage.setItem('userEmail', user.email)
      if (user.avatar) localStorage.setItem('userAvatar', user.avatar)
    } catch {
      setProfile({
        id: '',
        name: localStorage.getItem('userName') || '',
        email: localStorage.getItem('userEmail') || '',
        avatar: localStorage.getItem('userAvatar') || '',
      })
    } finally {
      setLoading(false)
    }
  }

  const handleLogout = () => {
    clearAuthState()
    navigate('/')
  }

  const handleDeleteAccount = async () => {
    setDeleting(true)
    setError('')
    try {
      await apiClient.delete('/api/v1/auth/delete-account')
      handleLogout()
    } catch (err: any) {
      setError(err?.response?.data?.error || err?.response?.data?.message || 'Failed to delete account')
    } finally {
      setDeleting(false)
      setDeleteDialogOpen(false)
    }
  }

  const initials = profile?.name
    ? profile.name.split(' ').map((w: string) => w[0]).join('').toUpperCase().slice(0, 2)
    : profile?.email?.[0]?.toUpperCase() || '?'

  const rows = [
    { label: 'Email', value: profile?.email || '—' },
    { label: 'Name', value: profile?.name || '—' },
    { label: 'Neo ID', value: profile?.neo_id || '—', mono: true, full: profile?.neo_id || '—' },
  ]

  const compactNeoId = (value: string) => {
    if (!value || value === '—') return value
    if (value.length <= 18) return value
    return `${value.slice(0, 12)}...${value.slice(-6)}`
  }

  return (
    <Container maxWidth="sm">
      <Box sx={{ py: { xs: 1.5, sm: 4 } }}>
        <Card
          sx={{
            borderRadius: 3,
            border: `1px solid ${colors.border}`,
            backgroundColor: colors.cardBg,
            boxShadow: dark ? '0 14px 34px rgba(0,0,0,0.34)' : '0 14px 30px rgba(15,23,42,0.10)',
            p: { xs: 1.6, sm: 2.4 },
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.6, mb: 2 }}>
            {loading ? (
              <Skeleton variant="circular" width={56} height={56} />
            ) : (
              <Avatar
                src={profile?.avatar || ''}
                imgProps={{ referrerPolicy: 'no-referrer' }}
                sx={{
                  width: 56,
                  height: 56,
                  bgcolor: '#1976d2',
                  fontSize: '1.1rem',
                  border: `1px solid ${colors.border}`,
                }}
              >
                {!profile?.avatar && initials}
              </Avatar>
            )}
            <Box sx={{ minWidth: 0 }}>
              {loading ? (
                <Skeleton width={180} height={24} />
              ) : (
                <Typography variant="h6" sx={{ fontWeight: 700, color: colors.text, lineHeight: 1.2 }}>
                  {profile?.name || profile?.email?.split('@')[0]}
                </Typography>
              )}
              <Chip
                label="Neo ID"
                size="small"
                sx={{
                  mt: 0.7,
                  height: 21,
                  fontSize: '0.72rem',
                  color: colors.muted,
                  border: `1px solid ${colors.border}`,
                  backgroundColor: 'transparent',
                }}
              />
            </Box>
          </Box>

          <Divider sx={{ borderColor: colors.line, mb: 1 }} />

          <Box sx={{ py: 0.5 }}>
            {rows.map((row, index) => (
              <Box key={row.label} sx={{ py: 1.15 }}>
                <Typography
                  variant="caption"
                  sx={{
                    color: colors.muted,
                    textTransform: 'uppercase',
                    letterSpacing: '0.08em',
                    fontSize: '0.68rem',
                  }}
                >
                  {row.label}
                </Typography>
                {loading ? (
                  <Skeleton width={220} height={22} sx={{ mt: 0.45 }} />
                ) : (
                  <Typography
                    title={row.label === 'Neo ID' ? (row as any).full : undefined}
                    sx={{
                      mt: 0.35,
                      color: colors.text,
                      fontSize: '0.98rem',
                      fontFamily: row.mono ? 'ui-monospace, SFMono-Regular, Menlo, monospace' : 'inherit',
                      wordBreak: row.mono ? 'break-all' : 'normal',
                    }}
                  >
                    {row.label === 'Neo ID' ? compactNeoId(row.value as string) : row.value}
                  </Typography>
                )}
                {index < rows.length - 1 && <Divider sx={{ borderColor: colors.line, mt: 1.2 }} />}
              </Box>
            ))}
          </Box>

          {error && <Alert severity="error" sx={{ mb: 1.5 }}>{error}</Alert>}

          <Stack spacing={1.2} sx={{ pt: 0.6 }}>
            <Button fullWidth variant="outlined" onClick={handleLogout}>
              Sign out
            </Button>
            <Button fullWidth variant="outlined" color="error" onClick={() => setDeleteDialogOpen(true)}>
              Delete account
            </Button>
          </Stack>
        </Card>
      </Box>

      <Dialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
        PaperProps={{ sx: { bgcolor: colors.cardBg, border: `1px solid ${colors.border}` } }}
      >
        <DialogTitle>Delete account?</DialogTitle>
        <DialogContent>
          <DialogContentText sx={{ color: colors.muted }}>
            This is permanent. All your data including favorites will be deleted.
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setDeleteDialogOpen(false)} disabled={deleting}>Cancel</Button>
          <Button onClick={handleDeleteAccount} color="error" variant="contained" disabled={deleting}>
            {deleting ? 'Deleting...' : 'Delete'}
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  )
}
