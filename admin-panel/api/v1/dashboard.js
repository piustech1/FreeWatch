import { setCorsAndCache, getDashboardData } from './_lib/catalogService.js';

export default async function handler(req, res) {
  setCorsAndCache(res, { maxAge: 300, stale: 600 }); // Edge cached for 5 mins

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    const data = await getDashboardData();
    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    console.error('Error serving /api/v1/dashboard:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to generate dashboard',
      details: error.message,
    });
  }
}
