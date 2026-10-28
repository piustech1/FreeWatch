import { setCorsAndCache, getFullCatalog, getVjAvatar } from './_lib/catalogService.js';

export default async function handler(req, res) {
  setCorsAndCache(res, { maxAge: 600, stale: 1200 });

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    const catalog = await getFullCatalog();
    const map = new Map();

    for (const m of catalog) {
      const vj = m.vj || 'Luganda Dubbed';
      map.set(vj, (map.get(vj) || 0) + 1);
    }

    const vjs = Array.from(map.entries())
      .map(([name, count]) => ({
        name,
        count,
        avatar: getVjAvatar(name),
      }))
      .sort((a, b) => b.count - a.count);

    return res.status(200).json({
      success: true,
      total: vjs.length,
      data: vjs,
    });
  } catch (error) {
    console.error('Error serving /api/v1/vjs:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to fetch VJs',
      details: error.message,
    });
  }
}
