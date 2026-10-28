import { setCorsAndCache, searchCatalog } from './_lib/catalogService.js';

export default async function handler(req, res) {
  setCorsAndCache(res, { maxAge: 120, stale: 240 });

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    const { q, query } = req.query || {};
    const searchTarget = q || query || '';

    if (!searchTarget.trim()) {
      return res.status(200).json({
        success: true,
        query: '',
        total: 0,
        data: [],
      });
    }

    const results = await searchCatalog(searchTarget);

    return res.status(200).json({
      success: true,
      query: searchTarget,
      total: results.length,
      data: results,
    });
  } catch (error) {
    console.error('Error serving /api/v1/search:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to search catalog',
      details: error.message,
    });
  }
}
