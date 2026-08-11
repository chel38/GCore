export type IdentityState =
  | 'uninitialized'
  | 'loading'
  | 'registration_required'
  | 'registering'
  | 'email_verification_pending'
  | 'registration_verified'
  | 'registration_finalizing'
  | 'profile_completion_required'
  | 'auth_verification_required'
  | 'authorized'
  | 'spawn_releasing'
  | 'post_spawn_identity'
  | 'character_required'
  | 'character_selected'
  | 'ready'
  | 'error'
  | 'disconnecting'

export interface AccountDto {
  id: number
  email: string
  firstName: string
  lastName: string
  displayName: string
  status: string
  createdAt: number
}

export interface CharacterDto {
  id: number
  firstName: string
  lastName: string
  createdAt: number
}

export interface IdentitySnapshot {
  protocolVersion: number
  locale: 'ru' | 'en'
  state: IdentityState
  account: AccountDto | null
  characters: CharacterDto[]
  selectedCharacter: CharacterDto | null
  limits: { maxCharacters: number }
  passwordAuthentication: false
  verification?: {
    type: 'registration' | 'authentication'
    maskedEmail: string
    expiresIn: number
    resendIn: number
  } | null
  registration?: {
    fullName: string
    email: string
    emailVerified: boolean
    profileOnly: boolean
  } | null
}

export interface NuiResponse {
  ok: boolean
  requestId?: string
  code?: string
}

export type NuiMessage =
  | { type: 'snapshot'; payload: IdentitySnapshot }
  | { type: 'rejected'; payload: { code: string; requestId?: string } }
  | { type: 'lifecycleError'; payload: { code: string } }
  | { type: 'reset' }

export interface NuiBridge {
  invoke<TPayload extends object>(callback: string, payload: TPayload): Promise<NuiResponse>
}
