import { setCorsAndCache, getMoviesPaginated } from './_lib/catalogService.js';

export default async function handler(req, res) {
  setCorsAndCache(res, { maxAge: 180, stale: 360 });

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    const {
      vj,
      category,
      genre,
      q,
      search,
      page = 1,
      limit = 40,
      sort = 'newest',
    } = req.query || {};

    const result = await getMoviesPaginated({
      page,
      limit,
      vj,
      category: category || genre,
      search: q || search,
      sort,
    });

    return res.status(200).json({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error('Error serving /api/v1/movies:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch movies',
      details: error.message,
    });
  }
}
