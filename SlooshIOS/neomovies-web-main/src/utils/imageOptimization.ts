/**
 * Оптимизация изображений для быстрой загрузки
 */

export const getOptimizedImageUrl = (url: string): string => {
  if (!url) return ''

  // Если это уже оптимизированный URL от нашего API
  if (url.includes('/api/v1/images/')) {
    return url
  }

  // Для внешних URL добавляем параметры оптимизации
  // Это работает если есть image CDN
  if (url.includes('kinopoiskapiunofficial')) {
    // Заменяем на меньший размер если возможно
    return url.replace(/kp_big/, 'kp').replace(/kp_small/, 'kp')
  }

  return url
}

/**
 * Preload image для лучшей производительности
 */
export const preloadImage = (src: string): Promise<void> => {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => resolve()
    img.onerror = reject
    img.src = src
  })
}

/**
 * Batch preload images
 */
export const preloadImages = async (urls: string[]): Promise<void> => {
  const promises = urls
    .filter((url) => !!url)
    .map((url) => preloadImage(url))
  
  await Promise.allSettled(promises)
}
