import { setCorsAndCache, getMovieById, getFullCatalog } from './_lib/catalogService.js';

export default async function handler(req, res) {
  setCorsAndCache(res, { maxAge: 600, stale: 1200 });

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    const { id } = req.query || {};
    if (!id) {
      return res.status(400).json({
        success: false,
        error: 'Missing required query parameter: id',
      });
    }

    const movie = await getMovieById(id);
    if (!movie) {
      return res.status(404).json({
        success: false,
        error: `Movie with id ${id} not found`,
      });
    }

    // Related movies (same VJ or same Category)
    const catalog = await getFullCatalog();
    const related = catalog
      .filter(m => m.id !== movie.id && (m.vj === movie.vj || m.category === movie.category))
      .slice(0, 10);

    return res.status(200).json({
      success: true,
      data: {
        ...movie,
        related,
      },
    });
  } catch (error) {
    console.error('Error serving /api/v1/movie:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch movie details',
      details: error.message,
    });
  }
}
