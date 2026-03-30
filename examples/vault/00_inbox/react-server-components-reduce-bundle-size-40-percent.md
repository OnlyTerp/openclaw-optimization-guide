# React Server Components reduce bundle size 40 percent

Found a case study where migrating to React Server Components cut client bundle size by 40%. Critical for LCP and Core Web Vitals.

SSR logic runs on edge, only sends deltas to client. Reduces JavaScript payload significantly.

Source: Vercel post about Shopify's Hydrogen adoption.

Impact: 2.1s faster FCP, 38% drop in TTI.

Tag: #performance #rsc