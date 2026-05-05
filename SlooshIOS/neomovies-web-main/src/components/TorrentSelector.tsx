import { useState } from 'react'
import {
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  CircularProgress,
  Alert,
  Box,
  Typography,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  List,
  ListItem,
  ListItemText,
  IconButton,
} from '@mui/material'
import ContentCopyIcon from '@mui/icons-material/ContentCopy'
import { BsMagnetFill } from 'react-icons/bs'
import { playersAPI } from '../api'

interface TorrentSelectorProps {
  kpId?: string | number
  type: 'movie' | 'tv'
  title?: string
}

interface Torrent {
  title: string
  magnet: string
  size?: string
  seeds?: number
  peers?: number
  quality?: string
  season?: number
}

export const TorrentSelector = ({ kpId, type, title }: TorrentSelectorProps) => {
  const [open, setOpen] = useState(false)
  const [torrents, setTorrents] = useState<Torrent[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [selectedSeason, setSelectedSeason] = useState<number | null>(null)
  const [seasons, setSeasons] = useState<number[]>([])
  const [, setCopied] = useState<string | null>(null)
  const [selectedQualities, setSelectedQualities] = useState<string[]>([])

  const fetchTorrents = async () => {
    setLoading(true)
    setError(null)
    try {
      if (!kpId) {
        setError('KP ID не найден для этого контента.')
        setLoading(false)
        return
      }
      const numericKpId = String(kpId).replace(/^kp_/, '')
      const response = await playersAPI.getTorrents(numericKpId)
      const data: any[] = Array.isArray(response.data)
        ? response.data
        : response.data?.results || response.data?.data || []

      if (data.length === 0) {
        setError('Торренты не найдены.')
        setLoading(false)
        return
      }
      setTorrents(data)
      setSelectedQualities([]) // Сбрасываем фильтры качества при загрузке новых торрентов

      // Извлекаем уникальные сезоны для сериалов
      if (type === 'tv') {
        const uniqueSeasons = [...new Set(data.map((t: any) => t.season).filter(Boolean))] as number[]
        setSeasons(uniqueSeasons.sort((a, b) => a - b))
        if (uniqueSeasons.length > 0) {
          setSelectedSeason(uniqueSeasons[0])
        }
      }
    } catch (err: any) {
      setError(`Ошибка при загрузке торрентов: ${err.message}`)
      console.error('Torrent fetch error:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleOpen = () => {
    setOpen(true)
    if (torrents.length === 0) {
      fetchTorrents()
    }
  }

  const handleCopyMagnet = (magnet: string) => {
    navigator.clipboard.writeText(magnet)
    setCopied(magnet)
    setTimeout(() => setCopied(null), 2000)
  }

  // Получаем уникальные качества из торрентов
  const toQualityString = (q: unknown): string => String(q ?? '').trim()
  const formatQualityLabel = (q: unknown): string => {
    const raw = toQualityString(q)
    if (!raw) return ''
    const lower = raw.toLowerCase()
    if (lower.endsWith('p') || lower.endsWith('k')) return raw
    if (/^\d+$/.test(raw)) return `${raw}p`
    return raw
  }

  const formatSizeGb = (value: unknown): string => {
    const n = typeof value === 'number' ? value : Number(String(value ?? '').trim())
    if (!Number.isFinite(n) || n <= 0) return String(value ?? '')
    const gb = n / (1024 * 1024 * 1024)
    return `${gb.toFixed(gb >= 10 ? 1 : 2)} GB`
  }

  const availableQualities = Array.from(
    new Set(torrents.map((t) => toQualityString(t.quality)).filter(Boolean))
  ).sort((a: string, b: string) => {
    const norm = (q: unknown) => String(q ?? '').trim().toLowerCase().replace(/\s+/g, '')
    // Приоритет: 4K -> 2K -> 1080p -> 720p -> 480p -> остальное
    const qualityOrder: Record<string, number> = {
      '4k': 0,
      '2160': 0,
      '2160p': 0,
      '2k': 1,
      '1440': 1,
      '1440p': 1,
      '1080': 2,
      '1080p': 2,
      '720': 3,
      '720p': 3,
      '480': 4,
      '480p': 4,
      '360': 5,
      '360p': 5,
    }
    const aKey = norm(a)
    const bKey = norm(b)
    return (qualityOrder[aKey] ?? 999) - (qualityOrder[bKey] ?? 999)
  })

  // Фильтруем торренты по сезону и качеству
  const filteredTorrents = torrents.filter((t) => {
    const seasonMatch = !selectedSeason || t.season === selectedSeason
    const qualityMatch =
      selectedQualities.length === 0 || selectedQualities.includes(toQualityString(t.quality))
    return seasonMatch && qualityMatch
  })

  return (
    <>
      <Button
        variant="outlined"
        onClick={handleOpen}
        startIcon={<BsMagnetFill style={{ fontSize: '0.875rem' }} />}
        size="small"
      >
        Торренты
      </Button>

      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Торренты {title && `- ${title}`}</DialogTitle>
        <DialogContent>
          {loading && (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          )}

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          {!loading && torrents.length > 0 && (
            <>
              {/* Фильтры качества */}
              {availableQualities.length > 0 && (
                <Box sx={{ mb: 2 }}>
                  <Typography variant="subtitle2" sx={{ mb: 1 }}>
                    Качество:
                  </Typography>
                  <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                    {availableQualities.map((quality) => (
                      <Button
                        key={quality}
                        variant={selectedQualities.includes(quality) ? 'contained' : 'outlined'}
                        size="small"
                        onClick={() => {
                          setSelectedQualities((prev) =>
                            prev.includes(quality)
                              ? prev.filter((q) => q !== quality)
                              : [...prev, quality]
                          )
                        }}
                      >
                        {formatQualityLabel(quality)}
                      </Button>
                    ))}
                  </Box>
                </Box>
              )}

              {type === 'tv' && seasons.length > 0 && (
                <FormControl fullWidth sx={{ mb: 2 }}>
                  <InputLabel>Сезон</InputLabel>
                  <Select
                    value={selectedSeason || ''}
                    label="Сезон"
                    onChange={(e) => setSelectedSeason(Number(e.target.value))}
                  >
                    {seasons.map((season) => (
                      <MenuItem key={season} value={season}>
                        Сезон {season}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              )}

              <List>
                {filteredTorrents.map((torrent, idx) => (
                  <ListItem
                    key={idx}
                    secondaryAction={
                      <Box>
                        <IconButton
                          edge="end"
                          onClick={() => handleCopyMagnet(torrent.magnet)}
                          title="Копировать magnet"
                        >
                          <ContentCopyIcon fontSize="small" />
                        </IconButton>
                        <IconButton
                          edge="end"
                          href={torrent.magnet}
                          title="Открыть в торрент клиенте"
                        >
                          <BsMagnetFill style={{ fontSize: '0.875rem' }} />
                        </IconButton>
                      </Box>
                    }
                  >
                    <ListItemText
                      primary={torrent.title}
                      secondary={
                        <>
                          {torrent.quality && (
                            <Typography variant="caption">
                              Качество: {formatQualityLabel(torrent.quality)}
                            </Typography>
                          )}
                          {torrent.size && (
                            <Typography variant="caption"> • Размер: {formatSizeGb(torrent.size)}</Typography>
                          )}
                          {torrent.seeds !== undefined && (
                            <Typography variant="caption"> • Сиды: {torrent.seeds}</Typography>
                          )}
                        </>
                      }
                    />
                  </ListItem>
                ))}
              </List>
            </>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Закрыть</Button>
        </DialogActions>
      </Dialog>
    </>
  )
}
