// This page runs inside the Neo ID popup window.
// Neo ID sends a postMessage to the opener and closes the window.
// If postMessage fails (e.g. same-origin redirect), we handle the token here.

import { useEffect } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Box, CircularProgress } from '@mui/material'

export const NeoIDCallback = () => {
  const [searchParams] = useSearchParams()

  useEffect(() => {
    const token = searchParams.get('token') || searchParams.get('access_token')
    const refreshToken = searchParams.get('refresh_token') || ''
    const state = searchParams.get('state') || ''

    if (!token) {
      // No token — close popup or redirect
      if (window.opener) {
        window.close()
      }
      return
    }

    const msg = {
      type: 'neo_id_auth',
      access_token: token,
      refresh_token: refreshToken,
      state,
    }

    if (window.opener) {
      // Send to parent window — origin '*' because Neo ID may be on different domain
      window.opener.postMessage(msg, '*')
      window.close()
    } else {
      // Not a popup — store and redirect
      localStorage.setItem('neo_id_pending_token', token)
      localStorage.setItem('neo_id_pending_refresh', refreshToken)
      window.location.replace('/')
    }
  }, [searchParams])

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#0a0a0a', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <CircularProgress sx={{ color: '#e53935' }} />
    </Box>
  )
}
