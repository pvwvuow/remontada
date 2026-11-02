// Simple in-memory TTL cache with stale-while-error behavior
interface CacheEntry<T> {
  value: T;
  expiresAt: number;
  storedAt: number;
}

const store = new Map<string, CacheEntry<unknown>>();

export function cacheGet<T>(key: string): { value: T; stale: boolean } | null {
  const e = store.get(key);
  if (!e) return null;
  return { value: e.value as T, stale: Date.now() > e.expiresAt };
}

export function cacheSet<T>(key: string, value: T, ttlMs: number): void {
  store.set(key, { value, expiresAt: Date.now() + ttlMs, storedAt: Date.now() });
  // opportunistic cleanup
  if (store.size > 200) {
    const now = Date.now();
    for (const [k, v] of store) {
      if (now > v.expiresAt + 10 * 60 * 1000) store.delete(k);
    }
  }
}

export async function cached<T>(
  key: string,
  ttlMs: number,
  producer: () => Promise<T>
): Promise<T> {
  const hit = cacheGet<T>(key);
  if (hit && !hit.stale) return hit.value;
  try {
    const fresh = await producer();
    cacheSet(key, fresh, ttlMs);
    return fresh;
  } catch (err) {
    // stale-while-error: return old data if we have it
    if (hit) return hit.value;
    throw err;
  }
}
