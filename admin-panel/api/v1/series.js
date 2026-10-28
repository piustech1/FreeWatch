import { setCorsAndCache, getSeriesEpisodes } from './_lib/catalogService.js';

export default async function handler(req, res) {
  setCorsAndCache(res, { maxAge: 600, stale: 1200 });

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    const { id, code } = req.query || {};
    const seriesIdentifier = code || id;

    if (!seriesIdentifier) {
      return res.status(400).json({
        success: false,
        error: 'Missing required query parameter: id or code',
      });
    }

    const seriesData = await getSeriesEpisodes(seriesIdentifier);
    return res.status(200).json({
      success: true,
      data: seriesData,
    });
  } catch (error) {
    console.error('Error serving /api/v1/series:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch series episodes',
      details: error.message,
    });
  }
}
