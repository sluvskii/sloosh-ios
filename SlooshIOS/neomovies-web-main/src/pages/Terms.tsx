import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Container,
  Box,
  Typography,
  Button,
  Paper,
  ToggleButton,
  ToggleButtonGroup,
  Divider,
  useTheme,
} from '@mui/material'
import LanguageIcon from '@mui/icons-material/Language'

export const Terms = () => {
  const theme = useTheme()
  const dark = theme.palette.mode === 'dark'
  const navigate = useNavigate()
  const [lang, setLang] = useState<'ru' | 'en'>('ru')

  const colors = {
    pageBg: dark ? '#121212' : '#f4f5f7',
    paperBg: dark ? '#1e1e1e' : '#ffffff',
    text: dark ? '#ffffff' : '#111827',
    muted: dark ? '#cccccc' : '#4b5563',
    subtitle: dark ? '#9ca3af' : '#6b7280',
    border: dark ? '#333333' : '#e5e7eb',
    buttonBorder: dark ? '#555555' : '#d1d5db',
  }

  const handleLanguageChange = (_event: React.MouseEvent<HTMLElement>, newLang: 'ru' | 'en') => {
    if (newLang !== null) {
      setLang(newLang)
    }
  }

  const handleAccept = () => {
    localStorage.setItem('acceptedTerms', 'true')
    navigate('/')
  }

  const handleDecline = () => {
    localStorage.setItem('acceptedTerms', 'false')
    alert(
      lang === 'ru'
        ? 'Вы не можете использовать сайт без согласия с условиями.'
        : 'You cannot use the site without agreeing to the terms.'
    )
  }

  const content = {
    ru: {
      title: 'Пользовательское соглашение NeoMovies',
      subtitle: 'Пожалуйста, внимательно ознакомьтесь с условиями использования',
      selectLanguage: 'Выберите язык',
      accept: 'Принимаю условия',
      decline: 'Отклонить',
      footer: '© 2026 Neo-Open-Source. Все права защищены.',
      sections: [
        {
          title: '1. Общие положения',
          text: 'Использование сайта NeoMovies возможно только при полном согласии с условиями настоящего Пользовательского соглашения. Несогласие с любыми положениями соглашения означает, что вы не имеете права использовать данный сайт и должны прекратить доступ к нему.',
        },
        {
          title: '2. Описание сервиса',
          text: 'NeoMovies предоставляет доступ к информации о фильмах и сериалах. Видео воспроизводятся с использованием сторонних видеохостингов и балансеров. Сайт не хранит и не распространяет видеофайлы. Мы выступаем исключительно в роли посредника между пользователем и внешними сервисами.\n\nНекоторая информация о доступности контента также может быть получена из общедоступных децентрализованных источников. Сайт не распространяет файлы и не является участником пиринговых сетей.',
        },
        {
          title: '3. Ответственность',
          text: 'Сайт не несёт ответственности за:',
          list: [
            'точность или легальность предоставленного сторонними плеерами контента;',
            'возможные нарушения авторских прав со стороны балансеров;',
            'действия пользователей, связанные с просмотром, загрузкой или распространением контента.',
          ],
          afterList: 'Вся ответственность за использование контента лежит исключительно на пользователе. Использование сторонних источников осуществляется на ваш собственный риск.',
        },
        {
          title: '4. Регистрация и персональные данные',
          text: 'Сайт собирает только минимальный набор данных: имя, email и пароль — исключительно для сохранения избранного. Пароли шифруются и хранятся безопасно. Мы не передаём ваши данные третьим лицам и не используем их в маркетинговых целях.\n\nИсходный код сайта полностью открыт и доступен для проверки в публичном репозитории, что обеспечивает максимальную прозрачность и возможность независимого аудита безопасности и обработки данных.\n\nПользователь подтверждает, что ему исполнилось 16 лет либо он получил разрешение от законного представителя.',
        },
        {
          title: '5. Изменения в соглашении',
          text: 'Мы оставляем за собой право вносить изменения в настоящее соглашение. Продолжение использования сервиса после внесения изменений означает ваше согласие с обновлёнными условиями.',
        },
        {
          title: '6. Заключительные положения',
          text: 'Настоящее соглашение вступает в силу с момента вашего согласия с его условиями и действует бессрочно.\n\nЕсли вы не согласны с какими-либо положениями данного соглашения, вы должны немедленно прекратить использование сервиса.',
        },
      ],
    },
    en: {
      title: 'NeoMovies Terms of Service',
      subtitle: 'Please read the terms of use carefully',
      selectLanguage: 'Select Language',
      accept: 'Accept Terms',
      decline: 'Decline',
      footer: '© 2026 Neo-Open-Source. All rights reserved.',
      sections: [
        {
          title: '1. General Provisions',
          text: 'Use of the NeoMovies website is only possible with full agreement to the terms of this User Agreement. Disagreement with any provisions of the agreement means that you do not have the right to use this site and must stop accessing it.',
        },
        {
          title: '2. Service Description',
          text: 'NeoMovies provides access to information about movies and TV shows. Videos are played using third-party video hosting services and load balancers. The site does not store or distribute video files. We act exclusively as an intermediary between the user and external services.\n\nSome information about content availability may also be obtained from publicly available decentralized sources. The site does not distribute files and is not a participant in peer-to-peer networks.',
        },
        {
          title: '3. Liability',
          text: 'The site is not responsible for:',
          list: [
            'the accuracy or legality of content provided by third-party players;',
            'possible copyright violations by load balancers;',
            'user actions related to viewing, downloading, or distributing content.',
          ],
          afterList: 'All responsibility for using the content lies solely with the user. Use of third-party sources is at your own risk.',
        },
        {
          title: '4. Registration and Personal Data',
          text: 'The site collects only a minimal set of data: name, email, and password — exclusively for saving favorites. Passwords are encrypted and stored securely. We do not share your data with third parties and do not use it for marketing purposes.\n\nThe site\'s source code is fully open and available for review in a public repository, ensuring maximum transparency and the ability for independent security and data processing audits.\n\nThe user confirms that they are at least 16 years old or have received permission from a legal guardian.',
        },
        {
          title: '5. Changes to the Agreement',
          text: 'We reserve the right to make changes to this agreement. Continued use of the service after changes are made means your acceptance of the updated terms.',
        },
        {
          title: '6. Final Provisions',
          text: 'This agreement comes into effect from the moment you agree to its terms and is valid indefinitely.\n\nIf you do not agree with any provisions of this agreement, you must immediately stop using the service.',
        },
      ],
    },
  }

  const t = content[lang]

  return (
    <Box sx={{ minHeight: '100vh', backgroundColor: colors.pageBg, py: { xs: 2, sm: 4 } }}>
      <Container maxWidth="lg">
        <Paper elevation={3} sx={{ p: { xs: 2, sm: 4 }, backgroundColor: colors.paperBg, color: colors.text }}>
          {/* Language Selector */}
          <Box sx={{ mb: 3, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 1, flexDirection: { xs: 'column', sm: 'row' } }}>
            <LanguageIcon sx={{ color: 'primary.main', fontSize: { xs: '1.5rem', sm: '1.75rem' } }} />
            <Typography variant="h6" sx={{ fontSize: { xs: '0.95rem', sm: '1.25rem' } }}>{t.selectLanguage}</Typography>
          </Box>

          <Box sx={{ mb: 3, display: 'flex', justifyContent: 'center' }}>
            <ToggleButtonGroup
              value={lang}
              exclusive
              onChange={handleLanguageChange}
              aria-label="language"
              size="small"
              sx={{
                '& .MuiToggleButton-root': {
                  color: colors.text,
                  borderColor: colors.buttonBorder,
                  backgroundColor: 'transparent',
                },
                '& .MuiToggleButton-root.Mui-selected': {
                  color: dark ? '#fff' : '#111827',
                  backgroundColor: dark ? '#2a2a2a' : '#eef2ff',
                },
                '& .MuiToggleButton-root.Mui-selected:hover': {
                  backgroundColor: dark ? '#343434' : '#e0e7ff',
                },
              }}
            >
              <ToggleButton value="ru" aria-label="russian" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                Русский
              </ToggleButton>
              <ToggleButton value="en" aria-label="english" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                English
              </ToggleButton>
            </ToggleButtonGroup>
          </Box>

          <Divider sx={{ mb: 3 }} />

          {/* Header */}
          <Box sx={{ textAlign: 'center', mb: 3 }}>
            <Typography variant="h4" component="h1" gutterBottom sx={{ fontWeight: 'bold', fontSize: { xs: '1.5rem', sm: '2.125rem' } }}>
              {t.title}
            </Typography>
            <Typography variant="body2" sx={{ fontSize: { xs: '0.8rem', sm: '0.875rem' }, color: colors.subtitle }}>
              {t.subtitle}
            </Typography>
          </Box>

          {/* Content */}
          <Box sx={{ mb: 3, lineHeight: 1.6 }}>
            {t.sections.map((section, index) => (
              <Box key={index} sx={{ mb: 2 }}>
                <Typography variant="h6" component="h2" sx={{ fontWeight: 'bold', mb: 1, color: colors.text, fontSize: { xs: '0.95rem', sm: '1.25rem' } }}>
                  {section.title}
                </Typography>
                {section.text.split('\n\n').map((paragraph, pIndex) => (
                  <Typography key={pIndex} variant="body2" sx={{ mb: 0.75, color: colors.muted, fontSize: { xs: '0.8rem', sm: '0.875rem' } }}>
                    {paragraph}
                  </Typography>
                ))}
                {section.list && (
                  <>
                    <Box component="ul" sx={{ pl: 2, mb: 0.75 }}>
                      {section.list.map((item, liIndex) => (
                        <Typography key={liIndex} component="li" variant="body2" sx={{ mb: 0.3, color: colors.muted, fontSize: { xs: '0.8rem', sm: '0.875rem' } }}>
                          {item}
                        </Typography>
                      ))}
                    </Box>
                    {section.afterList && (
                      <Typography variant="body2" sx={{ mb: 0.75, color: colors.muted, fontSize: { xs: '0.8rem', sm: '0.875rem' } }}>
                        {section.afterList}
                      </Typography>
                    )}
                  </>
                )}
              </Box>
            ))}
          </Box>

          <Divider sx={{ my: 3, borderColor: colors.border }} />

          {/* Actions */}
          <Box sx={{ display: 'flex', justifyContent: { xs: 'center', sm: 'flex-end' }, gap: 1, flexDirection: { xs: 'column', sm: 'row' } }}>
            <Button 
              variant="outlined" 
              onClick={handleDecline} 
              sx={{ color: colors.muted, borderColor: colors.buttonBorder, fontSize: { xs: '0.8rem', sm: '0.875rem' }, width: { xs: '100%', sm: 'auto' } }}
            >
              {t.decline}
            </Button>
            <Button 
              variant="contained" 
              color="primary" 
              onClick={handleAccept}
              sx={{ fontSize: { xs: '0.8rem', sm: '0.875rem' }, width: { xs: '100%', sm: 'auto' } }}
            >
              {t.accept}
            </Button>
          </Box>

          {/* Footer */}
          <Box sx={{ mt: 3, textAlign: 'center', borderTop: `1px solid ${colors.border}`, pt: 2 }}>
            <Typography variant="caption" sx={{ color: colors.subtitle, fontSize: { xs: '0.7rem', sm: '0.75rem' } }}>
              {t.footer}
            </Typography>
          </Box>
        </Paper>
      </Container>
    </Box>
  )
}
