import http from 'node:http';
import crypto from 'node:crypto';
import { XMLParser } from 'fast-xml-parser';

const PORT = Number(process.env.PORT || 8080);
const parser = new XMLParser({ ignoreAttributes: false, attributeNamePrefix: '@_' });
const feeds = [
  ['World', 'BBC News', 'https://feeds.bbci.co.uk/news/world/rss.xml'],
  ['Business', 'BBC News', 'https://feeds.bbci.co.uk/news/business/rss.xml'],
  ['Technology', 'BBC News', 'https://feeds.bbci.co.uk/news/technology/rss.xml'],
  ['World', 'NPR', 'https://feeds.npr.org/1001/rss.xml'],
  ['Technology', 'NPR', 'https://feeds.npr.org/1019/rss.xml'],
];

const clean = (v) => typeof v === 'string' ? v.trim() : '';
const arr = (v) => Array.isArray(v) ? v : (v ? [v] : []);
function stripHtml(value) {
  return clean(String(value || '').replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' '));
}
function validUrl(value) {
  try {
    const u = new URL(clean(value));
    return u.protocol === 'http:' || u.protocol === 'https:' ? u.toString() : '';
  } catch { return ''; }
}
function decodeEntities(s) {
  return s.replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>');
}
function toStory(item, category, feedSource) {
  const title = clean(item.title);
  const url = validUrl(item.link || item.guid?.['#text'] || item.guid);
  if (!title || !url) return null;
  const publishedAt = clean(item.pubDate || item.isoDate || item['dc:date']);
  const description = stripHtml(item.description || item.summary || '');
  const image = validUrl(item.enclosure?.['@_url'] || item['media:content']?.['@_url'] || '');
  const id = crypto.createHash('sha256').update(`${feedSource}|${url}`).digest('hex').slice(0, 24);
  return {
    id,
    headline: decodeEntities(title),
    neutralSummary: decodeEntities(description || title),
    summarySource: 'source',
    category,
    publishedAt,
    sourceName: feedSource,
    articleUrl: url,
    imageUrl: image,
    semanticLabel: decodeEntities(title),
    isBreaking: false,
    outlets: [{ name: feedSource, lean: 'Unknown', framing: '', articleUrl: url }],
  };
}
async function fetchFeed(category, source, url) {
  const response = await fetch(url, { headers: { 'User-Agent': 'TruthNewsBackend/1.0' }, signal: AbortSignal.timeout(10000) });
  if (!response.ok) throw new Error(`Feed ${response.status}`);
  const xml = await response.text();
  const data = parser.parse(xml);
  return arr(data?.rss?.channel?.item).map((x) => toStory(x, category, source)).filter(Boolean);
}
async function getStories(categories) {
  const wanted = new Set(categories.length ? categories : feeds.map(([c]) => c));
  const selected = feeds.filter(([category]) => wanted.has(category));
  const results = await Promise.allSettled(selected.map((f) => fetchFeed(...f)));
  const seen = new Set();
  return results.flatMap((r) => r.status === 'fulfilled' ? r.value : []).filter((story) => {
    if (seen.has(story.articleUrl)) return false;
    seen.add(story.articleUrl);
    return true;
  }).sort((a, b) => new Date(b.publishedAt || 0) - new Date(a.publishedAt || 0)).slice(0, 50);
}
function sendJson(res, status, body) {
  const text = JSON.stringify(body);
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'public, max-age=120', 'Access-Control-Allow-Origin': '*' });
  res.end(text);
}
const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') { res.writeHead(204, { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET,OPTIONS' }); return res.end(); }
  if (req.method === 'GET' && new URL(req.url, `http://${req.headers.host}`).pathname === '/health') return sendJson(res, 200, { ok: true });
  if (req.method !== 'GET' || new URL(req.url, `http://${req.headers.host}`).pathname !== '/news') return sendJson(res, 404, { error: 'Not found' });
  try {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const categories = clean(url.searchParams.get('categories')).split(',').map(clean).filter(Boolean);
    const articles = await getStories(categories);
    if (!articles.length) return sendJson(res, 503, { error: 'News is temporarily unavailable.' });
    return sendJson(res, 200, { articles });
  } catch (error) {
    console.error(error);
    return sendJson(res, 503, { error: 'News is temporarily unavailable.' });
  }
});
server.listen(PORT, () => console.log(`Truth backend listening on :${PORT}`));
