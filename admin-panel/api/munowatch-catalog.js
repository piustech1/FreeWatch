export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  try {
    let response;
    try {
      response = await fetch('https://mumowatch.ai.studio/dashboard', {
        headers: {
          'User-Agent': 'FreeWatch/1.0 (WebAdmin)',
          'Accept': 'application/json',
        },
      });
    } catch (_) {}

    if (!response || !response.ok) {
      try {
        response = await fetch('https://pearlpix-api.onrender.com/dashboard', {
          headers: {
            'User-Agent': 'FreeWatch/1.0 (WebAdmin)',
            'Accept': 'application/json',
          },
        });
      } catch (_) {}
    }

    if (!response || !response.ok) {
      throw new Error(`MunoWatch responded with HTTP ${response?.status || 'network error'}`);
    }

    const data = await response.json();
    return res.status(200).json(data);
  } catch (error) {
    console.error('Error proxying MunoWatch catalog:', error);
    return res.status(500).json({ error: 'Failed to fetch MunoWatch catalog', details: error.message });
  }
}
