"use client";

// ------------------------------------------------------------------
// Remontada — team favorites (localStorage, cross-tab synced)
// ------------------------------------------------------------------
// Storage shape: [{ id, fa, en?, ts }] capped at 30 entries, newest first.
// Sync strategy: a custom event for in-page updates + `storage` event
// for other tabs. useSyncExternalStore keeps React views in sync and
// SSR/hydration safe (server snapshot = empty list).
import { useSyncExternalStore } from "react";

export interface FavTeam {
  id: number;
  fa: string;
  en?: string;
  ts: number;
}

const KEY = "remontada:favorites";
const EVT = "remontada:favorites-changed";
const MAX = 30;

const EMPTY: FavTeam[] = [];
let cache: FavTeam[] | null = null;
const listeners = new Set<() => void>();
let initialized = false;

function isValidFav(x: unknown): x is FavTeam {
  if (!x || typeof x !== "object") return false;
  const o = x as Record<string, unknown>;
  return typeof o.id === "number" && Number.isFinite(o.id) && typeof o.fa === "string" && o.fa.length > 0;
}

function readRaw(): FavTeam[] {
  if (typeof window === "undefined") return EMPTY;
  try {
    const raw = window.localStorage.getItem(KEY);
    const arr: unknown = raw ? JSON.parse(raw) : [];
    if (!Array.isArray(arr)) return [];
    const clean = arr.filter(isValidFav).slice(0, MAX);
    // dedup by id (keep newest)
    const seen = new Set<number>();
    const out: FavTeam[] = [];
    for (const f of [...clean].sort((a, b) => (b.ts || 0) - (a.ts || 0))) {
      if (seen.has(f.id)) continue;
      seen.add(f.id);
      out.push(f);
    }
    return out;
  } catch {
    return [];
  }
}

function read(): FavTeam[] {
  if (cache) return cache;
  cache = readRaw();
  return cache;
}

function init() {
  if (initialized || typeof window === "undefined") return;
  initialized = true;
  const handler = () => {
    cache = null;
    listeners.forEach((l) => l());
  };
  window.addEventListener(EVT, handler);
  window.addEventListener("storage", (e) => {
    if (e.key === KEY || e.key === null) handler();
  });
}

function subscribe(cb: () => void): () => void {
  init();
  listeners.add(cb);
  return () => listeners.delete(cb);
}

function write(next: FavTeam[]) {
  cache = next;
  try {
    window.localStorage.setItem(KEY, JSON.stringify(next));
  } catch {
    // quota / private mode — in-memory state still works for this tab
  }
  window.dispatchEvent(new Event(EVT));
}

export function getFavorites(): FavTeam[] {
  return read();
}

export function isFavorite(id: number): boolean {
  return read().some((f) => f.id === id);
}

/** Toggle a team; returns the new state (true = now favorite). */
export function toggleFavorite(team: { id: number; fa: string; en?: string }): boolean {
  const cur = read();
  const exists = cur.some((f) => f.id === team.id);
  const next = exists
    ? cur.filter((f) => f.id !== team.id)
    : [{ id: team.id, fa: team.fa, en: team.en, ts: Date.now() }, ...cur].slice(0, MAX);
  write(next);
  return !exists;
}

export function removeFavorite(id: number) {
  write(read().filter((f) => f.id !== id));
}

/** React hook — SSR-safe (empty during hydration, updates right after). */
export function useFavorites(): FavTeam[] {
  return useSyncExternalStore(
    subscribe,
    () => read(),
    () => EMPTY
  );
}

export function useIsFavorite(id: number): boolean {
  return useFavorites().some((f) => f.id === id);
}
