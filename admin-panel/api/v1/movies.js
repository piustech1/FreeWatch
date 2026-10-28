import { setCorsAndCache, getFullCatalog } from './_lib/catalogService.js';

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
      limit = 20,
      sort = 'latest',
    } = req.query || {};

    let list = await getFullCatalog();

    // 1. Filter by Search Query
    const searchQuery = (q || search || '').trim().toLowerCase();
    if (searchQuery) {
      list = list.filter(m =>
        m.title.toLowerCase().includes(searchQuery) ||
        m.vj.toLowerCase().includes(searchQuery) ||
        m.category.toLowerCase().includes(searchQuery)
      );
    }

    // 2. Filter by VJ
    const vjFilter = (vj || '').trim().toLowerCase();
    if (vjFilter) {
      list = list.filter(m => m.vj.toLowerCase().includes(vjFilter));
    }

    // 3. Filter by Category / Genre
    const catFilter = (category || genre || '').trim().toLowerCase();
    if (catFilter) {
      if (catFilter === 'series') {
        list = list.filter(m => m.isTv);
      } else {
        list = list.filter(m => m.category.toLowerCase().includes(catFilter));
      }
    }

    // 4. Sort
    if (sort === 'rating') {
      list.sort((a, b) => b.vote_average - a.vote_average);
    } else if (sort === 'title') {
      list.sort((a, b) => a.title.localeCompare(b.title));
    } else {
      // default: latest ID
      list.sort((a, b) => b.id - a.id);
    }

    // 5. Pagination
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
    const total = list.length;
    const totalPages = Math.ceil(total / limitNum);
    const startIndex = (pageNum - 1) * limitNum;
    const items = list.slice(startIndex, startIndex + limitNum);

    return res.status(200).json({
      success: true,
      total,
      page: pageNum,
      limit: limitNum,
      totalPages,
      hasMore: pageNum < totalPages,
      data: items,
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
