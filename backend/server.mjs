import http from 'node:http';
import crypto from 'node:crypto';
import { XMLParser } from 'fast-xml-parser';

const PORT = Number(process.env.PORT || 8080);
const parser = new XMLParser({ ignoreAttributes: false, attributeNamePrefix: '@_' });

const feeds = [
  ['World', 'BBC News', 'https://feeds.bbci.co.uk/news/world/rss.xml'],
  ['Business', 'BBC News', 'https://feeds.bbci.co.uk/news/business/rss.xml'],
  ['Technology', 'BBC News', 'https://feeds.bbci.co.uk/news/technology/rss.xml'],
  ['Politics', 'BBC News', 'https://feeds.bbci.co.uk/news/politics/rss.xml'],
  ['Science', 'BBC News', 'https://feeds.bbci.co.uk/news/science_and_environment/rss.xml'],
  ['Health', 'BBC News', 'https://feeds.bbci.co.uk/news/health/rss.xml'],
  ['World', 'NPR', 'https://feeds.npr.org/1004/rss.xml'],
  ['Business', 'NPR', 'https://feeds.npr.org/1006/rss.xml'],
  ['Technology', 'NPR', 'https://feeds.npr.org/1019/rss.xml'],
  ['Politics', 'NPR', 'https://feeds.npr.org/1014/rss.xml'],
  ['Science', 'NPR', 'https://feeds.npr.org/1007/rss.xml'],
  ['Health', 'NPR', 'https://feeds.npr.org/1008/rss.xml'],
  ['World', 'Al Jazeera', 'https://www.aljazeera.com/xml/rss/all.xml'],
  ['World', 'Deutsche Welle', 'https://rss.dw.com/rdf/rss-en-all'],
  ['World', 'France 24', 'https://www.france24.com/en/rss'],
  ['World', 'Euronews', 'https://www.euronews.com/rss?format=mrss&level=theme&name=news'],
  ['World', 'Sky News', 'https://feeds.skynews.com/feeds/rss/home.xml'],
  ['World', 'CBC News', 'https://www.cbc.ca/webfeed/rss/rss-topstories'],
  ['World', 'PBS NewsHour', 'https://www.pbs.org/newshour/feeds/rss/headlines'],
  ['World', 'CNN', 'https://rss.cnn.com/rss/edition.rss'],
  ['World', 'The New York Times', 'https://rss.nytimes.com/services/xml/rss/nyt/World.xml'],
  ['Politics', 'The New York Times', 'https://rss.nytimes.com/services/xml/rss/nyt/Politics.xml'],
  ['Business', 'The New York Times', 'https://rss.nytimes.com/services/xml/rss/nyt/Business.xml'],
  ['Technology', 'The New York Times', 'https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml'],
  ['World', 'The Guardian', 'https://www.theguardian.com/world/rss'],
  ['Politics', 'The Guardian', 'https://www.theguardian.com/politics/rss'],
  ['Business', 'The Guardian', 'https://www.theguardian.com/business/rss'],
  ['Technology', 'The Guardian', 'https://www.theguardian.com/technology/rss'],
];

const clean = (v) => typeof v === 'string' ? v.trim() : '';
const arr = (v) => Array.isArray(v) ? v : (v ? [v] : []);

function stripHtml(value) {
  return clean(String(value || '').replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' '));
}
function validUrl(value, { image = false } = {}) {
  try {
    const u = new URL(clean(value));
    if (u.protocol !== 'http:' && u.protocol !== 'https:') return '';
    if (image && u.protocol === 'http:') u.protocol = 'https:';
    return u.toString();
  } catch { return ''; }
}
function decodeEntities(s) {
  return s.replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>');
}
function firstValue(...values) {
  for (const value of values) if (typeof value === 'string' && value.trim()) return value.trim();
  return '';
}
function extractLink(item) {
  for (const link of arr(item?.link)) {
    if (typeof link === 'string') { const u = validUrl(link); if (u) return u; }
    if (link && typeof link === 'object') {
      const u = validUrl(link['@_href'] || link.href || link['#text']);
      if (u) return u;
    }
  }
  return validUrl(item?.guid?.['#text'] || item?.guid || item?.id);
}
function extractImage(item) {
  const candidates = [];
  for (const value of arr(item?.enclosure)) {
    if (value && typeof value === 'object') candidates.push(value['@_url'], value['@_href'], value.url);
  }
  for (const key of ['media:content','media:thumbnail']) {
    for (const value of arr(item?.[key])) {
      if (value && typeof value === 'object') candidates.push(value['@_url'], value['@_href'], value.url);
      else candidates.push(value);
    }
  }
  candidates.push(item?.image?.url, item?.image?.['@_href']);
  for (const value of candidates) {
    const u = validUrl(value, { image: true });
    if (u) return u;
  }
  const html = String(item?.['content:encoded'] || item?.description || item?.summary || '');
  const matches = [...html.matchAll(/<(?:img|source)[^>]+(?:src|data-src|srcset)=["']([^"']+)["']/gi)];
  for (const m of matches) {
    const raw = String(m[1]).split(',')[0].trim().split(/\s+/)[0];
    const u = validUrl(raw, { image: true });
    if (u) return u;
  }
  return '';
}
function toStory(item, category, source) {
  const title = clean(item?.title);
  const url = extractLink(item);
  if (!title || !url) return null;
  const publishedAt = firstValue(item?.pubDate, item?.isoDate, item?.published, item?.updated, item?.['dc:date'], item?.date);
  const description = stripHtml(item?.description || item?.summary || item?.['content:encoded'] || item?.content || '');
  const image = extractImage(item);
  return {
    id: crypto.createHash('sha256').update(`${source}|${url}`).digest('hex').slice(0,24),
    headline: decodeEntities(title),
    neutralSummary: decodeEntities(description || title),
    summarySource: 'source',
    category,
    publishedAt,
    sourceName: source,
    articleUrl: url,
    imageUrl: image,
    semanticLabel: decodeEntities(title),
    isBreaking: false,
    outlets: [{ name: source, lean: '', framing: '', articleUrl: url }],
  };
}
async function fetchFeed(category, source, url) {
  const response = await fetch(url, { headers: { 'User-Agent': 'TruthNewsBackend/2.0 (+https://truthnews.app)' }, signal: AbortSignal.timeout(12000) });
  if (!response.ok) throw new Error(`${source}: Feed ${response.status}`);
  const xml = await response.text();
  const data = parser.parse(xml);
  const items = arr(data?.rss?.channel?.item).concat(arr(data?.feed?.entry));
  return items.map(x => toStory(x, category, source)).filter(Boolean);
}
function titleTerms(title) {
  const stop = new Set(['the','a','an','and','or','of','to','in','on','for','with','as','at','by','from','is','are','was','were','be','been','has','have','had','this','that','after','before','over','into','amid','says','said','new','news']);
  return new Set(clean(title).toLowerCase().replace(/[^a-z0-9Â£$%]+/g,' ').split(/\s+/).filter(w => w.length >= 3 && !stop.has(w)));
}
function titlesMatch(a,b) {
  const left=titleTerms(a), right=titleTerms(b);
  if(left.size<3 || right.size<3) return false;
  let intersection=0; for(const w of left) if(right.has(w)) intersection++;
  const union=new Set([...left,...right]).size;
  return intersection>=3 && (intersection/union>=0.42 || intersection/Math.min(left.size,right.size)>=0.72);
}
function mergeStories(stories) {
  const groups=[];
  for(const story of stories) {
    let group=groups.find(g => g.story.category===story.category && titlesMatch(g.story.headline,story.headline));
    if(!group) { groups.push({story:{...story},outlets:[...story.outlets]}); continue; }
    if(!group.outlets.some(o => o.name===story.sourceName)) group.outlets.push(...story.outlets);
    if(!group.story.imageUrl && story.imageUrl) group.story.imageUrl=story.imageUrl;
    if(new Date(story.publishedAt||0)>new Date(group.story.publishedAt||0)) group.story.publishedAt=story.publishedAt;
    if((story.neutralSummary||'').length>(group.story.neutralSummary||'').length) group.story.neutralSummary=story.neutralSummary;
  }
  return groups.map(({story,outlets}) => ({
    ...story, outletCount:outlets.length, outlets,
    id:crypto.createHash('sha256').update(outlets.map(o=>o.articleUrl).sort().join('|')).digest('hex').slice(0,24),
  })).sort((a,b)=>new Date(b.publishedAt||0)-new Date(a.publishedAt||0)).slice(0,60);
}

const AI_MODEL = process.env.OPENAI_MODEL || 'gpt-5.6-luna';
const OPENAI_API_KEY = clean(process.env.OPENAI_API_KEY);
const aiCache = new Map();

async function openAIJson(prompt) {
  if (!OPENAI_API_KEY) return null;
  const response = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: { 'Content-Type':'application/json', 'Authorization':`Bearer ${OPENAI_API_KEY}` },
    body: JSON.stringify({
      model: AI_MODEL,
      input: prompt,
      text: { format: { type: 'json_object' } },
    }),
    signal: AbortSignal.timeout(8000),
  });
  if (!response.ok) {
    const body = await response.text();
    throw new Error(`OpenAI ${response.status}: ${body.slice(0,300)}`);
  }
  const data = await response.json();
  const text = data.output_text || data.output?.flatMap(x => x.content || []).map(x => x.text || '').join('') || '';
  try { return JSON.parse(text); } catch { return null; }
}
async function enrichStory(story) {
  const key = `story:${story.id}`;
  if (aiCache.has(key)) return { ...story, ...aiCache.get(key) };
  if (!OPENAI_API_KEY) return story;
  const sourceText = story.outlets.map(o => `${o.name}: ${o.articleUrl}`).join('\n');
  const prompt = `You are the neutral editorial assistant for a news aggregation app.
Return JSON with exactly:
{"summary":"...","summarySource":"ai","outletLeans":[{"name":"...","lean":"Center|Lean Left|Left|Lean Right|Right"}]}
Rules:
- Write a factual, neutral summary of the story in 70-110 words. Do not add facts not supported by the supplied headline/description.
- Do not persuade, praise, condemn, or speculate.
- Assess each named outlet's political/media orientation using general publicly documented editorial positioning. This is an AI assessment, not an objective fact. Use exactly one of Center, Lean Left, Left, Lean Right, Right. Never use Unknown.
Story headline: ${story.headline}
Existing source description: ${story.neutralSummary}
Outlets:
${sourceText}`;
  try {
    const result = await openAIJson(prompt);
    const summary = clean(result?.summary);
    const outletLeans = Array.isArray(result?.outletLeans) ? result.outletLeans : [];
    const byName = new Map(outletLeans.map(x => [clean(x?.name), clean(x?.lean)]));
    const allowed = new Set(['Center','Lean Left','Left','Lean Right','Right']);
    const outlets = story.outlets.map(o => ({
      ...o,
      lean: allowed.has(byName.get(o.name)) ? byName.get(o.name) : o.lean,
    }));
    const patch = {
      ...(summary && summary.split(/\s+/).length >= 60 ? { neutralSummary: summary, summarySource:'ai' } : {}),
      outlets,
    };
    aiCache.set(key, patch);
    return { ...story, ...patch };
  } catch (e) {
    console.error('AI enrichment failed:', e.message);
    return story;
  }
}

async function getStories(categories) {
  const wanted = new Set(categories.length ? categories : feeds.map(([c])=>c));
  const selected=feeds.filter(([category])=>wanted.has(category));
  const results=await Promise.allSettled(selected.map(f=>fetchFeed(...f)));
  const seen=new Set();
  const unique=results.flatMap(r=>r.status==='fulfilled'?r.value:[]).filter(s=>{
    if(seen.has(s.articleUrl)) return false; seen.add(s.articleUrl); return true;
  });
  const merged=mergeStories(unique);
  // Enrich stories concurrently with a small limit.
const enriched = [];
const concurrency = 6;

for (let i = 0; i < merged.length; i += concurrency) {
  const batch = merged.slice(i, i + concurrency);

  const batchResults = await Promise.all(
    batch.map(story => enrichStory(story)),
  );

  enriched.push(...batchResults);
}

return enriched;
}
function sendJson(res,status,body) {
  const text=JSON.stringify(body);
  res.writeHead(status,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'public, max-age=120','Access-Control-Allow-Origin':'*'});
  res.end(text);
}
const server=http.createServer(async(req,res)=>{
  if(req.method==='OPTIONS'){res.writeHead(204,{'Access-Control-Allow-Origin':'*','Access-Control-Allow-Methods':'GET,OPTIONS'});return res.end();}
  const requestUrl=new URL(req.url,`http://${req.headers.host}`);
  if(req.method==='GET' && requestUrl.pathname==='/health') return sendJson(res,200,{ok:true,aiConfigured:Boolean(OPENAI_API_KEY),feedCount:feeds.length});
  if(req.method!=='GET' || requestUrl.pathname!=='/news') return sendJson(res,404,{error:'Not found'});
  try {
    const categories=clean(requestUrl.searchParams.get('categories')).split(',').map(clean).filter(Boolean);
    const articles=await getStories(categories);
    if(!articles.length) return sendJson(res,503,{error:'News is temporarily unavailable.'});
    return sendJson(res,200,{articles});
  } catch(error) {
    console.error(error);
    return sendJson(res,503,{error:'News is temporarily unavailable.'});
  }
});
server.listen(PORT,()=>console.log(`Truth backend listening on :${PORT}`));
