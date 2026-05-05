import type { Movie } from '../types'

export const filterValidMovies = (movies: Movie[]): Movie[] => {
  return movies.filter((movie) => {
    // Check if has poster
    const hasPoster = !!(
      movie.poster_path ||
      movie.posterUrlPreview ||
      movie.posterUrl
    )

    // Check if has title/name
    const hasTitle = !!(
      movie.title ||
      movie.name ||
      movie.nameRu ||
      movie.nameOriginal
    )

    // Year/rating in v2 API can be absent or equal to 0, so we do not
    // hard-filter by them; otherwise full pages become empty.
    return hasPoster && hasTitle
  })
}
