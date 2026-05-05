/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL?: string
  readonly VITE_NEO_ID_URL?: string
  readonly VITE_NEO_ID_API_KEY?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
