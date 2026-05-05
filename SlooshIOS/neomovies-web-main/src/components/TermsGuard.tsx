import { useEffect, useState } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'

interface TermsGuardProps {
  children: React.ReactNode
}

export const TermsGuard = ({ children }: TermsGuardProps) => {
  const navigate = useNavigate()
  const location = useLocation()
  const [termsAccepted, setTermsAccepted] = useState<boolean | null>(null)

  useEffect(() => {
    const accepted = localStorage.getItem('acceptedTerms')
    const token = localStorage.getItem('token')
    
    // Если уже принял условия - показываем контент
    if (accepted === 'true') {
      setTermsAccepted(true)
      return
    }

    // Если на странице /terms - не редиректим
    if (location.pathname === '/terms') {
      setTermsAccepted(true)
      return
    }

    // Если на странице /auth - не редиректим
    if (location.pathname.startsWith('/auth')) {
      setTermsAccepted(true)
      return
    }

    // Если авторизован - показываем контент (условия уже приняты при регистрации)
    if (token) {
      setTermsAccepted(true)
      return
    }

    // Иначе редиректим на условия
    setTermsAccepted(false)
    navigate('/terms', { replace: true })
  }, [navigate, location.pathname])

  // Если условия не приняты и не на странице /terms - не показываем контент
  if (termsAccepted === false) {
    return null
  }

  // Если условия приняты или на странице /terms - показываем контент
  return <>{children}</>
}
