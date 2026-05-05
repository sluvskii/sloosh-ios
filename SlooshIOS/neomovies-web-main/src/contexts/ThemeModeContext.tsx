import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'

type ThemeMode = 'light' | 'dark'

type ThemeModeContextValue = {
  mode: ThemeMode
  setMode: (mode: ThemeMode) => void
  toggleMode: () => void
}

const ThemeModeContext = createContext<ThemeModeContextValue | null>(null)

function resolveInitialMode(): ThemeMode {
  try {
    const stored = localStorage.getItem('themeMode')
    if (stored === 'light' || stored === 'dark') return stored
  } catch {}
  if (window.matchMedia?.('(prefers-color-scheme: dark)').matches) return 'dark'
  return 'light'
}

export function ThemeModeProvider({ children }: { children: ReactNode }) {
  const [mode, setModeState] = useState<ThemeMode>(resolveInitialMode)

  useEffect(() => {
    try {
      localStorage.setItem('themeMode', mode)
    } catch {}
  }, [mode])

  const value = useMemo<ThemeModeContextValue>(() => ({
    mode,
    setMode: (nextMode) => setModeState(nextMode),
    toggleMode: () => setModeState((prev) => (prev === 'dark' ? 'light' : 'dark')),
  }), [mode])

  return <ThemeModeContext.Provider value={value}>{children}</ThemeModeContext.Provider>
}

export function useThemeMode() {
  const ctx = useContext(ThemeModeContext)
  if (!ctx) throw new Error('useThemeMode must be used within ThemeModeProvider')
  return ctx
}
